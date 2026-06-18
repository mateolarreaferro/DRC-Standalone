// Best-effort discovery of web browsers for "Open in Browser" on web app artifacts.
import { execFile } from 'child_process'
import { existsSync } from 'fs'
import { join } from 'path'
import { homedir } from 'os'

export interface BrowserCandidate {
  name: string
  path: string
}

let cachedDefault: string | null | undefined

function exec(cmd: string, args: string[]): Promise<string> {
  return new Promise((resolve) => {
    execFile(cmd, args, { timeout: 4000 }, (err, stdout) => {
      resolve(err ? '' : stdout.toString())
    })
  })
}

const MAC_BROWSERS: { name: string; app: string }[] = [
  { name: 'Google Chrome', app: 'Google Chrome.app' },
  { name: 'Brave', app: 'Brave Browser.app' },
  { name: 'Microsoft Edge', app: 'Microsoft Edge.app' },
  { name: 'Firefox', app: 'Firefox.app' },
  { name: 'Arc', app: 'Arc.app' },
  { name: 'Chromium', app: 'Chromium.app' },
  { name: 'Safari', app: 'Safari.app' },
]

const WIN_BROWSERS: { name: string; paths: string[] }[] = [
  {
    name: 'Google Chrome',
    paths: [
      'Google/Chrome/Application/chrome.exe',
      'Google/Chrome Beta/Application/chrome.exe',
    ],
  },
  {
    name: 'Microsoft Edge',
    paths: ['Microsoft/Edge/Application/msedge.exe'],
  },
  {
    name: 'Firefox',
    paths: ['Mozilla Firefox/firefox.exe'],
  },
  {
    name: 'Brave',
    paths: ['BraveSoftware/Brave-Browser/Application/brave.exe'],
  },
]

function winRoots(): string[] {
  return [
    process.env['ProgramFiles'],
    process.env['ProgramFiles(x86)'],
    process.env['LOCALAPPDATA'],
  ].filter(Boolean) as string[]
}

function detectMacCandidates(): BrowserCandidate[] {
  const out: BrowserCandidate[] = []
  for (const dir of ['/Applications', join(homedir(), 'Applications')]) {
    for (const b of MAC_BROWSERS) {
      const path = join(dir, b.app)
      if (existsSync(path)) out.push({ name: b.name, path })
    }
  }
  const seen = new Set<string>()
  return out.filter((c) => {
    if (seen.has(c.path)) return false
    seen.add(c.path)
    return true
  })
}

function detectWinCandidates(): BrowserCandidate[] {
  const out: BrowserCandidate[] = []
  for (const root of winRoots()) {
    for (const b of WIN_BROWSERS) {
      for (const rel of b.paths) {
        const path = join(root, rel)
        if (existsSync(path)) out.push({ name: b.name, path })
      }
    }
  }
  const seen = new Set<string>()
  return out.filter((c) => {
    if (seen.has(c.path)) return false
    seen.add(c.path)
    return true
  })
}

async function detectLinuxCandidates(): Promise<BrowserCandidate[]> {
  const bins = [
    ['Google Chrome', 'google-chrome'],
    ['Google Chrome', 'google-chrome-stable'],
    ['Chromium', 'chromium'],
    ['Chromium', 'chromium-browser'],
    ['Firefox', 'firefox'],
    ['Brave', 'brave-browser'],
    ['Microsoft Edge', 'microsoft-edge'],
  ]
  const out: BrowserCandidate[] = []
  for (const [name, bin] of bins) {
    const found = (await exec('which', [bin])).trim()
    if (found && existsSync(found)) out.push({ name, path: found })
  }
  return out
}

export async function listBrowserCandidates(): Promise<BrowserCandidate[]> {
  if (process.platform === 'darwin') return detectMacCandidates()
  if (process.platform === 'win32') return detectWinCandidates()
  return detectLinuxCandidates()
}

export async function detectBrowserPath(force = false): Promise<string | null> {
  if (!force && cachedDefault !== undefined) return cachedDefault
  const list = await listBrowserCandidates()
  cachedDefault = list[0]?.path ?? null
  return cachedDefault
}
