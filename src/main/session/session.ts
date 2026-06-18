import { streamText } from 'ai'
import { Agent } from '../agent/agent'
import { Provider } from '../provider/provider'
import { Tool } from '../tool/registry'
import { Retrieval } from '../retrieval/engine'
import { MemoryStore } from '../memory/store'
import { MemoryRetrieval } from '../memory/retrieve'
import { matchGoldenShortcut } from './golden-shortcut'
import { Lessons } from '../memory/lessons'
import { NarrationManager } from './narration'
import { ascending } from '../util/id'
import { Log } from '../util/log'
import { Bus } from '../util/bus'
import { getCsoundEnvironmentBlock } from '../util/csound-version'
import { usageFromSdk } from '../util/usage-cost'
import { isProPlus, isWorkshopLite } from '../util/tier'
import { consultSpecialists } from './specialist-consult'

export interface SessionMessage {
  id: string
  role: 'user' | 'assistant' | 'system'
  content: string
  timestamp: number
}

export interface Session {
  id: string
  agentName: string
  messages: SessionMessage[]
  createdAt: number
  title?: string | null
}

const sessions = new Map<string, Session>()

/** Per-session abort + optional hook to unblock a hung stream loop. */
const generationAbort = new Map<string, { cancelled: boolean; forceEnd?: () => void }>()

/** Max wait for the main model stream (first byte or finish). */
const STREAM_TIMEOUT_MS = 120_000

export interface SendOptions {
  /** Re-send without adding another user turn to session history. */
  retry?: boolean
  /** Same intent, higher temperature + fresh Csound seed hint. */
  variant?: boolean
}

export namespace SessionManager {
  export function cancel(sessionID: string): void {
    const gen = generationAbort.get(sessionID)
    if (!gen) return
    gen.cancelled = true
    gen.forceEnd?.()
  }
  export function create(agentName: string): Session {
    const id = ascending('session')
    const session: Session = {
      id,
      agentName,
      messages: [],
      createdAt: Date.now(),
    }
    sessions.set(id, session)
    MemoryStore.upsertSession({ id, agentName, createdAt: session.createdAt })
    Log.info(`Session created: ${id} (${agentName})`)
    return session
  }

  export function get(id: string): Session | undefined {
    const live = sessions.get(id)
    if (live) return live
    // Cold session from a previous run — hydrate from the persistent store so
    // chats survive app restarts.
    const persisted = MemoryStore.loadSession(id)
    if (!persisted) return undefined
    const session: Session = {
      id: persisted.session.id,
      agentName: persisted.session.agentName,
      messages: persisted.messages.map((m) => ({
        id: m.id,
        role: m.role,
        content: m.content,
        timestamp: m.timestamp,
      })),
      createdAt: persisted.session.createdAt,
      title: persisted.session.title,
    }
    sessions.set(id, session)
    return session
  }

  export function list(): Session[] {
    // Merge in-memory sessions with persisted ones (persisted wins on dedupe so
    // restored chats show their stored title/agent), most-recent first.
    const byId = new Map<string, Session>()
    for (const row of MemoryStore.listSessions()) {
      byId.set(row.id, {
        id: row.id,
        agentName: row.agentName,
        messages: [],
        createdAt: row.createdAt,
        title: row.title,
      })
    }
    for (const s of sessions.values()) byId.set(s.id, s)
    return Array.from(byId.values()).sort((a, b) => b.createdAt - a.createdAt)
  }

