import { needsPlayerAdapt } from '../prompts/convert'
import { REALTIME_CSOPTIONS } from '../../shared/csd-realtime-options'
import { legacyDrBModelAdapt } from './legacyDrBModelAdapt'
import { scoreModelPlayerAdapt } from './scoreModelPlayerAdapt'
import { trappedPlayerAdapt } from './trappedPlayerAdapt'
import { wrapMidiModelForPlayer } from './midiModelPlayerWrap'

const PLAYER_SCORE = `<CsScore>
i 99 0 36000
f 0 36000
</CsScore>`

const PLAYER_SCORE_WITH_FT = `<CsScore>
f 1 0 16384 10 1
i 99 0 36000
f 0 36000
</CsScore>`

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

const PINGPONG_INSTR_99 = `
instr 99
aDelL = vdelay3(gaEcho, 280, 1000)
aDelR = vdelay3(gaEcho, 420, 1000)
aFbL = vdelay3(aDelR*0.38, 280, 1000)
aFbR = vdelay3(aDelL*0.4, 420, 1000)
aEchoL = gaEcho*0.6 + (aDelL + aFbL)*0.6
aEchoR = gaEcho*0.6 + (aDelR + aFbR)*0.6
outs aEchoL, aEchoR
clear gaEcho
endin`

const PLAYER_CHN_BRASS = `
chn_k "amplitude", 3, 2, 0.55, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "attack", 3, 3, 0.008, 0.001, 0.05, 0, 0, 0, 0, "unit=s label=Attack"
chn_k "release", 3, 3, 0.14, 0.03, 0.8, 0, 0, 0, 0, "unit=s label=Release"
chn_k "peakIndex", 3, 2, 7, 1, 14, 0, 0, 0, 0, "unit= label=FM_Brightness"
chn_k "modRatio", 3, 2, 1, 0.5, 2, 0, 0, 0, 0, "unit= label=Mod_Ratio"
chn_k "reverbMix", 3, 2, 0.22, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.75, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"

chnset 0.55, "amplitude"
chnset 0.008, "attack"
chnset 0.14, "release"
chnset 7, "peakIndex"
chnset 1, "modRatio"
chnset 0.22, "reverbMix"
chnset 0.75, "reverbSize"
`

const BRASS_VOICE = `
instr 1
  iAtt     chnget "attack"
  iRel     chnget "release"
  iPeak    chnget "peakIndex"
  iIdxDrop = min(0.065, max(0.035, iAtt * 2.5))
  kAmp     chnget "amplitude"
  kRatio   chnget "modRatio"
  kAmp     port kAmp, 0.02
  kRatio   port kRatio, 0.02
  kEnv     linsegr 0, iAtt, 1, iAtt + 0.015, 0.92, iRel, 0
  iVel     = p5
  kIdx     linsegr 0, 0.006, iPeak, iIdxDrop, iPeak * 0.34, max(p3 - iIdxDrop - 0.006, 0.01), iPeak * 0.34
  aSig     foscili kEnv * kAmp * iVel, p4, 1, kRatio, kIdx, giSine
  chnmix aSig, "revL"
  chnmix aSig, "revR"
  outs aSig, aSig
endin`

const PLAYER_CHN_FM = `
chn_k "amplitude", 3, 2, 0.5, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "attack", 3, 3, 0.01, 0.001, 2, 0, 0, 0, 0, "unit=s label=Attack"
chn_k "release", 3, 3, 0.5, 0.01, 6, 0, 0, 0, 0, "unit=s label=Release"
chn_k "fmIndex", 3, 2, 9, 0, 30, 0, 0, 0, 0, "unit= label=FM_Index"
chn_k "reverbMix", 3, 2, 0.3, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.8, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"

chnset 0.5, "amplitude"
chnset 0.01, "attack"
chnset 0.5, "release"
chnset 9, "fmIndex"
chnset 0.3, "reverbMix"
chnset 0.8, "reverbSize"
`

