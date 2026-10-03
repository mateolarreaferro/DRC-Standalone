import { useState, useCallback, useRef, useMemo, useEffect, type CSSProperties, type DragEvent } from 'react'
import { useNavigate, useLocation, useSearchParams } from 'react-router-dom'
import { usePlayerStore } from '../stores/playerStore'
import { useEditorStore } from '../stores/editorStore'
import { useArtifactStore } from '../stores/artifactStore'
import { resolveAgentCsd } from '../lib/playerLoad'
import Knob from '../components/player/Knob'
import PianoKeyboard from '../components/player/PianoKeyboard'
import { audioFeedback } from '../styles/audio-feedback'
import { useAppStore } from '../stores/appStore'
import { buildConvertPrompt, needsPlayerAdapt } from '../prompts/convert'
import { parseChannels, LEGACY_CHANNELS, type ChannelSpec } from '../lib/parseChannels'
import { useMidi } from '../lib/useMidi'
import { useMidiStore } from '../stores/midiStore'
import { useUsageStore } from '../stores/usageStore'
import UsageBar from '../components/chat/UsageBar'
import QuotaCooldown from '../components/QuotaCooldown'
import { isQuotaError } from '../lib/providerGuide'
import { applyQuotaCooldownFromMessage, isRateLimited, useRateLimitStore } from '../stores/rateLimitStore'
import { useCsoundConsoleStore } from '../stores/csoundConsoleStore'
import { mechanicalPlayerAdapt } from '../lib/mechanicalPlayerAdapt'
import {
  allDemoArpeggioReleaseNotes,
  arpeggioTag,
  demoPhraseFor,
  phraseMidiNotes,
  playDemoPhrase,
} from '../lib/playerDemoArpeggio'
import { loadWorkshopPlayerDemo } from '../lib/workshopDemos'
import PlayerDemosMenu from '../components/player/PlayerDemosMenu'
import PlayerAudioScope from '../components/player/PlayerAudioScope'
import PlayerCsdPanel from '../components/player/PlayerCsdPanel'
import StudyFlowButton from '../components/study/StudyFlowButton'
import type { SignalFlowStudyInput } from '../lib/signalFlowStudy'
import type { UsageRecord } from '../lib/usageFormat'

type AdaptStatus =
  | { kind: 'idle' }
  | { kind: 'reading' }
  | { kind: 'adapting' }
  | { kind: 'compiling' }
  | { kind: 'starting' }
  | { kind: 'ready'; hint?: string }
  | { kind: 'error'; message: string }

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

/** Short audible check so load is not silent — Player has no scheduled score. */
async function waitForCsoundEvents(maxMs = 10000): Promise<boolean> {
  const api = window.api?.csound
  if (!api?.event) return false
  const start = Date.now()
  while (Date.now() - start < maxMs) {
    const r = await api.event('i 100 0 0 "amplitude" 0.5')
    if (r?.success) return true
    await sleep(120)
  }
  return false
}

async function releaseDemoArpeggioNotes(notes?: readonly number[]): Promise<void> {
  const api = window.api?.csound
  if (!api?.event) return
  const toRelease = notes ?? allDemoArpeggioReleaseNotes()
  for (const midi of toRelease) {
    await api.event(`i -${arpeggioTag(midi)} 0 0`).catch(() => {})
  }
}