  export async function* send(
    sessionID: string,
    content: string,
    opts: SendOptions = {},
  ): AsyncGenerator<{ type: string; content: string; toolName?: string }> {
    const session = get(sessionID)
    if (!session) {
      yield { type: 'error', content: `Session not found: ${sessionID}` }
      return
    }

    const agent = Agent.get(session.agentName)
    if (!agent) {
      yield { type: 'error', content: `Agent not found: ${session.agentName}` }
      return
    }

    const retry = Boolean(opts.retry || opts.variant)

    if (!retry) {
      const userMsg: SessionMessage = {
        id: ascending('message'),
        role: 'user',
        content,
        timestamp: Date.now(),
      }
      session.messages.push(userMsg)
      if (!session.title) session.title = content.replace(/\s+/g, ' ').trim().slice(0, 80)
      MemoryStore.appendMessage({ ...userMsg, sessionId: sessionID })
      MemoryStore.touchSession(sessionID, session.title ?? undefined)
    } else {
      Log.info(`Retrying generation in session ${sessionID}${opts.variant ? ' (variant)' : ''}`)
    }

    yield { type: 'status', content: retry ? 'Retrying your request…' : 'Preparing your request…' }

    const isAutofix = /^The CSD you just wrote failed to (compile|run)\b/.test(content)

    if (!isAutofix && !retry && !isConversionTurn(content)) {
      const golden = matchGoldenShortcut(content)
      if (golden) {
        Log.info(`Golden shortcut: ${golden.starterId}`)
        yield { type: 'status', content: 'Using verified golden pattern (Csound 7 compile-checked)…' }
        const response = `${golden.intro}\n\n${golden.csd}`
        yield { type: 'text', content: response }
        const assistantMsg: SessionMessage = {
          id: ascending('message'),
          role: 'assistant',
          content: response,
          timestamp: Date.now(),
        }
        session.messages.push(assistantMsg)
        MemoryStore.appendMessage({ ...assistantMsg, sessionId: sessionID })
        MemoryStore.touchSession(sessionID)
        Bus.emit('session:message', { sessionID, role: 'assistant', content: response })
        return
      }
    }

    const abort = { cancelled: false, forceEnd: undefined as (() => void) | undefined }
    generationAbort.set(sessionID, abort)
    const clearAbort = () => generationAbort.delete(sessionID)

    Retrieval.init()
    const [ragContext, specialistBrief] = await Promise.all([
      Promise.resolve(Agent.isSineMode(agent) ? '' : Retrieval.formatForPrompt(content)),
      !Agent.isSineMode(agent) && !isAutofix ? consultSpecialists(content) : Promise.resolve(''),
    ])
    const ragBlock = [ragContext, specialistBrief].filter(Boolean).join('\n\n')
    const memory = {
      lessons: MemoryRetrieval.lessonsBlock(),
      // Proactive "previous errors" on real generation turns only. On autofix turns
      // the detailed errorFixBlock (full before/after) already fires for the exact
      // error, so the compact proactive list would be redundant.
      previousErrors: isAutofix ? '' : MemoryRetrieval.previousErrorsBlock(),
      guidance: MemoryRetrieval.learningBlock(),
      errorFixes: isAutofix
        ? MemoryRetrieval.errorFixBlock(content, content.includes('Runtime error') ? 'runtime' : 'compile')
        : '',
    }

    // Best-effort: learn any durable instruction this turn stated, for next time.
    // Skip autofix/conversion turns — those aren't user preferences.
    if (!isAutofix && !isConversionTurn(content) && !retry) {
      void Lessons.maybeCapture(content, sessionID)
    }
    const systemPrompt = buildSystemPrompt(agent, ragBlock, memory)

    // Resolve model
    const resolvedModel = agent.model
      ? agent.model
      : Agent.isSineMode(agent)
        ? Provider.smallModel()
        : Provider.defaultProvider()

    Log.info(`Using model: ${resolvedModel.providerID}/${resolvedModel.modelID}`)

    const providerLabel = Provider.providerLabel(resolvedModel.providerID)
    yield {
      type: 'status',
      content: `Calling ${providerLabel} (${resolvedModel.modelID})…`,
    }

    const providerChain = Provider.providerChain(resolvedModel)
    let activeModel = resolvedModel

    // Convert session history to AI SDK format
    const aiMessages = session.messages.map((m) => ({
      role: m.role as 'user' | 'assistant',
      content: m.content,
    }))

    // Surface any standing rule that matches this request RIGHT NEXT TO the
    // request itself. A rule buried in a 270-line system prompt is easy for the
    // model to skip; inline it can't. Only on real requests, not autofix/retry.
    if (!isAutofix && !retry && aiMessages.length > 0) {
      const matched = MemoryRetrieval.matchedLessons(content)
      if (matched.length > 0) {
        const last = aiMessages[aiMessages.length - 1]
        // Forceful, concrete framing: the rule OVERRIDES defaults and must be
        // realized in the actual code, not merely acknowledged in prose. Weak
        // wording let the model honor the letter ("pitched grains") while
        // missing the intent ("tonal"), e.g. random continuous grain pitch.
        last.content =
          `${last.content}\n\n` +
          `[NON-NEGOTIABLE standing rule you gave me earlier. It OVERRIDES my default approach and any conflicting habit. Apply it concretely in the generated code, not just in the description: ${matched.join(' ')}]`
        Log.info(`Applied ${matched.length} standing rule(s) inline: ${JSON.stringify(matched)}`)
      } else if (memory.lessons) {
        Log.info(`Standing rules exist but none token-matched this request`)
      }
    }

    Log.info(
      `Streaming with ${aiMessages.length} messages, ` +
      `system prompt ${systemPrompt.length} chars, ` +
      `lessons block ${memory.lessons ? memory.lessons.length : 0} chars, ` +
      `model ${resolvedModel.providerID}/${resolvedModel.modelID}`,
    )

    // Kick off narration + main stream in parallel. A shared queue lets whichever
    // emits first reach the caller first, and chunks interleave naturally.
    type StreamChunk = { type: string; content: string; toolName?: string }
    const queue: StreamChunk[] = []
    let mainDone = false
    let narrationDone = false
    let wake: (() => void) | null = null
    const notifyWaiters = () => {
      const w = wake
      wake = null
      w?.()
    }
    const ready = () => new Promise<void>((r) => { wake = r })
    const push = (c: StreamChunk) => { queue.push(c); notifyWaiters() }

    // Narration — best effort, grounded in the book index. Suppressed for:
    //  - autofix turns (prompt is full of error text + CSD, pushes the narrator off-script)
    //  - conversion templates (Web App / VST / CSD / Player — narrator misreads the
    //    "convert this code" instruction and either refuses or apologizes; nothing
    //    useful to add to a mechanical reformat)
    // isAutofix is computed earlier (drives both memory retrieval and narration).
    const isConversion = isConversionTurn(content)
    const lastCsd = lastAssistantCsd(session)
    // Workshop / free-tier mode: skip narration (2 extra Gemini calls per turn). Each
    // Agent message otherwise burns 3 API requests and hits the 20 RPM free cap fast.
    const workshopLite = isWorkshopLite()
    if (!workshopLite && !isAutofix && !isConversion && !retry && NarrationManager.canFire(sessionID)) {
      NarrationManager.markFired(sessionID)
      ;(async () => {
        try {
          for await (const ev of NarrationManager.streamNarration(content, lastCsd)) {
            push({ type: ev.type, content: ev.content })
          }
        } catch (err: any) {
          Log.warn(`Narration error: ${err.message}`)
        } finally {
          narrationDone = true
          notifyWaiters()
        }
      })()
    } else {
      // Either cooldown or autofix — nothing to stream.
      narrationDone = true
    }

    // Main response stream.
    let fullContent = ''
    let timedOut = false
    const baseTemperature = agent.temperature ?? 0.75
    let streamTemperature = baseTemperature
    if (opts.variant && aiMessages.length > 0) {
      streamTemperature = Math.min(1, baseTemperature + 0.18)
      const lastUser = [...aiMessages].reverse().find((m) => m.role === 'user')
      if (lastUser) {
        const seed = Math.floor(Math.random() * 99999) + 1
        lastUser.content +=
          `\n\n[Retry variant: honor the same musical intent but make fresh choices (timbre, rhythm, voicing). ` +
          `Use \`seed ${seed}\` in the CSD header instead of seed 0.]`
      }
    }
    abort.forceEnd = () => {
      if (mainDone) return
      if (!fullContent.trim()) {
        push({
          type: 'error',
          content:
            'Request cancelled. Wait for the timer to stop, then send once — ' +
            'do not repeat the same prompt while a request is still running.',
        })
      }
      mainDone = true
      notifyWaiters()
    }
    ;(async () => {
      const timeoutId = setTimeout(() => {
        if (mainDone) return
        timedOut = true
        Log.warn(`Main stream timed out after ${STREAM_TIMEOUT_MS}ms`)
        if (!fullContent.trim()) {
          push({
            type: 'error',
            content:
              `Request timed out after ${Math.round(STREAM_TIMEOUT_MS / 1000)} seconds. ` +
              'The model did not respond in time — this can happen on a busy free-tier key. ' +
              'Wait for any rate-limit countdown, then try once more. ' +
              'Groq or local Ollama in Settings are faster fallbacks.',
          })
        }
        mainDone = true
        notifyWaiters()
      }, STREAM_TIMEOUT_MS)

      try {
        let succeeded = false
        let lastError = ''

        for (let i = 0; i < providerChain.length; i++) {
          if (abort.cancelled || timedOut) break

          const candidate = providerChain[i]
          if (i > 0) {
            fullContent = ''
            activeModel = candidate
            push({
              type: 'status',
              content: `Trying ${Provider.providerLabel(candidate.providerID)} (${candidate.modelID})…`,
            })
            Log.info(`Fallback to ${candidate.providerID}/${candidate.modelID}`)
          }

          try {
            const attemptModel = Provider.getLanguageModel(candidate.providerID, candidate.modelID)
            Log.info('Starting streamText...')
            const stream = streamText({
              model: attemptModel as any,
              system: systemPrompt,
              messages: aiMessages,
              temperature: streamTemperature,
              topP: agent.topP,
            })
            for await (const chunk of stream.textStream) {
              if (abort.cancelled || timedOut) break
              fullContent += chunk
              push({ type: 'text', content: chunk })
            }
            if (fullContent.trim()) {
              succeeded = true
              activeModel = candidate
              try {
                const rawUsage = await Promise.race([
                  stream.usage,
                  new Promise<undefined>((resolve) => setTimeout(() => resolve(undefined), 8000)),
                ])
                const record = usageFromSdk(
                  activeModel.providerID,
                  activeModel.modelID,
                  rawUsage,
                  'main',
                )
                if (record) push({ type: 'usage', content: JSON.stringify(record) })
              } catch (err: any) {
                Log.warn(`Usage unavailable: ${err.message}`)
              }
              break
            }
            lastError = Provider.emptyStreamMessage(candidate.providerID)
            Log.warn(`Empty stream from ${candidate.providerID}/${candidate.modelID}`)
            if (!Provider.shouldTryNextProvider(null, true) || i >= providerChain.length - 1) break
          } catch (err: any) {
            lastError = `LLM Error: ${Provider.humanizeError(candidate.providerID, err)}`
            Log.warn(`Stream failed on ${candidate.providerID}: ${err.message}`)
            if (!Provider.shouldTryNextProvider(err, false) || i >= providerChain.length - 1) break
          }
        }

        if (!fullContent.trim() && !abort.cancelled && !timedOut) {
          push({
            type: 'error',
            content:
              lastError ||
              'All configured providers returned no output. Check keys in Settings or wait for rate limits to clear.',
          })
        }
      } catch (err: any) {
        Log.error('Stream error:', err.message)
        push({ type: 'error', content: `LLM Error: ${Provider.humanizeError(activeModel.providerID, err)}` })
      } finally {
        clearTimeout(timeoutId)
        mainDone = true
        notifyWaiters()
      }
    })()

    try {
      while (!mainDone || !narrationDone || queue.length > 0) {
        if (abort.cancelled && mainDone && narrationDone && queue.length === 0) break
        if (queue.length === 0) {
          await ready()
          continue
        }
        yield queue.shift()!
      }
    } finally {
      clearAbort()
    }

    Log.info(`Stream finished: ${fullContent.length} chars`)

    if (fullContent) {
      const assistantMsg: SessionMessage = {
        id: ascending('message'),
        role: 'assistant',
        content: fullContent,
        timestamp: Date.now(),
      }
      session.messages.push(assistantMsg)
      MemoryStore.appendMessage({ ...assistantMsg, sessionId: sessionID })
      MemoryStore.touchSession(sessionID)
      Bus.emit('session:message', { sessionID, role: 'assistant', content: fullContent })
    }
  }
}