const PLAYER_CHN_SHIMMER = `
chn_k "amplitude", 3, 2, 0.5, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "attack", 3, 3, 0.005, 0.001, 0.05, 0, 0, 0, 0, "unit=s label=Attack"
chn_k "release", 3, 3, 2.5, 0.2, 8, 0, 0, 0, 0, "unit=s label=Release"
chn_k "mod1Depth", 3, 2, 1, 0, 2, 0, 0, 0, 0, "unit= label=Shimmer_1"
chn_k "mod2Depth", 3, 2, 1, 0, 2, 0, 0, 0, 0, "unit= label=Shimmer_2"
chn_k "reverbMix", 3, 2, 0.4, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.92, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"

chnset 0.5, "amplitude"
chnset 0.005, "attack"
chnset 2.5, "release"
chnset 1, "mod1Depth"
chnset 1, "mod2Depth"
chnset 0.4, "reverbMix"
chnset 0.92, "reverbSize"
`

const PLAYER_CHN_PLUCK = `
chn_k "amplitude", 3, 2, 0.6, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "attack", 3, 3, 0.001, 0.0005, 0.05, 0, 0, 0, 0, "unit=s label=Attack"
chn_k "release", 3, 3, 0.3, 0.05, 2, 0, 0, 0, 0, "unit=s label=Release"
chn_k "fmIndex", 3, 2, 8, 0, 20, 0, 0, 0, 0, "unit= label=FM_Index"
chn_k "echoSend", 3, 2, 0.4, 0, 1, 0, 0, 0, 0, "unit= label=Echo_Send"

chnset 0.6, "amplitude"
chnset 0.001, "attack"
chnset 0.3, "release"
chnset 8, "fmIndex"
chnset 0.4, "echoSend"
`

const SHIMMER_VOICE = `
instr 1
  iAtt  chnget "attack"
  iRel  chnget "release"
  kAmp  chnget "amplitude"
  kM1   chnget "mod1Depth"
  kM2   chnget "mod2Depth"
  kAmp  port kAmp, 0.02
  kM1   port kM1, 0.02
  kM2   port kM2, 0.02
  kEnv  linsegr 0, iAtt, 1, iAtt + 0.05, 0.7, iRel, 0
  iVel  = p5

  kMod1Idx = 3.5 * kEnv * kM1
  aMod1 oscili kMod1Idx * p4, p4 * 3.5, giSine

  kMod2Idx = 2.1 * kEnv * kM2
  aMod2 oscili kMod2Idx * p4, p4 * 5.2, giSine

  aSig oscili kEnv * kAmp * iVel * 0.6, p4 + aMod1 + aMod2, giSine

  chnmix aSig, "revL"
  chnmix aSig, "revR"
  outs aSig, aSig
endin`

const SIMPLE_FM_VOICE = `
instr 1
  iAtt  chnget "attack"
  iRel  chnget "release"
  kAmp  chnget "amplitude"
  kFm   chnget "fmIndex"
  kAmp  port kAmp, 0.02
  kFm   port kFm, 0.02
  kEnv  linsegr 0, iAtt, 1, iAtt + 0.05, 0.7, iRel, 0
  iVel  = p5
  kModIndex = kEnv * kFm
  aSig  foscili kEnv * kAmp * iVel, p4, 1, 2.4, kModIndex, giSine
  chnmix aSig, "revL"
  chnmix aSig, "revR"
  outs aSig, aSig
endin`

function stripAmpPrefix(args: string): string {
  let a = args.trim()
  const patterns = [
    /^kEnv\s*\*\s*iAmp\s*,?\s*/i,
    /^kCarEnv\s*\*\s*iAmp\s*,?\s*/i,
    /^kEnv\s*\*?\s*/i,
    /^kCarEnv\s*\*?\s*/i,
    /^kAmp\s*\*?\s*/i,
    /^iAmp\s*,?\s*/i,
    /^iVel\s*,?\s*/i,
    /^p5\s*,?\s*/i,
  ]
  for (const re of patterns) {
    a = a.replace(re, '')
  }
  return a
}

