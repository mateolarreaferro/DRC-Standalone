import { app, BrowserWindow, shell, session } from 'electron'
import { join, resolve } from 'path'
import { existsSync, readFileSync } from 'fs'
import { electronApp, optimizer, is } from '@electron-toolkit/utils'
import { registerAllIPC } from './ipc/register'
import { MemoryDB } from './memory/db'
import { seedBuiltinLessons } from './memory/seed-builtin'
import { refreshCsoundEnvironment } from './util/csound-version'
import { ensureOllamaRunning } from './util/ollama-launch'

// Prevent GPU crashes in Electron
app.disableHardwareAcceleration()
app.commandLine.appendSwitch('disable-gpu-sandbox')

// In dev, load API keys from the repo's .env so the app works out of the box.
// In packaged builds, keys come from config.json (written by Settings page) or system env.
function loadDotenv(): void {
  if (!is.dev) return
  // app.getAppPath() in dev points to drc-app; .env lives at the repo root one level up.
  const candidates = [
    resolve(app.getAppPath(), '..', '.env'),
    resolve(app.getAppPath(), '.env'),
    resolve(process.cwd(), '.env'),
  ]
  for (const path of candidates) {
    if (!existsSync(path)) continue
    try {
      for (const line of readFileSync(path, 'utf-8').split('\n')) {
        const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/)
        if (!m) continue
        const [, key, raw] = m
        if (process.env[key]) continue
        process.env[key] = raw.replace(/^['"]|['"]$/g, '')
      }
      return
    } catch {}
  }
}

let mainWindow: BrowserWindow | null = null

function createWindow(): void {
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 900,
    minHeight: 600,
    show: false,
    titleBarStyle: 'hiddenInset',
    trafficLightPosition: { x: 16, y: 18 },
    backgroundColor: '#111110',
    webPreferences: {
      preload: join(__dirname, '../preload/index.js'),
      sandbox: false,
      contextIsolation: true,
      nodeIntegration: false,
    },
  })

  mainWindow.on('ready-to-show', () => {
    mainWindow?.show()
  })

  mainWindow.webContents.setWindowOpenHandler((details) => {
    shell.openExternal(details.url)
    return { action: 'deny' }
  })

  if (is.dev && process.env['ELECTRON_RENDERER_URL']) {
    mainWindow.loadURL(process.env['ELECTRON_RENDERER_URL'])
  } else {
    mainWindow.loadFile(join(__dirname, '../renderer/index.html'))
  }
}

app.whenReady().then(() => {
  loadDotenv()
  electronApp.setAppUserModelId('com.drc.app')

  // Web MIDI in the renderer needs explicit permission grants — Chromium
  // gates `navigator.requestMIDIAccess()` behind both 'midi' and 'midiSysex'
  // checks. We auto-grant since this is a desktop app the user installed.
  const allowMidi = (perm: string) => perm === 'midi' || perm === 'midiSysex'
  session.defaultSession.setPermissionRequestHandler((_wc, perm, cb) => {
    cb(allowMidi(perm))
  })
  session.defaultSession.setPermissionCheckHandler((_wc, perm) => allowMidi(perm))

  app.on('browser-window-created', (_, window) => {
    optimizer.watchWindowShortcuts(window)
  })

  MemoryDB.init() // open the persistent memory DB before any memory:* handler can fire
  seedBuiltinLessons()
  void refreshCsoundEnvironment()
  void ensureOllamaRunning()
  registerAllIPC()
  createWindow()

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow()
  })
})

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit()
  }
})

export { mainWindow }
