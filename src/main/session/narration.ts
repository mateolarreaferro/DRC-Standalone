import { streamText, generateText } from 'ai'
import { Agent } from '../agent/agent'
import { Provider } from '../provider/provider'
import { Retrieval } from '../retrieval/engine'
import { searchPassages } from '../retrieval/passages'
import { Log } from '../util/log'
import { usageFromSdk } from '../util/usage-cost'

// Clean a user query before feeding it to the narrator: strip anything that
// looks like code, CSD tags, compiler errors, or boilerplate so the model
// focuses on the musical topic rather than trying to debug.
function extractTopic(raw: string): string {
  let s = raw
    .replace(/<CsoundSynthesizer>[\s\S]*?<\/CsoundSynthesizer>/gi, '')
    .replace(/<Cabbage>[\s\S]*?<\/Cabbage>/gi, '')
    .replace(/```[\s\S]*?```/g, '')
    .replace(/<[^>]+>/g, '')
    .replace(/^Compiler error:.*$/gim, '')
    .replace(/^Current CSD:.*$/gim, '')
    .replace(/^The CSD you just wrote failed.*$/gim, '')
    .replace(/error:.*$/gim, '')
    .replace(/Line:\s*\d+/gi, '')
    .replace(/\n{2,}/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
  if (s.length > 220) s = s.slice(0, 220)
  return s || raw.slice(0, 100)
}

// Canonical attributions that MUST appear when the topic matches, regardless of
// what the retrieval happens to surface. Keeps the narrator from omitting the
// obvious origin (e.g. talking about FM without naming John Chowning).
const CANONICAL_FACTS: { re: RegExp; fact: string }[] = [
  {
    re: /\bfm\b|frequency modulation|\bdx7\b|chowning|fmod|modulation index/i,
    fact: 'FM (frequency modulation) synthesis was invented by John Chowning at Stanford (1967–1973) and licensed to Yamaha, powering the DX7.',
  },
  {
    re: /\bbell\b|risset|additive|gbuzz|partials/i,
    fact: 'Jean-Claude Risset pioneered additive synthesis and computer modeling of bell and brass tones at Bell Labs in the 1960s.',
  },
  {
    re: /granular|grain|partikkel|sndwarp/i,
    fact: 'Granular synthesis traces to Dennis Gabor’s acoustic quanta (1947) and was developed musically by Iannis Xenakis and Curtis Roads.',
  },
  {
    re: /physical model|waveguide|pluck|karplus|wgbow|wgflute|wgbrass/i,
    fact: 'Physical modeling via digital waveguides was developed by Julius O. Smith III at Stanford CCRMA; Karplus–Strong (1983) is the classic plucked-string case.',
  },
  {
    re: /subtractive|moog|ladder|vcf|moogladder/i,
    fact: 'Subtractive synthesis was popularized by Robert Moog’s voltage-controlled ladder filter in the 1960s.',
  },
  {
    re: /reverb|schroeder|freeverb|reverbsc/i,
    fact: 'Manfred Schroeder devised the first digital reverberation algorithms (comb and allpass networks) at Bell Labs in the early 1960s.',
  },
  {
    re: /vocoder|cross-?synth|channel vocoder/i,
    fact: 'The vocoder was invented by Homer Dudley at Bell Labs (1938); its analysis/resynthesis idea underlies cross-synthesis.',
  },
]

function matchedCanonicalFacts(topic: string): string[] {
  return CANONICAL_FACTS.filter((c) => c.re.test(topic)).map((c) => c.fact)
}

export namespace NarrationManager {
  const COOLDOWN_MS = 15_000
  const firedMap = new Map<string, number>()

  export function canFire(sessionID: string): boolean {
    const last = firedMap.get(sessionID) ?? 0
    return Date.now() - last >= COOLDOWN_MS
  }

  export function markFired(sessionID: string): void {
    firedMap.set(sessionID, Date.now())
  }

  // Stream historically-grounded narration about the technique/instrument the
  // user is asking about. Pulls passages from the Csound book and (optional)
  // graph entities so the narration references real, citeable context rather
  // than hallucinated lore. Runs in parallel with the main code-generation call.
  export type NarrationEvent =
    | { type: 'narration'; content: string }
    | { type: 'suggestions'; content: string } // content = JSON string[]
    | { type: 'usage'; content: string }

  export async function* streamNarration(
    userQuery: string,
    csdContext: string = ''
  ): AsyncGenerator<NarrationEvent> {
    const narratorAgent = Agent.get('narrator')
    if (!narratorAgent || !narratorAgent.prompt) {
      Log.warn('Narrator agent not configured')
      return
    }

    // Resolve small/fast model. If nothing is configured, bail gracefully.
    const { providerID, modelID } = Provider.smallModel()
    let model
    try {
      model = Provider.getLanguageModel(providerID, modelID)
    } catch (err: any) {
      Log.warn(`Narration disabled — no model for ${providerID}: ${err.message}`)
      return
    }

    // Strip anything that looks like code, CSD tags, or error output from the
    // user query before it reaches the narrator — otherwise Haiku sometimes
    // decides to help debug instead of providing historical context.
    const topic = extractTopic(userQuery)

    // Pull grounding from the extracted passage index first (cleaner,
    // topic-tagged quotes). Fall back to the raw book search if no passages
    // match — this keeps the old path alive for queries the extractor missed.
    const extracted = searchPassages(topic, 3)
    const bookChunks = extracted.length === 0 ? Retrieval.searchBook(topic, 3) : []
    const exampleChunks = Retrieval.searchExamples(topic, 1)
    const refs: string[] = []
    for (const p of extracted) {
      const tagHint = p.topic_tags.length ? ` tags="${p.topic_tags.slice(0, 3).join(', ')}"` : ''
      refs.push(`<passage source="${p.source_book}"${tagHint}>\n${p.content.slice(0, 900)}\n</passage>`)
    }
    for (const c of bookChunks) {
      refs.push(`<passage source="csound_book">\n${c.content.slice(0, 900)}\n</passage>`)
    }
    for (const ex of exampleChunks) {
      refs.push(`<example id="${ex.id}">\n${ex.content.slice(0, 600)}\n</example>`)
    }
    // Authoritative attributions that MUST be honored for this topic (e.g. FM ->
    // Chowning), independent of what retrieval surfaced.
    const canonical = matchedCanonicalFacts(topic)
    const factsBlock = canonical.length
      ? `\n\n<authoritative-facts>\n${canonical.join('\n')}\n</authoritative-facts>`
      : ''

    const grounding =
      (refs.length ? `\n\n<grounding>\n${refs.join('\n')}\n</grounding>` : '') + factsBlock

    const mustName = canonical.length
      ? ` You MUST name the originator/origin from <authoritative-facts> (for FM that means John Chowning).`
      : ''

    const userContent =
      `Topic: "${topic}"` +
      grounding +
      `\n\nProvide EXACTLY 2 short, COMPLETE sentences of historical/educational context, grounded in the material above. Each sentence must be under 22 words and end with a period.${mustName} Cite a specific composer, instrument, studio, year, or work when supported. Do NOT run sentences together. NEVER use em dashes or en dashes (— or –) or semicolons; use short separate sentences instead. NO code. NO CSD. NO emojis. NO markdown. NO bullet points. NO headers. Plain prose only.`

    try {
      const stream = streamText({
        model: model as any,
        system: narratorAgent.prompt,
        messages: [{ role: 'user', content: userContent }],
        temperature: 0.6,
        maxTokens: 180,   // ~2-3 sentences; first line of defense.
      })

      // Stream sentence-by-sentence. Accumulate chunks into a buffer; each time
      // the buffer holds a completed sentence (terminator + whitespace OR
      // end-of-stream), yield it and count it. Stop after the 2nd full sentence,
      // or when the buffer exceeds a hard cap with no sentence end in sight.
      //
      // Why buffer: emitting partial chunks and clipping on char count (the old
      // approach) cut mid-word when the model wrote a long sentence. Sentence-
      // granularity emits always terminate cleanly.
      const HARD_CAP = 500
      const SOFT_SENTENCE_LIMIT = 2
      let buf = ''
      let emittedChars = 0
      let sentencesOut = 0
      let stopped = false
      let emittedNarration = false

      const flushCompleteSentences = function* (force: boolean): Generator<string> {
        // Find the rightmost sentence terminator in buf that's followed by
        // whitespace (or is at end-of-buf when `force` is true).
        while (!stopped) {
          let endIdx = -1
          for (let i = 0; i < buf.length; i++) {
            const ch = buf[i]
            if (ch !== '.' && ch !== '!' && ch !== '?') continue
            const next = buf[i + 1]
            if (next === undefined) {
              if (force) endIdx = i + 1
              break
            }
            if (/\s/.test(next)) {
              endIdx = i + 1
              break
            }
          }
          if (endIdx < 0) return
          const sentence = buf.slice(0, endIdx)
          buf = buf.slice(endIdx).replace(/^\s+/, '')
          yield (emittedChars === 0 ? sentence : ' ' + sentence)
          emittedChars += sentence.length + (emittedChars === 0 ? 0 : 1)
          sentencesOut++
          if (sentencesOut >= SOFT_SENTENCE_LIMIT) {
            stopped = true
            return
          }
        }
      }

      for await (const chunk of stream.textStream) {
        if (stopped) continue
        buf += chunk
        // Strip any trailing "Keywords: ..." line the narrator tacks on —
        // the renderer strips it downstream anyway, but we don't want it
        // polluting our sentence/char accounting.
        const kwIdx = buf.search(/\n?Keywords:/i)
        if (kwIdx >= 0) buf = buf.slice(0, kwIdx)

        for (const out of flushCompleteSentences(false)) {
          emittedNarration = true
          yield { type: 'narration', content: out }
        }
        if (stopped) break

        // Safety valve: if the model's been going without any terminator and
        // we're way past budget, cut our losses at the last space in the buffer.
        if (emittedChars + buf.length > HARD_CAP) {
          const slice = buf.slice(0, HARD_CAP - emittedChars)
          const lastSpace = slice.lastIndexOf(' ')
          const cut = lastSpace > 40 ? lastSpace : slice.length
          const tail = buf.slice(0, cut).trim()
          if (tail) {
            emittedNarration = true
            yield { type: 'narration', content: (emittedChars === 0 ? tail : ' ' + tail) + '…' }
          }
          stopped = true
          break
        }
      }

      // Stream ended before we hit the sentence cap — flush whatever complete
      // sentences are still in the buffer, and if what's left looks like a
      // near-complete sentence, emit it too.
      if (!stopped) {
        for (const out of flushCompleteSentences(true)) {
          emittedNarration = true
          yield { type: 'narration', content: out }
        }
      }

      try {
        const rawUsage = await Promise.race([
          stream.usage,
          new Promise<undefined>((resolve) => setTimeout(() => resolve(undefined), 5000)),
        ])
        const record = usageFromSdk(providerID, modelID, rawUsage, 'narration')
        if (record) yield { type: 'usage', content: JSON.stringify(record) }
      } catch {
        /* usage optional */
      }

      // Skip suggestion generation when narration produced nothing (quota/key issue)
      // or in workshop-lite mode — it is an extra API call and can block 20s on 429.
      const allowSuggestions =
        emittedNarration && process.env.DRC_WORKSHOP_LITE === '0' && process.env.DRC_NARRATION_SUGGESTIONS === '1'
      if (allowSuggestions) {
        const suggestions = await generateSuggestions(model, topic, grounding)
        if (suggestions.length > 0) {
          yield { type: 'suggestions', content: JSON.stringify(suggestions) }
        }
      }
    } catch (err: any) {
      Log.warn(`Narration stream failed: ${err.message}`)
    }
  }

  // Generate short, imperative "make this next" prompts from the same grounding.
  async function generateSuggestions(
    model: any,
    topic: string,
    grounding: string,
  ): Promise<string[]> {
    try {
      const { text } = await generateText({
        model,
        system:
          `You suggest follow-up sound-design prompts for a Csound generator. Given a topic and reference passages, propose specific instruments, techniques, or famous works the user could ask the agent to GENERATE next.`,
        messages: [
          {
            role: 'user',
            content:
              `Topic: "${topic}"${grounding}\n\nList 3 short imperative prompts (4 to 8 words each) the user could click to generate something concrete related to this topic. Name specific instruments, composers, or works when the passages support it. Examples: "Generate a classic Risset bell", "Build a Chowning FM brass", "Make a Risset endless glissando". Output ONLY the prompts, one per line, no numbering, no quotes, no extra text.`,
          },
        ],
        temperature: 0.7,
        maxTokens: 90,
      })
      return text
        .split('\n')
        .map((l) => l.replace(/^[\s\-*\d.)]+/, '').replace(/^["'`]|["'`]$/g, '').trim())
        .filter((l) => l.length >= 4 && l.length <= 60)
        .slice(0, 3)
    } catch (err: any) {
      Log.warn(`Suggestion generation failed: ${err.message}`)
      return []
    }
  }
}
