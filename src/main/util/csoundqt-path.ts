// Best-effort discovery of CsoundQt (Csound 7 IDE) for "Open in CsoundQt".
import { execFile } from 'child_process'
import { existsSync, readdirSync } from 'fs'
import { join, basename } from 'path'
import { homedir } from 'os'

let cached: string | null | undefined

function exec(cmd: string, args: string[]): Promise<string> {
  return new Promise((resolve) => {
    execFile(cmd, args, { timeout: 4000 }, (err, stdout) => {
      resolve(err ? '' : stdout.toString())
    })
  })
}

function globNames(dir: string, prefix: string, suffix: string): string[] {
  try {
    return readdirSync(dir)
      .filter((n) => {
        const lower = n.toLowerCase()
        return lower.startsWith(prefix) && lower.endsWith(suffix)
      })
      .map((n) => join(dir, n))
  } catch {
    return []
  }
}

async function detectMac(): Promise<string | null> {
  for (const dir of ['/Applications', join(homedir(), 'Applications')]) {
    const apps = globNames(dir, 'csoundqt', '.app')
    if (apps.length) return apps.sort().reverse()[0]
  }
  const out = await exec('mdfind', ['kMDItemCFBundleIdentifier == "org.csound.csoundqt"'])
  const byId = out
    .split('\n')
    .map((s) => s.trim())
    .find((p) => p.endsWith('.app') && existsSync(p))
  if (byId) return byId
  const byName = await exec('mdfind', ['-name', 'CsoundQt'])
  return (
    byName
      .split('\n')
      .map((s) => s.trim())
      .filter((p) => p.toLowerCase().endsWith('.app'))
      .filter((p) => basename(p).toLowerCase().startsWith('csoundqt'))
      .find((p) => existsSync(p)) ?? null
  )
}

async function detectWin(): Promise<string | null> {
  const roots = [
    process.env['ProgramFiles'],
    process.env['ProgramFiles(x86)'],
    process.env['LOCALAPPDATA'],
  ].filter(Boolean) as string[]
  for (const root of roots) {
    for (const sub of ['CsoundQt', 'csoundqt']) {
      const exe = join(root, sub, 'CsoundQt.exe')
      if (existsSync(exe)) return exe
      const exe2 = join(root, sub, 'bin', 'CsoundQt.exe')
      if (existsSync(exe2)) return exe2
    }
    try {
      for (const name of readdirSync(root)) {
        if (!name.toLowerCase().includes('csoundqt')) continue
        const exes = globNames(join(root, name), 'csoundqt', '.exe')
        if (exes.length) return exes[0]
      }
    } catch {
      /* skip */
    }
  }
  return null
}

async function detectLinux(): Promise<string | null> {
  for (const name of ['csoundqt', 'CsoundQt', 'qcsound']) {
    const found = (await exec('which', [name])).trim()
    if (found && existsSync(found)) return found
  }
  for (const p of [
    '/usr/bin/csoundqt',
    '/usr/local/bin/csoundqt',
    '/usr/bin/CsoundQt',
    '/snap/bin/csoundqt',
  ]) {
    if (existsSync(p)) return p
  }
  return null
}

export async function detectCsoundQtPath(force = false): Promise<string | null> {
  if (!force && cached !== undefined) return cached
  let result: string | null = null
  try {
    if (process.platform === 'darwin') result = await detectMac()
    else if (process.platform === 'win32') result = await detectWin()
    else result = await detectLinux()
  } catch {
    result = null
  }
  cached = result
  return result
}
