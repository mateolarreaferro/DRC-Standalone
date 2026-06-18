#!/usr/bin/env node
/**
 * Cross-platform launcher + PATH contract checks.
 * LAC 2026 workshop gate — macOS and Linux launchers + PATH contract.
 *
 *   node scripts/test-platform-launchers.mjs
 */

import { existsSync, readFileSync, statSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { spawnSync } from 'node:child_process'

const REPO = dirname(dirname(fileURLToPath(import.meta.url)))
const platform = process.platform // darwin | linux | win32

let passed = 0
let failed = 0

function ok(msg) { console.log('  PASS', msg); passed++ }
function bad(msg, detail = '') { console.log('  FAIL', msg, detail); failed++ }
function skip(msg) { console.log('  SKIP', msg) }

const REQUIRED_UNIX = [
  'scripts/workshop-path.sh',
  'scripts/launch-drc.sh',
  'scripts/launch-workshop-attendee.sh',
  'launch-drc-standalone.sh',
  'launchers/Dr.C-Standalone.command',
  'launchers/Dr.C-Workshop-Attendee.command',
  'launchers/Dr.C-Standalone.sh',
  'launchers/Dr.C-Workshop-Attendee.sh',
]

const REQUIRED_WIN = [
  'scripts/workshop-path.ps1',
  'scripts/launch-drc.ps1',
  'scripts/launch-workshop-attendee.ps1',
  'scripts/launch-drc.bat',
  'scripts/launch-workshop-attendee.bat',
  'launch-drc-standalone.bat',
  'launchers/Dr.C-Standalone.bat',
  'launchers/Dr.C-Workshop-Attendee.bat',
]

const REQUIRED_ALL = [
  'PARTICIPANTS.md',
  'launchers/README.md',
  ...REQUIRED_UNIX,
  ...REQUIRED_WIN,
]

console.log(`\n[platform-launchers] OS=${platform} arch=${process.arch}\n`)

for (const rel of REQUIRED_ALL) {
  const p = join(REPO, rel)
  if (existsSync(p)) ok(`exists: ${rel}`)
  else bad(`missing: ${rel}`)
}

// csound-path.ts cross-platform
const csoundPathSrc = readFileSync(join(REPO, 'src/main/util/csound-path.ts'), 'utf-8')
if (csoundPathSrc.includes('win32') && csoundPathSrc.includes('linux') && csoundPathSrc.includes('pathDelimiter')) {
  ok('csound-path.ts handles macOS + Linux + Windows')
} else {
  bad('csound-path.ts missing cross-platform PATH')
}

// PARTICIPANTS.md sections
const participants = readFileSync(join(REPO, 'PARTICIPANTS.md'), 'utf-8')
for (const section of ['### macOS', '### Linux']) {
  if (participants.includes(section)) ok(`PARTICIPANTS.md has ${section}`)
  else bad(`PARTICIPANTS.md missing ${section}`)
}

// Executable bit on Unix shell scripts (mac/linux only)
if (platform !== 'win32') {
  for (const rel of ['scripts/launch-drc.sh', 'scripts/launch-workshop-attendee.sh']) {
    const mode = statSync(join(REPO, rel)).mode & 0o111
    if (mode) ok(`${rel} is executable`)
    else bad(`${rel} not executable — run: chmod +x ${rel}`)
  }
}

// Runtime checks on current host
if (spawnSync('node', ['--version'], { encoding: 'utf-8' }).status === 0) {
  ok(`node available: ${spawnSync('node', ['--version'], { encoding: 'utf-8' }).stdout.trim()}`)
} else bad('node not found')

const cs = spawnSync('csound', ['--version'], { encoding: 'utf-8' })
if (cs.status === 0) {
  const ver = (cs.stdout || cs.stderr || '').split('\n')[0]
  ok(`csound on this host: ${ver.trim()}`)
  if (/version\s+7/i.test(ver)) ok('Csound 7 detected on this host')
  else skip(`Csound 7 required for workshop gate — got: ${ver.trim()} (Ubuntu 22.04 apt is 6.17; see PARTICIPANTS.md Linux)`)
} else {
  skip('csound not on PATH on this host — install before workshop')
}

// Platform-specific launcher dry-run (syntax only)
if (platform === 'win32') {
  const ps = spawnSync('powershell', ['-NoProfile', '-Command', 'Get-Command csound -ErrorAction SilentlyContinue'], { encoding: 'utf-8' })
  if (ps.status === 0 && ps.stdout.trim()) ok('PowerShell can resolve csound')
  else skip('PowerShell csound check — install Csound on Windows VM to verify')
} else {
  const sh = spawnSync('bash', ['-n', join(REPO, 'scripts/launch-drc.sh')], { encoding: 'utf-8' })
  if (sh.status === 0) ok('bash -n scripts/launch-drc.sh')
  else bad('launch-drc.sh syntax error', sh.stderr)
}

console.log(`\n${passed} passed, ${failed} failed${failed ? ' — fix before workshop' : ''}\n`)
process.exit(failed > 0 ? 1 : 0)
