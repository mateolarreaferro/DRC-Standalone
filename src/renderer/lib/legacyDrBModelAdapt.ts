import { REALTIME_CSOPTIONS } from '../../shared/csd-realtime-options'

const PLAYER_SCORE_TAIL = `i 99 0 36000
f 0 36000`

const PLAYER_INSTR_100 = `
instr 100
  Schan strget p4
  iVal  = p5
  chnset iVal, Schan
  turnoff
endin`

const PLAYER_INSTR_99 = `
instr 99
  kMix  chnget "reverbMix"
  kSize chnget "reverbSize"
  aInL  chnget "revL"
  aInR  chnget "revR"
  aL, aR reverbsc aInL, aInR, kSize, 9000
  outs  aL * kMix, aR * kMix
  chnclear "revL"
  chnclear "revR"
endin`

function buildPlayerCsd(globals: string, chn: string, voice: string, scoreFt: string): string {
  return `<CsoundSynthesizer>
${REALTIME_CSOPTIONS}
<CsInstruments>
sr = 44100
ksmps = 64
nchnls = 2
0dbfs = 1

${globals}

${chn}
${voice}
${PLAYER_INSTR_100}
${PLAYER_INSTR_99}
</CsInstruments>
<CsScore>
${scoreFt}
${PLAYER_SCORE_TAIL}
</CsScore>
</CsoundSynthesizer>`
}

function extractInstrBody(source: string, num: string | number): string | null {
  const instrBlock = source.match(/<CsInstruments>([\s\S]*?)<\/CsInstruments>/i)?.[1] ?? source
  const re = new RegExp(`^\\s*instr\\s+${num}[^\\n]*\\n([\\s\\S]*?)^\\s*endin\\s*$`, 'im')
  return instrBlock.match(re)?.[1]?.trim() ?? null
}

function extractScoreFtLines(source: string): string {
  const score = source.match(/<CsScore>([\s\S]*?)<\/CsScore>/i)?.[1] ?? ''
  return score
    .split('\n')
    .filter((line) => /^\s*f\d+\s+/i.test(line))
    .join('\n')
    .trim()
}

const CHN_WAVESHAPE_BRASS = `
chn_k "amplitude", 3, 2, 0.55, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "attack", 3, 3, 0.04, 0.005, 0.2, 0, 0, 0, 0, "unit=s label=Attack"
chn_k "release", 3, 3, 0.35, 0.05, 2, 0, 0, 0, 0, "unit=s label=Release"
chn_k "distortion", 3, 2, 1, 0.3, 2, 0, 0, 0, 0, "unit= label=Distortion"
chn_k "reverbMix", 3, 2, 0.25, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.82, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"
chnset 0.55, "amplitude"
chnset 0.04, "attack"
chnset 0.35, "release"
chnset 1, "distortion"
chnset 0.25, "reverbMix"
chnset 0.82, "reverbSize"
`

const VOICE_WAVESHAPE_BRASS = `
instr 1
  iAtt  chnget "attack"
  iRel  chnget "release"
  kAmp  chnget "amplitude"
  kDist chnget "distortion"
  kAmp  port kAmp, 0.02
  kDist port kDist, 0.02
  iVel  = p5
  ifr   = p4
  ioffset = 0.5
  ibeatfb = 1.01 * ifr
  ibeatff = 0.99 * ifr
  kenv  oscil1i 0, 1, p3, 4
  kfreq2 line ibeatfb, p3, ibeatff
  ain1  oscili ioffset, ifr, 1
  awsh1 tablei kenv * kDist * ain1, 2, 1, ioffset
  ain2  oscili ioffset, kfreq2, 1
  awsh2 tablei kenv * kDist * ain2, 2, 1, ioffset
  aout  = kenv * kAmp * iVel * (0.8 * awsh1 + 0.2 * awsh2)
  chnmix aout, "revL"
  chnmix aout, "revR"
  outs aout, aout
endin`

const SCORE_WAVESHAPE_BRASS = `
f1  0 8192  10 1
f2  0 8192  13 0.5 1 0 1 .7 .8 .3 .1 .8 .9 1 1
f3  0 512   7 0 96 1 96 .8 96 .84 96 0.77 32 0.6 96 0
f4  0 512   7 0 32 1 32 .8 64 .9 128 0.6 128 0.4 100 0.25 28 0
`