export default function PlayerPage() {
  const navigate = useNavigate()
  const location = useLocation()
  const { isPlaying, currentTime, duration, setPlaying, channels, setChannel } = usePlayerStore()
  const { csdContent, setCsdContent } = useEditorStore()
  const artifacts = useArtifactStore((s) => s.artifacts)
  const activeArtifactId = useArtifactStore((s) => s.activeArtifactId)
  const agentCsd = useMemo(
    () => resolveAgentCsd(artifacts, activeArtifactId),
    [artifacts, activeArtifactId],
  )
  const audioEnabled = useAppStore((s) => s.audioFeedbackEnabled)
  const [activeNotes, setActiveNotes] = useState<Set<number>>(new Set())
  // Source-of-truth set used by note handlers — synchronous dedupe avoids
  // double-trigger on browser keydown autorepeat or simultaneous touch+mouse.
  const activeNotesRef = useRef<Set<number>>(new Set())
  /** Block note events while the engine is stopping or between loads. */
  const notesEnabledRef = useRef(false)
  /** Keyboard + USB MIDI accept input when the realtime engine is live (not transport UI). */
  const [inputLive, setInputLive] = useState(false)
  const workshopAutoLoadRef = useRef(false)
  const demosSectionRef = useRef<HTMLDivElement>(null)
  const playSessionRef = useRef(0)
  const lastArpeggioNotesRef = useRef<number[]>([])
  const [lastGoodCsd, setLastGoodCsd] = useState('')
  const [searchParams] = useSearchParams()
  // The CSD declares its own knobs via `chn_k`; we re-parse on every CSD change
  // and merge with prior values so live tweaks survive an identical reload.
  const channelSpecs = useMemo<ChannelSpec[]>(() => {
    const parsed = parseChannels(csdContent)
    return parsed.length > 0 ? parsed : LEGACY_CHANNELS
  }, [csdContent])
  const [paramValues, setParamValues] = useState<Record<string, number>>(() => {
    const seed: Record<string, number> = {}
    for (const c of channelSpecs) seed[c.name] = c.default
    return seed
  })
  // When the spec changes (new CSD adapted), seed any new channels to their
  // declared default and drop bindings for channels that no longer exist.
  useEffect(() => {
    setParamValues((prev) => {
      const next: Record<string, number> = {}
      for (const c of channelSpecs) {
        next[c.name] = prev[c.name] ?? c.default
      }
      return next
    })
  }, [channelSpecs])
  const [adaptStatus, setAdaptStatus] = useState<AdaptStatus>({ kind: 'idle' })
  const [dragging, setDragging] = useState(false)
  const [showCsd, setShowCsd] = useState(false)
  const [currentDemoId, setCurrentDemoId] = useState<string | undefined>()
  const [currentDemoTitle, setCurrentDemoTitle] = useState<string | undefined>()
  const [demoMenuVersion, setDemoMenuVersion] = useState(0)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const rateLimitUntil = useRateLimitStore((s) => s.until)
  const rateLimitProvider = useRateLimitStore((s) => s.providerLabel)
  const clearRateLimit = useRateLimitStore((s) => s.clearCooldown)
  const setEditorHidesConsole = useCsoundConsoleStore((s) => s.setEditorHidesConsole)

  useEffect(() => {
    setEditorHidesConsole(showCsd)
    return () => setEditorHidesConsole(false)
  }, [showCsd, setEditorHidesConsole])

  // USB MIDI routes through Web MIDI → stdin (native PortMIDI is disabled on Player).
  // Enable on mount so a controller works as soon as an instrument is live.
  useEffect(() => {
    if (!useMidiStore.getState().enabled) {
      useMidiStore.getState().setEnabled(true)
    }
  }, [])

  const formatTime = (seconds: number) => {
    const m = Math.floor(seconds / 60)
    const s = Math.floor(seconds % 60)
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`
  }

  // Build the fractional p1 the score event uses for a held note. Three-digit
  // padded MIDI ensures we get unique tags (1.069 ≠ 1.070), and `i -1.069 0 0`
  // hits exactly the instance to release. The voice's linsegr handles the tail.
  const tagFor = (midi: number) => `1.${midi.toString().padStart(3, '0')}`

  const releaseAllHeldNotes = useCallback(async () => {
    const api = window.api?.csound
    if (!api?.event) return
    for (const midi of [...activeNotesRef.current]) {
      await api.event(`i -${tagFor(midi)} 0 0`).catch(() => {})
    }
    activeNotesRef.current.clear()
    setActiveNotes(new Set())
  }, [])

  const stopPlayerEngine = useCallback(async () => {
    notesEnabledRef.current = false
    setInputLive(false)
    setPlaying(false)
    await releaseAllHeldNotes()
    await releaseDemoArpeggioNotes(lastArpeggioNotesRef.current)
    lastArpeggioNotesRef.current = []
    await window.api?.csound?.stop?.().catch(() => {})
  }, [releaseAllHeldNotes, setPlaying])

  // Kill realtime csound when leaving Player — otherwise a prior instrument keeps running.
  useEffect(() => {
    return () => {
      void stopPlayerEngine()
    }
  }, [stopPlayerEngine])

  const handleNoteOn = useCallback((midi: number, velocity = 0.8) => {
    if (!notesEnabledRef.current) return
    if (activeNotesRef.current.has(midi)) return
    activeNotesRef.current.add(midi)
    setActiveNotes((prev) => new Set(prev).add(midi))
    if (audioEnabled) audioFeedback.click()
    const hz = 440 * Math.pow(2, (midi - 69) / 12)
    const tag = tagFor(midi)
    // p3 = -1: indefinite duration. The matching i -1.NNN call below ends it.
    void window.api?.csound?.event(`i ${tag} 0 -1 ${hz.toFixed(3)} ${velocity.toFixed(3)}`)
  }, [audioEnabled])

  const handleNoteOff = useCallback((midi: number) => {
    if (!notesEnabledRef.current) return
    if (!activeNotesRef.current.has(midi)) return
    activeNotesRef.current.delete(midi)
    setActiveNotes((prev) => {
      const next = new Set(prev)
      next.delete(midi)
      return next
    })
    const tag = tagFor(midi)
    // Negative p1 of the same fractional tag fires linsegr's release segment
    // and turns off that specific instance once the tail completes.
    void window.api?.csound?.event(`i -${tag} 0 0`)
  }, [])

  const handleParamChange = useCallback((spec: ChannelSpec, value: number) => {
    setParamValues((prev) => ({ ...prev, [spec.name]: value }))
    setChannel(spec.name, value)
    void window.api?.csound?.setChannel(spec.name, value)
  }, [setChannel])

  // Wire Web MIDI: noteOn/Off reuse the on-screen keyboard handlers, and CCs
  // are routed through MIDI Learn — when a knob is armed (`learnTarget` set),
  // the next CC binds to it; otherwise CC values scale across the bound spec's
  // [min, max] and get pushed via setChannel like any other knob move.
  const midiEnabled    = useMidiStore((s) => s.enabled)
  const midiStatus     = useMidiStore((s) => s.status)
  const midiInputs     = useMidiStore((s) => s.inputs)
  const midiBindings   = useMidiStore((s) => s.bindings)
  const learnTarget    = useMidiStore((s) => s.learnTarget)
  const startLearn     = useMidiStore((s) => s.startLearn)
  const cancelLearn    = useMidiStore((s) => s.cancelLearn)
  const setMidiEnabled = useMidiStore((s) => s.setEnabled)

  const handleCCBinding = useCallback((channelName: string, normalized01: number) => {
    // Bindings persist in localStorage but channelSpecs is per-CSD. After a
    // re-adapt or load, an old binding can reference a channel name that no
    // longer exists (or differs only in case). Try exact, then case-insensitive,
    // then surface the miss so the user sees *why* the bound knob did nothing
    // rather than silently swallowing every CC.
    let spec = channelSpecs.find((c) => c.name === channelName)
    if (!spec) {
      const lc = channelName.toLowerCase()
      spec = channelSpecs.find((c) => c.name.toLowerCase() === lc)
    }
    if (!spec) {
      // eslint-disable-next-line no-console
      console.warn(
        `[midi] CC for "${channelName}" arrived but no chn_k channel matches — current patch declares: ${channelSpecs.map((c) => c.name).join(', ') || '(none)'}`,
      )
      return
    }
    // Map 0..1 across the spec's range. Exponential curves map log-spaced so a
    // mid-position knob lands musically (e.g. 632 Hz on a 20..20000 cutoff).
    let value: number
    if (spec.curve === 'exp' && spec.min > 0) {
      value = spec.min * Math.pow(spec.max / spec.min, normalized01)
    } else if (spec.curve === 'int') {
      value = Math.round(spec.min + (spec.max - spec.min) * normalized01)
    } else {
      value = spec.min + (spec.max - spec.min) * normalized01
    }
    handleParamChange(spec, value)
  }, [channelSpecs, handleParamChange])

  const handleHardwareCC = useCallback((cc: number, normalized01: number) => {
    const ch = `cc${cc}`
    if (channelSpecs.some((c) => c.name === ch)) {
      handleCCBinding(ch, normalized01)
    }
  }, [channelSpecs, handleCCBinding])

  useMidi(
    { onNoteOn: handleNoteOn, onNoteOff: handleNoteOff, onCC: handleHardwareCC },
    handleCCBinding,
    inputLive,
  )

  const ccLabelFor = (channel: string): string | null => {
    const auto = /^cc(\d+)$/i.exec(channel)
    if (auto) return `CC ${auto[1]}`
    for (const k of Object.keys(midiBindings)) {
      const b = midiBindings[k]
      if (b.channel === channel) return `CC ${b.cc}`
    }
    return null
  }

  // Load a raw CSD string: adapt via the LLM if it doesn't already follow the
  // Player convention, then compile + play. Returns once playback has kicked off
  // (or an error is surfaced in adaptStatus).
  const loadAndPlayCsd = useCallback(async (
    raw: string,
    opts?: { demoId?: string; demoTitle?: string; demoGroup?: string; filename?: string },
  ) => {
    if (!window.api?.csound) {
      setAdaptStatus({ kind: 'error', message: 'Csound bridge unavailable' })
      return
    }

    const session = ++playSessionRef.current
    const isActive = () => playSessionRef.current === session

    // Stop prior instrument completely — release keys, kill csound, cancel arpeggio.
    await stopPlayerEngine()
    if (!isActive()) return

    let csd = raw.trim()
    if (needsPlayerAdapt(csd)) {
      const wrapped = mechanicalPlayerAdapt(csd)
      if (wrapped) {
        csd = wrapped
      } else {
        const keys: any = await window.api?.config?.getApiKeys?.().catch(() => null)
        const hasKey = (keys?.available?.length ?? 0) > 0
        if (!hasKey) {
          setAdaptStatus({
            kind: 'error',
            message: 'This CSD needs adapting, but no model is configured. Click Workshop demo (no key) below, or enable Ollama in Settings.',
          })
          return
        }
        if (!isActive()) return
        setAdaptStatus({ kind: 'adapting' })
        const prompt = buildConvertPrompt('player', csd)
        const resp = await window.api.llm.adaptCsd(prompt).catch((err: any) => ({ ok: false, error: err?.message ?? 'adapt failed' })) as {
          ok: boolean
          csd?: string
          usage?: UsageRecord
          error?: string
        }
        if (resp?.ok && resp.csd) {
          if (resp.usage) useUsageStore.getState().record('player', resp.usage)
          csd = resp.csd
        } else {
          const msg = resp?.error ?? 'unknown'
          if (isQuotaError(msg)) applyQuotaCooldownFromMessage(msg)
          const fallback = mechanicalPlayerAdapt(csd)
          if (fallback) {
            csd = fallback
          } else {
            setAdaptStatus({
              kind: 'error',
              message: isQuotaError(msg)
                ? `${msg} Try Workshop demo (no key), or wait for the countdown.`
                : `Adapt failed: ${msg}`,
            })
            return
          }
        }
      }
    }

    setCsdContent(csd)
    const specs = parseChannels(csd)
    setParamValues(Object.fromEntries(specs.map((s) => [s.name, s.default])))
    if (!isActive()) return
    setAdaptStatus({ kind: 'compiling' })
    try {
      const { path } = await window.api.csound.writeCsd(csd)
      if (!isActive()) return
      const compile = await window.api.csound.compile(path)
      if (!compile.success) {
        setAdaptStatus({ kind: 'error', message: `Compile error: ${String(compile.error ?? '').slice(0, 240)}` })
        return
      }
      if (!isActive()) return
      setAdaptStatus({ kind: 'starting' })
      const playRes = await window.api.csound.play(path, { realtime: true })
      if (!isActive()) {
        await stopPlayerEngine()
        return
      }
      if (!playRes.success) {
        setAdaptStatus({ kind: 'error', message: `Playback error: ${String(playRes.error ?? '').slice(0, 240)}` })
        setPlaying(false)
        return
      }
      const eventsLive = await waitForCsoundEvents()
      if (!isActive()) return
      if (!eventsLive) {
        setAdaptStatus({
          kind: 'error',
          message: 'Audio engine started but keyboard events did not connect. Settings → Audio → reset to System default, then retry.',
        })
        setPlaying(false)
        return
      }
      for (const spec of specs) {
        await window.api.csound.setChannel(spec.name, spec.default).catch(() => {})
      }
      setLastGoodCsd(csd)
      setAdaptStatus({ kind: 'ready', hint: 'Playing demo…' })
      setPlaying(true)
      notesEnabledRef.current = true
      setInputLive(true)
      if (!useMidiStore.getState().enabled) {
        useMidiStore.getState().setEnabled(true)
      }
      const phrase = demoPhraseFor({
        id: opts?.demoId ?? currentDemoId,
        title: opts?.demoTitle ?? currentDemoTitle,
        demoGroup: opts?.demoGroup,
        filename: opts?.filename,
        csd,
      })
      lastArpeggioNotesRef.current = phraseMidiNotes(phrase)
      const emit = (line: string) => window.api!.csound!.event(line)
      await playDemoPhrase(phrase, isActive, emit)
      if (!isActive()) return
      setAdaptStatus({ kind: 'ready', hint: 'Live — click the keyboard below or use MIDI' })
    } catch (err: any) {
      if (!isActive()) return
      setAdaptStatus({ kind: 'error', message: err?.message ?? 'Unexpected error' })
    }
  }, [setCsdContent, setPlaying, stopPlayerEngine, currentDemoId, currentDemoTitle])

  const handleFile = useCallback(async (file: File) => {
    setAdaptStatus({ kind: 'reading' })
    try {
      const text = await file.text()
      if (!text.trim()) {
        setAdaptStatus({ kind: 'error', message: 'File is empty' })
        return
      }
      await loadAndPlayCsd(text)
    } catch (err: any) {
      setAdaptStatus({ kind: 'error', message: err?.message ?? 'Failed to read file' })
    }
  }, [loadAndPlayCsd])

  const handleDrop = useCallback((e: DragEvent<HTMLDivElement>) => {
    e.preventDefault()
    setDragging(false)
    const file = e.dataTransfer.files?.[0]
    if (file) void handleFile(file)
  }, [handleFile])

  const onPickFile = useCallback(() => fileInputRef.current?.click(), [])

  const loadBusy =
    adaptStatus.kind === 'reading' ||
    adaptStatus.kind === 'adapting' ||
    adaptStatus.kind === 'compiling' ||
    adaptStatus.kind === 'starting'

  const handleLoadAgentCsd = useCallback(async () => {
    const resolved = resolveAgentCsd(
      useArtifactStore.getState().artifacts,
      useArtifactStore.getState().activeArtifactId,
    )
    if (!resolved) {
      setAdaptStatus({
        kind: 'error',
        message: 'No CSD in the current Agent session — generate one on the Agent tab first.',
      })
      return
    }
    setAdaptStatus({ kind: 'reading' })
    await loadAndPlayCsd(resolved.csd)
  }, [loadAndPlayCsd])

  // Workshop buttons on Agent land here with a player-ready CSD — auto-load once.
  useEffect(() => {
    const state = location.state as { autoLoadWorkshop?: boolean } | null
    if (!state?.autoLoadWorkshop || !agentCsd || workshopAutoLoadRef.current) return
    workshopAutoLoadRef.current = true
    navigate(location.pathname, { replace: true, state: {} })
    void handleLoadAgentCsd()
  }, [location.state, location.pathname, agentCsd, handleLoadAgentCsd, navigate])

  const hasCsd = csdContent.trim().length > 0
  const hasP4 = csdContent.includes('p4')

  const adaptLabel =
    adaptStatus.kind === 'reading'   ? 'Reading CSD…' :
    adaptStatus.kind === 'adapting'  ? 'Adapting for Player…' :
    adaptStatus.kind === 'compiling' ? 'Compiling…' :
    adaptStatus.kind === 'starting'  ? 'Starting audio engine…' :
    adaptStatus.kind === 'ready'     ? (adaptStatus.hint ?? 'Live — click the keyboard below') :
    adaptStatus.kind === 'error'     ? adaptStatus.message :
    null

  const showRateLimit = rateLimitUntil != null && rateLimitUntil > Date.now()
  const loadDisabled = loadBusy

  const studyInput = useMemo<SignalFlowStudyInput>(() => ({
    title: currentDemoTitle ?? 'Player instrument',
    source: csdContent,
    channels: channelSpecs,
  }), [csdContent, channelSpecs, currentDemoTitle])

  const handleWorkshopDemo = useCallback(async (id: string) => {
    setAdaptStatus({ kind: 'reading' })
    const demo = await loadWorkshopPlayerDemo(id)
    if (!demo) {
      setAdaptStatus({ kind: 'error', message: 'Demo file missing — reinstall Dr.C or pick another demo.' })
      return
    }
    setCurrentDemoId(id)
    const meta = (await window.api?.workshop?.read?.(id))?.meta
    setCurrentDemoTitle(meta?.title)
    await loadAndPlayCsd(demo, {
      demoId: id,
      demoTitle: meta?.title,
      demoGroup: meta?.demoGroup,
      filename: meta?.filename,
    })
  }, [loadAndPlayCsd])

  useEffect(() => {
    if (searchParams.get('demos') !== '1') return
    demosSectionRef.current?.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
  }, [searchParams])

  const handleSaveDemoToMenu = useCallback(async (title: string, opts?: { updateExisting?: boolean }) => {
    const updateId =
      opts?.updateExisting && currentDemoId?.startsWith('user_') ? currentDemoId : undefined
    const r: any = await window.api?.workshop?.saveUserDemo?.({
      title,
      content: csdContent,
      id: updateId,
    })
    if (!r?.ok) throw new Error(r?.error ?? 'Save failed')
    setCurrentDemoId(r.meta?.id)
    setCurrentDemoTitle(r.meta?.title)
    setDemoMenuVersion((v) => v + 1)
  }, [csdContent, currentDemoId])

  const handleDeleteCurrentDemo = useCallback(async () => {
    if (!currentDemoId?.startsWith('user_')) return
    const name = currentDemoTitle ?? 'this demo'
    if (!window.confirm(`Remove “${name}” from your demo menu?`)) return
    const r: any = await window.api?.workshop?.deleteUserDemo?.(currentDemoId)
    if (!r?.ok) throw new Error(r?.error ?? 'Delete failed')
    setCurrentDemoId(undefined)
    setCurrentDemoTitle(undefined)
    setDemoMenuVersion((v) => v + 1)
  }, [currentDemoId, currentDemoTitle])

  const handleDemoDeleted = useCallback((id: string) => {
    if (currentDemoId === id) {
      setCurrentDemoId(undefined)
      setCurrentDemoTitle(undefined)
    }
    setDemoMenuVersion((v) => v + 1)
  }, [currentDemoId])

  const handleRevertCsd = useCallback(async () => {
    if (!lastGoodCsd.trim()) return
    setCsdContent(lastGoodCsd)
    await loadAndPlayCsd(lastGoodCsd)
  }, [lastGoodCsd, loadAndPlayCsd, setCsdContent])

  const canRevertCsd =
    Boolean(lastGoodCsd.trim()) &&
    csdContent.trim() !== lastGoodCsd.trim()

  const handleApplyCsd = useCallback(async () => {
    await loadAndPlayCsd(csdContent)
  }, [csdContent, loadAndPlayCsd])

  return (
    <div
      style={{
        ...styles.container,
        ...(dragging ? styles.containerDrag : {}),
        ...(showCsd ? styles.containerEditorOpen : {}),
      }}
      onDragOver={(e) => { e.preventDefault(); if (!dragging) setDragging(true) }}
      onDragLeave={(e) => {
        // Only clear when the drag leaves the whole container, not child elements.
        if (e.currentTarget === e.target) setDragging(false)
      }}
      onDrop={handleDrop}
    >
      <input
        ref={fileInputRef}
        type="file"
        accept=".csd,text/plain"
        style={{ display: 'none' }}
        onChange={(e) => {
          const f = e.target.files?.[0]
          if (f) void handleFile(f)
          e.target.value = ''
        }}
      />

      {/* Header */}
      <div style={styles.header}>
        <div style={styles.headerTitleRow}>
          <h1 style={styles.title}>Player</h1>
          <StudyFlowButton
            studyInput={studyInput}
            disabled={!csdContent.trim()}
            title="Block diagram of the loaded Player instrument"
          />
        </div>
        <div style={styles.headerActions}>
          <PlayerDemosMenu
            refreshKey={demoMenuVersion}
            sectionRef={demosSectionRef}
            disabled={loadDisabled}
            onLoad={(id) => void handleWorkshopDemo(id)}
            onDeleted={handleDemoDeleted}
          />
          <button
            type="button"
            onClick={() => setShowCsd((v) => !v)}
            style={{
              ...styles.loadButton,
              ...(showCsd ? styles.loadButtonPrimary : {}),
            }}
            disabled={false}
            title="View and edit the loaded Csound .csd"
          >
            {showCsd ? 'Hide Csound' : 'Show Csound'}
          </button>
          <button
            onClick={() => void handleLoadAgentCsd()}
            style={{
              ...styles.loadButton,
              ...(agentCsd ? styles.loadButtonPrimary : {}),
            }}
            disabled={loadDisabled}
            title={
              showRateLimit
                ? 'Free-tier rate limit — wait for the countdown'
                : agentCsd
                ? `Adapt and play “${agentCsd.title}” from Agent (MIDI + knobs)`
                : 'Generate a CSD on the Agent tab first'
            }
          >
            Load current Dr.C CSD
          </button>
          <button
            onClick={onPickFile}
            style={styles.loadButton}
            disabled={loadDisabled}
            title="Pick any .csd file — Dr.C adapts it for live play, chn_k knobs, and MIDI Learn"
          >
            Load any CSD…
          </button>
          {!agentCsd && (
            <button
              type="button"
              onClick={() => navigate('/agent')}
              style={styles.linkishBtn}
              title="Open Agent to generate a CSD"
            >
              Agent →
            </button>
          )}
          <button
            onClick={() => setMidiEnabled(!midiEnabled)}
            title={
              !midiEnabled       ? 'Enable physical MIDI input'        :
              midiStatus === 'denied'      ? 'MIDI access denied — check OS permissions' :
              midiStatus === 'unsupported' ? 'Web MIDI unavailable in this build'        :
              midiInputs.length === 0      ? 'MIDI on (no input devices)'                :
              `MIDI on — ${midiInputs.map((i) => i.name).join(', ')}`
            }
            style={{
              ...styles.loadButton,
              ...(midiEnabled ? styles.midiActive : {}),
            }}
          >
            MIDI {midiEnabled
              ? (midiStatus === 'ready' ? `(${midiInputs.length})` : midiStatus === 'requesting' ? '…' : '!')
              : 'off'}
          </button>
        </div>
      </div>

      {showRateLimit && (
        <QuotaCooldown
          until={rateLimitUntil!}
          providerLabel={rateLimitProvider}
          onExpired={clearRateLimit}
        />
      )}

      {showCsd && (
        <PlayerCsdPanel
          fillHeight
          csd={csdContent}
          onChange={setCsdContent}
          onApply={() => void handleApplyCsd()}
          onSaveToMenu={handleSaveDemoToMenu}
          onRevert={() => void handleRevertCsd()}
          onHide={() => setShowCsd(false)}
          onDeleteDemo={currentDemoId?.startsWith('user_') ? handleDeleteCurrentDemo : undefined}
          canRevert={canRevertCsd}
          applyBusy={loadBusy}
          currentDemoTitle={currentDemoTitle}
          currentDemoId={currentDemoId}
        />
      )}

      {/* Transport */}
      <div style={{ ...styles.transport, ...(showCsd ? styles.transportCompact : {}) }}>
        <button
          onClick={() => {
            if (audioEnabled) audioFeedback.click()
            if (isPlaying) {
              void stopPlayerEngine()
              return
            }
            const csd = lastGoodCsd || csdContent
            if (csd.trim()) void loadAndPlayCsd(csd)
          }}
          style={{
            ...styles.playButton,
            ...(isPlaying ? styles.playButtonActive : {}),
          }}
        >
          {isPlaying ? '■' : '▶'}
        </button>
        <span style={styles.time}>
          {formatTime(currentTime)} / {formatTime(duration || 0)}
        </span>
        <div style={styles.transportMeta}>
          {adaptLabel ? (
            <span style={{
              ...styles.hint,
              ...(adaptStatus.kind === 'error' ? { color: '#e28a8a', fontStyle: 'normal' } : {}),
            }}>
              {adaptLabel}
            </span>
              ) : !hasCsd ? (
            <span style={styles.hint}>
              {agentCsd
                ? `Ready: “${agentCsd.title}” from Agent — Load current Dr.C CSD adapts locally when possible (no API for typical FM bells)`
                : 'Workshop demo needs no key. Web Apps tab also works offline. Drop any .csd or load from Agent.'}
            </span>
          ) : null}
          <UsageBar area="player" variant="inline" sessionLabel="Adapts" />
        </div>
      </div>

      {/* Audio scope — hidden while editing Csound (editor uses the vertical space) */}
      {!showCsd && (
        <div style={styles.waveformArea}>
          <PlayerAudioScope activeNotes={activeNotes} isPlaying={isPlaying} height={160} />
        </div>
      )}

      {/* Parameters — built from chn_k declarations in the CSD */}
      {!showCsd && (
      <div style={styles.section}>
        <h3 style={styles.sectionTitle}>
          Parameters
          {channelSpecs.length > 0 && channelSpecs !== LEGACY_CHANNELS ? null : (
            <span style={styles.sectionHint}> — defaults (CSD has no chn_k declarations)</span>
          )}
        </h3>
        <div style={styles.knobGrid}>
          {channelSpecs.map((spec) => (
            <Knob
              key={spec.name}
              label={spec.label}
              value={paramValues[spec.name] ?? spec.default}
              min={spec.min}
              max={spec.max}
              step={spec.step}
              unit={spec.unit}
              onChange={(val) => handleParamChange(spec, val)}
              ccLabel={midiEnabled ? ccLabelFor(spec.name) : null}
              isLearning={midiEnabled && learnTarget === spec.name}
              onToggleLearn={
                midiEnabled
                  ? () => (learnTarget === spec.name ? cancelLearn() : startLearn(spec.name))
                  : undefined
              }
            />
          ))}
        </div>
      </div>
      )}

      {/* Keyboard */}
      {!showCsd && hasP4 && (
        <div style={styles.section}>
          <h3 style={styles.sectionTitle}>Keyboard</h3>
          <div style={styles.keyboardWrapper}>
            <PianoKeyboard
              startOctave={3}
              octaves={3}
              activeNotes={activeNotes}
              onNoteOn={handleNoteOn}
              onNoteOff={handleNoteOff}
              keyboardEnabled={inputLive}
            />
          </div>
        </div>
      )}

      {/* Always show keyboard in demo mode */}
      {!showCsd && !hasP4 && (
        <div style={styles.section}>
          <h3 style={styles.sectionTitle}>
            Keyboard
            <span style={styles.sectionHint}> — appears when CSD uses p4 (pitch)</span>
          </h3>
          <div style={styles.keyboardWrapper}>
            <PianoKeyboard
              startOctave={3}
              octaves={3}
              activeNotes={activeNotes}
              onNoteOn={handleNoteOn}
              onNoteOff={handleNoteOff}
              keyboardEnabled={inputLive}
            />
          </div>
        </div>
      )}
    </div>
  )
}

const styles: Record<string, CSSProperties> = {
  container: {
    height: '100%', overflow: 'auto', display: 'flex', flexDirection: 'column',
    alignItems: 'center', padding: '32px 48px', gap: 28, maxWidth: 900, margin: '0 auto',
    transition: 'background 150ms ease, box-shadow 150ms ease',
  },
  containerEditorOpen: {
    height: '100%',
    overflow: 'hidden',
    padding: '12px 20px 10px',
    gap: 10,
    maxWidth: 'min(1200px, 100%)',
    alignItems: 'stretch',
  },
  containerDrag: {
    background: 'var(--accent-muted)',
    boxShadow: 'inset 0 0 0 2px var(--accent)',
  },
  loadButton: {
    padding: '6px 14px', borderRadius: 8,
    border: 'var(--border-width) solid var(--border)', background: 'transparent',
    color: 'var(--text-secondary)', fontSize: 11, fontWeight: 600,
    letterSpacing: '0.06em', cursor: 'pointer', textTransform: 'none' as const,
    whiteSpace: 'nowrap' as const,
  },
  workshopBtn: {
    padding: '6px 14px', borderRadius: 8,
    border: '1.5px solid var(--accent)', background: 'var(--accent-muted)',
    color: 'var(--accent)', fontSize: 11, fontWeight: 600,
    cursor: 'pointer', whiteSpace: 'nowrap' as const,
  },
  loadButtonPrimary: {
    borderColor: 'var(--accent)',
    color: 'var(--accent)',
    background: 'var(--accent-muted)',
  },
  linkishBtn: {
    padding: '6px 10px', borderRadius: 8, border: 'none', background: 'transparent',
    color: 'var(--accent)', fontSize: 11, fontWeight: 600, cursor: 'pointer',
  },
  midiActive: { borderColor: 'var(--accent)', color: 'var(--accent)' },
  header: {
    width: '100%', display: 'flex', justifyContent: 'space-between', alignItems: 'center',
    flexShrink: 0,
  },
  headerTitleRow: { display: 'flex', alignItems: 'center', gap: 12 },
  title: { fontSize: 28, fontWeight: 300, color: 'var(--text-primary)', letterSpacing: '0.04em', margin: 0 },
  headerActions: { display: 'flex', gap: 8, flexWrap: 'wrap' },
  waveformArea: {
    width: '100%', borderRadius: 16, overflow: 'hidden',
    border: 'var(--border-width) solid var(--border)', background: 'var(--bg-secondary)',
  },
  transport: {
    display: 'flex', alignItems: 'center', gap: 16, width: '100%',
  },
  transportCompact: {
    gap: 10,
    flexShrink: 0,
  },
  transportMeta: {
    flex: 1,
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'flex-end',
    gap: 4,
    minWidth: 0,
  },
  playButton: {
    width: 52, height: 52, borderRadius: 16,
    border: 'var(--border-width) solid var(--border)', background: 'var(--bg-secondary)',
    color: 'var(--accent)', fontSize: 18,
    display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
    transition: 'all 150ms ease',
  },
  playButtonActive: { background: 'var(--accent)', color: 'var(--bg-primary)', borderColor: 'var(--accent)' },
  time: { fontFamily: 'var(--font-mono)', fontSize: 15, color: 'var(--text-secondary)', letterSpacing: '0.04em' },
  hint: { fontSize: 12, color: 'var(--text-muted)', fontStyle: 'italic' },
  section: { width: '100%' },
  sectionTitle: {
    fontSize: 12, fontWeight: 600, letterSpacing: '0.06em',
    color: 'var(--text-muted)', textTransform: 'uppercase', marginBottom: 16,
  },
  sectionHint: { fontWeight: 400, textTransform: 'none', letterSpacing: 'normal', fontStyle: 'italic' },
  knobGrid: {
    display: 'flex', flexWrap: 'wrap', gap: 24, justifyContent: 'center',
    padding: '20px 24px', borderRadius: 16,
    border: 'var(--border-width) solid var(--border)', background: 'var(--bg-secondary)',
  },
  keyboardWrapper: {
    padding: '16px 20px', borderRadius: 16,
    border: 'var(--border-width) solid var(--border)', background: 'var(--bg-secondary)',
    overflow: 'auto', display: 'flex', justifyContent: 'center',
  },
}
