import { IpcMain, dialog, BrowserWindow } from 'electron'
import { existsSync } from 'fs'
import { Provider } from '../provider/provider'
import { isProPlus } from '../util/tier'
import { ensureOllamaRunning } from '../util/ollama-launch'
import { loadConfig, saveConfig, setConfigValue, getConfigValue, type DrcConfig } from '../util/config'
import { detectCabbagePath } from '../util/cabbage-path'
import { detectCsoundQtPath } from '../util/csoundqt-path'
import { detectBrowserPath, listBrowserCandidates } from '../util/browser-path'
import { listAudioDevices, resolveStoredOutputIndex } from '../util/audio-devices'
import {
  AUDIO_INPUT_OFF,
  AUDIO_OUTPUT_KEY,
  AUDIO_INPUT_KEY,
  MIDI_INPUT_KEY,
  AUDIO_KEYS,
} from '../ipc/config-keys'

// The only keys that hold provider API secrets — masked and surfaced by
// config:getApiKeys. Everything else in config.json (e.g. cabbagePath) is a
// plain setting and must NOT leak into the API-keys view.
const PROVIDER_KEYS = ['openrouter', 'google', 'groq', 'anthropic', 'openai'] as const

/** When Groq is saved, clear preferOllama so free cloud keys are not skipped. */
function migrateProviderKeys(config: DrcConfig): DrcConfig {
  const next = { ...config }
  if (next.groq && next.preferOllama === '1') {
    const migrated = { ...next }
    delete migrated.preferOllama
    return saveConfig(migrated)
  }
  return config
}

function applyProviderConfig(config: Record<string, string | undefined>): void {
  Provider.configure({
    openrouterKey: config.openrouter,
    googleKey: config.google,
    groqKey: config.groq,
    anthropicKey: config.anthropic,
    openaiKey: config.openai,
    ollamaEnabled: config.ollamaEnabled === '1',
    ollamaModel: config.ollamaModel,
    ollamaBaseUrl: config.ollamaBaseUrl,
    preferOllama: config.preferOllama === '1',
  })
}

/** After a successful probe, persist the auto-picked model so restarts keep it. */
function persistProbedOllamaModel(): void {
  const status = Provider.ollamaStatus()
  const cfg = loadConfig()
  if (status.model?.trim() && !cfg.ollamaModel?.trim()) {
    applyProviderConfig(setConfigValue('ollamaModel', status.model.trim()))
  }
}

