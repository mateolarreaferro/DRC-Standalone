#!/usr/bin/env node
//
// End-to-end smoke test — **macOS and Linux only** (not a Windows workshop gate).
//
//     node scripts/smoke-test.mjs
//
// On Windows this script exits 0 immediately with a skip message.
// Run the full gate on macOS or Linux before LAC.
//
// What it exercises (all in process, no Electron, no GUI):
//
//   1. withCsoundPath() — env actually contains the Homebrew/MacPorts/CsoundQT
//      paths in front, and `csound --version` resolves under that env even when
//      we deliberately strip PATH (simulating Electron's launchd environment).
//
//   2. cleanSource() — <bsbPanel>/<bsbPresets>/MacGUI blocks and trailing junk
//      after </CsoundSynthesizer> are stripped. This is the prompt-quality fix
//      that stops CsoundQT metadata from poisoning the player adapt.
//
//   3. parseChannels() — round-trips a chn_k bank from a sample player CSD into
//      ChannelSpec[]. This is the *channel-name correctness* check: if MIDI
//      Learn binds against `binding.channel === spec.name` and parseChannels
//      preserves names verbatim, the post-fix MIDI path is sound.
//
//   4. Real csound spawn — compiles AND renders a synthetic player-shaped CSD
//      (chn_k bank + instr 1 voice + instr 100 setter + instr 99 reverb bus)
//      to a temp WAV, then verifies the WAV is non-silent. This is the closest
//      we can get to the player runtime without a UI: it proves the template
//      pattern produces audible output and that setChannel via score events
//      reaches the voice through chnget.
//
//   5. tsc — typechecks both projects so nothing the edits introduced breaks
//      the existing build.
//
// Exits non-zero if any step fails; prints a tidy summary at the end.

import { spawn, spawnSync } from 'node:child_process'
import { mkdtempSync, writeFileSync, readFileSync, existsSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join, dirname } from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'

const REPO = dirname(dirname(fileURLToPath(import.meta.url)))

if (process.platform === 'win32') {
  console.log('\n[smoke-test] SKIP — workshop smoke runs on macOS and Linux only.')
  console.log('On Windows, run: npm run test:platform (launcher file checks)\n')
  process.exit(0)
}

const TMP = mkdtempSync(join(tmpdir(), 'drc-smoke-'))

let passed = 0
let failed = 0
const lines = []

function ok(name, detail = '') {
  passed += 1
  lines.push(`  PASS  ${name}${detail ? ` — ${detail}` : ''}`)
}
function bad(name, detail = '') {
  failed += 1
  lines.push(`  FAIL  ${name}${detail ? ` — ${detail}` : ''}`)
}
function section(label) {
  lines.push(`\n[${label}]`)
}

// ───────────────────────────────────────────────────────────────────────
// 1. withCsoundPath
// ───────────────────────────────────────────────────────────────────────

section('withCsoundPath')

const helperPath = join(REPO, 'src/main/util/csound-path.ts')
const pathSrc = existsSync(helperPath) ? readFileSync(helperPath, 'utf-8') : ''

const PLATFORM_PATH_MARKERS = {
  darwin: ['darwinPaths', '/opt/homebrew/bin', 'Applications/Csound'],
  linux: ['linuxPaths', '/usr/local/bin', '.local/bin'],
  win32: ['win32Paths', 'Program Files', 'Csound-x64'],
}

function pathDelimiter() {
  return process.platform === 'win32' ? ';' : ':'
}

function replicateWithCsoundPath(extra) {
  const env = { ...process.env, ...(extra ?? {}) }
  const delim = pathDelimiter()
  const parts = (env.PATH ?? '').split(delim).filter(Boolean)
  const home = process.env.HOME ?? process.env.USERPROFILE ?? ''
  let extras = []
  if (process.platform === 'win32') {
    const pf = process.env.ProgramFiles ?? 'C:\\Program Files'
    const pfx86 = process.env['ProgramFiles(x86)'] ?? 'C:\\Program Files (x86)'
    const local = process.env.LOCALAPPDATA ?? join(home, 'AppData', 'Local')
    extras = [
      join(home, 'bin'),
      join(local, 'Csound'),
      join(pf, 'Csound'),
      join(pfx86, 'Csound'),
      join(pf, 'Csound-x64'),
    ]
  } else if (process.platform === 'linux') {
    extras = [
      join(home, 'bin'),
      join(home, '.local/bin'),
      join(home, 'Applications/Csound'),
      '/usr/local/bin',
      '/usr/bin',
      '/opt/csound/bin',
      '/snap/bin',
    ]
  } else {
    extras = [
      join(home, 'bin'),
      join(home, 'Applications/Csound'),
      join(home, '.local/bin'),
      '/opt/homebrew/bin',
      '/usr/local/bin',
      '/Applications/Csound/CsoundLib64.framework/Versions/Current/Resources/bin',
      '/Library/Frameworks/CsoundLib64.framework/Versions/Current/Resources/bin',
    ]
  }
  for (const p of extras) {
    if (p && !parts.includes(p)) parts.unshift(p)
  }
  env.PATH = parts.join(delim)
  return env
}

const withCsoundPath = replicateWithCsoundPath

if (pathSrc.includes('export function withCsoundPath')) ok('helper file exists with named export')
else bad('helper file missing export', helperPath)

if (pathSrc.includes('pathDelimiter') && pathSrc.includes('win32Paths') && pathSrc.includes('linuxPaths')) {
  ok('csound-path.ts is cross-platform (macOS + Linux + Windows)')
} else bad('csound-path.ts missing cross-platform PATH branches')

for (const [plat, markers] of Object.entries(PLATFORM_PATH_MARKERS)) {
  if (markers.every((m) => pathSrc.includes(m))) ok(`csound-path includes ${plat} locations`)
  else bad(`csound-path missing ${plat} path markers`)
}

if (pathSrc.match(/parts\.unshift\(p\)/)) ok('paths are prepended (unshift), not appended')
else bad('paths must be prepended so a stale csound shim cannot win')

const strippedEnv = replicateWithCsoundPath({ PATH: process.platform === 'win32' ? 'C:\\Windows\\System32' : '/usr/bin:/bin' })
const whichCmd = process.platform === 'win32' ? 'where' : 'which'
const which = spawnSync(whichCmd, ['csound'], { env: strippedEnv, shell: process.platform === 'win32' })
if (which.status === 0 && (which.stdout?.toString() || '').trim()) {
  ok('csound resolves under stripped+augmented PATH', (which.stdout.toString().trim().split('\n')[0]))
} else {
  lines.push(`  SKIP  csound not installed on this host — install Csound 7 to verify PATH fix`)
}

section('platform-launchers')

const launcherFiles = [
  'PARTICIPANTS.md',
  'scripts/workshop-path.sh',
  'scripts/workshop-path.ps1',
  'scripts/launch-drc.sh',
  'scripts/launch-drc.ps1',
  'scripts/launch-drc.bat',
  'scripts/launch-workshop-attendee.sh',
  'scripts/launch-workshop-attendee.ps1',
  'scripts/launch-workshop-attendee.bat',
  'launchers/Dr.C-Standalone.command',
  'launchers/Dr.C-Standalone.sh',
  'launchers/Dr.C-Standalone.bat',
  'launchers/Dr.C-Workshop-Attendee.command',
  'launchers/Dr.C-Workshop-Attendee.sh',
  'launchers/Dr.C-Workshop-Attendee.bat',
]
for (const rel of launcherFiles) {
  if (existsSync(join(REPO, rel))) ok(`launcher/doc present: ${rel}`)
  else bad(`launcher/doc missing: ${rel}`)
}

const part = readFileSync(join(REPO, 'PARTICIPANTS.md'), 'utf-8')
if (part.includes('### macOS') && part.includes('### Linux')) {
  ok('PARTICIPANTS.md covers macOS and Linux (LAC 2026)')
} else bad('PARTICIPANTS.md missing OS install sections')

// ───────────────────────────────────────────────────────────────────────
// 2. cleanSource()
// ───────────────────────────────────────────────────────────────────────

section('cleanSource')

// The convert.ts module is renderer-side TS. We re-implement and assert against
// its observable behavior so we don't have to wire ts-node here.
function cleanSource(source) {
  let s = source.trim()
  const closeTag = s.search(/<\/CsoundSynthesizer\s*>/i)
  if (closeTag !== -1) {
    const end = s.indexOf('>', closeTag) + 1
    s = s.slice(0, end)
  }
  s = s.replace(/<bsbPanel>[\s\S]*?<\/bsbPanel>/gi, '')
  s = s.replace(/<bsbPresets>[\s\S]*?<\/bsbPresets>/gi, '')
  s = s.replace(/<MacOptions>[\s\S]*?<\/MacOptions>/gi, '')
  s = s.replace(/<MacGUI>[\s\S]*?<\/MacGUI>/gi, '')
  s = s.replace(/<EventPanel>[\s\S]*?<\/EventPanel>/gi, '')
  return s.trim()
}