const PLUCK_VOICE = `
instr 1
  iAtt  chnget "attack"
  iRel  chnget "release"
  kAmp  chnget "amplitude"
  kFm   chnget "fmIndex"
  kEcho chnget "echoSend"
  kAmp  port kAmp, 0.02
  kFm   port kFm, 0.02
  kEcho port kEcho, 0.02
  kEnv  linsegr 0, iAtt, 1, iAtt + 0.02, 0.6, iRel, 0
  iVel  = p5
  kModIndex = kEnv * kFm
  aFM  foscili kEnv * kAmp * iVel, p4, 1, 2.01, kModIndex, 1
  aFat butterlp aFM, p4 * 6
  gaEcho += aFat * kEcho
  outs aFat, aFat
endin`

export function stripCabbageJunk(source: string): string {
  return source.replace(/<bsbPanel>[\s\S]*/i, '').trim()
}

function cleanGlobals(globals: string): string {
  return globals
    .split('\n')
    .filter((line) => !/^\s*(sr|ksmps|nchnls|0dbfs)\s*=/i.test(line))
    .filter((line) => !/^\s*gaRvb[LR]\s+init/i.test(line))
    .filter((line) => !/^\s*gaEcho\s+init/i.test(line))
    .filter((line) => !/^\s*chnset\s+/i.test(line))
    .join('\n')
    .trim()
}

function isShimmerBellVoice(body: string): boolean {
  return (
    /\bkMod1Idx\b/.test(body) &&
    /\bkMod2Idx\b/.test(body) &&
    /\baSig\s+oscili\b/i.test(body)
  )
}

function isChowningBrassVoice(body: string): boolean {
  return (
    /\bfoscili\b/i.test(body) &&
    /\b1,\s*1,\s*kIdx\b/.test(body) &&
    !/\bkMod1Idx\b/.test(body)
  )
}

function isPluckPingPongBass(body: string, instrBlock: string): boolean {
  return /\bgaEcho\b/.test(body) && /\bfoscili\b/i.test(body) && /\bvdelay3\b/i.test(instrBlock)
}

function isSimpleFosciliFm(body: string): boolean {
  return (
    /\bfoscili\b/i.test(body) &&
    /\bkIdx\b/.test(body) &&
    !/\bkMod1Idx\b/.test(body) &&
    !/\bgaEcho\b/.test(body)
  )
}

function buildPlayerCsd(
  globals: string,
  chn: string,
  voice: string,
  fx99: string,
  score: string,
  extraGlobals = 'gaEcho init 0\n',
): string {
  const globalBlock = extraGlobals ? `${extraGlobals}\n${globals}`.trim() : globals
  return `<CsoundSynthesizer>
${REALTIME_CSOPTIONS}
<CsInstruments>
sr = 44100
ksmps = 64
nchnls = 2
0dbfs = 1

${globalBlock}

${chn}
${voice}
${PLAYER_INSTR_100}
${fx99}
</CsInstruments>
${score}
</CsoundSynthesizer>`
}

