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

const CHN_STANDARD = `
chn_k "amplitude", 3, 2, 0.55, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "reverbMix", 3, 2, 0.35, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.88, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"
chnset 0.55, "amplitude"
chnset 0.35, "reverbMix"
chnset 0.88, "reverbSize"
`

const CHN_FOF = `
chn_k "amplitude", 3, 2, 0.55, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "vibratoDepth", 3, 2, 10, 0, 20, 0, 0, 0, 0, "unit= label=Vibrato_Depth"
chn_k "vowelRate", 3, 2, 0.5, 0.1, 2, 0, 0, 0, 0, "unit= label=Vowel_Rate"
chn_k "reverbMix", 3, 2, 0.35, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.88, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"
chnset 0.55, "amplitude"
chnset 10, "vibratoDepth"
chnset 0.5, "vowelRate"
chnset 0.35, "reverbMix"
chnset 0.88, "reverbSize"
`

const CHN_HORNER_WIND = `
chn_k "amplitude", 3, 2, 0.65, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "attack", 3, 3, 0.06, 0.02, 0.2, 0, 0, 0, 0, "unit=s label=Attack"
chn_k "release", 3, 3, 0.12, 0.04, 0.5, 0, 0, 0, 0, "unit=s label=Release"
chn_k "vibrato", 3, 2, 0.5, 0, 1, 0, 0, 0, 0, "unit= label=Vibrato"
chn_k "brightness", 3, 2, 7, 1, 9, 0, 0, 0, 0, "unit= label=Brightness"
chn_k "reverbMix", 3, 2, 0.28, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.85, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"
chnset 0.65, "amplitude"
chnset 0.06, "attack"
chnset 0.12, "release"
chnset 0.5, "vibrato"
chnset 7, "brightness"
chnset 0.28, "reverbMix"
chnset 0.85, "reverbSize"
giseed = 0.5
giwtsin = 1
`

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
  const direct = instrBlock.match(re)?.[1]?.trim()
  if (direct) return direct
  const multiRe = /^\s*instr\s+([\d,\s]+)[^\n]*\n([\s\S]*?)^\s*endin\s*$/im
  const multi = instrBlock.match(multiRe)
  if (multi && multi[1].split(',').some((n) => parseInt(n.trim(), 10) === Number(num))) {
    return multi[2]?.trim() ?? null
  }
  return null
}

function extractNamedInstrBody(source: string, name: string): string | null {
  const instrBlock = source.match(/<CsInstruments>([\s\S]*?)<\/CsInstruments>/i)?.[1] ?? source
  const re = new RegExp(`^\\s*instr\\s+${name}[^\\n]*\\n([\\s\\S]*?)^\\s*endin\\s*$`, 'im')
  return instrBlock.match(re)?.[1]?.trim() ?? null
}

function extractScoreFtLines(source: string): string {
  const score = source.match(/<CsScore>([\s\S]*?)<\/CsScore>/i)?.[1] ?? ''
  return score
    .split('\n')
    .filter((line) => /^\s*f\d+\s+/i.test(line) || /^\s*t\s+\d+/i.test(line))
    .join('\n')
    .trim()
}

function findVoiceInstr(source: string): { num: string; body: string } | null {
  const instrBlock = source.match(/<CsInstruments>([\s\S]*?)<\/CsInstruments>/i)?.[1]
  if (!instrBlock) return null
  const multi = instrBlock.match(/^\s*instr\s+([\d,\s]+)[^\n]*\n([\s\S]*?)^\s*endin\s*$/im)
  if (multi && /\b(cpspch|p4|p5|cpsmidi|cpsmidinn|ampmidi)\b/i.test(multi[2])) {
    return { num: multi[1].trim(), body: multi[2].trim() }
  }
  const re = /^\s*instr\s+(\d+|[A-Za-z_]\w*)[^\n]*\n([\s\S]*?)^\s*endin\s*$/gim
  let m: RegExpExecArray | null
  while ((m = re.exec(instrBlock)) !== null) {
    const num = m[1]
    const body = m[2]
    if (/^(Delay|Reverb)$/i.test(num)) continue
    if (num === '99' || num === '100' || num === '194') continue
    if (/\b(cpspch|p4|p5|cpsmidi|cpsmidinn|ampmidi)\b/i.test(body)) {
      return { num, body: body.trim() }
    }
  }
  return null
}

function stripGaBus(body: string): string {
  let b = body
  b = b.replace(/^\s*turnon[^\n]*\n/gim, '')
  b = b.replace(/^\s*gaDel[LR]\s*\+=[^\n]*\n/gim, '')
  b = b.replace(/^\s*gaRvb[LR]\s*\+=[^\n]*\n/gim, '')
  b = b.replace(/^\s*gaRvb[LR]\s*=\s*[^\n]*\n/gim, '')
  b = b.replace(/^\s*garvb\s*=\s*[^\n]*\n/gim, '')
  b = b.replace(/^\s*garev\s*=\s*[^\n]*\n/gim, '')
  b = b.replace(/^\s*outs?\s+a[Ll],\s*a[Rr]\s*$/gim, '')
  b = b.replace(/^\s*out\s*\([^\n]*\)\s*$/gim, '')
  b = b.replace(/^\s*out\s+[^\n]+$/gim, '')
  return b.trim()
}

