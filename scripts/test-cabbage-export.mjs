#!/usr/bin/env node
/**
 * Headless smoke test for Cabbage export launch path (no Electron UI).
 *   node scripts/test-cabbage-export.mjs
 */
import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { homedir } from 'node:os'
import { execFile } from 'node:child_process'
import { promisify } from 'node:util'

const execFileAsync = promisify(execFile)
const REPO = dirname(dirname(fileURLToPath(import.meta.url)))

let passed = 0
let failed = 0
function ok(msg) { console.log('  PASS', msg); passed++ }
function bad(msg, detail = '') { console.log('  FAIL', msg, detail); failed++ }

async function loadPrepare() {
  const mod = await import(join(REPO, 'src/shared/csd-cabbage-prepare.ts'))
  return mod.prepareCsdForCabbage
}

function globNames(dir, prefix, suffix) {
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

async function detectMacCabbage() {
  for (const dir of ['/Applications', join(homedir(), 'Applications')]) {
    const apps = globNames(dir, 'cabbage', '.app')
    if (apps.length) return apps.sort()[0]
  }
  try {
    const { stdout } = await execFileAsync('mdfind', ['-name', 'Cabbage'])
    const hit = stdout
      .split('\n')
      .map((s) => s.trim())
      .filter((p) => p.toLowerCase().endsWith('.app'))
      .filter((p) => p.split('/').pop().toLowerCase().startsWith('cabbage'))
      .find((p) => existsSync(p))
    return hit ?? null
  } catch {
    return null
  }
}

async function openWithApp(app, filePath) {
  try {
    await execFileAsync('open', ['-a', app, filePath])
    return true
  } catch {
    return false
  }
}

console.log('\n[cabbage-export] macOS launch smoke\n')

const samplePath = join(homedir(), 'Documents', 'DrC', 'cabbage', 'convert-to-cabbage.csd')
if (existsSync(samplePath)) {
  ok(`existing export sample: ${samplePath}`)
} else {
  bad('no prior Cabbage export at ~/Documents/DrC/cabbage/convert-to-cabbage.csd')
}

const cabbageApp = await detectMacCabbage()
if (cabbageApp && existsSync(cabbageApp)) {
  ok(`detected Cabbage: ${cabbageApp}`)
} else {
  bad('Cabbage.app not found — install Cabbage or set path in Settings')
}

// Mirror export.ipc safeFileName + write
const title = 'Test Export To Cabbage'
const base = title.replace(/[^a-zA-Z0-9_-]+/g, '-').replace(/^-+|-+$/g, '').toLowerCase()
const outName = (base || 'untitled') + '.csd'
const outDir = join(homedir(), 'Documents', 'DrC', 'cabbage')
if (!existsSync(outDir)) mkdirSync(outDir, { recursive: true })
const outPath = join(outDir, outName)

const minimal = `<Cabbage>
form caption("Test") size(400, 200) pluginId("Dcb1") guiMode("queue")
keyboard bounds(10, 10, 380, 120)
</Cabbage>
<CsoundSynthesizer>
<CsOptions>
-n -d -+rtmidi=NULL -M0
</CsOptions>
<CsInstruments>
sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1
giSine ftgen 0, 0, 4096, 10, 1
massign 0, 1
instr 1
  iFreq cpsmidi
  iVel ampmidi 1
  aSig oscili iVel * 0.3, iFreq, giSine
  outs aSig, aSig
endin
</CsInstruments>
<CsScore>
f0 3600
</CsScore>
</CsoundSynthesizer>
`

if (!minimal.includes('<Cabbage>')) bad('sanity: minimal CSD missing <Cabbage>')
else ok('minimal Cabbage CSD template valid')

writeFileSync(outPath, minimal, 'utf-8')
if (existsSync(outPath)) ok(`wrote ${outPath}`)
else bad(`failed to write ${outPath}`)

if (cabbageApp && existsSync(outPath)) {
  const launched = await openWithApp(cabbageApp, outPath)
  if (launched) ok(`open -a "${cabbageApp}" ${outName}`)
  else bad('open -a with detected path failed')
}

// Fallback name "Cabbage" (without version) — documents whether macOS alias works
if (existsSync(outPath)) {
  const aliasOk = await openWithApp('Cabbage', outPath)
  if (aliasOk) ok('open -a "Cabbage" (generic name) also works')
  else console.log('  INFO open -a "Cabbage" failed — versioned .app path is required')
}

// Source contract checks (same as smoke-test expectations)
const exportSrc = readFileSync(join(REPO, 'src/main/ipc/export.ipc.ts'), 'utf-8')
if (exportSrc.includes("export:openInCabbage") && exportSrc.includes('<Cabbage>')) {
  ok('export.ipc.ts openInCabbage handler present')
} else {
  bad('export.ipc.ts missing openInCabbage or <Cabbage> guard')
}

const launchSrc = readFileSync(join(REPO, 'src/main/util/launch-external.ts'), 'utf-8')
if (launchSrc.includes('openWithApp') && launchSrc.includes('execFile')) {
  ok('launch-external awaits open exit code (not fire-and-forget spawn)')
} else {
  bad('launch-external.ts missing awaited openWithApp')
}

const convertSrc = readFileSync(join(REPO, 'src/renderer/prompts/convert.ts'), 'utf-8')
if (convertSrc.includes('iFreq = cpsmidi') && convertSrc.includes('WRONG')) {
  ok('VST_TEMPLATE warns against iFreq = cpsmidi')
} else {
  bad('VST_TEMPLATE missing cpsmidi syntax guard')
}
if (convertSrc.includes('expsegr') && convertSrc.includes('i-rate')) {
  ok('VST_TEMPLATE documents i-rate envelope args')
} else {
  bad('VST_TEMPLATE missing envelope i-rate guidance')
}

const prepareCsdForCabbage = await loadPrepare()
const broken = existsSync(samplePath) ? readFileSync(samplePath, 'utf-8') : ''
if (broken.includes('iFreq = cpsmidi')) {
  const fixed = prepareCsdForCabbage(broken)
  if (fixed.includes('iFreq cpsmidi') && !fixed.includes('iFreq = cpsmidi')) {
    ok('prepareCsdForCabbage fixes iFreq = cpsmidi')
  } else {
    bad('prepareCsdForCabbage did not fix cpsmidi assignment')
  }
}

console.log(`\n[cabbage-export] ${passed} passed, ${failed} failed\n`)
process.exit(failed ? 1 : 0)