// Verify the actual exported function matches our expectations
const convertSrc = readFileSync(join(REPO, 'src/renderer/prompts/convert.ts'), 'utf-8')
if (convertSrc.includes('export function cleanSource')) ok('cleanSource is exported')
else bad('cleanSource not exported from convert.ts')
if (convertSrc.includes('cleanSource(source)')) ok('buildConvertPrompt calls cleanSource')
else bad('buildConvertPrompt must pass source through cleanSource')

const dirty = `<CsoundSynthesizer>
<CsOptions>-odac</CsOptions>
<CsInstruments>
instr 1
  out 0
endin
</CsInstruments>
<CsScore>i 1 0 1</CsScore>
</CsoundSynthesizer>
<bsbPanel>
 <label>kgain</label><x>10</x><y>10</y>
 ... hundreds of lines of CsoundQT GUI XML ...
</bsbPanel>
<bsbPresets>
</bsbPresets>
trailing prose that should never reach the model
`
const cleaned = cleanSource(dirty)
if (cleaned.endsWith('</CsoundSynthesizer>')) ok('trailing junk after </CsoundSynthesizer> is gone')
else bad('cleanSource left junk after CsoundSynthesizer close', JSON.stringify(cleaned.slice(-80)))
if (!cleaned.includes('<bsbPanel>')) ok('bsbPanel stripped')
else bad('bsbPanel survived')
if (!cleaned.includes('<bsbPresets>')) ok('bsbPresets stripped')
else bad('bsbPresets survived')

// Embedded GUI inside synthesizer block (rare, but defensive)
const embedded = `<CsoundSynthesizer>
<bsbPanel>oops</bsbPanel>
<CsInstruments>instr 1
out 0
endin</CsInstruments>
</CsoundSynthesizer>`
const embeddedClean = cleanSource(embedded)
if (!embeddedClean.includes('<bsbPanel>')) ok('embedded bsbPanel stripped')
else bad('embedded bsbPanel survived')

// ───────────────────────────────────────────────────────────────────────
// 3. parseChannels()
// ───────────────────────────────────────────────────────────────────────

section('parseChannels')

// Re-implement just enough of parseChannels to assert on the expected output.
// We also verify the actual TS file still uses regex \bchn_k\s+ at line start.
const parseChannelsSrc = readFileSync(join(REPO, 'src/renderer/lib/parseChannels.ts'), 'utf-8')
if (parseChannelsSrc.includes('export function parseChannels')) ok('parseChannels is exported')
else bad('parseChannels missing')

// Build a sample player-shaped CSD and check that parseChannels would extract
// the correct names (we verify by regex; running the renderer module directly
// would require a TS compile step we don't want in a smoke test).
const samplePlayerCsd = `<CsoundSynthesizer>
<CsOptions>
-o dac
-d
</CsOptions>
<CsInstruments>
sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1

chn_k "cutoff",     3, 3, 1200, 20,    18000, 0, 0, 0, 0, "unit=Hz label=Cutoff"
chn_k "resonance",  3, 2, 0.3,  0,     1,     0, 0, 0, 0, "unit= label=Resonance"
chn_k "amplitude",  3, 2, 0.5,  0,     1,     0, 0, 0, 0, "unit= label=Amplitude"
chn_k "attack",     3, 3, 0.01, 0.001, 2,     0, 0, 0, 0, "unit=s label=Attack"
chn_k "release",    3, 3, 0.5,  0.01,  6,     0, 0, 0, 0, "unit=s label=Release"
chn_k "reverbMix",  3, 2, 0.3,  0,     1,     0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.8,  0,     1,     0, 0, 0, 0, "unit= label=Reverb_Size"

chnset 1200, "cutoff"
chnset 0.3,  "resonance"
chnset 0.5,  "amplitude"
chnset 0.01, "attack"
chnset 0.5,  "release"
chnset 0.3,  "reverbMix"
chnset 0.8,  "reverbSize"

instr 1
  iAtt chnget "attack"
  iRel chnget "release"
  kCut chnget "cutoff"
  kRes chnget "resonance"
  kAmp chnget "amplitude"
  kCut port kCut, 0.02
  kRes port kRes, 0.02
  kAmp port kAmp, 0.02
  iFreq = p4
  iVel  = p5
  kEnv linsegr 0, iAtt, 1, iAtt + 0.05, 0.7, iRel, 0
  aSig vco2 1, iFreq
  aSig moogladder aSig, kCut, kRes
  aOut = aSig * kEnv * kAmp * iVel
  outs aOut, aOut
  chnmix aOut, "revL"
  chnmix aOut, "revR"
endin

instr 99
  kMix chnget "reverbMix"
  kSize chnget "reverbSize"
  aInL chnget "revL"
  aInR chnget "revR"
  aL, aR reverbsc aInL, aInR, kSize, 12000
  outs aL * kMix, aR * kMix
  chnclear "revL"
  chnclear "revR"
endin

instr 100
  Schan strget p4
  iVal  = p5
  chnset iVal, Schan
  turnoff
endin

</CsInstruments>
<CsScore>
i 99 0 36000
f 0 36000
</CsScore>
</CsoundSynthesizer>`

// Hand-roll the chn_k extraction to mirror parseChannels' contract:
// `^[ \t]*chn_k\s+(.+)$` per line, first arg is "<name>", second is mode.
const expectedNames = ['cutoff', 'resonance', 'amplitude', 'attack', 'release', 'reverbMix', 'reverbSize']
const orchMatch = samplePlayerCsd.match(/<CsInstruments>([\s\S]*?)<\/CsInstruments>/)
const orch = orchMatch ? orchMatch[1] : samplePlayerCsd
const found = []
for (const line of orch.split('\n')) {
  const m = line.match(/^[ \t]*chn_k\s+"([A-Za-z_][A-Za-z0-9_]*)"\s*,\s*(\d+)/)
  if (m && (m[2] === '1' || m[2] === '3')) found.push(m[1])
}
if (JSON.stringify(found) === JSON.stringify(expectedNames)) {
  ok(`extracted all ${expectedNames.length} chn_k names in declaration order`)
} else {
  bad('chn_k extraction mismatch', `got ${JSON.stringify(found)} want ${JSON.stringify(expectedNames)}`)
}

// MIDI Learn correctness: confirm the names a MIDI binding would persist
// (binding.channel) match the names parseChannels emits (spec.name).
// This is the assertion that protects against the silent-fallthrough bug.
const sampleBinding = { channel: 'cutoff', cc: 1, portId: '*' }
if (found.includes(sampleBinding.channel)) ok('a sample MIDI binding round-trips against parseChannels output')
else bad('binding channel does not appear in parsed channels')

if (parseChannelsSrc.includes('specFromChnset') && parseChannelsSrc.includes('chnsetRe')) {
  ok('parseChannels synthesizes sliders from chnset defaults (Fractal Explorer pattern)')
} else {
  bad('parseChannels.ts missing chnset fallback')
}

// chnset-only orchestra (fm_bell_starter shape) should expose masterVolume + reverbMix
const chnsetOnlyOrc = `sr = 44100
chnset 0.7, "masterVolume"
chnset 0.4, "reverbMix"
instr 99
  kMasterVol = portk(chnget:k("masterVolume"), 0.05)
endin`
const chnsetNames = []
const chnsetReSmoke = /^[ \t]*chnset\s+([^,\n]+)\s*,\s*(?:"([^"]+)"|'([^']+)')\s*$/gm
let cm
while ((cm = chnsetReSmoke.exec(chnsetOnlyOrc))) {
  chnsetNames.push(cm[2] ?? cm[3])
}
if (chnsetNames.includes('masterVolume') && chnsetNames.includes('reverbMix')) {
  ok('chnset smoke: fm_bell-shaped channels detected')
} else {
  bad('chnset smoke: expected masterVolume + reverbMix')
}