function detectOutSignal(body: string): string {
  const outLine = body.match(/^\s*out\s+([^:\n][^\n]*)$/gim)?.pop()
  if (outLine) {
    const expr = outLine.replace(/^\s*out\s+/i, '').split(';')[0]?.trim()
    if (expr) return expr
  }
  const outsLine = body.match(/^\s*outs\s+([^,\n]+)/gim)?.pop()
  if (outsLine) {
    const expr = outsLine.replace(/^\s*outs\s+/i, '').split(';')[0]?.trim()
    if (expr) return expr
  }
  const assigns = [...body.matchAll(/^\s*(a[a-zA-Z]\w*)\s*=/gim)]
  if (assigns.length) return assigns[assigns.length - 1][1]
  return 'aSig'
}

function finishVoice(body: string, outExpr?: string): string {
  const signal = outExpr ?? detectOutSignal(body)
  const cleaned = stripGaBus(body)
  if (/chnmix/i.test(cleaned)) return cleaned
  return `${cleaned}\n  chnmix ${signal}, "revL"\n  chnmix ${signal}, "revR"\n  outs ${signal}, ${signal}`
}

function remapHornerWindBody(body: string): string {
  let b = body
  b = b.replace(/iampscale\s*=\s*p4[^\n]*/i, 'iampscale = chnget("amplitude") * p5 * 8000')
  b = b.replace(/ifreq\s*=\s*p5[^\n]*/i, 'ifreq = p4')
  b = b.replace(
    /ivibdepth\s*=\s*abs\(p6\*ifreq\/100\.0\)[^\n]*/i,
    'ivibdepth = abs(chnget("vibrato") * ifreq / 100.0)',
  )
  b = b.replace(/iattack\s*=\s*p7[^\n]*/i, 'iattack = chnget("attack")')
  b = b.replace(/idecay\s*=\s*p8[^\n]*/i, 'idecay = chnget("release")')
  b = b.replace(/ifiltcut\s+tablei\s+p9,\s*2[^\n]*/i, 'ifiltcut tablei chnget("brightness"), 2')
  b = b.replace(
    /garev\s*=\s*garev\s*\+\s*asig[\s\S]*?outs\s+asig[^\n]*/i,
    '  chnmix asig * 0.8, "revL"\n        chnmix asig * 0.8, "revR"\n        outs    asig * 0.8, asig * 0.8',
  )
  return finishVoice(b, 'asig')
}

function remapCpspchP5Voice(body: string): string {
  let b = body
  b = b.replace(/iamp\s*=\s*p4\s*\*\s*(\d+)/gi, 'iamp = p5 * chnget("amplitude") * ($1 / 32768)')
  b = b.replace(/iamp\s*=\s*p4\b/gi, 'iamp = p5 * chnget("amplitude") * 0.55')
  b = b.replace(/ilevl\s*=\s*p4[^\n]*/gi, 'ilevl = p5 * chnget("amplitude") * 0.55')
  b = b.replace(/ifre\s*=\s*cpspch\s*\(\s*p5\s*(\+\s*\d+\s*)?\)/gi, 'ifre = p4')
  b = b.replace(/ifreq\s*=\s*cpspch\s*\(\s*p5\s*(\+\s*\d+\s*)?\)/gi, 'ifreq = p4')
  b = b.replace(/inote\s*=\s*cpspch\s*\(\s*p5\s*(\+\s*\d+\s*)?\)/gi, 'inote = p4')
  b = b.replace(/ipitch\s*=\s*cpspch\s*\(\s*p5\s*(\+\s*\d+\s*)?\)/gi, 'ipitch = p4')
  b = b.replace(/iptch\s*=\s*cpspch\s*\(\s*p5\s*(\+\s*\d+\s*)?\)/gi, 'iptch = p4')
  b = b.replace(/kamp\s+linseg\s+0,\s*0\.01,\s*p4/gi, 'kamp linseg 0, 0.01, p5 * chnget("amplitude") * 0.55')
  b = b.replace(/kamp\s+linen\s+\.2,/i, 'kamp linen p5 * chnget("amplitude") * 0.2,')
  if (/ibthatk\s*=\s*p7/i.test(b)) {
    b = b.replace(/ibthatk\s*=\s*p7/i, 'ibthatk = (p7 <= 0 ? 12 : p7)')
  }
  if (/aout01/i.test(b)) {
    b = b.replace(
      /^\s*outs\s+[^\n]+$/gim,
      `aMixL = (aout01*(iamp*(kgenamp*krelamp)))*kpan\n  aMixR = (aout02*(iamp*(kgenamp*krelamp)))*(1-kpan)\n  chnmix aMixL, "revL"\n  chnmix aMixR, "revR"\n  outs aMixL, aMixR`,
    )
    return b.trim()
  }
  if (/\bout\s+a1\s*\*\s*ilevl/i.test(b) || /\bguzz\b/i.test(b)) {
    b = b.replace(/ihigh\s*=\s*int\(\(\.5\*sr\)\/ipitch\*p6\)/i, 'ihigh = int((.5*sr)/ipitch*1)')
    b = b.replace(/ilow\s*=\s*p7/i, 'ilow = 1')
    b = b.replace(/iharm1\s*=\s*p8/i, 'iharm1 = 1')
    b = b.replace(/iharm2\s*=\s*p9/i, 'iharm2 = 0.1')
  }
  return finishVoice(b)
}