/** Deterministic Player wrap — no LLM. Covers FM, shimmer bell, ping-pong bass, and simple oscillators. */
export function mechanicalPlayerAdapt(source: string): string | null {
  const raw = stripCabbageJunk(source.trim())
  if (!raw || !needsPlayerAdapt(raw)) return raw

  if (/\b(cpsmidi|ampmidi|cpsmidib)\b/i.test(raw)) {
    const midi = wrapMidiModelForPlayer(raw)
    if (midi) return midi
  }

  const drB = legacyDrBModelAdapt(raw)
  if (drB) return drB

  const trapped = trappedPlayerAdapt(raw)
  if (trapped) return trapped

  const scoreModel = scoreModelPlayerAdapt(raw)
  if (scoreModel) return scoreModel

  const synth = raw.match(/<CsoundSynthesizer[\s\S]*?<\/CsoundSynthesizer>/i)?.[0]
  if (!synth) return null

  const instrBlock = synth.match(/<CsInstruments>([\s\S]*?)<\/CsInstruments>/i)?.[1]
  if (!instrBlock) return null

  let voiceBody = ''
  let globals = instrBlock
  const instrRe = /\binstr\s+(\d+)\s*\n([\s\S]*?)endin/gi
  let m: RegExpExecArray | null
  while ((m = instrRe.exec(instrBlock)) !== null) {
    const num = m[1]
    if (num === '99' || num === '100' || num === '1000') continue
    const body = m[2]
    if (/\bp4\b/.test(body) || /cpsmidinn|cpsmidi|midinn/i.test(body)) {
      voiceBody = body
      globals = instrBlock.slice(0, m.index).trim()
      break
    }
  }
  if (!voiceBody.trim()) return null

  if (isShimmerBellVoice(voiceBody)) {
    return buildPlayerCsd(cleanGlobals(globals), PLAYER_CHN_SHIMMER, SHIMMER_VOICE, PLAYER_INSTR_99, PLAYER_SCORE)
  }

  if (isChowningBrassVoice(voiceBody)) {
    return buildPlayerCsd(cleanGlobals(globals), PLAYER_CHN_BRASS, BRASS_VOICE, PLAYER_INSTR_99, PLAYER_SCORE)
  }

  if (isPluckPingPongBass(voiceBody, instrBlock)) {
    return buildPlayerCsd(
      cleanGlobals(globals),
      PLAYER_CHN_PLUCK,
      PLUCK_VOICE,
      PINGPONG_INSTR_99,
      PLAYER_SCORE_WITH_FT,
      'gaEcho init 0',
    )
  }

  if (isSimpleFosciliFm(voiceBody)) {
    return buildPlayerCsd(cleanGlobals(globals), PLAYER_CHN_FM, SIMPLE_FM_VOICE, PLAYER_INSTR_99, PLAYER_SCORE)
  }

  const midiWrap = wrapMidiModelForPlayer(raw)
  if (midiWrap) return midiWrap

  const oscLine =
    voiceBody.match(/^\s*(a\w+)\s*=\s*(foscili|oscili|poscil|vco2|pluck)\s*\((.+)\)\s*$/im) ??
    voiceBody.match(/^\s*(aSig|aOut|a1)\s+(foscili|oscili|poscil|vco2|pluck)\s+(.+)$/im) ??
    voiceBody.match(/^\s*(a\w+)\s+(foscili|oscili|poscil|vco2|pluck)\s+(.+)$/im)
  if (!oscLine) return null

  const opcode = oscLine[2]
  let ampArgs = stripAmpPrefix(oscLine[3] ?? '')
  ampArgs = ampArgs
    .replace(/\bcpsmidinn\s*\(\s*p4\s*\)/gi, 'p4')
    .replace(/\bcpsmidinn\s*\(\s*p5\s*\)/gi, 'p5')
    .replace(/\biFreq\b/g, 'p4')

  const usesFmIndex = /\bkIdx\b/i.test(voiceBody) || /\bkModIndex\b/i.test(voiceBody) || /fmIndex|foscili/i.test(voiceBody)
  const indexArg = usesFmIndex ? 'kModIndex' : ampArgs.split(',')[3]?.trim() ?? '1'

  const voice = `
instr 1
  iAtt  chnget "attack"
  iRel  chnget "release"
  kAmp  chnget "amplitude"
  kIdx  chnget "fmIndex"
  kAmp  port kAmp, 0.02
  kIdx  port kIdx, 0.02
  kEnv  linsegr 0, iAtt, 1, iAtt + 0.05, 0.7, iRel, 0
  iVel  = p5
  ${usesFmIndex ? 'kModIndex = kEnv * kIdx\n  ' : ''}aSig  ${opcode} kEnv * kAmp * iVel, ${ampArgs.replace(/,\s*kIdx\b/i, `, ${indexArg}`).replace(/,\s*kModIndex\b/i, ', kModIndex')}
  chnmix aSig, "revL"
  chnmix aSig, "revR"
  outs aSig, aSig
endin`

  return buildPlayerCsd(cleanGlobals(globals), PLAYER_CHN_FM, voice, PLAYER_INSTR_99, PLAYER_SCORE)
}

export function canMechanicalPlayerAdapt(source: string): boolean {
  try {
    return mechanicalPlayerAdapt(source) !== null
  } catch {
    return false
  }
}