const CHN_WAVESHAPE_CLARINET = `
chn_k "amplitude", 3, 2, 0.55, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "reverbMix", 3, 2, 0.35, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.9, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"
chnset 0.55, "amplitude"
chnset 0.35, "reverbMix"
chnset 0.9, "reverbSize"
`

const VOICE_WAVESHAPE_CLARINET = `
instr 1
  kAmp  chnget "amplitude"
  iVel  = p5
  ifqc  = p4
  idec  = (p3 > 0.75 ? 0.64 : p3 - 0.085)
  aenv  linen 255, 0.085, p3, idec
  a1    oscili aenv, ifqc, 1
  a1    tablei a1 + 256, 31
  aSig  = a1 * kAmp * iVel * 0.28
  chnmix aSig, "revL"
  chnmix aSig, "revR"
  outs aSig, aSig
endin`

const SCORE_WAVESHAPE_CLARINET = `
f1   0 2048 10 1
f31  0  512  7 -1 200 -.5 112 .5 200 1
`

const CHN_FM_STRING_PAD = `
chn_k "amplitude", 3, 2, 0.5, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "fmIndex", 3, 2, 1, 0.2, 3, 0, 0, 0, 0, "unit= label=FM_Index"
chn_k "reverbMix", 3, 2, 0.32, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.88, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"
chnset 0.5, "amplitude"
chnset 1, "fmIndex"
chnset 0.32, "reverbMix"
chnset 0.88, "reverbSize"
`

const VOICE_FM_STRING_PAD = `
instr 1
  kAmp  chnget "amplitude"
  kIdx  chnget "fmIndex"
  iVel  = p5
  ipitch = p4
  ksinc = ipitch
  kmod1hz = ksinc
  kmod2hz = ksinc * 3
  kmod3hz = ksinc * 4
  i1 = 7.5 / log(ipitch)
  i2 = 15 / sqrt(ipitch)
  i3 = 1.25 / sqrt(ipitch)
  indx1 = i1 * kIdx
  indx2 = i2 * kIdx
  indx3 = i3 * kIdx
  kindx1c envlpx indx1, p3 * 0.7, p3, p3 * 0.3, 6, 0.999, 0.01
  kindx2c envlpx indx2, p3 * 0.703, p3, p3 * 0.297, 6, 0.997, 0.01
  kindx3c envlpx indx3, p3 * 0.695, p3, p3 * 0.305, 6, 0.998, 0.01
  kindex1 = kindx1c * kmod1hz
  kindex2 = kindx2c * kmod2hz
  kindex3 = kindx3c * kmod3hz
  amod1 oscil kindex1, kmod1hz, 1, -1
  amod2 oscil kindex2, kmod2hz, 1, -1
  amod3 oscil kindex3, kmod3hz, 1, -1
  acarfrq = amod1 + amod2 + amod3 + ksinc
  kamp = kAmp * iVel * 0.25
  astr oscili kamp, acarfrq, 1, -1
  asig envlpx astr, 0.17, p3, p3 * 0.79, 2, 0.998, 0.01
  aSig = asig * 0.18
  chnmix aSig, "revL"
  chnmix aSig, "revR"
  outs aSig, aSig
endin`

const SCORE_FM_STRING_PAD = `
f1 0 512 10 1
f2 0 513 7 0 513 1
f3 0 513 7 1 513 0
f6 0 513 5 .001 62 .95 61 .55 200 1 190 .86
`

/** Legacy horn scores used p4 ≈ 8000 on a 32768 full-scale system — rescale for 0dbfs = 1. */
const HORN_LEGACY_AMP = 8000 / 32768

const CHN_FRENCH_HORN = `
giHornMaster = 0.52

chn_k "amplitude", 3, 2, 0.68, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "attack", 3, 3, 0.06, 0.02, 0.2, 0, 0, 0, 0, "unit=s label=Attack"
chn_k "release", 3, 3, 0.15, 0.04, 0.5, 0, 0, 0, 0, "unit=s label=Release"
chn_k "vibrato", 3, 2, 0.5, 0, 1, 0, 0, 0, 0, "unit= label=Vibrato"
chn_k "brightness", 3, 2, 9, 1, 9, 0, 0, 0, 0, "unit= label=Brightness"
chn_k "reverbMix", 3, 2, 0.28, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.85, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"
chnset 0.68, "amplitude"
chnset 0.06, "attack"
chnset 0.15, "release"
chnset 0.5, "vibrato"
chnset 9, "brightness"
chnset 0.28, "reverbMix"
chnset 0.85, "reverbSize"

giseed = 0.5
giwtsin = 1
`

