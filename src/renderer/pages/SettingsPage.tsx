import { useState, useEffect, type CSSProperties } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAppStore } from '../stores/appStore'
import { useCsoundConsoleStore } from '../stores/csoundConsoleStore'
import { useUsageStore } from '../stores/usageStore'
import { isFreeTierOnly, isSoloFreeProvider, OPENROUTER_OPTION, PROVIDER_OPTIONS } from '../lib/providerGuide'
import { formatWorkshopLinksForClipboard, SETUP_GUIDE } from '../../shared/workshop-links'
import { formatCostUSD, formatTokenCount } from '../lib/usageFormat'

export default function SettingsPage() {
  const navigate = useNavigate()
  const { theme, toggleTheme, audioFeedbackEnabled, setAudioFeedback } = useAppStore()
  const csoundConsoleEnabled = useCsoundConsoleStore((s) => s.userPinned)
  const setCsoundConsoleEnabled = useCsoundConsoleStore((s) => s.setUserPinned)
  const agentUsage = useUsageStore((s) => s.agent.totals)
  const playerUsage = useUsageStore((s) => s.player.totals)
  const combinedUsage = {
    totalTokens: agentUsage.totalTokens + playerUsage.totalTokens,
    totalCostUSD: agentUsage.totalCostUSD + playerUsage.totalCostUSD,
    turnCount: agentUsage.turnCount + playerUsage.turnCount,
  }
  const [openrouterKey, setOpenrouterKey] = useState('')
  const [googleKey, setGoogleKey] = useState('')
  const [groqKey, setGroqKey] = useState('')
  const [anthropicKey, setAnthropicKey] = useState('')
  const [openaiKey, setOpenaiKey] = useState('')
  const [savedKeys, setSavedKeys] = useState<Record<string, string>>({})
  const [available, setAvailable] = useState<string[]>([])
  const [proPlus, setProPlus] = useState(false)
  const [saving, setSaving] = useState('')
  const [testing, setTesting] = useState('')
  const [removing, setRemoving] = useState('')
  const [testResults, setTestResults] = useState<Record<string, { ok: boolean; message: string }>>({})
  const [cabbagePath, setCabbagePath] = useState('')
  const [cabbageExists, setCabbageExists] = useState<boolean | null>(null)
  const [cabbageDetected, setCabbageDetected] = useState('')
  const [cabbageSaving, setCabbageSaving] = useState(false)
  const [csoundQtPath, setCsoundQtPath] = useState('')
  const [csoundQtExists, setCsoundQtExists] = useState<boolean | null>(null)
  const [csoundQtDetected, setCsoundQtDetected] = useState('')
  const [csoundQtSaving, setCsoundQtSaving] = useState(false)
  const [browserPath, setBrowserPath] = useState('')
  const [browserExists, setBrowserExists] = useState<boolean | null>(null)
  const [browserDetected, setBrowserDetected] = useState('')
  const [browserCandidates, setBrowserCandidates] = useState<{ name: string; path: string }[]>([])
  const [browserSaving, setBrowserSaving] = useState(false)

  const [ollamaEnabled, setOllamaEnabled] = useState(false)
  const [preferOllama, setPreferOllama] = useState(false)
  const [ollamaBaseUrl, setOllamaBaseUrl] = useState('')
  const [ollamaModel, setOllamaModel] = useState('')
  const [ollamaModels, setOllamaModels] = useState<string[]>([])
  const [ollamaRunning, setOllamaRunning] = useState(false)
  const [ollamaTesting, setOllamaTesting] = useState(false)
  const [ollamaTestResult, setOllamaTestResult] = useState<{ ok: boolean; message: string } | null>(null)

  type Device = { index: number; id: string; name: string }
  const [audioDevices, setAudioDevices] = useState<{ outputs: Device[]; inputs: Device[]; midiInputs: Device[] }>({
    outputs: [], inputs: [], midiInputs: [],
  })
  const [audioCfg, setAudioCfg] = useState({ output: '', input: '', midiInput: '' })
  const [audioBusy, setAudioBusy] = useState(false)
  const [memoryReady, setMemoryReady] = useState<boolean | null>(null)
  const [memoryError, setMemoryError] = useState<string | null>(null)
  const [linksCopied, setLinksCopied] = useState(false)

  const loadMemoryStatus = async () => {
    try {
      const s: any = await window.api?.memory?.status?.()
      setMemoryReady(!!s?.ready)
      setMemoryError(s?.error ?? null)
    } catch {
      setMemoryReady(false)
    }
  }

  // Enumerate devices + load the saved selection. Reused by the Refresh button.
  const loadAudio = async () => {
    setAudioBusy(true)
    try {
      const devs: any = await window.api?.config?.listAudioDevices?.()
      if (devs) {
        setAudioDevices({
          outputs: devs.outputs ?? [], inputs: devs.inputs ?? [], midiInputs: devs.midiInputs ?? [],
        })
      }
      const sanitized: any = await window.api?.config?.sanitizeAudioDevices?.()
      const cfg: any = sanitized ?? await window.api?.config?.getAudioConfig?.()
      if (cfg) {
        setAudioCfg({
          output: cfg.output ?? '',
          input: cfg.input ?? '',
          midiInput: cfg.midiInput ?? '',
        })
      }
    } catch { /* csound may be missing — leave lists empty */ } finally {
      setAudioBusy(false)
    }
  }

  const updateDevice = async (
    configKey: string,
    stateKey: 'output' | 'input' | 'midiInput',
    value: string,
  ) => {
    setAudioCfg((c) => ({ ...c, [stateKey]: value })) // optimistic
    await window.api?.config?.setAudioDevice?.(configKey, value)
  }

  const resetAudioDefaults = async () => {
    const r: any = await window.api?.config?.resetAudioDevices?.()
    if (r) setAudioCfg({ output: '', input: '', midiInput: '' })
  }

  const resolveOutputLabel = (id: string) => {
    if (!id) return 'Auto (MacBook speakers / headphones)'
    const d = audioDevices.outputs.find((x) => String(x.index) === id)
    return d ? d.name : `Device ${id} (not found — reset or pick again)`
  }

  const resolveInputLabel = (id: string) => {
    if (!id || id === 'none') return 'None (mic off)'
    const d = audioDevices.inputs.find((x) => String(x.index) === id)
    return d ? d.name : `Device ${id} (not found — reset or pick again)`
  }

  const loadOllama = async () => {
    try {
      const r: any = await window.api?.config?.getOllama?.()
      if (!r) return
      setOllamaEnabled(!!r.enabled)
      setPreferOllama(!!r.preferOllama)
      setOllamaBaseUrl(r.baseUrl || '')
      setOllamaModel(r.model || '')
      setOllamaModels(r.models || [])
      setOllamaRunning(!!r.running)
    } catch {}
  }

  const saveOllama = async (patch: Record<string, unknown>) => {
    const r: any = await window.api?.config?.setOllama?.(patch)
    if (r) {
      setAvailable(r.available || [])
      setOllamaRunning(!!r.ok)
      setOllamaModels(r.models || ollamaModels)
      if (r.model) setOllamaModel(r.model)
      if (patch.enabled !== undefined) setOllamaEnabled(!!patch.enabled)
      window.dispatchEvent(new Event('drc:providers-changed'))
    }
  }

  const handleTestOllama = async () => {
    setOllamaTesting(true)
    setOllamaTestResult(null)
    try {
      const r: any = await window.api?.config?.testOllama?.()
      if (r?.ok && !ollamaEnabled) {
        setOllamaTestResult({
          ok: true,
          message: `${r.message} Now turn on Use local LLM for Agent above — Test alone does not enable the Agent.`,
        })
      } else {
        setOllamaTestResult(r ?? { ok: false, message: 'Test failed' })
      }
      if (r?.ok) {
        window.dispatchEvent(new Event('drc:providers-changed'))
        void loadOllama()
      }
    } catch {
      setOllamaTestResult({ ok: false, message: 'Test failed' })
    }
    setOllamaTesting(false)
  }

  // Load saved keys + Cabbage path on mount
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') navigate('/agent')
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [navigate])

  useEffect(() => {
    window.api?.config?.getApiKeys().then((result: any) => {
      setSavedKeys(result.keys || {})
      setAvailable(result.available || [])
      setProPlus(!!result.proPlus)
    }).catch(() => {})
    window.api?.config?.getCabbagePath?.().then((result: any) => {
      setCabbagePath(result?.path || '')
      setCabbageExists(result?.path ? !!result?.exists : null)
      setCabbageDetected(result?.detected || '')
    }).catch(() => {})
    window.api?.config?.getCsoundQtPath?.().then((result: any) => {
      setCsoundQtPath(result?.path || '')
      setCsoundQtExists(result?.path ? !!result?.exists : null)
      setCsoundQtDetected(result?.detected || '')
    }).catch(() => {})
    window.api?.config?.getBrowserPath?.().then((result: any) => {
      setBrowserPath(result?.path || '')
      setBrowserExists(result?.path ? !!result?.exists : null)
      setBrowserDetected(result?.detected || '')
    }).catch(() => {})
    window.api?.config?.listBrowsers?.().then((result: any) => {
      setBrowserCandidates(result?.browsers ?? [])
    }).catch(() => {})
    void loadAudio()
    void loadOllama()
    void loadMemoryStatus()
  }, [])

  const handleSaveCabbagePath = async () => {
    setCabbageSaving(true)
    try {
      const result = await window.api?.config?.setCabbagePath?.(cabbagePath.trim())
      setCabbageExists(result?.path ? !!result?.exists : null)
    } catch {}
    setCabbageSaving(false)
  }

  const handleChooseCabbage = async () => {
    try {
      const result = await window.api?.config?.chooseCabbagePath?.()
      if (result && !result.canceled) {
        setCabbagePath(result.path || '')
        setCabbageExists(result.path ? !!result.exists : null)
      }
    } catch {}
  }

  const handleDetectCabbage = async () => {
    try {
      const result = await window.api?.config?.detectCabbage?.()
      setCabbageDetected(result?.detected || '')
    } catch {}
  }

  const handleSaveCsoundQtPath = async () => {
    setCsoundQtSaving(true)
    try {
      const result = await window.api?.config?.setCsoundQtPath?.(csoundQtPath.trim())
      setCsoundQtExists(result?.path ? !!result?.exists : null)
    } catch {}
    setCsoundQtSaving(false)
  }

  const handleChooseCsoundQt = async () => {
    try {
      const result = await window.api?.config?.chooseCsoundQtPath?.()
      if (result && !result.canceled) {
        setCsoundQtPath(result.path || '')
        setCsoundQtExists(result.path ? !!result.exists : null)
      }
    } catch {}
  }

  const handleDetectCsoundQt = async () => {
    try {
      const result = await window.api?.config?.detectCsoundQt?.()
      setCsoundQtDetected(result?.detected || '')
    } catch {}
  }

  const handleSaveBrowserPath = async () => {
    setBrowserSaving(true)
    try {
      const result = await window.api?.config?.setBrowserPath?.(browserPath.trim())
      setBrowserExists(result?.path ? !!result?.exists : null)
    } catch {}
    setBrowserSaving(false)
  }

  const handleChooseBrowser = async () => {
    try {
      const result = await window.api?.config?.chooseBrowserPath?.()
      if (result && !result.canceled) {
        setBrowserPath(result.path || '')
        setBrowserExists(result.path ? !!result.exists : null)
      }
    } catch {}
  }

  const handleDetectBrowser = async () => {
    try {
      const result = await window.api?.config?.detectBrowser?.()
      setBrowserDetected(result?.detected || '')
    } catch {}
  }

  const handleSaveKey = async (provider: string, key: string) => {
    if (!key.trim()) return
    setSaving(provider)
    try {
      const result = await window.api?.config?.setApiKey(provider, key.trim())
      if (result?.success) {
        setAvailable(result.available || [])
        // Reload saved keys display
        const updated = await window.api?.config?.getApiKeys()
        setSavedKeys(updated?.keys || {})
        // Clear the input
        if (provider === 'openrouter') setOpenrouterKey('')
        if (provider === 'google') setGoogleKey('')
        if (provider === 'groq') setGroqKey('')
        if (provider === 'anthropic') setAnthropicKey('')
        if (provider === 'openai') setOpenaiKey('')
      }
    } catch {}
    setSaving('')
  }

  const handleRemoveKey = async (provider: string) => {
    const label =
      provider === 'openrouter' ? 'OpenRouter'
      : provider === 'google' ? 'Google AI (Gemini)'
      : provider === 'groq' ? 'Groq'
      : provider === 'anthropic' ? 'Anthropic'
      : 'OpenAI'
    if (!window.confirm(`Remove the saved ${label} key? You can paste a new one any time.`)) return
    setRemoving(provider)
    try {
      const result = await window.api?.config?.deleteApiKey?.(provider)
      if (result?.success) {
        setAvailable(result.available || [])
        const updated = await window.api?.config?.getApiKeys()
        setSavedKeys(updated?.keys || {})
        // Drop any stale test result for the now-removed key.
        setTestResults((prev) => {
          const nextResults = { ...prev }
          delete nextResults[provider]
          return nextResults
        })
      }
    } catch {}
    setRemoving('')
  }

  const handleTestKey = async (provider: string) => {
    setTesting(provider)
    setTestResults((prev) => {
      const next = { ...prev }
      delete next[provider]
      return next
    })
    try {
      const result = await window.api?.config?.testApiKey(provider)
      if (result) setTestResults((prev) => ({ ...prev, [provider]: result }))
    } catch (err) {
      setTestResults((prev) => ({
        ...prev,
        [provider]: { ok: false, message: err instanceof Error ? err.message : 'Test failed.' },
      }))
    }
    setTesting('')
  }

  const handleCopyWorkshopLinks = async () => {
    try {
      await navigator.clipboard.writeText(formatWorkshopLinksForClipboard())
      setLinksCopied(true)
      window.setTimeout(() => setLinksCopied(false), 2500)
    } catch {
      window.alert('Could not copy to clipboard — check app permissions.')
    }
  }

  const handleOpenWorkshopHandout = async () => {
    try {
      const result: any = await window.api?.workshop?.openHandout?.()
      if (!result?.ok) {
        window.alert(result?.error ?? 'Workshop handout PDF not found.')
      }
    } catch {
      window.alert('Could not open workshop handout.')
    }
  }

  const handleRevealWorkshopHandout = async () => {
    try {
      const result: any = await window.api?.workshop?.revealHandout?.()
      if (!result?.ok) {
        window.alert(result?.error ?? 'Workshop handout PDF not found.')
      }
    } catch {
      window.alert('Could not reveal workshop handout.')
    }
  }

  return (
    <div style={styles.container}>
      <div style={styles.headerRow}>
        <h1 style={styles.title}>Settings</h1>
        <button
          type="button"
          style={styles.doneBtn}
          onClick={() => navigate('/agent')}
          title="Return to Agent (Esc)"
        >
          Done
        </button>
      </div>

      {/* Status banner — distinguishes "saved in DRC" from "from env var" so a
          shell-exported GEMINI_API_KEY doesn't make us claim a key is set when
          the Saved row below is empty. We say "Saved", not "Connected", because
          we haven't actually verified the key with a network call — that's
          what the per-key Test button is for. */}
      {(() => {
        const savedNames = Object.keys(savedKeys)
        const envOnly = available.filter((p) => !savedNames.includes(p))
        const ok = savedNames.length > 0
        const borderColor = ok ? 'var(--success)' : (envOnly.length > 0 ? 'var(--warning)' : 'var(--warning)')
        const label = savedNames.length > 0
          ? `✓ Saved in DRC: ${savedNames.join(', ')}${envOnly.length > 0 ? ` (also detected via env: ${envOnly.join(', ')})` : ''} — click Test next to a key to verify it works`
          : envOnly.length > 0
            ? `Using API key from environment (${envOnly.join(', ')}). Save one below to override or to keep working without the env var.`
            : '⚠ No API key set — add one below to start using the agent'
        return (
          <div style={{ ...styles.statusBanner, borderColor }}>
            <span style={{ fontSize: 14 }}>{label}</span>
          </div>
        )
      })()}

      {/* Setup guide — links for classes, workshops, and presentations */}
      <section style={styles.section}>
        <h2 style={styles.sectionTitle}>{SETUP_GUIDE.sectionTitle}</h2>
        <div style={styles.freeTierCallout}>
          <span style={styles.freeTierCalloutTitle}>{SETUP_GUIDE.linksTitle}</span>
          <p style={styles.freeTierCalloutBody}>
            {SETUP_GUIDE.linksBody}
            {' '}Open the one-slide PDF for projection or printing.
          </p>
          <div style={{ ...styles.keyInput, marginTop: 4, flexWrap: 'wrap' }}>
            <button type="button" onClick={() => void handleCopyWorkshopLinks()} style={styles.saveButton}>
              {linksCopied ? SETUP_GUIDE.copyButtonDone : SETUP_GUIDE.copyButton}
            </button>
            <button type="button" onClick={() => void handleOpenWorkshopHandout()} style={styles.testButton}>
              {SETUP_GUIDE.handoutOpen}
            </button>
            <button type="button" onClick={() => void handleRevealWorkshopHandout()} style={styles.testButton}>
              {SETUP_GUIDE.handoutReveal}
            </button>
          </div>
        </div>
      </section>

      {/* Appearance */}
      <section style={styles.section}>
        <h2 style={styles.sectionTitle}>Appearance</h2>
        <div style={styles.row}>
          <div>
            <span style={styles.label}>Theme</span>
            <span style={styles.hint}>Switch between light and dark mode</span>
          </div>
          <button onClick={toggleTheme} style={styles.toggle}>
            {theme === 'dark' ? '● Dark' : '○ Light'}
          </button>
        </div>
        <div style={styles.row}>
          <div>
            <span style={styles.label}>Audio Feedback</span>
            <span style={styles.hint}>Subtle sounds on UI interactions</span>
          </div>
          <button onClick={() => setAudioFeedback(!audioFeedbackEnabled)} style={styles.toggle}>
            {audioFeedbackEnabled ? 'On' : 'Off'}
          </button>
        </div>
        <div style={styles.row}>
          <div>
            <span style={styles.label}>Welcome Tour</span>
            <span style={styles.hint}>Replay the first-run tour</span>
          </div>
          <button
            onClick={() => window.dispatchEvent(new Event('drc:replay-onboarding'))}
            style={styles.toggle}
          >
            Replay
          </button>
        </div>
      </section>

      {/* Memory / learning from 👍 */}
      <section style={styles.section}>
        <h2 style={styles.sectionTitle}>Memory & learning</h2>
        {memoryReady ? (
          <div style={styles.freeTierCallout}>
            <span style={styles.freeTierCalloutTitle}>Memory is on</span>
            <p style={styles.freeTierCalloutBody}>
              When you 👍 an instrument, Dr.C learns which techniques and opcodes you like and steers
              future generations toward them. Thumbs-down critiques become avoidance rules. Chat history
              and standing instructions persist across sessions.
            </p>
          </div>
        ) : (
          <div style={{ ...styles.freeTierCallout, borderColor: 'var(--warning)' }}>
            <span style={{ ...styles.freeTierCalloutTitle, color: 'var(--warning)' }}>Memory is off</span>
            <p style={styles.freeTierCalloutBody}>
              The local database module failed to load, so 👍/👎 feedback is not saved and Dr.C cannot
              remember your preferences. This usually happens after <code style={styles.codeInline}>npm install</code>{' '}
              without rebuilding for Electron.
            </p>
            {memoryError && (
              <p style={{ ...styles.hint, margin: '8px 0 0', fontFamily: 'var(--font-mono)', fontSize: 10 }}>
                {memoryError.slice(0, 200)}
              </p>
            )}
            <p style={{ ...styles.freeTierCalloutBody, marginTop: 10 }}>
              <strong>Fix:</strong> quit Dr.C, then in Terminal run:
            </p>
            <pre style={styles.memoryCmd}>cd ~/Dr.C-Standalone{'\n'}npx electron-builder install-app-deps</pre>
            <p style={styles.freeTierCalloutBody}>
              Restart Dr.C — the launcher script rebuilds this automatically when needed.
            </p>
          </div>
        )}
      </section>

      {/* Local LLM server */}
      <section style={styles.section}>
        <h2 style={styles.sectionTitle}>Local LLM server</h2>
        <div style={styles.freeTierCallout}>
          <span style={styles.freeTierCalloutTitle}>Best free option — no API key</span>
          <p style={styles.freeTierCalloutBody}>
            Any <strong>OpenAI-compatible</strong> server on your Mac or Linux machine.
            {' '}<strong>Ollama</strong> (recommended):{' '}
            <a href="https://ollama.com/download" target="_blank" rel="noopener noreferrer" style={styles.extLink}>
              ollama.com/download
            </a>
            {' '}→ <code style={styles.codeInline}>ollama pull qwen2.5-coder:7b</code>.
            {' '}<strong>LM Studio</strong> or <strong>llama.cpp server</strong>: start the local server, then set{' '}
            <strong>Server URL</strong> below (e.g. <code style={styles.codeInline}>http://127.0.0.1:1234</code>).
            Turn on <strong>Use local LLM for Agent</strong> → <strong>Refresh</strong> → <strong>Test</strong>.
          </p>
          <p style={{ ...styles.freeTierCalloutBody, marginTop: 8 }}>
            Default URL is Ollama (<code style={styles.codeInline}>http://127.0.0.1:11434</code>).
            More models:{' '}
            <a href="https://ollama.com/library" target="_blank" rel="noopener noreferrer" style={styles.extLink}>
              ollama.com/library
            </a>
            . See <strong>LOCAL-LLM.md</strong> in the Dr.C folder.
          </p>
        </div>
        <div style={styles.keyRow}>
          <div style={styles.keyInfo}>
            <span style={styles.label}>Server URL</span>
            <span style={styles.hint}>
              Ollama: <code style={styles.codeInline}>http://127.0.0.1:11434</code>
              {' '}· LM Studio: <code style={styles.codeInline}>http://127.0.0.1:1234</code>
              {' '}· llama.cpp: your server port (often 8080). Leave blank for Ollama default.
            </span>
          </div>
          <div style={styles.keyInput}>
            <input
              type="text"
              value={ollamaBaseUrl}
              onChange={(e) => setOllamaBaseUrl(e.target.value)}
              placeholder="http://127.0.0.1:11434"
              style={styles.input}
              onKeyDown={(e) => e.key === 'Enter' && void saveOllama({ baseUrl: ollamaBaseUrl })}
            />
            <button
              type="button"
              onClick={() => void saveOllama({ baseUrl: ollamaBaseUrl })}
              style={styles.testButton}
            >
              Apply
            </button>
          </div>
        </div>
        <div style={styles.row}>
          <div>
            <span style={styles.label}>Use local LLM for Agent</span>
            <span style={styles.hint}>
              {ollamaRunning ? '✓ Server reachable' : 'Server not detected — start Ollama, LM Studio, or your local server'}
            </span>
          </div>
          <button
            style={{ ...styles.toggle, ...(ollamaEnabled ? styles.toggleOn : {}) }}
            onClick={() => {
              const next = !ollamaEnabled
              setOllamaEnabled(next)
              void saveOllama({ enabled: next })
            }}
          >
            {ollamaEnabled ? 'On' : 'Off'}
          </button>
        </div>
        <div style={styles.row}>
          <div>
            <span style={styles.label}>Prefer local over cloud keys</span>
            <span style={styles.hint}>When on, Agent uses the local server first even if cloud keys are saved</span>
          </div>
          <button
            style={{ ...styles.toggle, ...(preferOllama ? styles.toggleOn : {}) }}
            onClick={() => {
              const next = !preferOllama
              setPreferOllama(next)
              void saveOllama({ preferOllama: next })
            }}
          >
            {preferOllama ? 'On' : 'Off'}
          </button>
        </div>
        <div style={styles.keyInput}>
          {ollamaModels.length > 0 ? (
            <select
              style={styles.select}
              value={ollamaModel}
              onChange={(e) => {
                setOllamaModel(e.target.value)
                void saveOllama({ model: e.target.value })
              }}
            >
              <option value="">Choose model…</option>
              {ollamaModels.map((m) => (
                <option key={m} value={m}>{m}</option>
              ))}
            </select>
          ) : (
            <input
              type="text"
              style={styles.input}
              value={ollamaModel}
              placeholder="qwen2.5-coder:7b"
              onChange={(e) => setOllamaModel(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && void saveOllama({ model: ollamaModel })}
              onBlur={() => ollamaModel.trim() && void saveOllama({ model: ollamaModel })}
            />
          )}
          <button onClick={() => void loadOllama()} style={styles.testButton}>Refresh</button>
          <button onClick={() => void handleTestOllama()} disabled={ollamaTesting} style={styles.saveButton}>
            {ollamaTesting ? 'Testing…' : 'Test'}
          </button>
        </div>
        {ollamaTestResult && (
          <span style={ollamaTestResult.ok ? styles.testOk : styles.testErr}>{ollamaTestResult.message}</span>
        )}
      </section>

      {/* API Keys */}
      <section style={styles.section}>
        <h2 style={styles.sectionTitle}>Agent model</h2>

        <div style={styles.freeTierCallout}>
          <span style={styles.freeTierCalloutTitle}>How to choose a model</span>
          <p style={styles.freeTierCalloutBody}>
            <strong>Simplest paid:</strong> one <strong>OpenRouter</strong> key (Claude, GPT, Gemini, and more).
            {' '}<strong>Best free:</strong> <strong>Local LLM server</strong> above (Ollama, LM Studio, …).
            {' '}<strong>Free cloud backups:</strong> Groq + Gemini (rate limits).
            {' '}<strong>No key:</strong> Web Apps and Player demo starters.
          </p>
        </div>

        {/* OpenRouter — one key */}
        <h3 style={styles.subsectionTitle}>One key (recommended)</h3>
        <div style={styles.keyRow}>
          <div style={styles.keyInfo}>
            <span style={styles.label}>
              {OPENROUTER_OPTION.label} <span style={styles.paidBadge}>{OPENROUTER_OPTION.tier}</span>
            </span>
            <span style={styles.hint}>
              {OPENROUTER_OPTION.hint} Key from{' '}
              <a href={OPENROUTER_OPTION.signupUrl} target="_blank" rel="noopener noreferrer" style={styles.extLink}>
                {OPENROUTER_OPTION.signupLabel}
              </a>
              .
            </span>
            {savedKeys.openrouter && (
              <div style={styles.savedRow}>
                <span style={styles.savedKey}>Saved: {savedKeys.openrouter}</span>
                <button onClick={() => handleTestKey('openrouter')} disabled={testing === 'openrouter'} style={styles.testButton}>
                  {testing === 'openrouter' ? 'Testing…' : 'Test'}
                </button>
                <button onClick={() => handleRemoveKey('openrouter')} disabled={removing === 'openrouter'} style={styles.removeButton}>
                  {removing === 'openrouter' ? 'Removing…' : 'Remove'}
                </button>
                {testResults.openrouter && (
                  <span style={testResults.openrouter.ok ? styles.testOk : styles.testErr}>
                    {testResults.openrouter.ok ? '✓ ' : '✗ '}{testResults.openrouter.message}
                  </span>
                )}
              </div>
            )}
          </div>
          <div style={styles.keyInput}>
            <input
              type="password"
              value={openrouterKey}
              onChange={(e) => setOpenrouterKey(e.target.value)}
              placeholder={OPENROUTER_OPTION.keyPlaceholder}
              style={styles.input}
              onKeyDown={(e) => e.key === 'Enter' && handleSaveKey('openrouter', openrouterKey)}
            />
            <button
              onClick={() => handleSaveKey('openrouter', openrouterKey)}
              disabled={!openrouterKey.trim() || saving === 'openrouter'}
              style={{ ...styles.saveButton, opacity: !openrouterKey.trim() ? 0.3 : 1 }}
            >
              {saving === 'openrouter' ? '...' : 'Save'}
            </button>
          </div>
        </div>

        <h3 style={styles.subsectionTitle}>Or direct provider keys</h3>

        {(isSoloFreeProvider(available) || isFreeTierOnly(available)) && (
          <div style={styles.freeTierCallout}>
            <span style={styles.freeTierCalloutTitle}>Using a free API tier</span>
            <p style={styles.freeTierCalloutBody}>
              Free Groq and Gemini are fine for trying Dr.C, but both have rate limits (~20–30 requests/minute).
              Dr.C uses <strong>Groq first</strong> and switches to Gemini automatically when one is throttled.
              Wait for the countdown, then <strong>Try again</strong>.
              For the best Agent results in class, use <strong>your own</strong> Anthropic, OpenAI, or OpenRouter key.
              <strong> Web Apps</strong> and <strong>Player demo starters</strong> need no key.
            </p>
            <div style={styles.freeProviderLinks}>
              {PROVIDER_OPTIONS.filter((p) => p.free).map((p) => (
                <a key={p.id} href={p.signupUrl} target="_blank" rel="noopener noreferrer" style={styles.extLink}>
                  Get {p.label} key →
                </a>
              ))}
            </div>
          </div>
        )}

        {combinedUsage.turnCount > 0 && (
          <div style={styles.usageCallout}>
            <span style={styles.freeTierCalloutTitle}>API usage this app session</span>
            <p style={styles.freeTierCalloutBody}>
              {formatTokenCount(combinedUsage.totalTokens)} tokens across {combinedUsage.turnCount}{' '}
              API call{combinedUsage.turnCount === 1 ? '' : 's'} · estimated{' '}
              {formatCostUSD(combinedUsage.totalCostUSD, combinedUsage.totalCostUSD === 0)}
            </p>
            {(agentUsage.turnCount > 0 || playerUsage.turnCount > 0) && (
              <p style={{ ...styles.hint, margin: '6px 0 0' }}>
                {agentUsage.turnCount > 0 && (
                  <>Agent: {formatTokenCount(agentUsage.totalTokens)} tok · {formatCostUSD(agentUsage.totalCostUSD, agentUsage.totalCostUSD === 0)}</>
                )}
                {agentUsage.turnCount > 0 && playerUsage.turnCount > 0 && ' · '}
                {playerUsage.turnCount > 0 && (
                  <>Player adapts: {formatTokenCount(playerUsage.totalTokens)} tok · {formatCostUSD(playerUsage.totalCostUSD, playerUsage.totalCostUSD === 0)}</>
                )}
              </p>
            )}
            <p style={{ ...styles.hint, margin: '8px 0 0' }}>
              Agent totals reset on New chat. Paid providers show estimated cost; free-tier keys show $0.00.
            </p>
          </div>
        )}

        <h3 style={styles.subsectionTitle}>Free cloud backups</h3>

        {/* Groq */}
        <div style={styles.keyRow}>
          <div style={styles.keyInfo}>
            <span style={styles.label}>
              Groq <span style={styles.freeBadge}>Free tier</span>
            </span>
            <span style={styles.hint}>
              Free — Dr.C tries Groq first when both free keys are saved. Key from{' '}
              <a href="https://console.groq.com/keys" target="_blank" rel="noopener noreferrer" style={styles.extLink}>
                console.groq.com/keys
              </a>
              . For best results, use your own Anthropic or OpenAI key below.
            </span>
            {savedKeys.groq && (
              <div style={styles.savedRow}>
                <span style={styles.savedKey}>Saved: {savedKeys.groq}</span>
                <button onClick={() => handleTestKey('groq')} disabled={testing === 'groq'} style={styles.testButton}>
                  {testing === 'groq' ? 'Testing…' : 'Test'}
                </button>
                <button onClick={() => handleRemoveKey('groq')} disabled={removing === 'groq'} style={styles.removeButton}>
                  {removing === 'groq' ? 'Removing…' : 'Remove'}
                </button>
                {testResults.groq && (
                  <span style={testResults.groq.ok ? styles.testOk : styles.testErr}>
                    {testResults.groq.ok ? '✓ ' : '✗ '}{testResults.groq.message}
                  </span>
                )}
              </div>
            )}
          </div>
          <div style={styles.keyInput}>
            <input
              type="password"
              value={groqKey}
              onChange={(e) => setGroqKey(e.target.value)}
              placeholder="gsk_..."
              style={styles.input}
              onKeyDown={(e) => e.key === 'Enter' && handleSaveKey('groq', groqKey)}
            />
            <button
              onClick={() => handleSaveKey('groq', groqKey)}
              disabled={!groqKey.trim() || saving === 'groq'}
              style={{ ...styles.saveButton, opacity: !groqKey.trim() ? 0.3 : 1 }}
            >
              {saving === 'groq' ? '...' : 'Save'}
            </button>
          </div>
        </div>

        {/* Google / Gemini */}
        <div style={styles.keyRow}>
          <div style={styles.keyInfo}>
            <span style={styles.label}>
              Google AI (Gemini) <span style={styles.freeBadge}>Free tier</span>
            </span>
            <span style={styles.hint}>
              Free backup when Groq is throttled. AI Studio key (not Vertex) from{' '}
              <a
                href="https://aistudio.google.com/apikey"
                target="_blank"
                rel="noopener noreferrer"
                style={styles.extLink}
              >
                aistudio.google.com/apikey
              </a>
              . Your own paid API key works much better for sound design.
            </span>
            {savedKeys.google && (
              <div style={styles.savedRow}>
                <span style={styles.savedKey}>Saved: {savedKeys.google}</span>
                <button
                  onClick={() => handleTestKey('google')}
                  disabled={testing === 'google'}
                  style={styles.testButton}
                >
                  {testing === 'google' ? 'Testing…' : 'Test'}
                </button>
                <button
                  onClick={() => handleRemoveKey('google')}
                  disabled={removing === 'google'}
                  style={styles.removeButton}
                >
                  {removing === 'google' ? 'Removing…' : 'Remove'}
                </button>
                {testResults.google && (
                  <span style={testResults.google.ok ? styles.testOk : styles.testErr}>
                    {testResults.google.ok ? '✓ ' : '✗ '}{testResults.google.message}
                  </span>
                )}
              </div>
            )}
          </div>
          <div style={styles.keyInput}>
            <input
              type="password"
              value={googleKey}
              onChange={(e) => setGoogleKey(e.target.value)}
              placeholder="AIza..."
              style={styles.input}
              onKeyDown={(e) => e.key === 'Enter' && handleSaveKey('google', googleKey)}
            />
            <button
              onClick={() => handleSaveKey('google', googleKey)}
              disabled={!googleKey.trim() || saving === 'google'}
              style={{
                ...styles.saveButton,
                opacity: !googleKey.trim() ? 0.3 : 1,
              }}
            >
              {saving === 'google' ? '...' : 'Save'}
            </button>
          </div>
        </div>

        {/* Anthropic */}
        <div style={styles.keyRow}>
          <div style={styles.keyInfo}>
            <span style={styles.label}>Anthropic (Claude)</span>
            <span style={styles.hint}>Optional direct key — or use OpenRouter above for one key to many models</span>
            {savedKeys.anthropic && (
              <div style={styles.savedRow}>
                <span style={styles.savedKey}>Saved: {savedKeys.anthropic}</span>
                <button
                  onClick={() => handleTestKey('anthropic')}
                  disabled={testing === 'anthropic'}
                  style={styles.testButton}
                >
                  {testing === 'anthropic' ? 'Testing…' : 'Test'}
                </button>
                <button
                  onClick={() => handleRemoveKey('anthropic')}
                  disabled={removing === 'anthropic'}
                  style={styles.removeButton}
                >
                  {removing === 'anthropic' ? 'Removing…' : 'Remove'}
                </button>
                {testResults.anthropic && (
                  <span style={testResults.anthropic.ok ? styles.testOk : styles.testErr}>
                    {testResults.anthropic.ok ? '✓ ' : '✗ '}{testResults.anthropic.message}
                  </span>
                )}
              </div>
            )}
          </div>
          <div style={styles.keyInput}>
            <input
              type="password"
              value={anthropicKey}
              onChange={(e) => setAnthropicKey(e.target.value)}
              placeholder="sk-ant-..."
              style={styles.input}
              onKeyDown={(e) => e.key === 'Enter' && handleSaveKey('anthropic', anthropicKey)}
            />
            <button
              onClick={() => handleSaveKey('anthropic', anthropicKey)}
              disabled={!anthropicKey.trim() || saving === 'anthropic'}
              style={{ ...styles.saveButton, opacity: !anthropicKey.trim() ? 0.3 : 1 }}
            >
              {saving === 'anthropic' ? '...' : 'Save'}
            </button>
          </div>
        </div>

        {/* OpenAI */}
        <div style={styles.keyRow}>
          <div style={styles.keyInfo}>
            <span style={styles.label}>OpenAI</span>
            <span style={styles.hint}>Optional direct key — or use OpenRouter above</span>
            {savedKeys.openai && (
              <div style={styles.savedRow}>
                <span style={styles.savedKey}>Saved: {savedKeys.openai}</span>
                <button
                  onClick={() => handleTestKey('openai')}
                  disabled={testing === 'openai'}
                  style={styles.testButton}
                >
                  {testing === 'openai' ? 'Testing…' : 'Test'}
                </button>
                <button
                  onClick={() => handleRemoveKey('openai')}
                  disabled={removing === 'openai'}
                  style={styles.removeButton}
                >
                  {removing === 'openai' ? 'Removing…' : 'Remove'}
                </button>
                {testResults.openai && (
                  <span style={testResults.openai.ok ? styles.testOk : styles.testErr}>
                    {testResults.openai.ok ? '✓ ' : '✗ '}{testResults.openai.message}
                  </span>
                )}
              </div>
            )}
          </div>
          <div style={styles.keyInput}>
            <input
              type="password"
              value={openaiKey}
              onChange={(e) => setOpenaiKey(e.target.value)}
              placeholder="sk-..."
              style={styles.input}
              onKeyDown={(e) => e.key === 'Enter' && handleSaveKey('openai', openaiKey)}
            />
            <button
              onClick={() => handleSaveKey('openai', openaiKey)}
              disabled={!openaiKey.trim() || saving === 'openai'}
              style={{ ...styles.saveButton, opacity: !openaiKey.trim() ? 0.3 : 1 }}
            >
              {saving === 'openai' ? '...' : 'Save'}
            </button>
          </div>
        </div>
      </section>

      {/* Audio & MIDI */}
      <section style={styles.section}>
        <h2 style={styles.sectionTitle}>Audio I/O</h2>
        <p style={styles.sectionIntro}>
          Choose input/output for the Player page (live MIDI and knobs). Agent playback on macOS
          renders a WAV and plays it through <code style={{ fontFamily: 'var(--font-mono)' }}>afplay</code>{' '}
          — that always follows your current macOS output (USB DAC, headphones, speakers, etc.).
        </p>

        <div style={styles.deviceRow}>
          <div style={styles.keyInfo}>
            <span style={styles.label}>Output device</span>
            <span style={styles.hint}>
              Player realtime uses csound <code style={{ fontFamily: 'var(--font-mono)' }}>-o dacN</code>.
              Dr.C never defaults to BlackHole, Zoom, or other virtual outputs — it picks MacBook
              speakers or headphones instead. Choose a device here if you want something else.
              Agent preview uses <code style={{ fontFamily: 'var(--font-mono)' }}>afplay</code> and follows macOS output.
            </span>
            <span style={styles.deviceStatus}>Active: {resolveOutputLabel(audioCfg.output)}</span>
          </div>
          <div style={styles.deviceControls}>
            <select
              style={styles.select}
              value={audioCfg.output}
              onChange={(e) => updateDevice('audioOutputDevice', 'output', e.target.value)}
            >
              <option value="">Auto (physical output — not BlackHole)</option>
              {audioDevices.outputs.map((d) => (
                <option key={d.index} value={String(d.index)}>{d.name} ({d.id})</option>
              ))}
            </select>
          </div>
        </div>

        <div style={styles.deviceRow}>
          <div style={styles.keyInfo}>
            <span style={styles.label}>Input device</span>
            <span style={styles.hint}>
              Player defaults to no mic (output only). Pick a device only for patches that use live
              adc input — laptop built-in mics are mono, so Dr.C injects <code>nchnls_i = 1</code>{' '}
              when input is enabled (stereo out + mono in).
            </span>
            <span style={styles.deviceStatus}>Active: {resolveInputLabel(audioCfg.input)}</span>
          </div>
          <select
            style={styles.select}
            value={audioCfg.input || 'none'}
            onChange={(e) => updateDevice('audioInputDevice', 'input', e.target.value)}
          >
            <option value="none">None (mic off)</option>
            {audioDevices.inputs.map((d) => (
              <option key={d.index} value={String(d.index)}>{d.name}</option>
            ))}
          </select>
        </div>

        <div style={styles.deviceRow}>
          <div style={styles.keyInfo}>
            <span style={styles.label}>MIDI input</span>
            <span style={styles.hint}>
              {audioDevices.midiInputs.length === 0
                ? 'No MIDI devices detected. Connect a controller and Refresh.'
                : 'Hardware MIDI keyboard or controller (optional).'}
            </span>
          </div>
          <select
            style={styles.select}
            value={audioCfg.midiInput}
            onChange={(e) => updateDevice('midiInputDevice', 'midiInput', e.target.value)}
            disabled={audioDevices.midiInputs.length === 0}
          >
            <option value="">Off</option>
            {audioDevices.midiInputs.map((d) => (
              <option key={d.index} value={String(d.index)}>{d.name}</option>
            ))}
          </select>
        </div>

        <div style={{ ...styles.keyInput, marginTop: 12, flexWrap: 'wrap' }}>
          <button type="button" onClick={() => void resetAudioDefaults()} style={styles.saveButton}>
            Reset to system defaults
          </button>
          <button type="button" onClick={() => void loadAudio()} disabled={audioBusy} style={styles.testButton}>
            {audioBusy ? 'Scanning…' : 'Refresh devices'}
          </button>
        </div>

        <h3 style={styles.subsectionTitle}>Diagnostics</h3>

        <div style={styles.deviceRow}>
          <div style={styles.keyInfo}>
            <span style={styles.label}>Show Csound console</span>
            <span style={styles.hint}>
              Hidden by default. Opens automatically when Csound reports an error.
              Turn <strong>On</strong> to keep it visible every session. Use{' '}
              <strong>Copy all</strong> or <strong>Save log</strong> in the panel footer
              to share diagnostics. Toggle here or from the sidebar (
              <code style={{ fontFamily: 'var(--font-mono)' }}>&gt;_</code> above Settings).
            </span>
          </div>
          <button
            type="button"
            onClick={() => setCsoundConsoleEnabled(!csoundConsoleEnabled)}
            style={styles.toggle}
          >
            {csoundConsoleEnabled ? 'On' : 'Off'}
          </button>
        </div>
      </section>

      {/* Cabbage */}
      <section style={styles.section}>
        <h2 style={styles.sectionTitle}>Cabbage</h2>
        <div style={styles.keyRow}>
          <div style={styles.keyInfo}>
            <span style={styles.label}>Cabbage App</span>
            <span style={styles.hint}>
              Where "Open in Cabbage" launches your plugin. We try to find it automatically;
              set it here if that misses.
            </span>
            {/* What we'll actually use, in priority order: explicit choice → auto-detected → nothing. */}
            {cabbagePath ? (
              <span style={cabbageExists === false ? styles.testErr : styles.testOk}>
                {cabbageExists === false ? `✗ Not found: ${cabbagePath}` : `✓ Using: ${cabbagePath}`}
              </span>
            ) : cabbageDetected ? (
              <span style={styles.testOk}>✓ Auto-detected: {cabbageDetected}</span>
            ) : (
              <span style={styles.testErr}>
                No Cabbage found automatically — choose it below, or install Cabbage and re-scan.
              </span>
            )}
          </div>
          <div style={styles.keyInput}>
            <button onClick={handleChooseCabbage} style={styles.saveButton}>
              Choose Cabbage…
            </button>
            {!cabbagePath && (
              <button onClick={handleDetectCabbage} style={styles.testButton}>
                Re-scan
              </button>
            )}
          </div>
        </div>

        {/* Power-user fallback: type/paste an exact path. */}
        <div style={styles.keyInput}>
          <input
            type="text"
            value={cabbagePath}
            onChange={(e) => setCabbagePath(e.target.value)}
            placeholder="/Applications/CabbagePro.app (or leave blank to auto-detect)"
            style={styles.input}
            onKeyDown={(e) => e.key === 'Enter' && handleSaveCabbagePath()}
          />
          <button onClick={handleSaveCabbagePath} disabled={cabbageSaving} style={styles.saveButton}>
            {cabbageSaving ? '...' : 'Save'}
          </button>
        </div>
      </section>

      {/* CsoundQt */}
      <section style={styles.section}>
        <h2 style={styles.sectionTitle}>CsoundQt</h2>
        <div style={styles.keyRow}>
          <div style={styles.keyInfo}>
            <span style={styles.label}>CsoundQt App</span>
            <span style={styles.hint}>
              Where "Open in CsoundQt" launches your CSD for editing, manual lookup, and opcode help.
              Install CsoundQt 7 (beta) after Csound 7 — see install docs.
            </span>
            {csoundQtPath ? (
              <span style={csoundQtExists === false ? styles.testErr : styles.testOk}>
                {csoundQtExists === false ? `✗ Not found: ${csoundQtPath}` : `✓ Using: ${csoundQtPath}`}
              </span>
            ) : csoundQtDetected ? (
              <span style={styles.testOk}>✓ Auto-detected: {csoundQtDetected}</span>
            ) : (
              <span style={styles.testErr}>
                No CsoundQt found — install from GitHub releases (v7.x) and choose it below, or re-scan.
              </span>
            )}
          </div>
          <div style={styles.keyInput}>
            <button onClick={handleChooseCsoundQt} style={styles.saveButton}>
              Choose CsoundQt…
            </button>
            {!csoundQtPath && (
              <button onClick={handleDetectCsoundQt} style={styles.testButton}>
                Re-scan
              </button>
            )}
          </div>
        </div>
        <div style={styles.keyInput}>
          <input
            type="text"
            value={csoundQtPath}
            onChange={(e) => setCsoundQtPath(e.target.value)}
            placeholder="/Applications/CsoundQt.app (or leave blank to auto-detect)"
            style={styles.input}
            onKeyDown={(e) => e.key === 'Enter' && handleSaveCsoundQtPath()}
          />
          <button onClick={handleSaveCsoundQtPath} disabled={csoundQtSaving} style={styles.saveButton}>
            {csoundQtSaving ? '...' : 'Save'}
          </button>
        </div>
      </section>

      {/* Web Browser */}
      <section style={styles.section}>
        <h2 style={styles.sectionTitle}>Web Browser</h2>
        <div style={styles.keyRow}>
          <div style={styles.keyInfo}>
            <span style={styles.label}>Default Browser</span>
            <span style={styles.hint}>
              Where &quot;Open in Browser&quot; launches your web app HTML. The page loads Csound 7 WASM
              from the CDN — you need an internet connection. Press Start Audio in the browser tab.
            </span>
            {browserPath ? (
              <span style={browserExists === false ? styles.testErr : styles.testOk}>
                {browserExists === false ? `✗ Not found: ${browserPath}` : `✓ Using: ${browserPath}`}
              </span>
            ) : browserDetected ? (
              <span style={styles.testOk}>✓ Auto-detected: {browserDetected}</span>
            ) : (
              <span style={styles.testErr}>
                No browser found automatically — choose one below, or re-scan.
              </span>
            )}
          </div>
          <div style={styles.keyInput}>
            <button onClick={handleChooseBrowser} style={styles.saveButton}>
              Choose Browser…
            </button>
            {!browserPath && (
              <button onClick={handleDetectBrowser} style={styles.testButton}>
                Re-scan
              </button>
            )}
          </div>
        </div>

        {browserCandidates.length > 0 && (
          <div style={styles.keyInput}>
            <select
              value={browserPath}
              onChange={(e) => setBrowserPath(e.target.value)}
              style={styles.select}
            >
              <option value="">Auto-detect (recommended)</option>
              {browserCandidates.map((b) => (
                <option key={b.path} value={b.path}>
                  {b.name}
                </option>
              ))}
            </select>
            <button onClick={handleSaveBrowserPath} disabled={browserSaving} style={styles.saveButton}>
              {browserSaving ? '...' : 'Save'}
            </button>
          </div>
        )}

        <div style={styles.keyInput}>
          <input
            type="text"
            value={browserPath}
            onChange={(e) => setBrowserPath(e.target.value)}
            placeholder="/Applications/Google Chrome.app (or leave blank to auto-detect)"
            style={styles.input}
            onKeyDown={(e) => e.key === 'Enter' && handleSaveBrowserPath()}
          />
          <button onClick={handleSaveBrowserPath} disabled={browserSaving} style={styles.saveButton}>
            {browserSaving ? '...' : 'Save'}
          </button>
        </div>
      </section>

    </div>
  )
}

const styles: Record<string, CSSProperties> = {
  container: { height: '100%', overflow: 'auto', padding: '40px 60px', maxWidth: 720 },
  headerRow: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 16,
    marginBottom: 24,
  },
  title: { fontSize: 28, fontWeight: 300, color: 'var(--text-primary)', letterSpacing: '0.04em', margin: 0 },
  doneBtn: {
    flexShrink: 0,
    padding: '8px 16px',
    borderRadius: 10,
    border: 'var(--border-width) solid var(--border)',
    background: 'var(--bg-secondary)',
    color: 'var(--text-primary)',
    fontSize: 13,
    fontWeight: 500,
    cursor: 'pointer',
    fontFamily: 'var(--font-primary)',
  },
  statusBanner: {
    padding: '12px 18px', borderRadius: 12, border: '1.5px solid',
    background: 'var(--bg-secondary)', marginBottom: 32,
  },
  section: { marginBottom: 36 },
  sectionTitle: {
    fontSize: 12, fontWeight: 600, letterSpacing: '0.06em', color: 'var(--text-muted)',
    textTransform: 'uppercase', marginBottom: 16, paddingBottom: 8,
    borderBottom: 'var(--border-width) solid var(--border-subtle)',
  },
  subsectionTitle: {
    fontSize: 11, fontWeight: 600, letterSpacing: '0.05em', color: 'var(--text-muted)',
    textTransform: 'uppercase', margin: '20px 0 12px',
  },
  sectionIntro: {
    margin: '0 0 16px', fontSize: 13, lineHeight: 1.55, color: 'var(--text-secondary)',
  },
  deviceStatus: {
    fontSize: 11, color: 'var(--accent)', fontFamily: 'var(--font-mono)', marginTop: 4,
  },
  row: {
    display: 'flex', justifyContent: 'space-between', alignItems: 'center',
    padding: '12px 0', gap: 24,
  },
  keyRow: {
    padding: '16px 0', borderBottom: '1px solid var(--border-subtle)',
    display: 'flex', flexDirection: 'column', gap: 10,
  },
  keyInfo: { display: 'flex', flexDirection: 'column', gap: 2 },
  keyInput: { display: 'flex', gap: 8, alignItems: 'center' },
  deviceRow: {
    padding: '14px 0', borderBottom: '1px solid var(--border-subtle)',
    display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 24,
  },
  select: {
    padding: '8px 12px', borderRadius: 8, border: 'var(--border-width) solid var(--border)',
    background: 'var(--bg-tertiary)', color: 'var(--text-primary)', fontSize: 13,
    fontFamily: 'var(--font-primary)', cursor: 'pointer', minWidth: 200, maxWidth: 280,
    flexShrink: 0,
  },
  deviceControls: {
    display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'flex-end', flexShrink: 0,
  },
  label: { display: 'block', fontSize: 14, fontWeight: 500, color: 'var(--text-primary)', marginBottom: 2 },
  hint: { display: 'block', fontSize: 12, color: 'var(--text-muted)', lineHeight: 1.4 },
  savedKey: {
    display: 'block', fontSize: 11, color: 'var(--success)', fontFamily: 'var(--font-mono)',
  },
  savedRow: {
    display: 'flex', alignItems: 'center', gap: 10, marginTop: 6, flexWrap: 'wrap',
  },
  testButton: {
    padding: '3px 10px', borderRadius: 6, border: 'var(--border-width) solid var(--border)',
    background: 'transparent', color: 'var(--text-secondary)', fontSize: 11,
    fontFamily: 'var(--font-primary)', cursor: 'pointer',
  },
  removeButton: {
    padding: '3px 10px', borderRadius: 6, border: 'var(--border-width) solid var(--border)',
    background: 'transparent', color: 'var(--warning)', fontSize: 11,
    fontFamily: 'var(--font-primary)', cursor: 'pointer',
  },
  extLink: {
    color: 'var(--accent)', textDecoration: 'underline', cursor: 'pointer',
  },
  codeInline: {
    fontFamily: 'var(--font-mono)', fontSize: 12, color: 'var(--text-primary)',
  },
  memoryCmd: {
    margin: '8px 0 0',
    padding: '10px 12px',
    borderRadius: 8,
    background: 'var(--bg-tertiary)',
    border: '1px solid var(--border)',
    fontFamily: 'var(--font-mono)',
    fontSize: 11,
    lineHeight: 1.5,
    color: 'var(--text-primary)',
    whiteSpace: 'pre-wrap',
  },
  testOk: { fontSize: 11, color: 'var(--success)' },
  testErr: { fontSize: 11, color: 'var(--warning)', lineHeight: 1.4 },
  toggle: {
    padding: '6px 16px', borderRadius: 8, border: 'var(--border-width) solid var(--border)',
    background: 'var(--bg-tertiary)', color: 'var(--text-secondary)', fontSize: 13,
    fontWeight: 500, fontFamily: 'var(--font-primary)', minWidth: 80, cursor: 'pointer',
  },
  toggleOn: {
    background: 'var(--accent-muted)', color: 'var(--accent)', borderColor: 'var(--accent)',
  },
  input: {
    flex: 1, padding: '8px 12px', borderRadius: 8,
    border: 'var(--border-width) solid var(--border)', background: 'var(--bg-tertiary)',
    color: 'var(--text-primary)', fontSize: 13, fontFamily: 'var(--font-mono)', outline: 'none',
  },
  saveButton: {
    padding: '8px 18px', borderRadius: 8, border: 'none',
    background: 'var(--accent)', color: 'var(--bg-primary)', fontSize: 13,
    fontWeight: 500, fontFamily: 'var(--font-primary)', cursor: 'pointer',
    flexShrink: 0,
  },
  freeTierCallout: {
    padding: '14px 18px',
    borderRadius: 12,
    border: '1px solid var(--border)',
    background: 'var(--bg-secondary)',
    marginBottom: 20,
  },
  freeTierCalloutTitle: {
    fontSize: 11,
    fontWeight: 600,
    letterSpacing: '0.06em',
    textTransform: 'uppercase',
    color: 'var(--accent)',
  },
  freeTierCalloutBody: {
    fontSize: 13,
    lineHeight: 1.55,
    color: 'var(--text-secondary)',
    margin: '8px 0 10px',
  },
  freeProviderLinks: {
    display: 'flex',
    flexWrap: 'wrap',
    gap: 14,
  },
  paidBadge: {
    fontSize: 10,
    fontWeight: 600,
    color: 'var(--text-secondary)',
    background: 'var(--bg-tertiary)',
    padding: '2px 7px',
    borderRadius: 6,
    marginLeft: 6,
    verticalAlign: 'middle',
  },
  freeBadge: {
    fontSize: 10,
    fontWeight: 600,
    color: 'var(--accent)',
    background: 'var(--accent-muted)',
    padding: '2px 7px',
    borderRadius: 6,
    marginLeft: 6,
    verticalAlign: 'middle',
  },
  usageCallout: {
    padding: '14px 18px',
    borderRadius: 12,
    border: '1px solid var(--border-subtle)',
    background: 'var(--bg-tertiary)',
    marginBottom: 16,
  },
}
