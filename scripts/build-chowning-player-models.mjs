#!/usr/bin/env node
/**
 * Split combined Chowning FM orchestra CSDs into individual Player-ready models
 * with classic carrier:modulator ratios preserved.
 *
 *   node scripts/build-chowning-player-models.mjs
 */

import { readFileSync, writeFileSync, mkdirSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const REPO = dirname(dirname(fileURLToPath(import.meta.url)))
const OUT_DIR = join(REPO, 'resources/workshop-starters/models/chowning')
const MANIFEST_PATH = join(REPO, 'resources/workshop-starters/chowning-player-demos.json')

const REF_HZ = 440

const CSOPTIONS = `<CsOptions>
-o dac
-d
--limiter=0.9
</CsOptions>`

const PLAYER_TAIL = `
instr 100
  Schan strget p4
  iVal  = p5
  chnset iVal, Schan
  turnoff
endin

instr 99
  kMix  chnget "reverbMix"
  kSize chnget "reverbSize"
  aInL  chnget "revL"
  aInR  chnget "revR"
  aL, aR reverbsc aInL, aInR, kSize, 9000
  outs aL * kMix, aR * kMix
  chnclear "revL"
  chnclear "revR"
endin
`

const CHN_STD = `
chn_k "amplitude", 3, 2, 0.55, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "reverbMix", 3, 2, 0.28, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.82, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"
chnset 0.55, "amplitude"
chnset 0.28, "reverbMix"
chnset 0.82, "reverbSize"

giMaster = 0.28
`

const FT_TABLES = `
giSine  ftgen 0, 0, 1024, 10, 1
giBellIdx ftgen 0, 0, 1024, 5, 1, 1000, 0.01
giWoodIdx ftgen 0, 0, 1024, 8, 0.8, 50, 1, 100, 0.7, 824, 0
giWoodAmp ftgen 0, 0, 512, 7, 1, 100, 0
giBrassEnv ftgen 0, 0, 1024, 7, 0, 100, 1, 124, 0.7, 600, 0.7, 100, 0
giClarEnv ftgen 0, 0, 1024, 7, 0, 100, 1, 824, 1, 100, 0
`

/** Classic Chowning 2-op presets from FM_Bell_Bass_Clairnet_Wood.csd score @ pch 8.00 */
const TWO_OP_PRESETS = [
  {
    id: 'chowning_fm_bell',
    title: 'FM Nasty Lead 1',
    filename: 'chowning_fm_bell.csd',
    demoOrder: 350,
    fc: 200,
    fm: 280,
    peak: 10,
    idxFn: 'giBellIdx',
    ampFn: 'giBellIdx',
    carAmp: 0.38,
    description: 'Classic 5:7 inharmonic FM nasty lead — Chowning/Mathews ratios (fc=200 fm=280 @ A440)',
  },
  {
    id: 'chowning_fm_bass',
    title: 'FM Pad',
    filename: 'chowning_fm_bass.csd',
    demoOrder: 351,
    fc: 440,
    fm: 440,
    peak: 5,
    idxFn: 'giBrassEnv',
    ampFn: 'giBrassEnv',
    carAmp: 0.42,
    description: '1:1 FM pad timbre — Chowning brasslike preset (fc=fm=440)',
  },
  {
    id: 'chowning_fm_wood',
    title: 'FM Nasty Lead 2',
    filename: 'chowning_fm_wood.csd',
    demoOrder: 352,
    fc: 80,
    fm: 55,
    peak: 25,
    idxFn: 'giWoodIdx',
    ampFn: 'giWoodAmp',
    carAmp: 0.48,
    description: '16:11 wood-drum FM ratio — Chowning wood preset (fc=80 fm=55 @ A440)',
  },
]

function buildTwoOpCsd(preset) {
  const fcR = preset.fc / REF_HZ
  const fmR = preset.fm / REF_HZ
  return `<CsoundSynthesizer>
${CSOPTIONS}
<CsInstruments>
sr = 44100
ksmps = 64
nchnls = 2
0dbfs = 1

${FT_TABLES}

giFcRatio = ${fcR}
giFmRatio = ${fmR}
giPeak    = ${preset.peak}
giCarAmp  = ${preset.carAmp}

${CHN_STD}

instr 1
  iFreq = p4
  iVel  = p5 * chnget("amplitude")
  iDur  = p3 < 0 ? 8 : p3
  ifc   = iFreq * giFcRatio
  ifm   = iFreq * giFmRatio
  id    = giPeak * ifm
  iamp  = iVel * giCarAmp
  km    oscil id, 1/iDur, ${preset.idxFn}
  kc    oscil iamp, 1/iDur, ${preset.ampFn}
  am    oscil km, ifm, giSine
  ac    oscil kc, ifc + am, giSine
  kGate linsegr 1, 0.002, 1, max(iDur - 0.02, 0.02), 0.35, 0.06, 0
  aOut  = tanh(ac * kGate * giMaster * 1.4)
  chnmix aOut, "revL"
  chnmix aOut, "revR"
  outs aOut, aOut
endin
${PLAYER_TAIL}
</CsInstruments>
<CsScore>
i 99 0 36000
f 0 36000
</CsScore>
</CsoundSynthesizer>
`
}

function extractInstr(source, num) {
  const block = source.match(/<CsInstruments>([\s\S]*?)<\/CsInstruments>/i)?.[1] ?? ''
  const re = new RegExp(`^\\s*instr\\s+${num}\\b[\\s\\S]*?^\\s*endin\\s*$`, 'im')
  const m = block.match(re)
  if (!m) throw new Error(`instr ${num} not found`)
  return m[0].replace(/^\s*instr\s+\d+\s*/i, '').replace(/\s*endin\s*$/i, '').trim()
}

function adaptWilliamsBody(body) {
  let b = body
  b = b.replace(/\bcpspch\s*\(\s*p4\s*\)/gi, 'p4')
  b = b.replace(/\boctpch\s*\(\s*p4\s*\)/gi, 'octcps(p4)')
  b = b.replace(/\bampdb\s*\(\s*p5\s*\)/gi, '(p5 * chnget("amplitude"))')
  b = b.replace(/^\s*outs\s+[^\n]+$/gim, '')
  return b
}

function outputTail(adaptedBody) {
  if (/\balt\s*=/.test(adaptedBody) && /\bart\s*=/.test(adaptedBody)) {
    return `
  kGate linsegr 1, 0.002, 1, max(iDur - 0.04, 0.02), 0.45, 0.08, 0
  aL = tanh(alt * kGate * giMaster * 1.5)
  aR = tanh(art * kGate * giMaster * 1.5)
  chnmix aL, "revL"
  chnmix aR, "revR"
  outs aL, aR`
  }
  if (/\bgalt\s*=/.test(adaptedBody) && /\bgart\s*=/.test(adaptedBody)) {
    return `
  kGate linsegr 1, 0.002, 1, max(iDur - 0.04, 0.02), 0.45, 0.08, 0
  galt = tanh(galt * kGate * giMaster * 1.5)
  gart = tanh(gart * kGate * giMaster * 1.5)
  chnmix galt, "revL"
  chnmix gart, "revR"
  outs galt, gart`
  }
  if (/\basig\s*=/.test(adaptedBody)) {
    return `
  kGate linsegr 1, 0.002, 1, max(iDur - 0.04, 0.02), 0.45, 0.08, 0
  aL = tanh(asig * sqrt(0.5) * kGate * giMaster * 1.5)
  aR = tanh(asig * sqrt(0.5) * kGate * giMaster * 1.5)
  chnmix aL, "revL"
  chnmix aR, "revR"
  outs aL, aR`
  }
  throw new Error('Could not detect Williams instrument output variables')
}

function buildWilliamsCsd({ body, ftBlock, extraGlobals = '' }) {
  const voice = adaptWilliamsBody(body)
  const tail = outputTail(voice)
  return `<CsoundSynthesizer>
${CSOPTIONS}
<CsInstruments>
sr = 44100
ksmps = 64
nchnls = 2
0dbfs = 1

${extraGlobals}
${ftBlock}

${CHN_STD}

instr 1
  iDur = p3 < 0 ? 8 : p3
${voice
  .split('\n')
  .map((l) => {
    const t = l.trim()
    if (!t) return l
    let line = l.replace(/\bp3\b/g, 'iDur')
    return '  ' + line.trimStart()
  })
  .join('\n')}
${tail}
endin
${PLAYER_TAIL}
</CsInstruments>
<CsScore>
i 99 0 36000
f 0 36000
</CsScore>
</CsoundSynthesizer>
`
}

const WILLIAMS_FT = {
  sitar: `
giSine ftgen 0, 0, 513, 10, 1
giSitarA1 ftgen 0, 0, 513, 7, 0, 64, 1, 64, 0.4, 384, 0.2
giSitarA3 ftgen 0, 0, 513, 7, 0, 64, 0.8, 128, 1, 320, 0.5
giSitarA4 ftgen 0, 0, 513, 7, 0, 64, 1, 448, 0.5
giSitarA5 ftgen 0, 0, 513, 7, 0, 16, 1, 128, 0.3, 368, 0.8
`,
  trumpet: `
giSine ftgen 0, 0, 513, 10, 1
giTrpVib ftgen 0, 0, 513, 8, 0, 128, 0.6, 192, 1, 144, 0.4, 32, 0.3, 16, 0
giTrpPort ftgen 0, 0, 513, 6, 0, 32, 0.9, 32, 1, 456, 0.9
`,
  dsfBrass: `
giDsfCs ftgen 0, 0, 513, 11, 1
giSine ftgen 0, 0, 513, 10, 1
giDsfAdsr ftgen 0, 0, 513, 7, 0, 64, 1, 32, 1, 32, 0.65, 21, 0.75, 85, 0.75, 22, 0.65, 171, 0.5, 85, 0
`,
  dsfClar: `
giDsfCs ftgen 0, 0, 513, 11, 1
giSine ftgen 0, 0, 513, 10, 1
giDsfSlow ftgen 0, 0, 512, 7, 0, 50, 0.4, 100, 0.9, 50, 1, 20, 1, 42, 0.85, 50, 0.5, 100, 0.2, 100, 0
`,
  wood: `
giSine ftgen 0, 0, 513, 10, 1
giWoodAmp ftgen 0, 0, 513, 7, 0, 13, 0.6, 23, 0.9, 25, 1, 17, 0.9, 34, 0.5, 64, 0.2, 84, 0.1, 84, 0.05, 168, 0
giWoodShp ftgen 0, 0, 513, 3, -1, 1, 1, 0.841, -0.707, -0.595, 0.5, 0.42, -0.354, -0.297, 0.25, 0.210
`,
  piano: `
giPianoLo ftgen 0, 0, 513, 10, 0.158, 0.316, 1, 1, 0.282, 0.112, 0.063, 0.079, 0.126, 0.071
giPianoHi ftgen 0, 0, 513, 10, 1, 0.282, 0.089, 0.1, 0.071, 0.089, 0.05
giPianoShort ftgen 0, 0, 513, 7, 1, 190, 0.4, 210, 0.2, 112, 0
giPianoLong ftgen 0, 0, 513, 5, 1, 512, 0.015625
`,
}

const WILLIAMS_PRESETS = [
  {
    id: 'chowning_fm_sitar',
    title: 'FM Keys 1',
    filename: 'chowning_fm_sitar.csd',
    demoOrder: 360,
    instr: 1,
    ft: 'sitar',
    description: 'Williams parallel/stacked FM keys — E.W. Williams Chowning collection',
    patchTables: (body) => {
      return body
        .replace(/\bisnf\s*=\s*2\b/gi, 'isnf = giSine')
        .replace(/\bia1f\s*=\s*11\b/gi, 'ia1f = giSitarA1')
        .replace(/\bia3f\s*=\s*13\b/gi, 'ia3f = giSitarA3')
        .replace(/\bia4f\s*=\s*14\b/gi, 'ia4f = giSitarA4')
        .replace(/\bia5f\s*=\s*15\b/gi, 'ia5f = giSitarA5')
        .replace(/\bsqrt\s*\(\s*p6\s*\)/gi, 'sqrt(0.5)')
        .replace(/\bsqrt\s*\(\s*1\s*-\s*p6\s*\)/gi, 'sqrt(0.5)')
    },
  },
  {
    id: 'chowning_dsf_brass',
    title: 'FM Pad 2',
    filename: 'chowning_dsf_brass.csd',
    demoOrder: 362,
    instr: 3,
    ft: 'dsfBrass',
    description: 'Moorer discrete-summation pad — Williams after Moorer CMJ',
    patchTables: (body) =>
      body
        .replace(/\bicsf\s*=\s*1\b/gi, 'icsf = giDsfCs')
        .replace(/\bisnf\s*=\s*2\b/gi, 'isnf = giSine')
        .replace(/\biampf\s*=\s*p6\b/gi, 'iampf = giDsfAdsr')
        .replace(/\bipan\s*=\s*p7\b/gi, 'ipan = 0.5'),
  },
  {
    id: 'chowning_williams_wood',
    title: 'FM Lead 1',
    filename: 'chowning_williams_wood.csd',
    demoOrder: 364,
    instr: 5,
    ft: 'wood',
    description: 'Wave-shaped ring-mod wood drum after Dodge — Williams Chowning collection',
    patchTables: (body) =>
      body
        .replace(/\bisnf\s*=\s*2\b/gi, 'isnf = giSine')
        .replace(/\biampf\s*=\s*12\b/gi, 'iampf = giWoodAmp')
        .replace(/\bitblf\s*=\s*13\b/gi, 'itblf = giWoodShp')
        .replace(/\bsqrt\s*\(\s*p6\s*\)/gi, 'sqrt(0.5)')
        .replace(/\bsqrt\s*\(\s*1\s*-\s*p6\s*\)/gi, 'sqrt(0.5)'),
  },
]

mkdirSync(OUT_DIR, { recursive: true })

const manifest = []

for (const preset of TWO_OP_PRESETS) {
  const rel = `models/chowning/${preset.filename}`
  const csd = buildTwoOpCsd(preset)
  writeFileSync(join(REPO, 'resources/workshop-starters', rel), csd, 'utf-8')
  manifest.push({
    id: preset.id,
    title: preset.title,
    filename: rel,
    playerReady: true,
    playerDemo: true,
    demoGroup: 'Chowning FM',
    demoOrder: preset.demoOrder,
    description: preset.description,
  })
  console.log('+', rel)
}

const williamsSrc = readFileSync(
  join(REPO, 'resources/workshop-starters/models/chowning/_sources/williams_fm_suite.csd'),
  'utf-8',
)

for (const preset of WILLIAMS_PRESETS) {
  let body = extractInstr(williamsSrc, preset.instr)
  body = preset.patchTables(body)
  const csd = buildWilliamsCsd({
    title: preset.title,
    body,
    ftBlock: WILLIAMS_FT[preset.ft],
  })
  const rel = `models/chowning/${preset.filename}`
  writeFileSync(join(REPO, 'resources/workshop-starters', rel), csd, 'utf-8')
  manifest.push({
    id: preset.id,
    title: preset.title,
    filename: rel,
    playerReady: true,
    playerDemo: true,
    demoGroup: 'Chowning FM',
    demoOrder: preset.demoOrder,
    description: preset.description,
  })
  console.log('+', rel)
}

writeFileSync(MANIFEST_PATH, JSON.stringify(manifest, null, 2) + '\n', 'utf-8')
console.log(`\nWrote ${manifest.length} Chowning demos → ${MANIFEST_PATH}`)