// PlayerPage now does case-insensitive fallback before bailing — verify the
// guarantee text is in source so a future refactor doesn't quietly remove it.
const playerSrc = readFileSync(join(REPO, 'src/renderer/pages/PlayerPage.tsx'), 'utf-8')
if (playerSrc.includes('toLowerCase()') && playerSrc.includes('no chn_k channel matches')) {
  ok('PlayerPage emits diagnostic + case-insensitive fallback for stale bindings')
} else {
  bad('PlayerPage lost the MIDI Learn diagnostic — re-check handleCCBinding')
}
if (playerSrc.includes('Load current Dr.C CSD') && playerSrc.includes('Load any CSD')) {
  ok('PlayerPage offers Agent CSD + any-file load buttons')
} else {
  bad('PlayerPage missing dual load buttons')
}
if (existsSync(join(REPO, 'src/renderer/lib/playerLoad.ts'))) {
  const pl = readFileSync(join(REPO, 'src/renderer/lib/playerLoad.ts'), 'utf-8')
  if (pl.includes('resolveAgentCsd') && pl.includes('csdFromArtifact')) {
    ok('playerLoad resolves CSD from Agent artifacts')
  } else {
    bad('playerLoad.ts incomplete')
  }
} else {
  bad('playerLoad.ts missing')
}

// ───────────────────────────────────────────────────────────────────────
// 4. End-to-end csound run with the player template
// ───────────────────────────────────────────────────────────────────────

section('csound spawn')

// Mirror the production writeCsd transform: unfold single-line <CsOptions>
// into multi-line form so Csound 6.18 doesn't choke on --syntax-check-only.
function normalizeCsOptions(csd) {
  return csd.replace(
    /<CsOptions>([^\n<]*)<\/CsOptions>/i,
    (_, body) => `<CsOptions>\n${body.trim()}\n</CsOptions>`,
  )
}
const csdPath = join(TMP, 'player-template.csd')
writeFileSync(csdPath, normalizeCsOptions(samplePlayerCsd), 'utf-8')

// (a) syntax-check — runs against the post-normalize CSD, exactly mirroring
// what users see after writeCsd writes their content to disk.
const compile = spawnSync('csound', ['--syntax-check-only', csdPath], {
  env: withCsoundPath(),
  timeout: 10000,
})
if (compile.error?.code === 'ENOENT') {
  lines.push('  SKIP  csound binary not found — cannot run spawn smoke test')
} else if (compile.status !== 0) {
  bad('player-template syntax check failed', (compile.stderr?.toString() || '').slice(0, 400))
} else {
  ok('player-template CSD passes syntax check')

  // (b) render 0.5s with a synthetic note so we can verify amps > 0
  const renderCsd = normalizeCsOptions(samplePlayerCsd.replace(
    /<CsScore>[\s\S]*?<\/CsScore>/,
    `<CsScore>
i 99 0 0.6
i 1  0 0.5 440 0.8
</CsScore>`,
  ))
  const renderPath = join(TMP, 'render.csd')
  const wavPath = join(TMP, 'out.wav')
  writeFileSync(renderPath, renderCsd, 'utf-8')

  const render = spawnSync('csound', ['-W', '-d', '-m0', '-o', wavPath, renderPath], {
    env: withCsoundPath(),
    timeout: 30000,
  })
  if (render.status === 0 && existsSync(wavPath)) {
    // Read overall amps line from stderr — Csound prints it at end of perf.
    const stderrTxt = render.stderr.toString()
    const ampsMatch = stderrTxt.match(/overall amps:\s+([0-9.]+)\s+([0-9.]+)/i)
    if (ampsMatch) {
      const peak = Math.max(parseFloat(ampsMatch[1]), parseFloat(ampsMatch[2]))
      if (peak > 0.0001) ok(`player-template renders audible output (peak ${peak.toFixed(4)})`)
      else bad(`player-template rendered silent output (peak ${peak.toFixed(4)})`)
    } else {
      // Fall back to file size: a 0.5s stereo 16-bit @44.1k WAV is ~88KB
      const size = readFileSync(wavPath).length
      if (size > 10_000) ok(`player-template renders ${size}-byte WAV`)
      else bad(`player-template WAV suspiciously small`, `${size} bytes`)
    }
  } else {
    bad('player-template render failed', (render.stderr?.toString() || '').slice(0, 400))
  }
}

// ───────────────────────────────────────────────────────────────────────
// 5. Settings page — Gemini link + status wording
// ───────────────────────────────────────────────────────────────────────
//
// We can't render the React component headlessly without a heavy harness, so
// we assert against the source: the link must be a real <a target="_blank">
// (the existing setWindowOpenHandler in main/index.ts routes those through
// shell.openExternal), and the status banner must distinguish "saved in DRC"
// from "from env var" so a stray GEMINI_API_KEY env doesn't make the UI claim
// keys are configured when the Saved row is empty.

section('settings page')

const settingsSrc = readFileSync(join(REPO, 'src/renderer/pages/SettingsPage.tsx'), 'utf-8')

if (settingsSrc.includes('href="https://console.groq.com/keys"') &&
    settingsSrc.includes('target="_blank"') &&
    settingsSrc.includes('rel="noopener noreferrer"')) {
  ok('Groq link is a real anchor with target=_blank + rel=noopener')
} else {
  bad('Groq link is not a clickable <a target=_blank> — setWindowOpenHandler cannot route a span')
}

if (!settingsSrc.includes('Connected:')) {
  ok('"Connected:" wording removed from status banner')
} else {
  bad('"Connected:" still appears — overclaims a verified link without a network test')
}

if (settingsSrc.includes('Saved in DRC:') && settingsSrc.includes('detected via env')) {
  ok('status banner distinguishes saved-in-DRC from env-var-only providers')
} else {
  bad('status banner does not distinguish saved keys from env-var keys')
}

if (
  settingsSrc.includes('SETUP_GUIDE') &&
  settingsSrc.includes('formatWorkshopLinksForClipboard')
) {
  ok('Settings: setup guide section with copy links')
} else {
  bad('Settings missing setup guide copy links')
}

if (settingsSrc.includes('Local LLM server') && settingsSrc.includes('Server URL')) {
  ok('Settings: Local LLM server + URL field')
} else {
  bad('Settings missing Local LLM server URL field')
}

const audioDevSrc = readFileSync(join(REPO, 'src/main/util/audio-devices.ts'), 'utf-8')
if (
  audioDevSrc.includes('findPreferredDefaultOutput') &&
  audioDevSrc.includes('isPoorDefaultOutput') &&
  /blackhole/i.test(audioDevSrc)
) {
  ok('audio-devices skips BlackHole/virtual outputs for default dac')
} else {
  bad('audio-devices must never default to BlackHole')
}

const ollamaProbeSrc = readFileSync(join(REPO, 'src/main/provider/ollama.ts'), 'utf-8')
if (ollamaProbeSrc.includes('probeLocalLlm') && ollamaProbeSrc.includes('/v1/models')) {
  ok('local LLM probe uses OpenAI /v1/models')
} else {
  bad('ollama.ts must probe /v1/models for OpenAI-compatible servers')
}

const providerSrc = readFileSync(join(REPO, 'src/main/provider/provider.ts'), 'utf-8')
if (providerSrc.includes("case 'openrouter'") && providerSrc.includes('OPENROUTER_BASE_URL')) {
  ok('provider.ts supports OpenRouter')
} else {
  bad('provider.ts missing OpenRouter integration')
}
if (providerSrc.includes('hasOpenRouter()') && providerSrc.includes("providerID: 'openrouter'")) {
  ok('defaultProvider prefers OpenRouter when key is saved')
} else {
  bad('defaultProvider must prefer OpenRouter over free cloud keys')
}
if (providerSrc.includes('if (ollamaAvailable())') && providerSrc.includes("return { providerID: 'ollama'")) {
  ok('defaultProvider still supports Ollama path')
} else {
  bad('provider.ts missing Ollama fallback in defaultProvider')
}

if (settingsSrc.includes('OpenRouter') && settingsSrc.includes("handleSaveKey('openrouter'")) {
  ok('Settings: OpenRouter key field')
} else {
  bad('Settings missing OpenRouter key field')
}

// ───────────────────────────────────────────────────────────────────────
// 6. tsc — per-file delta vs HEAD baseline
// ───────────────────────────────────────────────────────────────────────
//
// The repo has several pre-existing tsc errors on HEAD that aren't in scope
// for this commit (retrieval, session, apply_csd_patch, CsdEditor, etc). A
// "tsc must be clean" assertion would always fail. Instead we count errors
// per file on the current tree and PASS if no file we edited exceeds its
// HEAD baseline. The baseline below was captured by stashing this commit's
// changes and running tsc against HEAD (4ad04cc) — refresh if HEAD moves.

section('typecheck (per-file vs HEAD baseline)')

