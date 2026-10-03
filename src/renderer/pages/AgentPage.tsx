import { useState, useRef, useEffect, useCallback, useMemo, type CSSProperties } from 'react'
import { Link } from 'react-router-dom'
import { useSessionStore, type AgentMode, type Message } from '../stores/sessionStore'
import { useArtifactStore, primaryContent, findBySourceMessageId, hasWebappForMessage, type Artifact } from '../stores/artifactStore'
import ArtifactPanel from '../components/artifacts/ArtifactPanel'
import ErrorBoundary from '../components/ErrorBoundary'
import { useEditorStore } from '../stores/editorStore'
import ArtifactCard from '../components/chat/ArtifactCard'
import MessageFeedback from '../components/chat/MessageFeedback'
import ProfileBadge from '../components/chat/ProfileBadge'
import SessionHistory from '../components/chat/SessionHistory'
import { audioFeedback } from '../styles/audio-feedback'
import { useAppStore } from '../stores/appStore'
import { detect, detectCsd, stripArtifact, deriveTitle, type DetectionResult } from '../lib/artifactDetect'
import { prepareCsdForCabbage } from '../../shared/csd-cabbage-prepare'
import { buildConvertPrompt, detectConvertIntent, type ConvertTarget } from '../prompts/convert'
import { playArtifact, stopPlayback, resetAutofix, isAutofixUserMessage } from '../lib/playback'
import { usePlaybackStore } from '../stores/playbackStore'
import { wrapWithArtifactContext } from '../lib/artifactContext'
import { buildWebApp } from '../lib/webHarness'
import { buildWebappManifest, prepareWebappCompileCsd } from '../lib/webappPrepare'
import StudyFlowButton from '../components/study/StudyFlowButton'
import type { SignalFlowStudyInput } from '../lib/signalFlowStudy'
import { compileCheckWebappCsd } from '../lib/playback'
import UsageBar from '../components/chat/UsageBar'
import AgentActivityBar from '../components/chat/AgentActivityBar'

function artifactCodeFromDetection(detected: DetectionResult): string {
  return detected.type === 'vst' ? prepareCsdForCabbage(detected.code) : detected.code
}
import PromptRetryBar from '../components/chat/PromptRetryBar'
import QuotaCooldown from '../components/QuotaCooldown'
import ApiKeyPromptDialog from '../components/ApiKeyPromptDialog'
import { useUsageStore } from '../stores/usageStore'
import { isRateLimited, useRateLimitStore } from '../stores/rateLimitStore'
import { formatCostUSD, formatTokenCount } from '../lib/usageFormat'