// Pull the most recent assistant-authored CSD content so narration has real
// context about what the user has been building, not just their latest prompt.
// Conversion turns (Web App / VST / CSD / Player templates) are mechanical
// reformats, not user preferences — used to gate narration and lesson capture.
function isConversionTurn(content: string): boolean {
  return /^(Convert the Csound project below|Adapt the Csound project below|Extract the <CsoundSynthesizer>)/.test(content)
}

function lastAssistantCsd(session: Session): string {
  for (let i = session.messages.length - 1; i >= 0; i--) {
    const m = session.messages[i]
    if (m.role !== 'assistant') continue
    const match = m.content.match(/<CsoundSynthesizer>[\s\S]*?<\/CsoundSynthesizer>/i)
    if (match) return match[0]
  }
  return ''
}

interface MemoryBundle {
  lessons?: string
  previousErrors?: string
  guidance?: string
  errorFixes?: string
}

function buildSystemPrompt(
  agent: Agent.Info,
  ragContext: string = '',
  memory: MemoryBundle = {},
): string {
  const parts: string[] = []

  // Remembered instructions go FIRST — before the persona prompt — so explicit
  // user rules frame everything. They are non-negotiable unless the request
  // overrides them.
  if (memory.lessons) parts.push(memory.lessons)

  // Previous-errors memory sits right beside remembered-instructions: both are
  // strong, always-on framing. Distilled avoidance rules from past autofixes so the
  // model sidesteps known failure modes instead of regenerating a broken draft.
  if (memory.previousErrors) parts.push(memory.previousErrors)

  if (agent.prompt) {
    parts.push(agent.prompt)
  }

  // Feedback-learned soft guidance + prior fixes follow the persona prompt.
  if (memory.guidance) parts.push(memory.guidance)
  if (memory.errorFixes) parts.push(memory.errorFixes)

  if (ragContext) {
    parts.push(`<retrieved-knowledge>
${ragContext}
</retrieved-knowledge>`)
  }

  parts.push(`<environment>
- Platform: ${process.platform}
${getCsoundEnvironmentBlock()}
- Tier: ${isProPlus() ? 'Pro+ (Gemini Pro, book RAG, specialist consults, narration on)' : 'Standard'}
- Session mode: ${agent.options?.sineMode ? 'Sine' : 'Complex'}
</environment>

<artifacts>
You can create three types of artifacts. The user's UI auto-detects them from your output and renders them as interactive panels (like Claude's artifacts).

1. **CSD Instrument** — Output a complete \`<CsoundSynthesizer>...<\/CsoundSynthesizer>\` block. The UI will auto-play it and show it as an editable artifact with Play/Stop controls. Default score: a short musical demo (scale, arpeggios, ostinato, closing chord) so the user hears what the instrument can do — not one long held note.

2. **Web App** — Dr.C builds the HTML host for you. When the user converts to a web app (or asks to "export as web app"), emit ONLY a web-ready \`<CsoundSynthesizer>…</CsoundSynthesizer>\` orchestra CSD with \`chn_k\` control declarations. Do NOT write HTML or JavaScript — the app wraps your orchestra into a WASM7 page with sliders, Start/Stop, and keyboard. Put score lines only in \`<CsScore>\`, never inside \`<CsInstruments>\`.

3. **VST Plugin** — When the user asks for a VST/AU plugin, output a CSD with a \`<Cabbage>\` section before \`<CsoundSynthesizer>\`. Auto-generate Cabbage widgets (rslider, combobox, keyboard) mapped to the k-rate parameters. The UI will show the plugin configuration.

Always output the full artifact code — never truncate or use placeholders.

Pick the format from the user's intent, not from a default. Web app / export-as-web-app → orchestra CSD with \`chn_k\` (not HTML). VST / Cabbage / DAW → \`<Cabbage>\` + CSD. Otherwise emit a plain CSD. When switching an existing artifact, follow the conversion template the user message includes — it overrides these defaults.
</artifacts>

<response-style>
Keep prose extremely brief. Before an artifact, write at most ONE short sentence on what you are making. After it, at most ONE short sentence (or none). Do not explain the code line by line, list features, or recap. The artifact speaks for itself; the user can ask for detail if they want it. Spend your output budget on the artifact, not prose, so the CSD is never truncated.

Never use em dashes or en dashes (— or –). Use a comma, a period, parentheses, or the word "to" instead.
</response-style>`)

  return parts.join('\n\n')
}
