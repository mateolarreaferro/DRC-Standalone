import { execFile } from 'child_process'
import { promisify } from 'util'
import { withCsoundPath } from './csound-path'

const execFileAsync = promisify(execFile)

export interface CsoundEnvironment {
  versionLine: string
  binaryPath: string
  major: 6 | 7 | 0
  ready: boolean
}

let cached: CsoundEnvironment = {
  versionLine: 'unknown',
  binaryPath: '',
  major: 0,
  ready: false,
}

export function getCsoundEnvironment(): CsoundEnvironment {
  return cached
}

export function getCsoundEnvironmentBlock(): string {
  if (!cached.ready) {
    return '- Csound: not yet detected (will resolve on first compile)'
  }
  const target = cached.major === 7 ? 'Csound 7' : cached.major === 6 ? 'Csound 6 (upgrade to 7 recommended)' : 'Csound'
  return [
    `- Csound CLI: ${cached.versionLine}`,
    `- Binary: ${cached.binaryPath || 'not found'}`,
    `- Target runtime: ${target} — emit syntax that compiles on this binary`,
  ].join('\n')
}

export async function refreshCsoundEnvironment(): Promise<CsoundEnvironment> {
  const env = withCsoundPath()
  try {
    const { stdout: versionOut } = await execFileAsync('csound', ['--version'], { env })
    const versionLine =
      versionOut.split('\n').find((l) => /--Csound version/i.test(l))?.trim() ??
      versionOut.split('\n')[0]?.trim() ??
      'unknown'
    let binaryPath = ''
    try {
      const { stdout: whichOut } = await execFileAsync('which', ['csound'], { env })
      binaryPath = whichOut.trim()
    } catch {}
    const major: 6 | 7 | 0 = /version\s+7/i.test(versionLine) ? 7 : /version\s+6/i.test(versionLine) ? 6 : 0
    cached = { versionLine, binaryPath, major, ready: true }
  } catch {
    cached = {
      versionLine: 'NOT FOUND',
      binaryPath: '',
      major: 0,
      ready: true,
    }
  }
  return cached
}