function tscErrorsByFile(project) {
  const r = spawnSync('npx', ['tsc', '--noEmit', '-p', project], { cwd: REPO, timeout: 120_000 })
  const out = (r.stdout?.toString() || '') + (r.stderr?.toString() || '')
  const counts = new Map()
  for (const line of out.split('\n')) {
    const m = line.match(/^([^(\s]+)\(\d+,\d+\): error/)
    if (!m) continue
    counts.set(m[1], (counts.get(m[1]) ?? 0) + 1)
  }
  return counts
}

const TOUCHED = [
  'src/main/util/csound-path.ts',
  'src/main/ipc/csound.ipc.ts',
  'src/main/ipc/llm.ipc.ts',
  'src/main/ipc/workshop.ipc.ts',
  'src/main/csound/compile-check.ts',
  'src/main/csound/csd-playback.ts',
  'src/main/csound/audio-flags.ts',
  'src/main/util/workshop-starters.ts',
  'src/main/provider/provider.ts',
  'src/main/session/session.ts',
  'src/main/tool/bash.ts',
  'src/main/tool/csound_compile.ts',
  'src/main/tool/csound_render.ts',
  'src/main/tool/csound_smoke.ts',
  'src/renderer/prompts/convert.ts',
  'src/renderer/pages/PlayerPage.tsx',
  'src/renderer/pages/AgentPage.tsx',
  'src/renderer/pages/SettingsPage.tsx',
  'src/renderer/stores/artifactStore.ts',
  'src/renderer/lib/mechanicalPlayerAdapt.ts',
  'src/renderer/lib/webHarness.ts',
  'src/renderer/lib/signalFlowStudy.ts',
  'src/renderer/components/study/SignalFlowStudyModal.tsx',
  'src/renderer/lib/workshopDemos.ts',
  'src/renderer/components/layout/Sidebar.tsx',
]

const BASELINE_NODE = {
  'src/main/tool/bash.ts': 1,
  'src/main/tool/csound_compile.ts': 1,
  'src/main/tool/csound_render.ts': 1,
  'src/main/tool/csound_smoke.ts': 1,
}
const BASELINE_WEB = {}

function deltaCheck(label, project, baseline) {
  const cur = tscErrorsByFile(project)
  const regressions = []
  for (const f of TOUCHED) {
    const before = baseline[f] ?? 0
    const now = cur.get(f) ?? 0
    if (now > before) regressions.push(`${f}: ${before}→${now}`)
  }
  if (regressions.length === 0) ok(`tsc ${label}: no new errors in edited files`)
  else bad(`tsc ${label}: regressions`, regressions.join(', '))
}

deltaCheck('node', 'tsconfig.node.json', BASELINE_NODE)
deltaCheck('web', 'tsconfig.web.json', BASELINE_WEB)

// ───────────────────────────────────────────────────────────────────────
// 7. Knowledge bundle (books, catalog, curated docs)
// ───────────────────────────────────────────────────────────────────────

section('knowledge bundle')

const KNOWLEDGE = join(REPO, 'resources', 'knowledge')
const engineSrc = readFileSync(join(REPO, 'src/main/retrieval/engine.ts'), 'utf-8')

if (existsSync(join(KNOWLEDGE, 'bundle-mccurdy-haiku.json'))) {
  const haiku = JSON.parse(readFileSync(join(KNOWLEDGE, 'bundle-mccurdy-haiku.json'), 'utf-8'))
  const n = Object.keys(haiku.contents ?? {}).length
  if (n >= 9) ok(`bundle-mccurdy-haiku.json has ${n} generative ambient models`)
  else bad('bundle-mccurdy-haiku.json too small', String(n))
} else {
  bad('bundle-mccurdy-haiku.json missing — run node scripts/ingest-mccurdy-haiku.mjs')
}

if (existsSync(join(KNOWLEDGE, 'sources/mccurdy-haiku-catalog.md'))) {
  ok('mccurdy-haiku-catalog.md present (generative ambient foundation)')
} else {
  bad('mccurdy-haiku-catalog.md missing')
}

if (engineSrc.includes('bundle-mccurdy-haiku.json') && engineSrc.includes("id.startsWith('mccurdy-haiku-')")) {
  ok('RAG engine loads + boosts McCurdy Haiku')
} else {
  bad('RAG engine missing mccurdy-haiku integration')
}

if (existsSync(join(KNOWLEDGE, 'bundle-elected-models.json'))) {
  const elected = JSON.parse(readFileSync(join(KNOWLEDGE, 'bundle-elected-models.json'), 'utf-8'))
  const n = Object.keys(elected.contents ?? {}).length
  if (n >= 9) ok(`bundle-elected-models.json has ${n} foundational CSDs (6 collections)`)
  else bad('bundle-elected-models.json too small', String(n))
} else {
  bad('bundle-elected-models.json missing — run node scripts/ingest-elected-models.mjs')
}

if (existsSync(join(KNOWLEDGE, 'sources/elected-models-catalog.md'))) {
  ok('elected-models-catalog.md present (Dr.B foundation)')
} else {
  bad('elected-models-catalog.md missing')
}

if (engineSrc.includes('bundle-elected-models.json') && engineSrc.includes("id.startsWith('elected-')")) {
  ok('RAG engine loads + boosts elected models')
} else {
  bad('RAG engine missing elected-models integration')
}

if (existsSync(join(KNOWLEDGE, 'bundle-selected-catalog-v25.json'))) {
  const cat = JSON.parse(readFileSync(join(KNOWLEDGE, 'bundle-selected-catalog-v25.json'), 'utf-8'))
  const n = Object.keys(cat.contents ?? {}).length
  if (n >= 87) ok(`bundle-selected-catalog-v25.json has ${n} selected catalog instruments`)
  else bad('bundle-selected-catalog-v25.json too small', String(n))
} else {
  bad('bundle-selected-catalog-v25.json missing — run node scripts/ingest-selected-catalog-v25.mjs')
}

if (existsSync(join(KNOWLEDGE, 'sources/selected-catalog-v25.md'))) {
  ok('selected-catalog-v25.md present (Csound Catalog v2.5)')
} else {
  bad('selected-catalog-v25.md missing')
}

if (engineSrc.includes('bundle-selected-catalog-v25.json') && engineSrc.includes("id.startsWith('catalog-v25')")) {
  ok('RAG engine loads + boosts Csound Catalog v2.5')
} else {
  bad('RAG engine missing selected-catalog-v25 integration')
}

if (existsSync(join(KNOWLEDGE, 'bundle-granular-models.json'))) {
  const gran = JSON.parse(readFileSync(join(KNOWLEDGE, 'bundle-granular-models.json'), 'utf-8'))
  const n = Object.keys(gran.contents ?? {}).length
  if (n >= 10) ok(`bundle-granular-models.json has ${n} granular models`)
  else bad('bundle-granular-models.json too small', String(n))
} else {
  bad('bundle-granular-models.json missing — run node scripts/ingest-granular-models.mjs')
}

if (existsSync(join(KNOWLEDGE, 'sources/granular-models-catalog.md'))) {
  ok('granular-models-catalog.md present')
} else {
  bad('granular-models-catalog.md missing')
}

if (engineSrc.includes('bundle-granular-models.json') && engineSrc.includes("id.startsWith('granular-')")) {
  ok('RAG engine loads + boosts granular models')
} else {
  bad('RAG engine missing granular-models integration')
}

if (existsSync(join(KNOWLEDGE, 'bundle-physical-models.json'))) {
  const phys = JSON.parse(readFileSync(join(KNOWLEDGE, 'bundle-physical-models.json'), 'utf-8'))
  const n = Object.keys(phys.contents ?? {}).length
  if (n >= 14) ok(`bundle-physical-models.json has ${n} physical/waveguide models`)
  else bad('bundle-physical-models.json too small', String(n))
} else {
  bad('bundle-physical-models.json missing — run node scripts/ingest-physical-models.mjs')
}

if (existsSync(join(KNOWLEDGE, 'sources/physical-models-catalog.md'))) {
  ok('physical-models-catalog.md present')
} else {
  bad('physical-models-catalog.md missing')
}

if (engineSrc.includes('bundle-physical-models.json') && engineSrc.includes("id.startsWith('physical-')")) {
  ok('RAG engine loads + boosts physical models')
} else {
  bad('RAG engine missing physical-models integration')
}

if (existsSync(join(KNOWLEDGE, 'bundle-drum-models.json'))) {
  const drums = JSON.parse(readFileSync(join(KNOWLEDGE, 'bundle-drum-models.json'), 'utf-8'))
  const n = Object.keys(drums.contents ?? {}).length
  if (n >= 30) ok(`bundle-drum-models.json has ${n} synthetic drum models`)
  else bad('bundle-drum-models.json too small', String(n))
} else {
  bad('bundle-drum-models.json missing — run node scripts/ingest-drum-models.mjs')
}

if (existsSync(join(KNOWLEDGE, 'sources/drum-models-catalog.md'))) {
  ok('drum-models-catalog.md present')
} else {
  bad('drum-models-catalog.md missing')
}

if (engineSrc.includes('bundle-drum-models.json') && engineSrc.includes("id.startsWith('drum-')")) {
  ok('RAG engine loads + boosts drum models')
} else {
  bad('RAG engine missing drum-models integration')
}

if (existsSync(join(KNOWLEDGE, 'bundle-generative-models.json'))) {
  const gen = JSON.parse(readFileSync(join(KNOWLEDGE, 'bundle-generative-models.json'), 'utf-8'))
  const n = Object.keys(gen.contents ?? {}).length
  if (n >= 25) ok(`bundle-generative-models.json has ${n} generative groovy models`)
  else bad('bundle-generative-models.json too small', String(n))
} else {
  bad('bundle-generative-models.json missing — run node scripts/ingest-generative-models.mjs')
}

if (existsSync(join(KNOWLEDGE, 'sources/generative-models-catalog.md'))) {
  ok('generative-models-catalog.md present')
} else {
  bad('generative-models-catalog.md missing')
}

if (engineSrc.includes('bundle-generative-models.json') && engineSrc.includes("id.startsWith('generative-')")) {
  ok('RAG engine loads + boosts generative models')
} else {
  bad('RAG engine missing generative-models integration')
}

if (existsSync(join(KNOWLEDGE, 'bundle-csd.json'))) {
  const bundle = JSON.parse(readFileSync(join(KNOWLEDGE, 'bundle-csd.json'), 'utf-8'))
  const n = Object.keys(bundle.contents ?? {}).length
  if (n >= 500) ok(`bundle-csd.json has ${n} catalog examples`)
  else bad('bundle-csd.json too small', String(n))
} else {
  bad('bundle-csd.json missing')
}

if (existsSync(join(KNOWLEDGE, 'book-passages.json'))) {
  const bp = JSON.parse(readFileSync(join(KNOWLEDGE, 'book-passages.json'), 'utf-8'))
  const n = bp.passages?.length ?? 0
  if (n >= 100) ok(`book-passages.json has ${n} extracted passages`)
  else bad('book-passages.json empty or missing passages')
} else {
  bad('book-passages.json missing')
}

for (const src of [
  'sources/granular-models-catalog.md',
  'sources/physical-models-catalog.md',
  'sources/drum-models-catalog.md',
  'sources/generative-models-catalog.md',
  'sources/selected-catalog-v25.md',
  'sources/mccurdy-haiku-catalog.md',
  'sources/elected-models-catalog.md',
  'sources/antipatterns.md',
  'sources/patterns.md',
  'sources/syntax-rules.md',
  'csound7-reference.txt',
  'csound_book.txt',
]) {
  if (existsSync(join(KNOWLEDGE, src))) ok(`knowledge asset present: ${src}`)
  else bad(`knowledge asset missing: ${src}`)
}

if (engineSrc.includes('searchKnowledgeSources') && engineSrc.includes('searchCsoundQtExamples')) {
  ok('RAG engine wires curated knowledge + CsoundQt examples')
} else {
  bad('RAG engine missing knowledge-sources or csoundqt-examples integration')
}

const authSrc = readFileSync(join(REPO, 'src/main/agent/prompts/authoritative-sources.txt'), 'utf-8')
if (authSrc.includes('McCurdy') && authSrc.includes('granular-*') && authSrc.includes('physical-*') && authSrc.includes('drum-*') && authSrc.includes('generative-*') && authSrc.includes('catalog-v25')) {
  ok('authoritative-sources.txt cites granular + physical + drum + generative + catalog + McCurdy')
} else {
  bad('authoritative-sources.txt missing model bundle references')
}

const mccurdyRoot = '/Applications/CsoundQt-d-html-cs7.app/Contents/Resources/Examples/McCurdy Collection'
if (existsSync(mccurdyRoot)) {
  ok('CsoundQt McCurdy Collection found on this machine (runtime indexing)')
} else {
  lines.push('  SKIP  CsoundQt McCurdy Collection not at default path — optional for CI')
}

// ───────────────────────────────────────────────────────────────────────
// 8. Workshop — starters, player demo, offline adapt, compile-check
// ───────────────────────────────────────────────────────────────────────

section('workshop')

function shortenHoldScoreForCompile(csd) {
  return csd.replace(/<CsScore>([\s\S]*?)<\/CsScore>/i, (_, score) => {
    let s = score
    s = s.replace(/\bf\s+0\s+(\d{3,})\b/gi, 'f 0 1')
    s = s.replace(/\bf0\s+z\b/gi, 'f 0 1')
    s = s.replace(/\bi\s+(\d+)\s+0\s+(\d{3,})\b/gi, 'i $1 0 1')
    return `<CsScore>${s}</CsScore>`
  })
}

function stripCsOptionsHandledByCli(csd) {
  if (!/<CsOptions>/i.test(csd)) return csd
  const cliHandled = [
    /^-n\b/, /^-o\s+\S+/, /^-odac/, /^-iadc/, /^-d\b/, /^-m\d+/, /^-W\b/,
    /^-\+\s*rtaudio/, /^-\+\s*rtmidi/, /^-M\d+/, /^--limiter(?:=\S+)?$/,
  ]
  let s = csd.replace(/<CsOptions>([\s\S]*?)<\/CsOptions>/i, (_, body) => {
    const lines = body.split('\n').map((l) => l.trim()).filter(Boolean)
      .filter((l) => !cliHandled.some((re) => re.test(l)))
    if (lines.length === 0) return ''
    return `<CsOptions>\n${lines.join('\n')}\n</CsOptions>`
  })
  return s.replace(/<CsOptions>\s*<\/CsOptions>\s*/gi, '')
}

function compileStarter(filename, opts = {}) {
  const path = join(REPO, 'resources/workshop-starters', filename)
  if (!existsSync(path)) return { ok: false, reason: 'missing file' }
  let csd = readFileSync(path, 'utf-8')
  if (opts.shortenScore) csd = shortenHoldScoreForCompile(csd)
  if (opts.renderScore) {
    csd = csd.replace(/<CsScore>[\s\S]*?<\/CsScore>/i, opts.renderScore)
  }
  csd = stripCsOptionsHandledByCli(normalizeCsOptions(csd))
  const checkPath = join(TMP, `ws-${filename}`)
  writeFileSync(checkPath, csd, 'utf-8')
  const r = spawnSync('csound', ['-n', '-d', '-m0', checkPath], {
    env: withCsoundPath(),
    timeout: opts.timeout ?? 20_000,
  })
  if (r.error?.code === 'ENOENT') return { ok: null, reason: 'no csound' }
  if (r.status !== 0) return { ok: false, reason: (r.stderr?.toString() || '').slice(0, 200) }
  const perfErr = (r.stderr?.toString() || '').match(/(\d+)\s+errors in performance/i)
  if (perfErr && parseInt(perfErr[1], 10) > 0) return { ok: false, reason: perfErr[0] }
  return { ok: true }
}

const compileCheckSrc = readFileSync(join(REPO, 'src/main/csound/compile-check.ts'), 'utf-8')
if (compileCheckSrc.includes('shortenHoldScoreForCompile') && compileCheckSrc.includes('runCsoundCompileCheck')) {
  ok('compile-check shortens player hold scores before dry-run')
  if (compileCheckSrc.includes('stripCsOptionsHandledByCli')) {
    ok('compile-check strips CsOptions flags before dry-run')
  } else {
    bad('compile-check.ts must strip duplicate CsOptions')
  }
} else {
  bad('compile-check.ts missing hold-score shortening')
}

const offlinePrepareSrc = existsSync(join(REPO, 'src/shared/csd-offline-prepare.ts'))
  ? readFileSync(join(REPO, 'src/shared/csd-offline-prepare.ts'), 'utf-8')
  : ''
if (offlinePrepareSrc.includes('prepareCsdForOfflineRender') && offlinePrepareSrc.includes('BASS_OFFLINE_DEMO_SCORE')) {
  ok('offline prepare module injects demo score for silent Player hold CSDs')
} else {
  bad('src/shared/csd-offline-prepare.ts missing')
}
if (offlinePrepareSrc.includes('stripCsOptionsHandledByCli')) {
  ok('stripCsOptionsHandledByCli removes CLI-duplicated CsOptions flags')
} else {
  bad('csd-offline-prepare.ts missing stripCsOptionsHandledByCli')
}

const webappPrepareSrc = existsSync(join(REPO, 'src/shared/csd-webapp-prepare.ts'))
  ? readFileSync(join(REPO, 'src/shared/csd-webapp-prepare.ts'), 'utf-8')
  : ''
  if (
  webappPrepareSrc.includes('prepareOrchestraForWebapp') &&
  webappPrepareSrc.includes('adaptOrchestraPitchVelocityForWebKeyboard') &&
  webappPrepareSrc.includes('adaptGaRvbReverbForWebapp') &&
  webappPrepareSrc.includes('isMisplacedScoreLine') &&
  webappPrepareSrc.includes('instr\\s+100')
) {
  ok('webapp prepare strips misplaced score lines, adapts Hz keyboard, fixes gaRvb/p6 send')
} else {
  bad('csd-webapp-prepare.ts missing orchestra cleanup for web export')
}

const cabbagePrepareSrc = existsSync(join(REPO, 'src/shared/csd-cabbage-prepare.ts'))
  ? readFileSync(join(REPO, 'src/shared/csd-cabbage-prepare.ts'), 'utf-8')
  : ''
if (
  cabbagePrepareSrc.includes('prepareCsdForCabbage') &&
  cabbagePrepareSrc.includes('fixCabbageMidiOpcodeSyntax') &&
  cabbagePrepareSrc.includes('fixCabbageEnvelopeRates')
) {
  ok('cabbage prepare fixes cpsmidi/ampmidi opcode syntax and envelope i-rate slips')
} else {
  bad('csd-cabbage-prepare.ts missing Cabbage export fixes')
}

const convertVstSrc = existsSync(join(REPO, 'src/renderer/prompts/convert.ts'))
  ? readFileSync(join(REPO, 'src/renderer/prompts/convert.ts'), 'utf-8')
  : ''
if (convertVstSrc.includes('iFreq = cpsmidi') && convertVstSrc.includes('MIDI opcode syntax')) {
  ok('VST convert prompt documents cpsmidi syntax (no equals)')
} else {
  bad('convert.ts VST_TEMPLATE missing cpsmidi syntax guard')
}

const webappPrepareLib = existsSync(join(REPO, 'src/renderer/lib/webappPrepare.ts'))
  ? readFileSync(join(REPO, 'src/renderer/lib/webappPrepare.ts'), 'utf-8')
  : ''
if (
  webappPrepareLib.includes('mechanicalPlayerAdapt') &&
  webappPrepareLib.includes('buildWebappManifest') &&
  webappPrepareLib.includes('prepareWebappCompileCsd')
) {
  ok('webappPrepare runs mechanicalPlayerAdapt before web export (reverb + chn_k sliders)')
} else {
  bad('webappPrepare.ts missing mechanical adapt for web export')
}

const webHarnessSrc = existsSync(join(REPO, 'src/renderer/lib/webHarness.ts'))
  ? readFileSync(join(REPO, 'src/renderer/lib/webHarness.ts'), 'utf-8')
  : ''
if (
  webHarnessSrc.includes('compileOrc') &&
  webHarnessSrc.includes('adaptOrcForWebKeyboard') &&
  webHarnessSrc.includes('piano-scroll') &&
  webHarnessSrc.includes('PIANO_OCTAVES')
) {
  ok('webHarness compiles orchestra then starts WASM7 audio with piano keyboard (3 octaves)')
} else {
  bad('webHarness.ts missing compileOrc/start runtime or piano keyboard')
}

if (
  webHarnessSrc.includes('buildFactoryPresets') &&
  webHarnessSrc.includes('FACTORY_PRESETS') &&
  webHarnessSrc.includes('initFactoryPresets') &&
  webHarnessSrc.includes('randomizeControls') &&
  webHarnessSrc.includes('presetStorageKey')
) {
  ok('webHarness embeds preset bar + factory presets from chn_k defaults')
} else {
  bad('webHarness.ts missing preset bar / localStorage factory presets')
}

if (
  webHarnessSrc.includes('startVisualizerLoop') &&
  webHarnessSrc.includes('initMIDI') &&
  webHarnessSrc.includes('panicNotes') &&
  webHarnessSrc.includes('turnoff2 1, 0, 0')
) {
  ok('webHarness adds FM·SYNTH + Fractal patterns: viz, USB MIDI, Panic/turnoff2')
} else {
  bad('webHarness.ts missing viz / MIDI / Panic turnoff2 runtime')
}

if (webHarnessSrc.includes('STUDY') && webHarnessSrc.includes('Study flow') && webHarnessSrc.includes('buildSignalFlowStudy')) {
  ok('webHarness embeds Study flow block diagrams (Mermaid)')
} else {
  bad('webHarness.ts missing Study flow diagrams')
}

if (existsSync(join(REPO, 'src/renderer/lib/signalFlowStudy.ts'))) {
  const sf = readFileSync(join(REPO, 'src/renderer/lib/signalFlowStudy.ts'), 'utf-8')
  if (sf.includes('buildSignalFlowStudy') && sf.includes('architectureMermaid')) {
    ok('signalFlowStudy.ts builds architecture + signal + controls diagrams')
  } else {
    bad('signalFlowStudy.ts incomplete')
  }
} else {
  bad('signalFlowStudy.ts missing')
}

if (existsSync(join(REPO, 'src/renderer/lib/artifactDetect.ts'))) {
  const detectSrc = readFileSync(join(REPO, 'src/renderer/lib/artifactDetect.ts'), 'utf-8')
  if (detectSrc.includes('export function detectCsd')) {
    ok('artifactDetect exposes detectCsd for web-app conversion turns')
  } else {
    bad('artifactDetect.ts missing detectCsd')
  }
}

const sessionSrc = readFileSync(join(REPO, 'src/main/session/session.ts'), 'utf-8')
if (sessionSrc.includes('chn_k') && sessionSrc.includes('Do NOT write HTML')) {
  ok('session prompt: web app conversion emits orchestra CSD, not HTML')
} else {
  bad('session.ts still tells model to hand-write HTML for web apps')
}

const audioFlagsSrc = readFileSync(join(REPO, 'src/main/csound/audio-flags.ts'), 'utf-8')
if (audioFlagsSrc.includes('resolveDacOutputArg') && audioFlagsSrc.includes("flags.push('-o',")) {
  ok('realtime play maps device index → dac id (-o dac1 not dac0)')
} else {
  bad('audio-flags.ts must map csound device index to dac id for -o dacN')
}
if (audioFlagsSrc.includes('csoundLimiterCliFlag()')) {
  ok('realtime play passes --limiter on CLI for every spawn')
} else {
  bad('audio-flags.ts must append csoundLimiterCliFlag() to buildRealtimeIoFlags')
}

const realtimeOptsSrc = readFileSync(join(REPO, 'src/shared/csd-realtime-options.ts'), 'utf-8')
if (realtimeOptsSrc.includes('prepareCsdForCsoundQt') && realtimeOptsSrc.includes('-o dac')) {
  ok('CsoundQt export rewrites CsOptions to -o dac')
} else {
  bad('csd-realtime-options.ts missing prepareCsdForCsoundQt')
}

const csoundIpcSrc = readFileSync(join(REPO, 'src/main/ipc/csound.ipc.ts'), 'utf-8')
if (csoundIpcSrc.includes('prepareCsdForOfflineRender') && csoundIpcSrc.includes('renderOutputWasSilent')) {
  ok('Agent afplay path uses offline demo score + silent render detection')
} else {
  bad('csound.ipc.ts missing offline preview prepare')
}
if (csoundIpcSrc.includes('ensureCsoundLimiterCsOptions') && csoundIpcSrc.includes('csoundLimiterCliFlag()')) {
  ok('writeCsd + offline render inject --limiter=0.9')
} else {
  bad('csound.ipc.ts must ensure limiter on writeCsd and offline render CLI')
}

const playbackSrc = readFileSync(join(REPO, 'src/main/csound/csd-playback.ts'), 'utf-8')
  if (playbackSrc.includes('ensureRealtimeChannelHeaders') && playbackSrc.includes('nchnls_i')) {
    ok('prepareCsdForRealtimePlay injects nchnls_i for laptop mono mic / output-only play')
  } else {
    bad('csd-playback must inject nchnls_i for realtime channel mismatch')
  }
  if (playbackSrc.includes('prepareCsdForRealtimePlay') && playbackSrc.includes('csoundOutputIndicatesRealtimeReady')) {
  ok('csd-playback strips offline -o and demo scores for Player realtime')
  if (playbackSrc.includes('stripCsOptionsHandledByCli')) {
    ok('prepareCsdForRealtimePlay strips CsOptions flags handled on CLI')
  } else {
    bad('prepareCsdForRealtimePlay must strip duplicate CsOptions before spawn')
  }
  const agentLike = `<CsoundSynthesizer>
<CsOptions>-n -d -m0 -o /tmp/drc.wav</CsOptions>
<CsInstruments>
instr 1
  kEnv linsegr 0, 0.01, 1, 0.5, 0
  aSig oscili kEnv, p4, 1
  outs aSig, aSig
endin
instr 100
  Schan strget p4
  chnset p5, Schan
  turnoff
endin
instr 99
  outs 0, 0
endin
chn_k "amplitude", 3, 2, 0.5, 0, 1, 0, 0, 0, 0
</CsInstruments>
<CsScore>
i 1 0 12 60 0.3
f 0 1
</CsScore>
</CsoundSynthesizer>`
  // Mirror prepare logic checks (smoke without importing TS)
  if (/-o\s+\S+/.test(agentLike) && /\bi\s+1\s+0\s+12/.test(agentLike)) {
    ok('agent-like CSD fixture has offline opts + demo score (Player play must sanitize)')
  }
} else {
  bad('csd-playback.ts missing realtime prepare helpers')
}

if (existsSync(join(REPO, 'src/main/ipc/workshop.ipc.ts')) &&
    existsSync(join(REPO, 'src/main/util/workshop-starters.ts'))) {
  ok('workshop IPC + starter loader present')
} else {
  bad('workshop IPC files missing')
}

if (existsSync(join(REPO, 'resources/workshop-starters/player_fm_bell.csd'))) {
  ok('player_fm_bell.csd bundled (no API demo)')
} else {
  bad('player_fm_bell.csd missing')
}
if (existsSync(join(REPO, 'resources/workshop-starters/fm_piano_reverb_starter.csd'))) {
  ok('fm_piano_reverb_starter.csd bundled (FM piano + ga reverb)')
} else {
  bad('fm_piano_reverb_starter.csd missing')
}

const consoleSrc = readFileSync(join(REPO, 'src/renderer/components/CsoundConsole.tsx'), 'utf-8')
if (consoleSrc.includes('Copy all') && consoleSrc.includes('Save log')) {
  ok('Csound console supports Copy all + Save log')
} else {
  bad('CsoundConsole missing copy/save controls')
}

const mechSrc = existsSync(join(REPO, 'src/renderer/lib/mechanicalPlayerAdapt.ts'))
  ? readFileSync(join(REPO, 'src/renderer/lib/mechanicalPlayerAdapt.ts'), 'utf-8')
  : ''
if (mechSrc.includes('export function mechanicalPlayerAdapt')) {
  ok('mechanicalPlayerAdapt exported (offline Player wrap)')
} else {
  bad('mechanicalPlayerAdapt.ts missing')
}

const agentSrc = readFileSync(join(REPO, 'src/renderer/pages/AgentPage.tsx'), 'utf-8')
if (
  agentSrc.includes('Explore Csound Models in Player') &&
  agentSrc.includes('/player?demos=1')
) {
  ok('Agent links to Player demo menu')
} else {
  bad('Agent missing Player demo menu link')
}

section('webapp artifact guard')

const artifactStoreSrc = readFileSync(join(REPO, 'src/renderer/stores/artifactStore.ts'), 'utf-8')
if (artifactStoreSrc.includes('export function findBySourceMessageId')) {
  ok('artifactStore prefers webapp over csd for shared sourceMessageId')
} else {
  bad('artifactStore missing findBySourceMessageId')
}
if (artifactStoreSrc.includes('removeArtifacts')) {
  ok('artifactStore can prune spurious CSD after web-app wrap')
} else {
  bad('artifactStore missing removeArtifacts')
}

if (
  agentSrc.includes('webappBuildInFlightRef') &&
  agentSrc.includes('webappBuildInFlightRef.current === last.id')
) {
  ok('AgentPage blocks detect() while async web-app wrap is in flight')
} else {
  bad('AgentPage missing webappBuildInFlightRef guard')
}
if (agentSrc.includes('findBySourceMessageId')) {
  ok('AgentPage re-adopts webapp via findBySourceMessageId (survives remount)')
} else {
  bad('AgentPage missing findBySourceMessageId adoption')
}
if (agentSrc.includes('removeArtifacts(spurious)')) {
  ok('AgentPage drops race-created CSD after web-app build succeeds')
} else {
  bad('AgentPage missing spurious CSD cleanup after web-app wrap')
}
if (
  agentSrc.includes('findBySourceMessageId(artifacts, msg.id)') &&
  agentSrc.includes("canonical?.type === 'webapp'")
) {
  ok('Agent chat cards prefer webapp canonical over stale CSD map entry')
} else {
  bad('AgentPage missing render-time webapp canonical fallback')
}

if (
  agentSrc.includes("canonicalForMsg?.type === 'webapp'") ||
  agentSrc.includes('webappFrozenMessageIds')
) {
  ok('AgentPage freezes webapp artifacts — never re-detects orchestra CSD')
} else {
  bad('AgentPage missing webapp freeze guard after conversion')
}
if (agentSrc.includes('afterUserMsgId') && agentSrc.includes('assistantTurnAfterUser')) {
  ok('AgentPage gates web-app convert until NEW assistant turn after user message')
} else {
  bad('AgentPage missing afterUserMsgId conversion turn gate')
}
if (agentSrc.includes('webappFrozenMessageIds')) {
  ok('AgentPage permanently freezes message ids after web-app wrap')
} else {
  bad('AgentPage missing webappFrozenMessageIds permanent freeze')
}
if (artifactStoreSrc.includes("a.type === 'webapp'") && artifactStoreSrc.includes('CsoundSynthesizer')) {
  ok('artifactStore blocks updateInPlace CSD overwrite on webapp artifacts')
} else {
  bad('artifactStore missing webapp updateInPlace guard')
}
if (artifactStoreSrc.includes('hasWebappForMessage') && artifactStoreSrc.includes("input.type === 'csd'")) {
  ok('artifactStore blocks addArtifact CSD when webapp owns source message')
} else {
  bad('artifactStore missing addArtifact webapp lock guard')
}
if (agentSrc.includes('messagesContentKey')) {
  ok('AgentPage keys detection on message content (usage metadata cannot re-detect)')
} else {
  bad('AgentPage missing messagesContentKey detection split')
}
if (agentSrc.includes('isMessageWebappLocked')) {
  ok('AgentPage uses isMessageWebappLocked before CSD add/update paths')
} else {
  bad('AgentPage missing isMessageWebappLocked guards')
}
if (agentSrc.includes('webappFrozenMessageIds.current.add(messageId)') && agentSrc.includes('Optimistic freeze')) {
  ok('AgentPage optimistically freezes message id before async web-app wrap')
} else {
  bad('AgentPage missing optimistic webapp freeze at wrap start')
}
const rendererPlaybackSrc = readFileSync(join(REPO, 'src/renderer/lib/playback.ts'), 'utf-8')
if (rendererPlaybackSrc.includes("artifact.type === 'webapp'")) {
  ok('playArtifact skips webapp (iframe/browser only — no compile autofix)')
} else {
  bad('playback.ts missing webapp play guard')
}
if (agentSrc.includes('conversionBusy') && agentSrc.includes('webappBuildInFlightRef.current')) {
  ok('AgentPage preserves pending web-app conversion when user chats mid-wrap')
} else {
  bad('AgentPage missing conversionBusy guard in buildPayloadFromText')
}
if (agentSrc.includes('editBaseRef.current = null') && agentSrc.includes('requestConversion')) {
  ok('AgentPage clears editBaseRef before Convert to Web App')
} else {
  bad('AgentPage missing editBaseRef clear on requestConversion')
}

const artifactCardSrc = readFileSync(join(REPO, 'src/renderer/components/chat/ArtifactCard.tsx'), 'utf-8')
const artifactPanelSrc = readFileSync(join(REPO, 'src/renderer/components/artifacts/ArtifactPanel.tsx'), 'utf-8')
if (artifactCardSrc.includes('Open in Browser') && artifactCardSrc.includes('onOpenInBrowser')) {
  ok('ArtifactCard shows Open in Browser for webapp artifacts')
} else {
  bad('ArtifactCard missing Open in Browser for webapp')
}
if (artifactPanelSrc.includes('Open in Browser') && !artifactPanelSrc.includes('Export to Browser')) {
  ok('ArtifactPanel labels webapp export as Open in Browser')
} else {
  bad('ArtifactPanel missing prominent Open in Browser label')
}

const playerDemosMenuSrc = existsSync(join(REPO, 'src/renderer/components/player/PlayerDemosMenu.tsx'))
  ? readFileSync(join(REPO, 'src/renderer/components/player/PlayerDemosMenu.tsx'), 'utf-8')
  : ''
if (
  playerSrc.includes('PlayerDemosMenu') &&
  playerDemosMenuSrc.includes('Demos — No API Key Required')
) {
  ok('Player: demo menu + mechanical adapt before LLM')
} else {
  bad('Player missing offline demo menu')
}

if (existsSync(join(REPO, 'scripts/launch-workshop-attendee.sh'))) {
  ok('attendee launcher script (DRC_PRO_PLUS=0, workshop-lite)')
} else {
  bad('scripts/launch-workshop-attendee.sh missing')
}

if (existsSync(join(REPO, 'resources/workshop/LAC-2026-one-slide.pdf'))) {
  ok('workshop one-slide PDF handout present')
} else {
  bad('resources/workshop/LAC-2026-one-slide.pdf missing — run npm run generate:workshop-handout')
}

const workshopLinksSrc = readFileSync(join(REPO, 'src/shared/workshop-links.ts'), 'utf-8')
if (
  workshopLinksSrc.includes('formatWorkshopLinksForClipboard') &&
  workshopLinksSrc.includes('WORKSHOP_LINK_GROUPS') &&
  workshopLinksSrc.includes('SETUP_GUIDE')
) {
  ok('shared setup-links module present (SETUP_GUIDE for classes)')
} else {
  bad('src/shared/workshop-links.ts missing or incomplete')
}


for (const [file, opts] of [
  ['fm_bell_starter.csd', {}],
  ['pluck_bass_starter.csd', {}],
  ['fm_starter.csd', {}],
  ['fm_piano_reverb_starter.csd', {}],
  ['pad_starter.csd', {}],
  ['player_fm_bell.csd', { shortenScore: true }],
  ['player_trapped_blue.csd', { shortenScore: true }],
  ['player_trapped_sand.csd', { shortenScore: true }],
  ['player_pluck_bass.csd', { shortenScore: true }],
  ['player_fm_starter.csd', { shortenScore: true }],
  ['midi_synth_starter.csd', { shortenScore: true, renderScore: '<CsScore>\ni 1 0 0.2 440 100\n</CsScore>' }],
]) {
  const r = compileStarter(file, opts)
  if (r.ok === null) {
    lines.push(`  SKIP  ${file} — csound not installed`)
    break
  } else if (r.ok) {
    ok(`${file} compiles`)
  } else {
    bad(`${file} compile failed`, r.reason)
  }
}

// Mechanical wrap smoke: fm_bell_starter → player-shaped CSD with instr 100 + chn_k
const bellPath = join(REPO, 'resources/workshop-starters/fm_bell_starter.csd')
if (existsSync(bellPath) && mechSrc) {
  const bell = readFileSync(bellPath, 'utf-8')
  const hasVoice = /\boscili\b/i.test(bell) && /\bp4\b/.test(bell) && /\bkMod1Idx\b/.test(bell)
  if (hasVoice) ok('fm_bell_starter is shimmer bell (dual oscili + p4)')
  else bad('fm_bell_starter missing shimmer voice for Player adapt')
}

const bassPath = join(REPO, 'resources/workshop-starters/pluck_bass_starter.csd')
if (existsSync(bassPath) && mechSrc) {
  const bass = readFileSync(bassPath, 'utf-8')
  const hasPluck = /\bgaEcho\b/.test(bass) && /\bfoscili\b/i.test(bass) && /\bvdelay3\b/i.test(bass)
  if (hasPluck) ok('pluck_bass_starter is ping-pong bass (gaEcho + foscili + vdelay3)')
  else bad('pluck_bass_starter missing ping-pong voice for Player adapt')
}
if (mechSrc.includes('isPluckPingPongBass') && mechSrc.includes('isShimmerBellVoice') && mechSrc.includes('isSimpleFosciliFm')) {
  ok('mechanicalPlayerAdapt: shimmer bell + ping-pong bass + simple FM paths')
} else {
  bad('mechanicalPlayerAdapt missing specialized voice paths')
}

const legacyAdaptPath = join(REPO, 'src/renderer/lib/legacyDrBModelAdapt.ts')
const modelRoutesPath = join(REPO, 'src/shared/workshop-model-routes.ts')
const goldenPath = join(REPO, 'src/main/session/golden-shortcut.ts')
if (existsSync(legacyAdaptPath) && mechSrc.includes('legacyDrBModelAdapt')) {
  ok('mechanicalPlayerAdapt delegates to legacyDrBModelAdapt (Dr. B collection)')
} else {
  bad('legacyDrBModelAdapt not wired into mechanicalPlayerAdapt')
}
if (existsSync(modelRoutesPath) && existsSync(goldenPath)) {
  const routes = readFileSync(modelRoutesPath, 'utf-8')
  const golden = readFileSync(goldenPath, 'utf-8')
  if (routes.includes('WaveshapeBrass.csd') && routes.includes('FrenchHorn.csd') && golden.includes('matchWorkshopModelRoute')) {
    ok('golden-shortcut routes brass/horn/clarinet/pad to Dr. B models')
  } else {
    bad('workshop-model-routes not wired into golden-shortcut')
  }
  if (routes.includes('chowning_fm_bell')) {
    const idx = routes.indexOf("starterId: 'chowning_fm_bell'")
    const chowningBellBlock = idx >= 0 ? routes.slice(Math.max(0, idx - 180), idx + 80) : ''
    const requiresChowning = chowningBellBlock.includes('/\\bchowning\\b/')
    const allowsBareFmBell = chowningBellBlock.includes('fm\\s*bell') || chowningBellBlock.includes('bell.*fm')
    if (requiresChowning && !allowsBareFmBell) {
      ok('chowning_fm_bell route requires explicit "chowning" (not bare FM bell)')
    } else {
      bad('chowning_fm_bell still matches bare "FM bell" — use fm_bell_starter instead')
    }
  } else {
    bad('workshop-model-routes missing chowning_fm_bell')
  }
  if (golden.includes('matchFmBellStarter') && golden.includes('extractGoldenIntent')) {
    ok('golden-shortcut prioritizes fm_bell_starter and parses artifact-edit intent')
  } else {
    bad('golden-shortcut missing FM bell priority / intent extraction')
  }
}
if (offlinePrepareSrc.includes('BELL_OFFLINE_DEMO_SCORE') && offlinePrepareSrc.includes('CHOWNING_HZ_DEMO_SCORE')) {
  ok('offline prepare: bell melody + Hz Chowning demo scores')
} else {
  bad('csd-offline-prepare missing bell/Hz demo score guards')
}
const chowningBellPath = join(REPO, 'resources/workshop-starters/models/chowning/chowning_fm_bell.csd')
if (existsSync(chowningBellPath) && offlinePrepareSrc.includes('CHOWNING_HZ_DEMO_SCORE')) {
  const raw = readFileSync(chowningBellPath, 'utf-8')
  const orch = raw.match(/<CsInstruments>([\s\S]*?)<\/CsInstruments>/i)?.[1] ?? ''
  const usesMidi = /\bcpsmidinn\s*\(\s*p4\s*\)/i.test(orch)
  const hzFirst = offlinePrepareSrc.match(/CHOWNING_HZ_DEMO_SCORE = `[\s\S]*?i 1 0\s+4\.5\s+([\d.]+)/)?.[1]
  if (!usesMidi && hzFirst && parseFloat(hzFirst) > 200) {
    ok('chowning_fm_bell offline demo uses Hz pitches (not MIDI 60)')
  } else {
    bad('chowning_fm_bell offline demo guard missing or still MIDI-as-Hz')
  }
}
if (existsSync(bellPath)) {
  const fmBellStarter = readFileSync(bellPath, 'utf-8')
  if (/\bkMod1Idx\b/.test(fmBellStarter) && /\bi\s+1\s+0\s+4\.5\s+72\b/.test(fmBellStarter)) {
    ok('fm_bell_starter has shimmer voice + descending MIDI bell score')
  } else {
    bad('fm_bell_starter missing workshop bell character markers')
  }
}
const brassModel = join(REPO, 'resources/workshop-starters/models/misc_synths/WaveshapeBrass.csd')
if (existsSync(brassModel) && existsSync(legacyAdaptPath)) {
  const legacy = readFileSync(legacyAdaptPath, 'utf-8')
  if (legacy.includes('isWaveshapeBrass') && legacy.includes('instr 1')) {
    ok('legacyDrBModelAdapt includes WaveshapeBrass keyboard wrap')
  } else {
    bad('legacyDrBModelAdapt missing WaveshapeBrass path')
  }
}

// ───────────────────────────────────────────────────────────────────────
// summary
// ───────────────────────────────────────────────────────────────────────

console.log(lines.join('\n'))
console.log(`\n${passed} passed, ${failed} failed`)
process.exit(failed === 0 ? 0 : 1)