function remapFrenchHornBody(body: string): string {
  let b = body
  b = b.replace(
    /iampscale\s*=\s*p4[^\n]*/i,
    `iampscale = chnget("amplitude") * p5 * ${HORN_LEGACY_AMP.toFixed(6)}`,
  )
  b = b.replace(/ifreq\s*=\s*p5[^\n]*/i, 'ifreq = p4')
  b = b.replace(
    /ivibdepth\s*=\s*abs\(p6\*ifreq\/100\.0\)[^\n]*/i,
    'ivibdepth = abs(chnget("vibrato") * ifreq / 100.0)',
  )
  b = b.replace(/iattack\s*=\s*p7[^\n]*/i, 'iattack = chnget("attack")')
  b = b.replace(/idecay\s*=\s*p8[^\n]*/i, 'idecay = chnget("release")')
  b = b.replace(/ifiltcut\s+tablei\s+p9,\s*2[^\n]*/i, 'ifiltcut tablei chnget("brightness"), 2')
  b = b.replace(
    /garev\s*=\s*garev\s*\+\s*asig[\s\S]*?outs\s+asig\*\.8,\s*asig\*\.8/i,
    '  chnmix asig * giHornMaster, "revL"\n        chnmix asig * giHornMaster, "revR"\n        outs tanh(asig * giHornMaster), tanh(asig * giHornMaster)',
  )
  return b.trim()
}

function isWaveshapeBrass(source: string): boolean {
  return /\binstr\s+13\b/i.test(source) && /tablei\s+kenv\*ain/i.test(source)
}

function isWaveshapeClarinet(source: string): boolean {
  return /tablei\s+a1\s*\+\s*256,\s*31/i.test(source) && /cpspch\(p5\)/i.test(source)
}

function isFmStringPad(source: string): boolean {
  return /FMSTRINGS|kmod1hz|envlpx\s+asig/i.test(source) && /cpspch\(p5\)/i.test(source)
}

function isFrenchHorn(source: string): boolean {
  return /\binstr\s+25\b/i.test(source) && /French horn/i.test(source)
}

/** Mechanical wrap for legacy Dr. B score models — keyboard + chn_k + instr 99 reverb. */
export function legacyDrBModelAdapt(source: string): string | null {
  const raw = source.replace(/<bsbPanel>[\s\S]*/i, '').trim()
  if (!raw.includes('<CsoundSynthesizer')) return null

  if (isWaveshapeBrass(raw)) {
    return buildPlayerCsd('', CHN_WAVESHAPE_BRASS, VOICE_WAVESHAPE_BRASS, SCORE_WAVESHAPE_BRASS)
  }

  if (isWaveshapeClarinet(raw)) {
    const ft = extractScoreFtLines(raw) || SCORE_WAVESHAPE_CLARINET.trim()
    return buildPlayerCsd('', CHN_WAVESHAPE_CLARINET, VOICE_WAVESHAPE_CLARINET, ft)
  }

  if (isFmStringPad(raw)) {
    const ft = extractScoreFtLines(raw) || SCORE_FM_STRING_PAD.trim()
    return buildPlayerCsd('', CHN_FM_STRING_PAD, VOICE_FM_STRING_PAD, ft)
  }

  if (isFrenchHorn(raw)) {
    const body = extractInstrBody(raw, 25)
    if (!body) return null
    const ft = extractScoreFtLines(raw)
    if (!ft) return null
    const voice = `instr 1\n${remapFrenchHornBody(body)}\nendin`
    return buildPlayerCsd('', CHN_FRENCH_HORN, voice, ft)
  }

  return null
}

export function canLegacyDrBModelAdapt(source: string): boolean {
  try {
    return legacyDrBModelAdapt(source) !== null
  } catch {
    return false
  }
}