// Strip a stray leading web-app wrapper so a fresh turn's CSD can be recovered.
const DOCTYPE_RE = /<!DOCTYPE\s+html\s*>/gi
const HTML_FENCE_RE = /```(?:html|HTML)\s*\n/g

function userMessageBeforeAssistant(messages: Message[], assistantId: string): Message | null {
  const idx = messages.findIndex((m) => m.id === assistantId)
  if (idx <= 0) return null
  for (let i = idx - 1; i >= 0; i--) {
    if (messages[i].role === 'user') return messages[i]
    if (messages[i].role === 'assistant' && messages[i].type !== 'narration') break
  }
  return null
}

/** True when `assistantId` is a non-narration assistant turn strictly after `userMsgId`. */
function assistantTurnAfterUser(messages: Message[], userMsgId: string, assistantId: string): boolean {
  const userIdx = messages.findIndex((m) => m.id === userMsgId)
  const asstIdx = messages.findIndex((m) => m.id === assistantId)
  return userIdx >= 0 && asstIdx > userIdx
}

function syncWebappFrozenFromStore(frozen: Set<string>): void {
  for (const a of useArtifactStore.getState().artifacts) {
    if (a.type === 'webapp' && a.sourceMessageId) frozen.add(a.sourceMessageId)
  }
}

function isMessageWebappLocked(messageId: string, frozen: Set<string>): boolean {
  if (frozen.has(messageId)) return true
  return hasWebappForMessage(useArtifactStore.getState().artifacts, messageId)
}

const MODE_INFO: Record<AgentMode, { label: string; color: string }> = {
  csound: { label: 'Complex', color: '#7cb8a4' },
  'csound-sine': { label: 'Sine', color: '#f0b27a' },
}

// Strip emojis and the simplest markdown so the chat bubble reads as plain prose
// no matter what the model tried. Headings / lists collapse to their label text.
const EMOJI_RE = /[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{1F000}-\u{1F2FF}\u{2300}-\u{23FF}]/gu
function cleanChatText(text: string): string {
  return text
    .replace(EMOJI_RE, '')
    .replace(/```[\s\S]*?```/g, '')               // fenced code blocks
    .replace(/`([^`]+)`/g, '$1')                   // inline code
    .replace(/^\s{0,3}#{1,6}\s+/gm, '')           // atx headings
    .replace(/\*\*([^*]+)\*\*/g, '$1')             // bold
    .replace(/(^|\s)\*([^*\n]+)\*(?=\s|$|[.,;:!?])/g, '$1$2') // italics
    .replace(/^[ \t]*[-*+][ \t]+/gm, '')          // bullet markers
    .replace(/^[ \t]*\d+\.[ \t]+/gm, '')          // ordered list markers
    .replace(/\s*[—–]\s*/g, ', ')                  // em/en dashes -> comma (backstop)
    .replace(/\n{3,}/g, '\n\n')                    // collapse big gaps
    .trim()
}

export default function AgentPage() {
  const [input, setInput] = useState('')
  const [lastUserPrompt, setLastUserPrompt] = useState('')
  const [providersAvailable, setProvidersAvailable] = useState<string[] | null>(null)
  const playingArtifactId = usePlaybackStore((s) => s.artifactId)
  const messagesEndRef = useRef<HTMLDivElement>(null)
  /** Last successful send — powers one-click retry without retyping. */
  const lastSendRef = useRef<{ displayText: string; payload: string } | null>(null)
  const { messages, agentMode, setAgentMode, isStreaming, agentActivity, addMessage, setStreaming, setSessionID, sessionID, startNewSession, clearMessages, removeFailedAssistantTurn } = useSessionStore()
  const rateLimitUntil = useRateLimitStore((s) => s.until)
  const rateLimitProvider = useRateLimitStore((s) => s.providerLabel)
  const clearRateLimit = useRateLimitStore((s) => s.clearCooldown)
  const [historyOpen, setHistoryOpen] = useState(false)
  const [showApiKeyDialog, setShowApiKeyDialog] = useState(false)
  const { artifacts, panelOpen, addArtifact, updatePrimary, updateInPlace, setActive, activeArtifactId } = useArtifactStore()
  const audioEnabled = useAppStore((s) => s.audioFeedbackEnabled)

  useEffect(() => {
    const refresh = () => {
      window.api?.config?.getApiKeys().then((r: any) => {
        setProvidersAvailable(r?.available ?? [])
      }).catch(() => setProvidersAvailable([]))
    }
    refresh()
    window.addEventListener('drc:providers-changed', refresh)
    window.addEventListener('focus', refresh)
    return () => {
      window.removeEventListener('drc:providers-changed', refresh)
      window.removeEventListener('focus', refresh)
    }
  }, [])

  // Map message IDs to artifact IDs for rendering
  const [msgArtifactMap, setMsgArtifactMap] = useState<Map<string, string>>(new Map())
  const msgArtifactMapRef = useRef(msgArtifactMap)
  msgArtifactMapRef.current = msgArtifactMap

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  // Live artifact detection — runs on every content change (including during streaming).
  // First detection creates the artifact; subsequent updates mutate it in place.
  // When streaming completes and the artifact is a fresh CSD, autoplay it once.
  const autoPlayedRef = useRef<Set<string>>(new Set())
  // The artifact version a follow-up edit should branch from — the one loaded in
  // the panel at send time, not necessarily the newest. Set in handleSend.
  const editBaseRef = useRef<string | null>(null)
  // When a "Convert to Web App" is in flight, the model streams back an adapted
  // orchestra CSD (not HTML). We suppress the normal CSD-artifact path for that
  // ONE turn and, on completion, deterministically wrap the orchestra into a web
  // app via buildWebApp. The flag is consumed (cleared) the moment that turn is
  // handled, so it can never leak into a later, unrelated generation.
  // `editBaseId` is set when this turn is a FOLLOW-UP edit of an existing web app
  // (vs a first-time conversion): the rebuilt web app becomes a new VERSION of that
  // artifact rather than a brand-new one.
  const pendingWebappConvertRef = useRef<{ title: string; editBaseId?: string; afterUserMsgId: string } | null>(null)
  // Message ids that already produced a web app — never re-detect orchestra CSD from them.
  const webappFrozenMessageIds = useRef<Set<string>>(new Set())
  // True only on a turn that explicitly requested a format conversion. A fresh
  // generation leaves it false, so a stray DOCTYPE is never made a webapp/vst.
  const convertTurnRef = useRef<boolean>(false)
  // While buildWebApp + compile-check run async, block normal detect() from
  // re-deriving a spurious CSD from the same orchestra message.
  const webappBuildInFlightRef = useRef<string | null>(null)

  // Re-seed frozen message ids on mount and whenever the artifact store gains a webapp.
  useEffect(() => {
    syncWebappFrozenFromStore(webappFrozenMessageIds.current)
    return useArtifactStore.subscribe(() => {
      syncWebappFrozenFromStore(webappFrozenMessageIds.current)
    })
  }, [])

  // Detection keys on message text only — usage metadata must not re-trigger detect().
  const messagesContentKey = useMemo(
    () => messages.map((m) => `${m.id}\t${m.role}\t${m.type ?? ''}\t${m.content}`).join('\n'),
    [messages],
  )

  useEffect(() => {
    // Look for the most recent non-narration assistant message. Narration messages
    // are ambient context and never contain artifacts.
    let last: Message | null = null
    for (let i = messages.length - 1; i >= 0; i--) {
      const m = messages[i]
      if (m.role === 'assistant' && m.type !== 'narration') { last = m; break }
    }
    if (!last) return

    const streaming = useSessionStore.getState().isStreaming
    const storeNow = useArtifactStore.getState()
    const canonicalForMsg = findBySourceMessageId(storeNow.artifacts, last.id)
    if (isMessageWebappLocked(last.id, webappFrozenMessageIds.current)) {
      const mappedId = msgArtifactMapRef.current.get(last.id)
      if (canonicalForMsg && mappedId !== canonicalForMsg.id) {
        setMsgArtifactMap((prev) => new Map(prev).set(last.id, canonicalForMsg.id))
      }
      if (canonicalForMsg && storeNow.activeArtifactId !== canonicalForMsg.id) {
        setActive(canonicalForMsg.id)
      }
      return
    }

    // Convert-to-Web-App: model must emit orchestra CSD; host wraps via buildWebApp.
    // Use detectCsd (not detect) so stray HTML never hijacks the conversion turn.
    const pendingConvert = pendingWebappConvertRef.current
    if (pendingConvert) {
      // Do not consume on a PRIOR assistant message (e.g. original CSD) before the
      // conversion stream's first chunk — that wrapped the wrong orchestra and left
      // pendingConvert null when the real conversion response arrived as plain CSD.
      if (!assistantTurnAfterUser(messages, pendingConvert.afterUserMsgId, last.id)) return

      const csdDet = detectCsd(last.content)
      if (!csdDet) return
      if (streaming && !csdDet.complete) return

      const csd = csdDet.code
      const title = pendingConvert.title || deriveTitle(csd, 'csd', lastUserPrompt)
      const editBaseId = pendingConvert.editBaseId
      const messageId = last.id
      editBaseRef.current = null
      pendingWebappConvertRef.current = null
      convertTurnRef.current = false
      webappBuildInFlightRef.current = messageId
      // Optimistic freeze — block detect()/updateInPlace for the full async wrap.
      webappFrozenMessageIds.current.add(messageId)

      void (async () => {
        try {
          const compileCheck = await compileCheckWebappCsd(prepareWebappCompileCsd(csd))
          if (!compileCheck.ok) {
            webappFrozenMessageIds.current.delete(messageId)
            addMessage({
              id: `webapp-compile-${Date.now()}`,
              role: 'assistant',
              type: 'narration',
              content:
                `Web app conversion could not compile. ${compileCheck.error ?? 'Check the Csound console for details.'} ` +
                'Common fix: score lines like f 0 3600 must live in <CsScore>, not <CsInstruments>. Try Convert to Web App again.',
              timestamp: Date.now(),
            })
            return
          }
          const manifest = buildWebappManifest(csd)
          const html = buildWebApp({
            orc: manifest.orc,
            channels: manifest.channels,
            title,
            hasKeyboard: manifest.hasKeyboard,
            hasReverbBus: manifest.hasReverbBus,
          })
          const artifact = editBaseId
            ? updatePrimary(editBaseId, html, messageId)
            : addArtifact({ type: 'webapp', title, content: html, sourceMessageId: messageId })
          webappFrozenMessageIds.current.add(messageId)
          // Drop any spurious CSD created by detect() while the wrap was in flight.
          const store = useArtifactStore.getState()
          const spurious = store.artifacts
            .filter((a) => a.sourceMessageId === messageId && a.type === 'csd' && a.id !== artifact.id)
            .map((a) => a.id)
          if (spurious.length) store.removeArtifacts(spurious)
          setMsgArtifactMap((prev) => new Map(prev).set(messageId, artifact.id))
          setActive(artifact.id)
        } finally {
          if (webappBuildInFlightRef.current === messageId) {
            webappBuildInFlightRef.current = null
          }
        }
      })()
      return
    }

    if (webappBuildInFlightRef.current === last.id) return

    const detected = detect(last.content)
    if (!detected) return
    if (detected.type === 'csd' && isMessageWebappLocked(last.id, webappFrozenMessageIds.current)) {
      return
    }

    let existingId = msgArtifactMapRef.current.get(last.id)
    const userBefore = userMessageBeforeAssistant(messages, last.id)
    const isAutofixTurn = !!(userBefore && isAutofixUserMessage(userBefore.content))
    const autofixTargetId = isAutofixTurn
      ? (useSessionStore.getState().pendingAutofixArtifactId
        ?? useSessionStore.getState().lastFailure?.artifactId
        ?? null)
      : null

    // Auto-fix: update the broken artifact in place — never spawn a second one.
    if (autofixTargetId && (!existingId || existingId !== autofixTargetId)) {
      const autofixTarget = useArtifactStore.getState().artifacts.find((a) => a.id === autofixTargetId)
      if (autofixTarget?.type === 'webapp') return
      if (isMessageWebappLocked(last.id, webappFrozenMessageIds.current)) return
      updateInPlace(autofixTargetId, artifactCodeFromDetection(detected))
      setMsgArtifactMap((prev) => new Map(prev).set(last.id, autofixTargetId))
      if (detected.complete && !useArtifactStore.getState().panelOpen) {
        useArtifactStore.getState().openPanel()
      }
      return
    }

    if (!existingId) {
      // Re-adopt an artifact already built for this message in a previous mount.
      // The store survives navigation but our local map doesn't, so without this
      // a remount would re-derive a brand-new artifact from the message text —
      // and for converted web apps that text is an orchestra CSD, not the HTML,
      // so it would clobber the web app with a spurious CSD version.
      const adopted = findBySourceMessageId(useArtifactStore.getState().artifacts, last.id)
      if (adopted) {
        setMsgArtifactMap((prev) => new Map(prev).set(last.id, adopted.id))
        if (adopted.type === 'webapp') {
          webappFrozenMessageIds.current.add(last.id)
          setActive(adopted.id)
        }
        return
      }
      // Fresh-turn guard: a non-conversion generation must be a CSD. A stray
      // DOCTYPE/HTML outranks the CSD in findStart, so without this a model that
      // wrongly emits a web app on a first turn would render as a webapp. Refuse
      // it; recover an embedded CSD if the message has one, else ignore the turn.
      if (!convertTurnRef.current && detected.type !== 'csd') {
        if (!streaming) {
          const stripped = last.content.replace(DOCTYPE_RE, '').replace(HTML_FENCE_RE, '')
          const csdFallback = detect(stripped)
          if (csdFallback && csdFallback.type === 'csd' && !isMessageWebappLocked(last.id, webappFrozenMessageIds.current)) {
            const t = deriveTitle(csdFallback.code, 'csd', lastUserPrompt)
            const a = addArtifact({ type: 'csd', title: t, content: csdFallback.code, sourceMessageId: last.id }, { openPanel: true })
            setMsgArtifactMap((prev) => new Map(prev).set(last.id, a.id))
          }
        }
        return
      }
      // If this turn was an edit of the artifact loaded in the panel, branch the
      // new version from THAT version (same title/lineage), not the newest one.
      const base = editBaseRef.current
        ? useArtifactStore.getState().artifacts.find((a) => a.id === editBaseRef.current)
        : null
      if (base && base.type === detected.type) {
        if (canonicalForMsg?.type === 'webapp' || isMessageWebappLocked(last.id, webappFrozenMessageIds.current)) {
          if (canonicalForMsg) {
            setMsgArtifactMap((prev) => new Map(prev).set(last.id, canonicalForMsg.id))
            setActive(canonicalForMsg.id)
          }
          editBaseRef.current = null
          return
        }
        const artifact = updatePrimary(base.id, artifactCodeFromDetection(detected), last.id)
        setMsgArtifactMap((prev) => new Map(prev).set(last.id, artifact.id))
        editBaseRef.current = null
        return
      }
      if (detected.type === 'csd' && isMessageWebappLocked(last.id, webappFrozenMessageIds.current)) return
      const title = deriveTitle(detected.code, detected.type, lastUserPrompt)
      const artifact = addArtifact(
        { type: detected.type, title, content: artifactCodeFromDetection(detected), sourceMessageId: last.id },
        { openPanel: detected.complete },
      )
      setMsgArtifactMap((prev) => new Map(prev).set(last.id, artifact.id))
      return
    }

    // Never overwrite an artifact whose type no longer matches the message text
    // (e.g. a converted web app derived from an orchestra-CSD message). The
    // message isn't the source of truth for those, so re-deriving would corrupt it.
    const storeArtifacts = useArtifactStore.getState().artifacts
    const existing = storeArtifacts.find((a) => a.id === existingId)
    const canonical = findBySourceMessageId(storeArtifacts, last.id)
    if (canonical && existing && canonical.id !== existing.id) {
      setMsgArtifactMap((prev) => new Map(prev).set(last.id, canonical.id))
      return
    }
    if (existing && existing.type !== detected.type) return
    if (detected.type === 'csd' && isMessageWebappLocked(last.id, webappFrozenMessageIds.current)) return
    if (existing?.type === 'webapp' && detected.type === 'csd') return

    updateInPlace(existingId, artifactCodeFromDetection(detected))

    if (detected.complete && !useArtifactStore.getState().panelOpen) {
      useArtifactStore.getState().openPanel()
    }
  }, [messagesContentKey, lastUserPrompt])

  // Autoplay is separate from detection — playback state must not re-run detect().
  useEffect(() => {
    if (isStreaming) return
    let last: Message | null = null
    for (let i = messages.length - 1; i >= 0; i--) {
      const m = messages[i]
      if (m.role === 'assistant' && m.type !== 'narration') { last = m; break }
    }
    if (!last) return
    if (isMessageWebappLocked(last.id, webappFrozenMessageIds.current)) return

    const detected = detect(last.content)
    if (!detected?.complete || detected.type !== 'csd') return

    const userBefore = userMessageBeforeAssistant(messages, last.id)
    const isAutofixTurn = !!(userBefore && isAutofixUserMessage(userBefore.content))
    if (isAutofixTurn) {
      const autofixTargetId =
        useSessionStore.getState().pendingAutofixArtifactId
        ?? useSessionStore.getState().lastFailure?.artifactId
        ?? msgArtifactMapRef.current.get(last.id)
        ?? null
      if (!autofixTargetId || autoPlayedRef.current.has(last.id)) return
      const artifact = useArtifactStore.getState().artifacts.find((a) => a.id === autofixTargetId)
      if (!artifact || artifact.type !== 'csd') return
      autoPlayedRef.current.add(last.id)
      void playArtifact(artifact, { allowAutofix: false })
      return
    }

    const existingId = msgArtifactMapRef.current.get(last.id)
    if (!existingId || autoPlayedRef.current.has(last.id)) return
    const canonicalForMsg = findBySourceMessageId(useArtifactStore.getState().artifacts, last.id)
    if (canonicalForMsg?.type === 'webapp') return
    const artifact = useArtifactStore.getState().artifacts.find((a) => a.id === existingId)
    if (!artifact || artifact.type !== 'csd') return
    autoPlayedRef.current.add(last.id)
    void playArtifact(artifact)
  }, [messagesContentKey, isStreaming])

  // Send a conversion prompt to the LLM
  const requestConversion = useCallback(async (targetType: ConvertTarget) => {
    const active = useArtifactStore.getState().getActive()
    if (!active) return
    if (providersAvailable !== null && providersAvailable.length === 0) {
      setShowApiKeyDialog(true)
      return
    }

    const prompt = buildConvertPrompt(targetType, primaryContent(active))
    const shortLabel =
      targetType === 'webapp' ? 'Convert to Web App' :
      targetType === 'vst' ? 'Convert to Cabbage' :
      'Extract standalone CSD'

    // The webapp conversion now returns an orchestra CSD that we wrap ourselves
    // (see the detection effect). Mark the turn so it's intercepted.
    editBaseRef.current = null
    const userMsgId = `msg_${Date.now()}`
    pendingWebappConvertRef.current =
      targetType === 'webapp'
        ? { title: active.title, editBaseId: active.type === 'webapp' ? active.id : undefined, afterUserMsgId: userMsgId }
        : null
    // Explicit conversion — the fresh-turn guard must NOT suppress the artifact.
    convertTurnRef.current = true

    setInput('')
    // Show a compact user-visible message, not the full template
    addMessage({ id: userMsgId, role: 'user', content: shortLabel, timestamp: Date.now() })
    setLastUserPrompt(shortLabel)
    setStreaming(true)

    try {
      if (window.api?.session) {
        const activeSid = sessionID ?? (await window.api.session.create(agentMode)).id
        if (!sessionID) setSessionID(activeSid)
        lastSendRef.current = { displayText: shortLabel, payload: prompt }
        await window.api.session.send(activeSid, prompt)
      }
    } catch (err: any) {
      pendingWebappConvertRef.current = null
      convertTurnRef.current = false
      addMessage({ id: `msg_${Date.now()}`, role: 'assistant', content: `Error: ${err.message}`, timestamp: Date.now() })
      setStreaming(false)
    }
  }, [sessionID, agentMode, providersAvailable])

  const newChat = useCallback(() => {
    void stopPlayback()
    resetAutofix(sessionID)
    startNewSession()
    // Clear ALL artifact state too — otherwise the previous session's artifact
    // stays loaded in the panel and becomes the edit base for the new session's
    // first message, so "nothing works" in what should be a clean session.
    useArtifactStore.getState().reset()
    editBaseRef.current = null
    setMsgArtifactMap(new Map())
    autoPlayedRef.current = new Set()
    pendingWebappConvertRef.current = null
    convertTurnRef.current = false
    webappBuildInFlightRef.current = null
    webappFrozenMessageIds.current = new Set()
    lastSendRef.current = null
  }, [sessionID, startNewSession])

  // Reopen a persisted chat. We pre-seed autoPlayedRef with the loaded message
  // ids so restoring a session that ends in a CSD doesn't blast audio on open.
  const loadSession = useCallback(async (id: string) => {
    if (!window.api?.session) return
    const data: any = await window.api.session.get(id)
    if (!data) return
    void stopPlayback()
    resetAutofix(sessionID)
    clearMessages()
    // Drop the prior session's artifact state before loading this one, so it can't
    // leak across sessions. The artifact-detection effect rebuilds this session's
    // final artifact from its loaded messages.
    useArtifactStore.getState().reset()
    useUsageStore.getState().resetArea('agent')
    editBaseRef.current = null
    setMsgArtifactMap(new Map())
    pendingWebappConvertRef.current = null
    convertTurnRef.current = false
    webappBuildInFlightRef.current = null
    webappFrozenMessageIds.current = new Set()
    setSessionID(data.id)
    if (['csound', 'csound-sine'].includes(data.agent)) setAgentMode(data.agent)
    const loaded = new Set<string>()
    for (const m of data.messages ?? []) {
      if (m.role !== 'user' && m.role !== 'assistant') continue
      addMessage({ id: m.id, role: m.role, content: m.content, timestamp: m.timestamp })
      if (m.role === 'assistant') loaded.add(m.id)
    }
    autoPlayedRef.current = loaded // suppress autoplay for restored turns
  }, [sessionID, clearMessages, setSessionID, setAgentMode, addMessage])

  const handleOpenInBrowser = useCallback(async (artifact: Artifact) => {
    if (artifact.type !== 'webapp') return
    await window.api?.export?.openInBrowser?.(primaryContent(artifact), artifact.title)
  }, [])

  const handlePlay = useCallback((artifact: Artifact) => {
    void playArtifact(artifact)
  }, [])

  const handleStop = useCallback(() => {
    void stopPlayback()
  }, [])

  const handleCancel = useCallback(async () => {
    const sid = useSessionStore.getState().sessionID
    useSessionStore.getState().setAgentActivity('Cancelling…')
    if (sid && window.api?.session?.cancel) {
      await window.api.session.cancel(sid)
    }
  }, [])

  const buildPayloadFromText = useCallback((text: string): string => {
    const active = useArtifactStore.getState().getActive()
    const convertTo = active ? detectConvertIntent(text, active.type) : null
    const conversionBusy = Boolean(pendingWebappConvertRef.current || webappBuildInFlightRef.current)

    if (active && active.type === 'webapp' && !convertTo) {
      if (!conversionBusy) {
        const msgs = useSessionStore.getState().messages
        const srcMsg = active.sourceMessageId
          ? msgs.find((m) => m.id === active.sourceMessageId)
          : null
        const srcDet = srcMsg ? detect(srcMsg.content) : null
        const srcCsd = srcDet && srcDet.type === 'csd' ? srcDet.code : null
        if (srcCsd) {
          editBaseRef.current = null
          // afterUserMsgId patched in handleSend before addMessage
          pendingWebappConvertRef.current = { title: active.title, editBaseId: active.id, afterUserMsgId: '' }
          convertTurnRef.current = true
          return `${buildConvertPrompt('webapp', srcCsd)}\n\n<user-note>${text}</user-note>`
        }
        editBaseRef.current = active.id
        pendingWebappConvertRef.current = null
      }
      return wrapWithArtifactContext(text)
    }

    if (!conversionBusy) {
      editBaseRef.current = active && !convertTo ? active.id : null
      pendingWebappConvertRef.current =
        convertTo === 'webapp' && active
          ? { title: active.title, editBaseId: active.type === 'webapp' ? active.id : undefined, afterUserMsgId: '' }
          : null
      convertTurnRef.current = Boolean(convertTo && active)
    }

    if (conversionBusy) {
      return wrapWithArtifactContext(text)
    }

    return convertTo && active
      ? `${buildConvertPrompt(convertTo, primaryContent(active))}\n\n<user-note>${text}</user-note>`
      : wrapWithArtifactContext(text)
  }, [])

  const handleSend = async (
    overrideText?: string,
    opts?: { retry?: boolean; variant?: boolean; refillOnly?: boolean },
  ) => {
    const retry = Boolean(opts?.retry || opts?.variant)

    if (opts?.refillOnly) {
      setInput(overrideText ?? lastUserPrompt)
      return
    }

    const text = (overrideText ?? input).trim()
    if (!retry && !text) return
    if (isStreaming) return
    if (isRateLimited()) return
    if (providersAvailable !== null && providersAvailable.length === 0) {
      setShowApiKeyDialog(true)
      return
    }

    let displayText: string
    let payload: string

    if (retry) {
      if (!lastSendRef.current) return
      displayText = lastSendRef.current.displayText
      payload = lastSendRef.current.payload
      removeFailedAssistantTurn()
    } else {
      displayText = text
      resetAutofix(sessionID)
      if (!pendingWebappConvertRef.current && !webappBuildInFlightRef.current) {
        convertTurnRef.current = false
      }
      payload = buildPayloadFromText(text)
      const userMsgId = `msg_${Date.now()}`
      if (pendingWebappConvertRef.current?.afterUserMsgId === '') {
        pendingWebappConvertRef.current = { ...pendingWebappConvertRef.current, afterUserMsgId: userMsgId }
      }
      lastSendRef.current = { displayText, payload }
      addMessage({ id: userMsgId, role: 'user', content: text, timestamp: Date.now() })
      setInput('')
    }

    if (audioEnabled) audioFeedback.click()
    useSessionStore.getState().setAgentActivity(retry ? 'Retrying…' : 'Sending to the Agent…')
    setLastUserPrompt(displayText)
    setStreaming(true)

    try {
      if (window.api?.session) {
        const activeSid = sessionID ?? (await window.api.session.create(agentMode)).id
        if (!sessionID) setSessionID(activeSid)
        await window.api.session.send(activeSid, payload, {
          retry: opts?.retry,
          variant: opts?.variant,
        })
      } else {
        addMessage({ id: `msg_${Date.now()}`, role: 'assistant', content: 'Not connected — restart app.', timestamp: Date.now() })
        setStreaming(false)
      }
    } catch (err: any) {
      addMessage({ id: `msg_${Date.now()}`, role: 'assistant', content: `Error: ${err.message}`, timestamp: Date.now() })
      setStreaming(false)
    }
  }

  const showRetryBar = useMemo(() => {
    if (isStreaming || !lastUserPrompt) return false
    const last = messages[messages.length - 1]
    if (!last) return false
    if (last.type === 'error') return true
    if (last.role === 'assistant' && last.type !== 'narration' && !detect(last.content)) return true
    return false
  }, [messages, isStreaming, lastUserPrompt])

  const lastUserMsgId = useMemo(() => {
    for (let i = messages.length - 1; i >= 0; i--) {
      if (messages[i].role === 'user') return messages[i].id
    }
    return null
  }, [messages])

  const agentInstrument = useMemo(() => {
    if (activeArtifactId) {
      const hit = artifacts.find((a) => a.id === activeArtifactId)
      if (hit) return hit
    }
    for (let i = artifacts.length - 1; i >= 0; i--) {
      const a = artifacts[i]
      if (a.type === 'csd' || a.type === 'webapp' || a.type === 'vst') return a
    }
    return null
  }, [artifacts, activeArtifactId])

  const agentStudyInput = useMemo<SignalFlowStudyInput | null>(() => {
    if (!agentInstrument) return null
    return { title: agentInstrument.title, source: primaryContent(agentInstrument) }
  }, [agentInstrument])

  const renderMessage = (msg: Message) => {
    if (msg.role === 'user') {
      const isLastUser = msg.id === lastUserMsgId
      const retryDisabled = isStreaming
      return (
        <div key={msg.id} style={styles.userRow}>
          <div style={styles.userBubbleCol}>
            <button
              type="button"
              style={{
                ...styles.userPromptBtn,
                ...(retryDisabled ? styles.userPromptBtnDisabled : {}),
              }}
              disabled={retryDisabled}
              onClick={() => {
                if (isLastUser && lastSendRef.current) {
                  handleSend(undefined, { retry: true })
                } else {
                  handleSend(msg.content, { refillOnly: true })
                }
              }}
              title={isLastUser ? 'Try again with this prompt' : 'Put this prompt in the text field'}
            >
              {msg.content}
            </button>
            {isLastUser && !retryDisabled && (
              <div style={styles.userPromptActions}>
                <button type="button" style={styles.userPromptAction} onClick={() => handleSend(undefined, { retry: true })}>
                  Try again
                </button>
                <button type="button" style={styles.userPromptAction} onClick={() => handleSend(msg.content, { refillOnly: true })}>
                  Edit
                </button>
                <button type="button" style={styles.userPromptAction} onClick={() => handleSend(undefined, { variant: true })}>
                  Variation
                </button>
              </div>
            )}
          </div>
        </div>
      )
    }

    if (msg.type === 'error') {
      const retryDisabled = isStreaming
      return (
        <div key={msg.id} style={styles.assistantRow}>
          <div style={styles.errorBubble}>
            <span style={styles.errorLabel}>Could not generate</span>
            <p style={styles.errorText}>{msg.content}</p>
            {lastUserPrompt && (
              <div style={styles.errorActions}>
                <button type="button" style={styles.errorActionPrimary} disabled={retryDisabled} onClick={() => handleSend(undefined, { retry: true })}>
                  Try again
                </button>
                <button type="button" style={styles.errorAction} disabled={retryDisabled} onClick={() => handleSend(lastUserPrompt, { refillOnly: true })}>
                  Edit prompt
                </button>
                <button type="button" style={styles.errorAction} disabled={retryDisabled} onClick={() => handleSend(undefined, { variant: true })}>
                  Try variation
                </button>
              </div>
            )}
          </div>
        </div>
      )
    }

    if (msg.type === 'narration') {
      // Strip the narrator's trailing "Keywords: ..." line so it reads as prose,
      // and convert any em/en dashes to commas (backstop for the no-dash rule).
      const body = msg.content
        .replace(/\n?Keywords:[^\n]*$/i, '')
        .replace(/\s*[—–]\s*/g, ', ')
        .trim()
      if (!body) return null
      return (
        <div key={msg.id} style={styles.assistantRow}>
          <div style={styles.narrationBubble}>
            <span style={styles.narrationLabel}>CONTEXT</span>
            <p style={styles.narrationText}>{body}</p>
            {msg.suggestions && msg.suggestions.length > 0 && (
              <div style={styles.suggestionRow}>
                {msg.suggestions.map((s) => (
                  <button
                    key={s}
                    style={styles.suggestionChip}
                    disabled={isStreaming}
                    onClick={() => handleSend(s)}
                    title={`Generate: ${s}`}
                  >
                    {s}
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>
      )
    }

    const text = stripArtifact(msg.content)
    const canonical = findBySourceMessageId(artifacts, msg.id)
    const mappedId = msgArtifactMap.get(msg.id)
    const artifactId =
      canonical?.type === 'webapp'
        ? canonical.id
        : (mappedId && artifacts.some((a) => a.id === mappedId) ? mappedId : canonical?.id ?? mappedId)
    const artifact = artifactId ? artifacts.find((a) => a.id === artifactId) : null
    // Don't offer feedback on the turn that's still streaming in.
    const streamingThis = isStreaming && messages[messages.length - 1]?.id === msg.id
    const showFeedback = !streamingThis && (Boolean(text) || Boolean(artifact))

    return (
      <div key={msg.id} style={styles.assistantRow}>
        <div style={styles.assistantBubble}>
          {text && <p style={styles.msgText}>{cleanChatText(text)}</p>}
          {artifact && (
            <ArtifactCard
              artifact={artifact}
              isPlaying={playingArtifactId === artifact.id}
              onClick={() => setActive(artifact.id)}
              onPlay={() => handlePlay(artifact)}
              onStop={handleStop}
              onOpenInBrowser={
                artifact.type === 'webapp'
                  ? () => void handleOpenInBrowser(artifact)
                  : undefined
              }
            />
          )}
          {showFeedback && <MessageFeedback messageId={msg.id} content={msg.content} />}
          {msg.usage && (
            <span style={styles.msgUsage} title="Estimated tokens and cost for this response">
              {formatTokenCount(msg.usage.totalTokens)} tok ·{' '}
              {formatCostUSD(msg.usage.costUSD, msg.usage.freeTier)}
              {msg.usage.freeTier ? ' · free tier' : ''}
            </span>
          )}
        </div>
      </div>
    )
  }

  const needsApiKey = providersAvailable !== null && providersAvailable.length === 0
  const showRateLimit = rateLimitUntil != null && rateLimitUntil > Date.now()

  function inputBar(centered: boolean) {
    return (
      <>
        {showRateLimit && (
          <QuotaCooldown
            until={rateLimitUntil!}
            providerLabel={rateLimitProvider}
            onExpired={clearRateLimit}
            compact={centered}
          />
        )}
        <AgentActivityBar compact={!centered} onCancel={isStreaming ? handleCancel : undefined} />
        {showRetryBar && (
          <PromptRetryBar
            prompt={lastUserPrompt}
            disabled={isStreaming}
            onTryAgain={() => handleSend(undefined, { retry: true })}
            onEdit={() => handleSend(lastUserPrompt, { refillOnly: true })}
            onVariant={() => handleSend(undefined, { variant: true })}
          />
        )}
        <div style={centered ? styles.inputBlockCentered : styles.inputBlock}>
          {needsApiKey && (
            <p style={centered ? styles.promptKeyHintCentered : styles.promptKeyHint}>
              Add a free or personal API key in{' '}
              <Link to="/settings" style={styles.promptKeyLink}>Settings</Link>
              {' '}before your first sound — Web Apps need no key.
            </p>
          )}
          <div style={styles.inputInner}>
            <textarea
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter' && !e.shiftKey) {
                  e.preventDefault()
                  handleSend()
                }
              }}
              placeholder={
                isStreaming
                  ? 'Dr.C is working on your request…'
                  : showRateLimit
                    ? 'Free-tier rate limit — wait for the countdown…'
                  : needsApiKey
                    ? 'Describe your first sound…'
                    : 'Describe a sound...'
              }
              style={styles.textarea}
              rows={1}
              disabled={isStreaming || showRateLimit}
            />
            <button
              onClick={() => (isStreaming ? handleCancel() : handleSend())}
              disabled={isStreaming ? false : !input.trim() || showRateLimit}
              style={{
                ...styles.sendBtn,
                opacity: isStreaming ? 1 : !input.trim() ? 0.3 : 1,
              }}
              title={isStreaming ? 'Cancel this request' : 'Send'}
            >{isStreaming ? '✕' : '↑'}</button>
          </div>
          <div style={styles.inputFooter}>
            <div style={styles.modeSwitch}>
              {(Object.keys(MODE_INFO) as AgentMode[]).map((m) => (
                <button key={m} onClick={() => setAgentMode(m)}
                  style={{ ...styles.modeBtn, ...(agentMode === m ? { background: 'var(--bg-secondary)', color: MODE_INFO[m].color } : {}) }}>
                  {MODE_INFO[m].label}
                </button>
              ))}
            </div>
            <div style={styles.footerRight}>
              <ProfileBadge />
              <span style={styles.hint}>CSD · Web App · Cabbage</span>
            </div>
          </div>
        </div>
      </>
    )
  }

  return (
    <div style={styles.page}>
      <SessionHistory
        open={historyOpen}
        currentSessionID={sessionID}
        onClose={() => setHistoryOpen(false)}
        onLoad={(id) => void loadSession(id)}
      />

      {/* Chat side */}
      <div style={styles.chatSide}>
        <div style={styles.topBar}>
          <button style={styles.topBtn} onClick={() => setHistoryOpen(true)} title="Session history">
            ☰ History
          </button>
          <button
            style={styles.topBtn}
            onClick={newChat}
            disabled={messages.length === 0 && !sessionID}
            title="Start a new chat"
          >
            ＋ New
          </button>
          <div style={styles.topBarSpacer} />
          <StudyFlowButton
            studyInput={agentStudyInput}
            label="Study flow"
            title="Block diagram of the current Agent instrument"
          />
        </div>
        {messages.length === 0 ? (
          /* Landing — centered hero + input (Claude-style) */
          <div style={styles.landing}>
            <div style={styles.landingInner}>
              <div style={styles.logo}>
                <span style={styles.logoDr}>Dr</span><span style={styles.logoC}>C</span>
              </div>
              <p style={styles.emptyTitle}>What do you want to hear?</p>
              <p style={styles.emptyDesc}>
                {needsApiKey
                  ? 'No API key yet? Explore bundled Csound models on the Player tab, or open Web Apps — both work offline.'
                  : 'Describe a sound in your own words. Curated web demos live under the Web Apps tab.'}
              </p>
              <div style={styles.workshopRow}>
                <Link to="/player?demos=1" style={styles.workshopBtn}>
                  Explore Csound Models in Player
                </Link>
                <Link to="/apps" style={styles.workshopLink}>Web Apps →</Link>
              </div>
              {inputBar(true)}
            </div>
          </div>
        ) : (
          /* Conversation — messages fill, input docked at bottom */
          <>
            <div style={styles.messages}>
              {messages.map(renderMessage)}
              {isStreaming && (() => {
                const last = messages[messages.length - 1]
                const awaitingFirstChunk = !last || last.role === 'user'
                return (
                  <div style={styles.assistantRow}>
                    <div style={styles.streamingBubble}>
                      <div style={styles.thinkingWrap}>
                        <div style={styles.dots}>
                          <span style={styles.dot} />
                          <span style={{ ...styles.dot, animationDelay: '0.18s' }} />
                          <span style={{ ...styles.dot, animationDelay: '0.36s' }} />
                        </div>
                        <span style={styles.thinkingLabel}>
                          {agentActivity || (awaitingFirstChunk ? 'Waiting for the model…' : 'Writing your CSD…')}
                        </span>
                      </div>
                    </div>
                  </div>
                )
              })()}
              <div ref={messagesEndRef} />
            </div>
            <div style={styles.inputArea}>
              <UsageBar area="agent" />
              {inputBar(false)}
            </div>
          </>
        )}
      </div>

      {/* Artifact panel (co-work) — defer Monaco until CSD is complete */}
      {panelOpen && (
        <ErrorBoundary
          label="Artifact editor"
          onError={() => useEditorStore.getState().setForcePlain(true)}
        >
          <ArtifactPanel onConvert={requestConversion} />
        </ErrorBoundary>
      )}
      {showApiKeyDialog && <ApiKeyPromptDialog onClose={() => setShowApiKeyDialog(false)} />}
    </div>
  )
}

const styles: Record<string, CSSProperties> = {
  page: { height: '100%', display: 'flex', background: 'var(--bg-primary)' },

  chatSide: { flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0, position: 'relative' },

  topBar: {
    display: 'flex',
    gap: 6,
    alignItems: 'center',
    padding: '8px 16px',
    borderBottom: '1px solid var(--border-subtle)',
  },
  topBarSpacer: { flex: 1 },
  topBtn: {
    border: '1px solid var(--border)',
    background: 'transparent',
    color: 'var(--text-secondary)',
    fontSize: 11,
    fontFamily: 'var(--font-primary)',
    padding: '4px 10px',
    borderRadius: 8,
    cursor: 'pointer',
  },
  footerRight: { display: 'flex', alignItems: 'center', gap: 10 },

  messages: { flex: 1, overflow: 'auto', padding: '24px 0' },

  userRow: { display: 'flex', justifyContent: 'flex-end', padding: '3px 28px' },
  userBubbleCol: {
    maxWidth: 560,
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'flex-end',
    gap: 6,
  },
  userPromptBtn: {
    textAlign: 'left',
    maxWidth: 560,
    background: 'var(--accent-muted)',
    borderRadius: '16px 16px 4px 16px',
    padding: '10px 16px',
    border: '1px solid transparent',
    cursor: 'pointer',
    fontSize: 14,
    lineHeight: 1.65,
    color: 'var(--text-primary)',
    whiteSpace: 'pre-wrap',
    fontFamily: 'var(--font-primary)',
  },
  userPromptBtnDisabled: {
    opacity: 0.55,
    cursor: 'not-allowed',
  },
  userPromptActions: {
    display: 'flex',
    flexWrap: 'wrap',
    gap: 6,
    justifyContent: 'flex-end',
  },
  userPromptAction: {
    fontSize: 11,
    fontWeight: 500,
    padding: '4px 10px',
    borderRadius: 8,
    border: '1px solid var(--border)',
    background: 'var(--bg-secondary)',
    color: 'var(--text-secondary)',
    cursor: 'pointer',
  },
  userBubble: {
    maxWidth: 560, background: 'var(--accent-muted)', borderRadius: '16px 16px 4px 16px', padding: '10px 16px',
  },

  assistantRow: { display: 'flex', padding: '3px 28px' },
  assistantBubble: { maxWidth: 640 },

  narrationBubble: {
    maxWidth: 640,
    padding: '12px 16px',
    borderLeft: '2px solid var(--accent)',
    background: 'var(--accent-muted)',
    borderRadius: '2px 10px 10px 2px',
    display: 'flex',
    flexDirection: 'column',
    gap: 6,
  },
  narrationLabel: {
    fontSize: 9,
    fontWeight: 700,
    letterSpacing: '0.14em',
    color: 'var(--accent)',
    fontFamily: 'var(--font-primary)',
  },
  narrationText: {
    fontSize: 13,
    lineHeight: 1.55,
    color: 'var(--text-secondary)',
    fontStyle: 'italic',
    margin: 0,
  },
  errorBubble: {
    maxWidth: 520,
    padding: '14px 18px',
    borderRadius: 12,
    border: '1.5px solid #c45c5c',
    background: 'rgba(196, 92, 92, 0.08)',
  },
  errorLabel: {
    display: 'block',
    fontSize: 10,
    fontWeight: 600,
    letterSpacing: '0.08em',
    textTransform: 'uppercase',
    color: '#c45c5c',
    marginBottom: 6,
  },
  errorText: {
    fontSize: 13.5,
    lineHeight: 1.55,
    color: 'var(--text-primary)',
    margin: 0,
  },
  errorActions: {
    display: 'flex',
    flexWrap: 'wrap',
    gap: 8,
    marginTop: 12,
  },
  errorActionPrimary: {
    fontSize: 12,
    fontWeight: 600,
    padding: '6px 12px',
    borderRadius: 8,
    border: '1px solid var(--accent)',
    background: 'var(--accent-muted)',
    color: 'var(--accent)',
    cursor: 'pointer',
  },
  errorAction: {
    fontSize: 12,
    fontWeight: 500,
    padding: '6px 12px',
    borderRadius: 8,
    border: '1px solid var(--border)',
    background: 'var(--bg-primary)',
    color: 'var(--text-secondary)',
    cursor: 'pointer',
  },
  suggestionRow: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    gap: 6,
    marginTop: 12,
  },
  suggestionChip: {
    width: '100%',
    maxWidth: 340,
    textAlign: 'center',
    padding: '8px 14px',
    borderRadius: 10,
    border: '1px solid var(--accent)',
    background: 'transparent',
    color: 'var(--accent)',
    fontSize: 12,
    fontWeight: 500,
    cursor: 'pointer',
    fontFamily: 'var(--font-primary)',
    whiteSpace: 'nowrap',
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    transition: 'background 150ms ease, opacity 150ms ease',
  },

  msgText: { fontSize: 14, lineHeight: 1.65, color: 'var(--text-primary)', whiteSpace: 'pre-wrap', margin: 0 },
  msgUsage: {
    display: 'block',
    marginTop: 8,
    fontSize: 10,
    fontFamily: 'var(--font-mono)',
    color: 'var(--text-muted)',
  },

  streamingBubble: { padding: '8px 0' },
  thinkingWrap: {
    display: 'inline-flex', alignItems: 'center', gap: 10,
    padding: '8px 14px', borderRadius: 14,
    background: 'var(--bg-secondary)',
    border: '1px solid var(--border-subtle)',
  },
  dots: { display: 'flex', gap: 5 },
  dot: {
    width: 8, height: 8, borderRadius: '50%', background: 'var(--accent)',
    animation: 'pulse 1.2s ease-in-out infinite',
  },
  thinkingLabel: {
    fontSize: 12, color: 'var(--text-secondary)',
    fontFamily: 'var(--font-primary)', fontStyle: 'italic',
  },

  landing: {
    flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center',
    justifyContent: 'center', overflow: 'auto', padding: 40,
  },
  landingInner: {
    width: '100%', maxWidth: 640,
    display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14,
  },
  logo: { display: 'flex', alignItems: 'baseline' },
  logoDr: { fontSize: 44, fontWeight: 600, color: 'var(--text-primary)' },
  logoC: { fontSize: 44, fontWeight: 300, color: 'var(--accent)' },
  emptyTitle: { fontSize: 18, fontWeight: 500, color: 'var(--text-primary)' },
  emptyDesc: { fontSize: 14, color: 'var(--text-muted)', textAlign: 'center', maxWidth: 460, lineHeight: 1.5 },

  inputArea: {
    padding: '10px 28px 18px', borderTop: '1px solid var(--border-subtle)',
    display: 'flex', justifyContent: 'center',
  },
  inputBlock: { width: '100%', maxWidth: 720 },
  inputBlockCentered: { width: '100%', marginTop: 12 },
  inputInner: { display: 'flex', gap: 8, alignItems: 'flex-end', width: '100%' },
  textarea: {
    flex: 1, resize: 'none', border: '1.5px solid var(--border)', borderRadius: 14,
    padding: '11px 16px', fontSize: 14, fontFamily: 'var(--font-primary)',
    background: 'var(--bg-secondary)', color: 'var(--text-primary)', outline: 'none',
    minHeight: 44, maxHeight: 160, lineHeight: 1.5,
  },
  sendBtn: {
    width: 40, height: 40, borderRadius: 12, border: 'none', background: 'var(--accent)',
    color: 'var(--bg-primary)', fontSize: 18, fontWeight: 700,
    display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', flexShrink: 0,
  },
  inputFooter: {
    display: 'flex', justifyContent: 'space-between', alignItems: 'center',
    marginTop: 6, width: '100%',
  },
  modeSwitch: {
    display: 'flex', gap: 2, background: 'var(--bg-tertiary)', borderRadius: 8, padding: 2,
  },
  modeBtn: {
    padding: '3px 10px', fontSize: 11, fontWeight: 500, letterSpacing: '0.04em',
    border: 'none', background: 'transparent', color: 'var(--text-muted)',
    borderRadius: 6, cursor: 'pointer', textTransform: 'uppercase' as const,
    fontFamily: 'var(--font-primary)',
  },
  hint: { fontSize: 11, color: 'var(--text-muted)', fontStyle: 'italic' },

  promptKeyHint: {
    fontSize: 12,
    lineHeight: 1.45,
    color: 'var(--text-muted)',
    margin: '0 0 8px',
  },
  promptKeyHintCentered: {
    fontSize: 12.5,
    lineHeight: 1.45,
    color: 'var(--text-muted)',
    margin: '0 0 10px',
    textAlign: 'center',
  },
  promptKeyLink: {
    color: 'var(--accent)',
    textDecoration: 'none',
    fontWeight: 500,
  },
  workshopRow: {
    display: 'flex',
    flexWrap: 'wrap',
    gap: 10,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 4,
  },
  workshopBtn: {
    padding: '8px 14px',
    borderRadius: 10,
    border: '1.5px solid var(--accent)',
    background: 'var(--accent-muted)',
    color: 'var(--accent)',
    fontSize: 12,
    fontWeight: 600,
    cursor: 'pointer',
    fontFamily: 'var(--font-primary)',
  },
  workshopLink: {
    fontSize: 12,
    color: 'var(--accent)',
    textDecoration: 'none',
    fontWeight: 500,
  },
}
