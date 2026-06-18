import { join } from 'path'
import { delimiter as pathDelimiter } from 'node:path'

// Electron apps often inherit a minimal PATH. Prepend common Csound install
// locations so `csound` resolves on macOS, Linux, and Windows.

function homeDir(): string {
  return process.env.HOME ?? process.env.USERPROFILE ?? ''
}

function darwinPaths(home: string): string[] {
  return [
    join(home, 'bin'),
    join(home, 'Applications/Csound'),
    join(home, '.local/bin'),
    '/opt/homebrew/bin',
    '/usr/local/bin',
    '/Applications/Csound/CsoundLib64.framework/Versions/Current/Resources/bin',
    '/Library/Frameworks/CsoundLib64.framework/Versions/Current/Resources/bin',
  ]
}

function linuxPaths(home: string): string[] {
  return [
    join(home, 'bin'),
    join(home, '.local/bin'),
    join(home, 'Applications/Csound'),
    '/usr/local/bin',
    '/usr/bin',
    '/opt/csound/bin',
    '/snap/bin',
  ]
}

function win32Paths(home: string): string[] {
  const pf = process.env.ProgramFiles ?? 'C:\\Program Files'
  const pfx86 = process.env['ProgramFiles(x86)'] ?? 'C:\\Program Files (x86)'
  const local = process.env.LOCALAPPDATA ?? join(home, 'AppData', 'Local')
  return [
    join(home, 'bin'),
    join(local, 'Csound'),
    join(pf, 'Csound'),
    join(pfx86, 'Csound'),
    join(pf, 'Csound-x64'),
  ]
}

function extraPaths(): string[] {
  const home = homeDir()
  if (process.platform === 'win32') return win32Paths(home)
  if (process.platform === 'linux') return linuxPaths(home)
  return darwinPaths(home)
}

export function withCsoundPath(extra?: NodeJS.ProcessEnv): NodeJS.ProcessEnv {
  const env = { ...process.env, ...(extra ?? {}) }
  const delim = pathDelimiter
  const parts = (env.PATH ?? '').split(delim).filter(Boolean)
  for (const p of extraPaths()) {
    if (p && !parts.includes(p)) parts.unshift(p)
  }
  env.PATH = parts.join(delim)
  return env
}

/** Exported for smoke tests — platform-specific Csound search paths. */
export function csoundSearchPaths(): string[] {
  return extraPaths()
}
