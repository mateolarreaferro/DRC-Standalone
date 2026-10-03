import { spawn, execFile } from 'child_process'
import { existsSync } from 'fs'
import { shell } from 'electron'

const MAC_CSOUNDQT_NAMES = ['CsoundQt']
const MAC_CABBAGE_NAMES = ['Cabbage', 'CabbageLite', 'Cabbage Studio', 'CabbagePro']

function openWithApp(appNameOrPath: string, filePath: string): Promise<boolean> {
  return new Promise((resolve) => {
    execFile('open', ['-a', appNameOrPath, filePath], (err) => resolve(!err))
  })
}

function spawnBinary(bin: string, filePath: string): { ok: boolean; method: string; error?: string } {
  try {
    const child = spawn(bin, [filePath], { detached: true, stdio: 'ignore' })
    child.unref()
    return { ok: true, method: `spawn "${bin}"` }
  } catch (err: any) {
    return { ok: false, method: `spawn "${bin}"`, error: err?.message ?? 'spawn failed' }
  }
}

/** Launch an external app on a file; macOS tries `open -a`, then spawn / xdg-open. */
export async function launchExternalOnFile(
  filePath: string,
  preferred: string,
  macFallbackNames: string[],
  settingsHint: string,
): Promise<{ ok: boolean; method: string; error?: string }> {
  const platform = process.platform

  if (platform === 'darwin') {
    const candidates = [preferred, ...macFallbackNames]
      .filter(Boolean)
      .filter((c) => !c.startsWith('/') || existsSync(c))
    for (const cand of candidates) {
      if (await openWithApp(cand, filePath)) return { ok: true, method: `open -a "${cand}"` }
    }
    const err = await shell.openPath(filePath)
    if (!err) return { ok: true, method: 'default file handler' }
    return { ok: false, method: 'open', error: settingsHint }
  }

  if (platform === 'win32') {
    if (preferred && existsSync(preferred)) return spawnBinary(preferred, filePath)
    const err = await shell.openPath(filePath)
    if (!err) return { ok: true, method: 'default file handler' }
    return { ok: false, method: 'openPath', error: settingsHint }
  }

  if (preferred && existsSync(preferred)) return spawnBinary(preferred, filePath)
  try {
    const child = spawn('xdg-open', [filePath], { detached: true, stdio: 'ignore' })
    child.unref()
    return { ok: true, method: 'xdg-open' }
  } catch (err: any) {
    return { ok: false, method: 'xdg-open', error: err?.message ?? settingsHint }
  }
}

export const LAUNCH_HINTS = {
  cabbage: 'No Cabbage app found. Set its path in Settings → Cabbage.',
  csoundqt: 'No CsoundQt found. Install CsoundQt 7 (see docs) and set its path in Settings → CsoundQt.',
  browser: 'No browser found. Choose your default browser in Settings → Web Browser.',
}

export const MAC_FALLBACK = {
  cabbage: MAC_CABBAGE_NAMES,
  csoundqt: MAC_CSOUNDQT_NAMES,
  browser: ['Google Chrome', 'Safari', 'Firefox', 'Microsoft Edge', 'Brave Browser'],
}