export function handleConfigIPC(ipcMain: IpcMain): void {
  try {
    const saved = migrateProviderKeys(loadConfig())
    if (Object.keys(saved).length > 0) {
      applyProviderConfig(saved)
    }
    void Provider.refreshOllamaStatus(saved.ollamaEnabled === '1')
    void ensureOllamaRunning()
  } catch {}

  ipcMain.handle('config:setApiKey', async (_event, provider: string, key: string) => {
    const config = setConfigValue(provider, key)

    applyProviderConfig(config)

    return { success: true, available: Provider.availableProviders() }
  })

  // Remove a saved provider key entirely.
  // key was stuck with it — the only recovery was hand-editing config.json. We
  // validate the provider name so a stray call can't wipe an unrelated setting
  // (e.g. cabbagePath), then reconfigure so the change takes effect immediately.
  ipcMain.handle('config:deleteApiKey', async (_event, provider: string) => {
    if (!PROVIDER_KEYS.includes(provider as (typeof PROVIDER_KEYS)[number])) {
      return { success: false, available: Provider.availableProviders() }
    }
    const config = setConfigValue(provider, '')
    applyProviderConfig(config)
    return { success: true, available: Provider.availableProviders() }
  })

  ipcMain.handle('config:testApiKey', async (_event, provider: string) => {
    if (!PROVIDER_KEYS.includes(provider as (typeof PROVIDER_KEYS)[number])) {
      return { ok: false, message: `Unknown provider: ${provider}` }
    }
    if (!Provider.availableProviders().includes(provider)) {
      return { ok: false, message: 'No key saved for this provider yet.' }
    }
    return Provider.testApiKey(provider)
  })

  ipcMain.handle('config:getApiKeys', async () => {
    const config = loadConfig()
    await Provider.refreshOllamaStatus(config.ollamaEnabled === '1')
    persistProbedOllamaModel()
    // Return masked keys — provider secrets only, never other settings.
    const masked: Record<string, string> = {}
    for (const k of PROVIDER_KEYS) {
      const v = config[k]
      if (v && v.length > 8) {
        masked[k] = v.slice(0, 4) + '...' + v.slice(-4)
      } else if (v) {
        masked[k] = '***'
      }
    }
    return { keys: masked, available: Provider.availableProviders(), proPlus: isProPlus() }
  })

  ipcMain.handle('config:getOllama', async () => {
    const probe = await Provider.refreshOllamaStatus(true)
    persistProbedOllamaModel()
    const cfg = loadConfig()
    return {
      enabled: cfg.ollamaEnabled === '1',
      preferOllama: cfg.preferOllama === '1',
      model: cfg.ollamaModel ?? Provider.ollamaStatus().model ?? '',
      baseUrl: cfg.ollamaBaseUrl ?? '',
      running: probe.ok,
      models: probe.models,
    }
  })

  ipcMain.handle('config:setOllama', async (_event, patch: {
    enabled?: boolean
    preferOllama?: boolean
    model?: string
    baseUrl?: string
  }) => {
    if (patch.enabled !== undefined) setConfigValue('ollamaEnabled', patch.enabled ? '1' : '')
    if (patch.preferOllama !== undefined) setConfigValue('preferOllama', patch.preferOllama ? '1' : '')
    if (patch.model !== undefined) setConfigValue('ollamaModel', patch.model.trim())
    if (patch.baseUrl !== undefined) setConfigValue('ollamaBaseUrl', patch.baseUrl.trim())
    applyProviderConfig(loadConfig())
    await Provider.refreshOllamaStatus(true)
    persistProbedOllamaModel()
    const cfg = loadConfig()
    return {
      success: true,
      available: Provider.availableProviders(),
      ...Provider.ollamaStatus(),
      model: cfg.ollamaModel ?? Provider.ollamaStatus().model ?? '',
    }
  })

  ipcMain.handle('config:testOllama', async () => {
    const result = await Provider.testOllama()
    if (result.ok) persistProbedOllamaModel()
    return result
  })

  // Cabbage install path — lets users point us at their exact app/binary when
  // auto-detection misses it. `exists` is echoed back so the UI can warn about a
  // typo'd path; `detected` is the auto-found install we'd use when no explicit
  // path is set, so the UI can show what will happen without configuration.
  ipcMain.handle('config:getCabbagePath', async () => {
    const path = getConfigValue('cabbagePath') ?? ''
    const detected = path ? '' : ((await detectCabbagePath()) ?? '')
    return { path, exists: path ? existsSync(path) : false, detected }
  })

  ipcMain.handle('config:setCabbagePath', async (_event, path: string) => {
    const trimmed = (path ?? '').trim()
    setConfigValue('cabbagePath', trimmed)
    return { success: true, path: trimmed, exists: trimmed ? existsSync(trimmed) : false }
  })

  // Force a fresh scan (e.g. after the user installs Cabbage without restarting).
  ipcMain.handle('config:detectCabbage', async () => {
    return { detected: (await detectCabbagePath(true)) ?? '' }
  })

  // --- Audio / MIDI setup ----------------------------------------------------

  // Enumerate the devices csound can see, so the Settings panel can offer a real
  // dropdown. Best-effort: returns empty lists if csound isn't on PATH.
  ipcMain.handle('config:listAudioDevices', async () => {
    try {
      return await listAudioDevices()
    } catch (err: any) {
      return { outputs: [], inputs: [], midiInputs: [], error: String(err?.message ?? err) }
    }
  })

  // Current selection ('' = system default output; input 'none' = mic off).
  ipcMain.handle('config:getAudioConfig', async () => {
    const rawInput = getConfigValue(AUDIO_INPUT_KEY) ?? ''
    return {
      output: getConfigValue(AUDIO_OUTPUT_KEY) ?? '',
      input: rawInput === '' ? AUDIO_INPUT_OFF : rawInput,
      midiInput: getConfigValue(MIDI_INPUT_KEY) ?? '',
    }
  })

  ipcMain.handle('config:resetAudioDevices', async () => {
    setConfigValue(AUDIO_OUTPUT_KEY, '')
    setConfigValue(AUDIO_INPUT_KEY, AUDIO_INPUT_OFF)
    setConfigValue(MIDI_INPUT_KEY, '')
    return { success: true, output: '', input: AUDIO_INPUT_OFF, midiInput: '' }
  })

  // Persist one device field. Output: '' = system default; input 'none' = off.
  ipcMain.handle('config:setAudioDevice', async (_event, field: string, value: string) => {
    if (!AUDIO_KEYS.includes(field as (typeof AUDIO_KEYS)[number])) {
      return { success: false, error: `Unknown audio field: ${field}` }
    }
    const v = (value ?? '').trim()
    if (field === AUDIO_INPUT_KEY && v === AUDIO_INPUT_OFF) {
      setConfigValue(field, AUDIO_INPUT_OFF)
      return { success: true }
    }
    if (v && !/^\d+$/.test(v)) return { success: false, error: 'Invalid device index' }
    setConfigValue(field, v)
    return { success: true }
  })

  // Drop saved indices that no longer appear in csound --devices (e.g. unplugged USB).
  ipcMain.handle('config:sanitizeAudioDevices', async () => {
    const devs = await listAudioDevices().catch(() => ({ outputs: [], inputs: [], midiInputs: [] }))
    const out = getConfigValue(AUDIO_OUTPUT_KEY) ?? ''
    const inp = getConfigValue(AUDIO_INPUT_KEY) ?? ''
    const midi = getConfigValue(MIDI_INPUT_KEY) ?? ''
    let changed = false
    const resolvedOut = resolveStoredOutputIndex(out, devs.outputs)
    if (resolvedOut !== out) {
      setConfigValue(AUDIO_OUTPUT_KEY, resolvedOut)
      changed = true
    }
    if (inp === '') {
      setConfigValue(AUDIO_INPUT_KEY, AUDIO_INPUT_OFF)
      changed = true
    } else if (/^\d+$/.test(inp) && !devs.inputs.some((d) => String(d.index) === inp)) {
      setConfigValue(AUDIO_INPUT_KEY, AUDIO_INPUT_OFF)
      changed = true
    }
    if (/^\d+$/.test(midi) && !devs.midiInputs.some((d) => String(d.index) === midi)) {
      setConfigValue(MIDI_INPUT_KEY, '')
      changed = true
    }
    return {
      changed,
      output: getConfigValue(AUDIO_OUTPUT_KEY) ?? '',
      input: getConfigValue(AUDIO_INPUT_KEY) ?? '',
      midiInput: getConfigValue(MIDI_INPUT_KEY) ?? '',
    }
  })

  // Native picker — far lower friction than typing a path. On macOS the user
  // selects the .app bundle; elsewhere the Cabbage executable. We persist the
  // choice immediately so the next "Open in Cabbage" uses it.
  ipcMain.handle('config:chooseCabbagePath', async () => {
    const win = BrowserWindow.getFocusedWindow()
    const options: Electron.OpenDialogOptions = {
      title: 'Choose Cabbage',
      properties: ['openFile'],
      filters: process.platform === 'win32' ? [{ name: 'Executable', extensions: ['exe'] }] : undefined,
    }
    const result = win ? await dialog.showOpenDialog(win, options) : await dialog.showOpenDialog(options)
    if (result.canceled || !result.filePaths[0]) return { canceled: true }
    const chosen = result.filePaths[0]
    setConfigValue('cabbagePath', chosen)
    return { canceled: false, path: chosen, exists: existsSync(chosen) }
  })

  // CsoundQt install path — same pattern as Cabbage.
  ipcMain.handle('config:getCsoundQtPath', async () => {
    const path = getConfigValue('csoundQtPath') ?? ''
    const detected = path ? '' : ((await detectCsoundQtPath()) ?? '')
    return { path, exists: path ? existsSync(path) : false, detected }
  })

  ipcMain.handle('config:setCsoundQtPath', async (_event, path: string) => {
    const trimmed = (path ?? '').trim()
    setConfigValue('csoundQtPath', trimmed)
    return { success: true, path: trimmed, exists: trimmed ? existsSync(trimmed) : false }
  })

  ipcMain.handle('config:detectCsoundQt', async () => {
    return { detected: (await detectCsoundQtPath(true)) ?? '' }
  })

  ipcMain.handle('config:chooseCsoundQtPath', async () => {
    const win = BrowserWindow.getFocusedWindow()
    const options: Electron.OpenDialogOptions = {
      title: 'Choose CsoundQt',
      properties: process.platform === 'darwin' ? ['openFile', 'openDirectory'] : ['openFile'],
      filters: process.platform === 'win32' ? [{ name: 'Executable', extensions: ['exe'] }] : undefined,
    }
    const result = win ? await dialog.showOpenDialog(win, options) : await dialog.showOpenDialog(options)
    if (result.canceled || !result.filePaths[0]) return { canceled: true }
    const chosen = result.filePaths[0]
    setConfigValue('csoundQtPath', chosen)
    return { canceled: false, path: chosen, exists: existsSync(chosen) }
  })

  ipcMain.handle('config:getBrowserPath', async () => {
    const path = getConfigValue('browserPath') ?? ''
    const detected = path ? '' : ((await detectBrowserPath()) ?? '')
    return { path, exists: path ? existsSync(path) : false, detected }
  })

  ipcMain.handle('config:setBrowserPath', async (_event, path: string) => {
    const trimmed = (path ?? '').trim()
    setConfigValue('browserPath', trimmed)
    return { success: true, path: trimmed, exists: trimmed ? existsSync(trimmed) : false }
  })

  ipcMain.handle('config:detectBrowser', async () => {
    return { detected: (await detectBrowserPath(true)) ?? '' }
  })

  ipcMain.handle('config:listBrowsers', async () => {
    return { browsers: await listBrowserCandidates() }
  })

  ipcMain.handle('config:chooseBrowserPath', async () => {
    const win = BrowserWindow.getFocusedWindow()
    const options: Electron.OpenDialogOptions = {
      title: 'Choose your default browser',
      properties: process.platform === 'darwin' ? ['openFile', 'openDirectory'] : ['openFile'],
      filters: process.platform === 'win32' ? [{ name: 'Executable', extensions: ['exe'] }] : undefined,
    }
    const result = win ? await dialog.showOpenDialog(win, options) : await dialog.showOpenDialog(options)
    if (result.canceled || !result.filePaths[0]) return { canceled: true }
    const chosen = result.filePaths[0]
    setConfigValue('browserPath', chosen)
    return { canceled: false, path: chosen, exists: existsSync(chosen) }
  })
}