function remapGhostBellBody(body: string): string {
  let b = body
  b = b.replace(/iFreq\s*=\s*cpsmidinn\s*\(\s*p4\s*\)/i, 'iFreq = p4')
  b = b.replace(
    /iPadSyn\s+ftgenonce[^\n]*\\\s*\n[^\n]*/i,
    'iBw = (p6 <= 0 ? 3 : p6)\n  iPadSyn ftgenonce 0, 0, 2^18, "padsynth", iBaseHz, iBw, 2, 1, 1, 1, \\\n                  0,.03, .0, .8,  0, .2,  0, .2,  0,.02,  0,.03,  0,.02,  0,.04',
  )
  b = b.replace(/poscil\s*\(\s*p5\s*\*\s*aEnv/i, 'poscil(p5 * chnget("amplitude") * aEnv')
  b = stripGaBus(b)
  if (!/chnmix/i.test(b)) {
    b = `${b}\n  chnmix aL, "revL"\n  chnmix aR, "revR"\n  outs aL, aR`
  }
  return b.trim()
}

function remapCpspchP4Voice(body: string): string {
  let b = body
  b = b.replace(/ifreq\s*=\s*cpspch\s*\(\s*p4\s*\)/i, 'ifreq = p4')
  b = b.replace(/inote\s*=\s*cpspch\s*\(\s*p4\s*\)/i, 'inote = p4')
  b = b.replace(/kamp\s+linen\s+\.2,/i, 'kamp linen p5 * chnget("amplitude") * 0.2,')
  return finishVoice(b)
}

function remapHzOscVoice(body: string): string {
  let b = body
  b = b.replace(/\boscili\s+([^,\n]+),\s*p5,/gi, 'oscili $1, p4,')
  b = b.replace(/\boscil\s+([^,\n]+),\s*p5,/gi, 'oscil $1, p4,')
  b = b.replace(/aout\s*=\s*p4\s*\*\s*kenv/gi, 'aout = p5 * chnget("amplitude") * kenv')
  b = b.replace(/klpfcut\s*=[^\n]*/gi, (line) => line.replace(/\bp5\b/g, 'p4'))
  return finishVoice(b, 'aSig')
}

function remapMoogVcfBody(body: string): string {
  let b = body
  b = b.replace(/imax\s+init\s+ampdb\(\d+\)/i, 'imax init 1')
  b = b.replace(/kpit\s*=\s*p4/i, 'kpit = p4')
  b = b.replace(/kvel\s*=\s*p5/i, 'kvel = p5 * chnget("amplitude")')
  b = b.replace(/kcut\s*=\s*p6/i, 'kcut = (p6 <= 0 ? chnget("cutoff") : p6)')
  b = b.replace(/krez\s*=\s*p7/i, 'krez = (p7 <= 0 ? chnget("resonance") : p7)')
  b = b.replace(/kenvtof\s*=\s*p8/i, 'kenvtof = (p8 <= 0 ? chnget("envMod") : p8)')
  b = b.replace(/cpspch\s*\(\s*kpit\s*\)/i, 'kpit')
  return finishVoice(b, 'aout * kvel')
}

function remapWaveSequencingBody(body: string): string {
  let b = body
  b = b.replace(/ihz\s*=\s*cpspch\s*\(\s*p4\s*\)/i, 'ihz = p4')
  b = b.replace(/kenv\s+envlpx\s+p5,/i, 'kenv envlpx p5 * chnget("amplitude") * 2.15,')
  b = b.replace(/iseed\s*=\s*p9/i, 'iseed = (p9 <= 0 ? 0.5 : p9)')
  b = b.replace(/irise\s*=\s*p6/i, 'irise = (p6 <= 0 ? 0.1 : p6)')
  b = b.replace(/idecay\s*=\s*p7/i, 'idecay = (p7 <= 0 ? 0.3 : p7)')
  b = b.replace(/ievfn\s*=\s*p8/i, 'ievfn = (p8 <= 0 ? 5 : p8)')
  b = b.replace(/irndhz\s*=\s*p10/i, 'irndhz = (p10 <= 0 ? 5 : p10)')
  b = b.replace(/ipanhz\s*=\s*p11/i, 'ipanhz = (p11 <= 0 ? 5 : p11)')
  b = b.replace(/ifna\s*=\s*p12/i, 'ifna = (p12 <= 0 ? 2 : p12)')
  b = b.replace(/ifnb\s*=\s*p13/i, 'ifnb = (p13 <= 0 ? 3 : p13)')
  b = b.replace(/ifnc\s*=\s*p14/i, 'ifnc = (p14 <= 0 ? 4 : p14)')
  b = b.replace(/ifnd\s*=\s*p15/i, 'ifnd = (p15 <= 0 ? 5 : p15)')
  return finishVoice(b)
}

function remapFmSitarBody(body: string): string {
  let b = body
  b = b.replace(/icps\s*=\s*cpspch\s*\(\s*p4\s*\)/i, 'icps = p4')
  b = b.replace(/iamp\s*=\s*ampdb\s*\(\s*p5\s*\)/i, 'iamp = p5 * chnget("amplitude") * 0.5')
  b = b.replace(/ilft\s*=\s*sqrt\s*\(\s*p6\s*\)/i, 'ilft = 0.707')
  b = b.replace(/irght\s*=\s*sqrt\s*\(\s*1\s*-\s*p6\s*\)/i, 'irght = 0.707')
  b = b.replace(/^\s*outs\s+galt,\s*gart\s*$/gim, '')
  b = b.replace(/galt\s*=\s*asig\*ilft[\s\S]*?gart\s*=\s*asig\*irght/gi, '')
  return finishVoice(b, '(a1+a4)/2 * iamp')
}

function remapKarplusVoice(body: string): string {
  let b = body
  b = b.replace(/\bcontinue\s*:/gi, 'kcontinue:')
  b = b.replace(/\bgoto\s+continue\b/gi, 'goto kcontinue')
  b = b.replace(/ifreq\s*=\s*cpspch\s*\(\s*p4\s*\)/i, 'ifreq = p4')
  b = b.replace(/ipluck\s*=\s*p5/i, 'ipluck = 0.4 + p5 * 0.5')
  b = b.replace(/^\s*out\s+awgout\s*$/gim, '')
  return finishVoice(b, 'awgout * p5 * chnget("amplitude")')
}

const VOICE_FOF = `
instr 1
  iAmp   = p5 * chnget("amplitude") * 0.45
  ipitch = p4
  ivibr  = chnget("vibratoDepth") * 0.4 + 4
  ivibd  = chnget("vibratoDepth")
  irate  = chnget("vowelRate")
  idet   = 0.5
  iLeng  = min(10, p3)
  kenv   linseg 0, min(0.1, p3 * 0.2), 1, max(iLeng - 0.2, 0.01), 1, 0.1, 0
  iseed  = rnd(1)
  k1     randi 0.5, irate, iseed
  k1     = k1 + 0.5
  k2     linseg 0, min(10, p3), ivibd
  k3     oscil k2, ivibr, 1
  k1f    table k1, 11, 1
  k2f    table k1, 12, 1
  k3f    table k1, 13, 1
  k4f    table k1, 14, 1
  k5f    table k1, 15, 1
  k1b    table k1, 21, 1
  k2b    table k1, 22, 1
  k3b    table k1, 23, 1
  k4b    table k1, 24, 1
  k5b    table k1, 25, 1
  kpitch = ipitch + k3 + idet
  a1     fof 1.0, kpitch, k1f, 0, k1b, 0.003, 0.02, 0.007, 1000, 1, 2, iLeng
  a2     fof 0.7, kpitch, k2f, 0, k2b, 0.003, 0.02, 0.007, 1000, 1, 2, iLeng
  a3     fof 0.5, kpitch, k3f, 0, k3b, 0.003, 0.02, 0.007, 1000, 1, 2, iLeng
  a4     fof 0.4, kpitch, k4f, 0, k4b, 0.003, 0.02, 0.007, 1000, 1, 2, iLeng
  a5     fof 0.3, kpitch, k5f, 0, k5b, 0.003, 0.02, 0.007, 1000, 1, 2, iLeng
  aSig   = (a1 + a2 + a3 + a4 + a5) * iAmp * kenv
  chnmix aSig, "revL"
  chnmix aSig, "revR"
  outs aSig, aSig
endin`

const CHN_TB303 = `
chn_k "amplitude", 3, 2, 0.55, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "cutoff", 3, 2, 0.45, 0, 1, 0, 0, 0, 0, "unit= label=Filter_Cutoff"
chn_k "resonance", 3, 2, 0.7, 0, 1, 0, 0, 0, 0, "unit= label=Resonance"
chn_k "envMod", 3, 2, 0.55, 0, 1, 0, 0, 0, 0, "unit= label=Env_Mod"
chn_k "reverbMix", 3, 2, 0.25, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.82, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"
chnset 0.55, "amplitude"
chnset 0.45, "cutoff"
chnset 0.7, "resonance"
chnset 0.55, "envMod"
chnset 0.25, "reverbMix"
chnset 0.82, "reverbSize"
`

const CHN_DEEPNOTE = `
chn_k "amplitude", 3, 2, 0.55, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "brightness", 3, 2, 0.85, 0.2, 1, 0, 0, 0, 0, "unit= label=Filter"
chn_k "reverbMix", 3, 2, 0.4, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.92, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"
chnset 0.55, "amplitude"
chnset 0.85, "brightness"
chnset 0.4, "reverbMix"
chnset 0.92, "reverbSize"
`

const CHN_MOOG_SEQ = `
chn_k "amplitude", 3, 2, 0.55, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "cutoff", 3, 2, 0.65, 0, 1, 0, 0, 0, 0, "unit= label=Cutoff"
chn_k "detune", 3, 2, 2, 0, 8, 0, 0, 0, 0, "unit=Hz label=Detune"
chn_k "reverbMix", 3, 2, 0.3, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.85, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"
chnset 0.55, "amplitude"
chnset 0.65, "cutoff"
chnset 2, "detune"
chnset 0.3, "reverbMix"
chnset 0.85, "reverbSize"
`

const CHN_NOISE_GLISS = `
chn_k "amplitude", 3, 2, 0.45, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "resRatio", 3, 2, 1.005, 1, 1.05, 0, 0, 0, 0, "unit= label=Res_Ratio"
chn_k "reverbMix", 3, 2, 0.45, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.9, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"
chnset 0.45, "amplitude"
chnset 1.005, "resRatio"
chnset 0.45, "reverbMix"
chnset 0.9, "reverbSize"
`

const VOICE_TB303 = `
instr 1
  iAmp = p5 * chnget("amplitude") * 0.55
  kpitch = p4
  kfco = chnget("cutoff") * 8000 + 200
  kres = chnget("resonance") * 0.85
  kenv expseg 1, max(p3 * 0.4, 0.01), 0.001
  kveg linen 1, 0.004, p3, 0.016
  kamp = kveg * iAmp * (0.4 + 0.6 * kenv)
  ksweep = kveg * (800 + kenv * chnget("envMod") * 7000)
  kfco = min(kfco + ksweep, sr * 0.45)
  abuzz buzz kamp, kpitch, sr/(2*kpitch), 1, 0
  asaw integ abuzz, 0
  asawdc atone asaw, 1
  aremovedc init 0
  ireson = 1
  ainpt = asawdc - aremovedc * kres * ireson
  alpf tone ainpt, kfco
  alpf tone alpf, kfco
  alpf tone alpf, kfco
  alpf tone alpf, kfco
  aout balance alpf, asawdc
  aremovedc atone aout, 10
  chnmix aremovedc, "revL"
  chnmix aremovedc, "revR"
  outs aremovedc, aremovedc
endin`

const VOICE_DEEPNOTE = `
instr 1
  iAmp = p5 * chnget("amplitude") * 0.6
  kpch = p4
  kjit jitter 30, 1, 3
  kpch = kpch + kjit * 0.15
  kenv linsegr 0, 0.05, 1, max(p3 - 0.15, 0.01), 0.85, 0.1, 0
  aout vco2 1, kpch, 4, 0.95
  aout moogvcf aout, 10000 * chnget("brightness"), 0.1
  aout = aout * iAmp * kenv
  chnmix aout, "revL"
  chnmix aout, "revR"
  outs aout, aout
endin`

const VOICE_STEP_MOOG = `
instr 1
  iAmp = p5 * chnget("amplitude") * 0.55
  ivcf = chnget("cutoff") * 6000 + 500
  idet = chnget("detune")
  kenv linsegr 0, 0.02, 1, max(p3 - 0.08, 0.01), 0.8, 0.06, 0
  avco1 oscil 0.5, p4 - idet, 8, -1
  avco2 oscil 0.5, p4 + idet, 8, -1
  avcf moogvcf (avco1 + avco2) * iAmp * kenv, ivcf, 0.1
  chnmix avcf, "revL"
  chnmix avcf, "revR"
  outs avcf, avcf
endin`

const VOICE_NOISE_GLISS = `
instr 1
  iAmp = p5 * chnget("amplitude") * 0.4
  ires1 = p4
  ires2 = p4 * chnget("resRatio")
  ibw = p4 * 0.02
  iseed = 0.179087 + p4 * 0.0001
  kenv linsegr 0, max(p3 * 0.4, 0.01), iAmp, max(p3 * 0.5, 0.01), 0, 0.05, 0
  anoise randi 1.0, 13000, iseed
  ares reson anoise, ires1, ibw, 1
  ares1 reson ares, ires2, ibw, 1
  chnmix ares1 * kenv, "revL"
  chnmix ares1 * kenv, "revR"
  outs ares1 * kenv, ares1 * kenv
endin`

const VOICE_TAMBOURINE = `
instr 1
  iAmp = p5 * chnget("amplitude") * 20000
  a1 tambourine iAmp, 0.01
  chnmix a1, "revL"
  chnmix a1, "revR"
  outs a1, a1
endin`

const VOICE_FEEDBACK = `
instr 1
  iAmp = p5 * chnget("amplitude") * 0.32
  kfreq = max(p4, 80)
  kfdbk linseg 0.9, p3/5, 1.4, p3/5, 0.9, p3/5, 1.2, 2*p3/5, 1
  asig oscili 1, kfreq, 1
  atemp delayr 1/20
  acomb deltapi 1/kfreq
  aiir dcblock asig + kfdbk*acomb
  aiir = aiir - aiir*aiir*aiir/6
  delayw aiir
  aout = acomb * iAmp * 9000
  kenv linsegr 0, 0.02, 1, max(p3-0.1,0.01), 0.7, 0.08, 0
  chnmix aout * kenv, "revL"
  chnmix aout * kenv, "revR"
  outs aout * kenv, aout * kenv
endin`

const VOICE_ITERATED_SINE = `
instr 1
  kcount = 0
  ifreq = p4
  inb = 6
  ir1 = 0.1
  irf = 3.14
  ix1 = 0.2
  ixf = 0.8
  iAmp = p5 * chnget("amplitude") * 0.55
  arenv linseg 0,.01,1,p3-.11,.6,.1,0
  aosc oscili 1, ifreq, 1
  aosc = (1+ aosc)/2
  ar = ir1 + (irf-ir1)*arenv*aosc
  avibosc oscili 1, 5, 1
  avibosc = (1+avibosc)/2
  axenvibr linseg 0, .5, 0, .5, 1, p3-1, 1
  ax = ix1+(ixf-ix1)*axenvibr*avibosc
 iter:
  ax = sin(ar * ax)
  kcount = kcount + 1
  if kcount < inb goto iter
  aSig = tanh(ax) * iAmp * arenv
  chnmix aSig, "revL"
  chnmix aSig, "revR"
  outs aSig, aSig
endin`

const VOICE_SIMPLE_FLUTE = `
instr 1
  iAmp = p5 * chnget("amplitude") * 0.55
  ifreq = p4
  ivib = chnget("vibrato") * ifreq * 0.005
  kenv linsegr 0, 0.05, 1, max(p3 - 0.12, 0.01), 0.85, 0.07, 0
  kvib oscil ivib, 5, 1
  kpch = ifreq + kvib
  asig oscil3 iAmp * kenv, kpch, 1
  asig butterlp asig, 3500, 1
  chnmix asig, "revL"
  chnmix asig, "revR"
  outs asig, asig
endin`

const VOICE_CRICKET = `
instr 1
  iAmp = p5 * chnget("amplitude") * 6000
  ifqc = max(p4, 40) / 100
  idur = min(p3, 2)
  kdclck linseg 0, 0.005, 1, idur - 0.01, 1, 0.005, 0
  kfqc1 oscil 4800 * ifqc, 19, 1
  kamp oscil 1, 19, 1
  afnd oscil kamp, kfqc1, 1
  aout pareq afnd * iAmp * kdclck, 7000, 0.005, 0.707, 2
  chnmix aout, "revL"
  chnmix aout, "revR"
  outs aout, aout
endin`

const SCORE_FOF = `
f1  0 4096 10 1
f2  0 1024 19 0.5 0.5 270 0.5
f11 0 1024 -7 600 256 400 256 250 256 400 256 350
f12 0 1024 -7 1040 256 1620 256 1750 256 750 256 600
f13 0 1024 -7 2250 256 2400 256 2600 256 2400 256 2400
f14 0 1024 -7 2450 256 2800 256 3050 256 2600 256 2675
f15 0 1024 -7 2750 256 3100 256 3340 256 2900 256 2950
f21 0 1024 -7 60 256 40 256 60 256 40 256 40
f22 0 1024 -7 70 256 80 256 90 256 80 256 80
f23 0 1024 -7 110 256 100 256 100 256 100 256 100
f24 0 1024 -7 120 256 120 256 120 256 120 256 120
f25 0 1024 -7 130 256 120 256 120 256 120 256 120
`

const SCORE_STEP_MOOG = `
f3 0 1024 -5 .001 14 1 1010 .001
f5 0 1024 -5 .001 12 1 1000 1 12 .001
f8 0 1024 7 0 512 1 0 -1 512 0
`

function isFofChoir(source: string): boolean {
  return /\bfof\b/i.test(source) && /\btable\s+k1,\s*11/i.test(source)
}

function isHornerWind(source: string): boolean {
  return /\bifreq\s*=\s*p5\b/i.test(source) && /\biampscale\s*=\s*p4\b/i.test(source)
}

function isCookHornerWind(source: string): boolean {
  return /\biampscale\s*=\s*p4\b/i.test(source) && /\bifreq\s*=\s*cpspch\s*\(\s*p5\s*\)/i.test(source)
}

function remapCookHornerWindBody(body: string): string {
  let b = body
  b = b.replace(/iampscale\s*=\s*p4[^\n]*/i, 'iampscale = chnget("amplitude") * p5 * 8000')
  b = b.replace(/ifreq\s*=\s*cpspch\s*\(\s*p5\s*\)[^\n]*/i, 'ifreq = p4')
  b = b.replace(
    /ivibdepth\s*=\s*abs\(p6\*ifreq\/100\.0\)[^\n]*/i,
    'ivibdepth = abs(chnget("vibrato") * ifreq / 100.0)',
  )
  b = b.replace(/iattack\s*=\s*p7[^\n]*/i, 'iattack = chnget("attack")')
  b = b.replace(/idecay\s*=\s*p8[^\n]*/i, 'idecay = chnget("release")')
  b = b.replace(/ifiltcut\s+tablei\s+p9,\s*2[^\n]*/i, 'ifiltcut tablei chnget("brightness"), 2')
  b = b.replace(
    /garev\s*=\s*garev\s*\+\s*asig[\s\S]*?outs\s+asig[^\n]*/i,
    '  chnmix asig * 0.8, "revL"\n        chnmix asig * 0.8, "revR"\n        outs    asig * 0.8, asig * 0.8',
  )
  return finishVoice(b, detectOutSignal(b) === 'aSig' ? 'asig' : detectOutSignal(b))
}

function isKarplus(source: string): boolean {
  return /Karplus-Strong|Karplus Strong/i.test(source) && /\bcpspch\s*\(\s*p4\s*\)/i.test(source)
}

function isGhostBell(source: string): boolean {
  return /GhostBell|padsynth/i.test(source) && /\bcpsmidinn\s*\(\s*p4\s*\)/i.test(source)
}

function isTb303(source: string): boolean {
  return /TB-303|TB303|BASSLINE ROLAND/i.test(source)
}

function isDeepNote(source: string): boolean {
  return /DeepNote|deepnote/i.test(source) || /\bipch1\s*=\s*p4\b/i.test(source)
}

function isStepSequencer(source: string): boolean {
  return /StepSequencer|Sequencer:\s*2\*VCOs/i.test(source)
}

function isNoiseGlissPad(source: string): boolean {
  return /DOUBLE RESONATED NOISE|NoiseGlissPad/i.test(source)
}

function isPhysicalModels(source: string): boolean {
  return /PhysicalModels1/i.test(source) || /\binstr\s+01\b[\s\S]{0,120}\bguiro\b/i.test(source)
}

function isFeedbackSimulator(source: string): boolean {
  return /FeedbackSimulator|feedback simulator/i.test(source)
}

function isCrickets(source: string): boolean {
  return /\bCRICKETS\b/i.test(source)
}

function isHzOscGaBus(source: string): boolean {
  return /gaDelL\s+init/i.test(source) && /\boscili[^\n]*,\s*p5,/i.test(source) && /\bp4\s*\*\s*kenv/i.test(source)
}

function isMoogVcfBass(source: string): boolean {
  return /MOOG VCF|moog\.orc/i.test(source) && /\bcpspch\s*\(\s*kpit\s*\)/i.test(source)
}

function isFmSitar(source: string): boolean {
  return /FM-SITAR/i.test(source) && /\bcpspch\s*\(\s*p4\s*\)/i.test(source)
}

function isIteratedSine(source: string): boolean {
  return /FUNCTIONAL ITERATIONS|IteratedSine/i.test(source)
}

function isFlute2Zakian(source: string): boolean {
  return /Lee Zakian|;FLUTE/i.test(source) && /\binstr\s+2\b/i.test(source)
}

function isWaveSequencing(source: string): boolean {
  return /Wavestation|WaveSequencing/i.test(source) && /\benvlpx\b/i.test(source)
}

/** Extended adapt for Dr. B misc synth score models. */
export function scoreModelPlayerAdapt(source: string): string | null {
  const raw = source.replace(/<bsbPanel>[\s\S]*/i, '').trim()
  if (!raw.includes('<CsoundSynthesizer')) return null

  if (isFofChoir(raw)) {
    const ft = extractScoreFtLines(raw) || SCORE_FOF.trim()
    return buildPlayerCsd('', CHN_FOF, VOICE_FOF, ft)
  }

  if (isGhostBell(raw)) {
    const body = extractNamedInstrBody(raw, 'GhostBell')
    if (!body) return null
    return buildPlayerCsd('', CHN_STANDARD, `instr 1\n${remapGhostBellBody(body)}\nendin`, 'f1 0 4096 10 1')
  }

  if (isTb303(raw)) {
    const ft = extractScoreFtLines(raw) || 'f1 0 8192 10 1'
    return buildPlayerCsd('', CHN_TB303, VOICE_TB303, ft)
  }

  if (isDeepNote(raw)) {
    return buildPlayerCsd('', CHN_DEEPNOTE, VOICE_DEEPNOTE, 'f1 0 4096 10 1')
  }

  if (isStepSequencer(raw)) {
    const ft = extractScoreFtLines(raw) || SCORE_STEP_MOOG.trim()
    return buildPlayerCsd('', CHN_MOOG_SEQ, VOICE_STEP_MOOG, ft)
  }

  if (isNoiseGlissPad(raw)) {
    return buildPlayerCsd('', CHN_NOISE_GLISS, VOICE_NOISE_GLISS, 'f1 0 4096 10 1')
  }

  if (isPhysicalModels(raw)) {
    return buildPlayerCsd('', CHN_STANDARD, VOICE_TAMBOURINE, 'f1 0 4096 10 1')
  }

  if (isFeedbackSimulator(raw)) {
    const ft = extractScoreFtLines(raw) || 'f1 0 8192 10 1'
    return buildPlayerCsd('', CHN_STANDARD, VOICE_FEEDBACK, ft)
  }

  if (isCrickets(raw)) {
    return buildPlayerCsd('', CHN_STANDARD, VOICE_CRICKET, 'f1 0 4096 10 1')
  }

  if (isFmSitar(raw)) {
    const body = extractInstrBody(raw, 1)
    if (!body) return null
    const ft = extractScoreFtLines(raw) || 'f2 0 513 10 1\nf11 0 513 7 0 64 1 64 .4 384 .2\nf13 0 513 7 0 64 .8 128 1 320 .5\nf14 0 513 7 0 64 1 448 .5\nf15 0 513 7 0 16 1 128 .3 368 .8'
    return buildPlayerCsd('', CHN_STANDARD, `instr 1\n${remapFmSitarBody(body)}\nendin`, ft)
  }

  if (isMoogVcfBass(raw)) {
    const body = extractInstrBody(raw, 1)
    if (!body) return null
    return buildPlayerCsd('', CHN_TB303, `instr 1\n${remapMoogVcfBody(body)}\nendin`, 'f1 0 4096 10 1')
  }

  if (isHzOscGaBus(raw)) {
    const body = extractInstrBody(raw, 1)
    if (!body) return null
    const ft = extractScoreFtLines(raw) || 'f1 0 4096 10 1\nf3 0 4096 10 1\nf4 0 4096 7 0 512 1 0 -1 512 0'
    return buildPlayerCsd('', CHN_STANDARD, `instr 1\n${remapHzOscVoice(body)}\nendin`, ft)
  }

  if (isIteratedSine(raw)) {
    return buildPlayerCsd('', CHN_STANDARD, VOICE_ITERATED_SINE, 'f1 0 8192 10 1')
  }

  if (isFlute2Zakian(raw)) {
    return buildPlayerCsd('', CHN_HORNER_WIND, VOICE_SIMPLE_FLUTE, 'f1 0 4096 10 1')
  }

  if (isWaveSequencing(raw)) {
    const body = extractInstrBody(raw, 1)
    if (!body) return null
    const ft = extractScoreFtLines(raw) || 'f2 0 4096 10 1\nf3 0 4096 10 1\nf4 0 4096 10 1\nf5 0 4096 10 1'
    return buildPlayerCsd('', CHN_STANDARD, `instr 1\n${remapWaveSequencingBody(body)}\nendin`, ft)
  }

  if (isCookHornerWind(raw)) {
    const voice = findVoiceInstr(raw)
    if (!voice) return null
    const ft = extractScoreFtLines(raw)
    if (!ft) return null
    const body = remapCookHornerWindBody(voice.body)
    return buildPlayerCsd('', CHN_HORNER_WIND, `instr 1\n${body}\nendin`, ft)
  }

  if (isHornerWind(raw)) {
    const voice = findVoiceInstr(raw)
    if (!voice) return null
    const ft = extractScoreFtLines(raw)
    if (!ft) return null
    const body = remapHornerWindBody(voice.body)
    return buildPlayerCsd('', CHN_HORNER_WIND, `instr 1\n${body}\nendin`, ft)
  }

  if (isKarplus(raw)) {
    const body = extractInstrBody(raw, 1)
    if (!body) return null
    const voice = remapKarplusVoice(body)
    return buildPlayerCsd('', CHN_STANDARD, `instr 1\n${voice}\nendin`, 'f1 0 4096 10 1')
  }

  const voice = findVoiceInstr(raw)
  if (!voice) return null
  const ft = extractScoreFtLines(raw)
  if (!ft && !/\bftgen\b/i.test(raw)) return null

  let body = voice.body
  if (/cpspch\s*\(\s*p5/i.test(body) && /\bp4\b/.test(body)) {
    body = remapCpspchP5Voice(body)
  } else if (/cpspch\s*\(\s*p4\s*\)/i.test(body)) {
    body = remapCpspchP4Voice(body)
  } else {
    return null
  }

  const voiceBlock = `instr 1\n${body}\nendin`
  return buildPlayerCsd('', CHN_STANDARD, voiceBlock, ft || 'f1 0 4096 10 1')
}

export function canScoreModelPlayerAdapt(source: string): boolean {
  try {
    return scoreModelPlayerAdapt(source) !== null
  } catch {
    return false
  }
}
