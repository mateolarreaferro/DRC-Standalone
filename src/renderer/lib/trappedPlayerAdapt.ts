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

const CHN_BASE = `
chn_k "amplitude", 3, 2, 0.55, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "reverbMix", 3, 2, 0.35, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.85, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"
chnset 0.55, "amplitude"
chnset 0.35, "reverbMix"
chnset 0.85, "reverbSize"
`

interface ParamDef {
  id: string
  label: string
  default: number
  min: number
  max: number
}

function extractInstrBody(source: string, num: string | number): string | null {
  const instrBlock = source.match(/<CsInstruments>([\s\S]*?)<\/CsInstruments>/i)?.[1] ?? source
  const re = new RegExp(`^\\s*instr\\s+${num}[^\\n]*\\n([\\s\\S]*?)^\\s*endin?\\s*$`, 'im')
  return instrBlock.match(re)?.[1]?.trim() ?? null
}

function findVoiceInstrNum(source: string): string | null {
  const instrBlock = source.match(/<CsInstruments>([\s\S]*?)<\/CsInstruments>/i)?.[1]
  if (!instrBlock) return null
  const re = /^\s*instr\s+(\d+)\b[^\n]*\n([\s\S]*?)^\s*endin?\s*$/gim
  let m: RegExpExecArray | null
  while ((m = re.exec(instrBlock)) !== null) {
    const num = m[1]
    if (num === '98' || num === '99') continue
    const body = m[2]
    if (/\b(cpspch|octpch)\s*\(\s*p5\s*\)/i.test(body) || /\bp6\b/.test(body)) {
      return num
    }
  }
  return null
}

function parseParamComments(source: string, instrNum: string): ParamDef[] {
  const block = source.match(/<CsInstruments>([\s\S]*?)<\/CsInstruments>/i)?.[1] ?? ''
  const section = block.match(
    new RegExp(`instr\\s+${instrNum}[^\\n]*\\n([\\s\\S]*?)^\\s*endin?`, 'im'),
  )?.[1] ?? ''
  const params: ParamDef[] = []
  const seen = new Set<string>()
  const re = /;\s*p(\d+)\s*=\s*([^\n]+)/gi
  let m: RegExpExecArray | null
  while ((m = re.exec(section)) !== null) {
    const pNum = m[1]
    const desc = m[2].trim().toLowerCase()
    if (seen.has(pNum)) continue
    if (pNum === '5' && !/sweep|swp|strt|start|filter|fltr|freq/i.test(desc)) continue
    if (pNum === '6' && /amp/i.test(desc)) continue
    seen.add(pNum)
    const def = paramFromDescription(pNum, desc)
    if (def) params.push(def)
  }
  return params
}

function paramFromDescription(pNum: string, desc: string): ParamDef | null {
  if (/amp/.test(desc)) return null
  if (/reverb|rvb|rvbsnd|send factor/.test(desc)) return null
  if (/del(ay)?\s*send/.test(desc)) {
    return { id: 'delayMix', label: 'Delay_Mix', default: 0.25, min: 0, max: 1 }
  }
  if (/lfo|vib/.test(desc) && /rate|freq|frq/.test(desc)) {
    return { id: 'lfoRate', label: 'LFO_Rate', default: 19, min: 1, max: 40 }
  }
  if (/harmonic|harm/.test(desc)) {
    return { id: 'harmonics', label: 'Harmonics', default: 13, min: 1, max: 24 }
  }
  if (/sweep/.test(desc)) {
    return { id: 'sweepRate', label: 'Sweep_Rate', default: 0.21, min: 0.01, max: 1 }
  }
  if (/glis|drop/.test(desc)) {
    return { id: 'glissFactor', label: 'Gliss_Factor', default: 0.8, min: 0.1, max: 1 }
  }
  if (/rand.*freq|freq.*rand/.test(desc)) {
    return { id: 'randFreq', label: 'Rand_Freq', default: 30, min: 2, max: 60 }
  }
  if (/rand.*amp|amp.*rand/.test(desc)) {
    return { id: 'randAmp', label: 'Rand_Amp', default: 8000, min: 1000, max: 12000 }
  }
  if (/del(ay)?\s*send/.test(desc)) {
    return { id: 'delayMix', label: 'Delay_Mix', default: 0.25, min: 0, max: 1 }
  }
  if (/bdwth|bandwidth/.test(desc)) {
    return { id: 'bandwidth', label: 'Bandwidth', default: 30, min: 1, max: 100 }
  }
  if (/filter|fltr|strtfreq|endfreq|swp/.test(desc)) {
    return { id: 'filterSweep', label: 'Filter_Sweep', default: 6000, min: 200, max: 12000 }
  }
  if (/pan/.test(desc)) return null
  if (pNum === '8' || pNum === '9' || pNum === '10') {
    return {
      id: `paramP${pNum}`,
      label: `Param_P${pNum}`,
      default: pNum === '8' ? 19 : pNum === '9' ? 13 : 0.5,
      min: 0,
      max: pNum === '10' ? 1 : 100,
    }
  }
  return null
}

function buildExtraChn(params: ParamDef[]): string {
  const uniq = new Map<string, ParamDef>()
  for (const p of params) uniq.set(p.id, p)
  const lines: string[] = []
  for (const p of uniq.values()) {
    lines.push(
      `chn_k "${p.id}", 3, 2, ${p.default}, ${p.min}, ${p.max}, 0, 0, 0, 0, "unit= label=${p.label}"`,
    )
    lines.push(`chnset ${p.default}, "${p.id}"`)
  }
  if (uniq.has('filterSweep')) {
    lines.push(
      `chn_k "filterSweepEnd", 3, 2, 4000, 200, 12000, 0, 0, 0, 0, "unit= label=Filter_End"`,
    )
    lines.push(`chnset 4000, "filterSweepEnd"`)
  }
  return lines.length ? `${lines.join('\n')}\n` : ''
}

function mapPfields(body: string, params: ParamDef[]): string {
  let b = body
  const ids = new Set(params.map((p) => p.id))
  if (ids.has('lfoRate')) {
    b = b.replace(/,\s*p8\s*,/g, ', chnget("lfoRate"),')
    b = b.replace(/\bosci[l]?\s+k2,\s*p7\b/g, 'oscil k2, chnget("lfoRate")')
    if (!ids.has('bandwidth')) {
      b = b.replace(/\bp7\b/g, 'chnget("lfoRate")')
    }
  }
  if (ids.has('harmonics')) {
    b = b.replace(/\blinseg\s+p9\b/g, 'linseg chnget("harmonics")')
    b = b.replace(/\bksweep\s+linseg\s+p9\b/g, 'ksweep linseg chnget("harmonics")')
  }
  if (ids.has('sweepRate')) {
    b = b.replace(/p3\s*\*\s*p10\b/g, 'p3 * chnget("sweepRate")')
  }
  if (ids.has('glissFactor')) {
    b = b.replace(/\bline\s+0,\s*p3,\s*p8\b/g, 'line 0, p3, chnget("glissFactor")')
    b = b.replace(/\bexpseg[^\n]*\bp8\b/g, (line) => line.replace(/\bp8\b/g, 'chnget("glissFactor")'))
    b = b.replace(/\bp8\b/g, 'chnget("glissFactor")')
  }
  if (ids.has('randFreq')) {
    b = b.replace(/\brandh[^\n]*\bp8\b/g, (line) => line.replace(/\bp8\b/g, 'chnget("randFreq")'))
  }
  if (ids.has('filterSweep')) {
    b = b.replace(/\bexpon\s+p7\b/g, 'expon chnget("filterSweep")')
    b = b.replace(/\bexpon\s+p7,\s*p3,\s*p8\b/g, 'expon chnget("filterSweep"), p3, chnget("filterSweepEnd")')
    b = b.replace(/\bk1\s+expon\s+p7,\s*p3,\s*p8\b/g, 'k1 expon chnget("filterSweep"), p3, chnget("filterSweepEnd")')
  }
  if (ids.has('bandwidth')) {
    b = b.replace(/\bk1\s*\/\s*p9\b/g, 'k1 / chnget("bandwidth")')
    b = b.replace(/,\s*k1\s*\/\s*p9\b/g, ', k1 / chnget("bandwidth")')
    b = b.replace(/\bp7\b/g, 'chnget("bandwidth")')
  }
  return b
}

function stripTrappedFx(body: string): string {
  let b = body
  b = b.replace(/^\s*garvb[^\n]*(\n|$)/gim, '')
  b = b.replace(/^\s*gadel[^\n]*(\n|$)/gim, '')
  return b.trim()
}

function finishTrappedVoice(body: string): string {
  const cleaned = stripTrappedFx(body)
  if (/chnmix/i.test(cleaned)) {
    let b = cleaned.replace(/^\s*chnmix[^\n]*$/gim, '')
    b = b.replace(/^\s*outs\s+[^\n]+$/gim, '').trim()
    return finishTrappedVoice(b)
  }
  const outsLines = cleaned.match(/^\s*outs\s+([^\n]+)$/gim) ?? []
  const withoutOuts = cleaned.replace(/^\s*outs\s+[^\n]+$/gim, '').trim()
  if (!outsLines.length) {
    return `${withoutOuts}\n  chnmix aSig, "revL"\n  chnmix aSig, "revR"\n  outs aSig, aSig`
  }
  const last = outsLines[outsLines.length - 1]
  const stereo = last.match(/^\s*outs\s+([^,\n]+)\s*,\s*([^\n]+)$/i)
  if (stereo) {
    return `${withoutOuts}\n  aOutL = ${stereo[1].trim()}\n  aOutR = ${stereo[2].trim()}\n  chnmix aOutL, "revL"\n  chnmix aOutR, "revR"\n  outs aOutL, aOutR`
  }
  const mono = last.match(/^\s*outs\s+(.+)$/i)
  const s = mono?.[1]?.trim() ?? 'aSig'
  return `${withoutOuts}\n  chnmix ${s}, "revL"\n  chnmix ${s}, "revR"\n  outs ${s}, ${s}`
}

function replaceCpsoct(body: string): string {
  let b = body
  b = b.replace(
    /cpsoct\s*\(\s*\(\s*(?:ifreq|icps|p4)\s*\+([^)]+)\)\s*\+([^)]+)\)/gi,
    '(p4 +$1) +$2',
  )
  b = b.replace(/cpsoct\s*\(\s*(?:ifreq|icps|p4)\s*\+([^)]+)\)/gi, 'p4 +$1')
  b = b.replace(/cpsoct\s*\(\s*(?:ifreq|icps|p4)\s*\)/gi, 'p4')
  return b
}

function isUnpitchedTrapped(body: string): boolean {
  return !/\b(cpspch|octpch)\s*\(\s*p5\s*\)/i.test(body) && !/\bifreq\b/i.test(body)
}

function remapUnpitchedBody(body: string, params: ParamDef[]): string {
  let b = stripTrappedFx(body)
  b = `iAmp = p5 * chnget("amplitude") * 0.55\n${b}`
  b = b.replace(/\blinen\s+p4\b/g, 'linen iAmp')
  b = mapPfields(b, params)
  if (params.some((p) => p.id === 'filterSweep')) {
    b = b.replace(/\bexpon\s+p5,\s*p3,\s*p6\b/g, 'expon chnget("filterSweep"), p3, chnget("filterSweepEnd")')
    b = b.replace(/\blinseg\s+p6\s*\*/g, 'linseg chnget("filterSweepEnd") *')
    b = b.replace(/\bp5\s*\*\s*1\.4\b/g, 'chnget("filterSweep") * 1.4')
  }
  if (params.some((p) => p.id === 'bandwidth')) {
    b = b.replace(/\bp7\b/g, 'chnget("bandwidth")')
  }
  return finishTrappedVoice(b)
}

function remapTrappedBody(body: string, params: ParamDef[]): string {
  if (isUnpitchedTrapped(body)) return remapUnpitchedBody(body, params)

  let b = stripTrappedFx(body)
  b = b.replace(/ifreq\s*=\s*cpspch\s*\(\s*p5\s*\)/gi, 'icps = p4')
  b = b.replace(/ifreq\s*=\s*octpch\s*\(\s*p5\s*\)/gi, 'icps = p4')
  b = replaceCpsoct(b)
  b = b.replace(/\bifreq\b/g, 'icps')
  b = `iAmp = p5 * chnget("amplitude") * 0.55\n${b}`
  b = b.replace(/\bp6\b/g, 'iAmp')
  b = mapPfields(b, params)
  if (/gadel|amix/i.test(body) && params.some((p) => p.id === 'delayMix')) {
    b = b.replace(
      /^\s*outs\s+([^\n]+)$/gim,
      'aDlySig delay (a1 + a2 + a3 + a4), 0.08\n  aMixOut = amix + aDlySig * chnget("delayMix")\n  outs aMixOut, aMixOut',
    )
  }
  return finishTrappedVoice(b)
}

function extractScoreFtLines(source: string): string {
  const score = source.match(/<CsScore>([\s\S]*?)<\/CsScore>/i)?.[1] ?? ''
  return score
    .split('\n')
    .filter((line) => /^\s*f\d+\s+/i.test(line))
    .join('\n')
    .trim()
}

function buildPlayerCsd(chn: string, voice: string, scoreFt: string): string {
  return `<CsoundSynthesizer>
${REALTIME_CSOPTIONS}
<CsInstruments>
sr = 44100
ksmps = 64
nchnls = 2
0dbfs = 1

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

export function isTrappedModel(source: string): boolean {
  const s = source.replace(/<bsbPanel>[\s\S]*/i, '')
  return (
    /trapped-\d/i.test(s) ||
    (/garvb\s+init/i.test(s) && /\b(cpspch|octpch)\s*\(\s*p5\s*\)/i.test(s)) ||
    (/====\s*(IVORY|BLUE|VIOLET|BLACK|GREEN|SAND|FOAM|TEAL|RUST|TAUPE|PEWTER|COPPER|RED)/i.test(s))
  )
}

/** Player wrap for Trapped in Convert score models (13 timbres + variations). */
export function trappedPlayerAdapt(source: string): string | null {
  const raw = source.replace(/<bsbPanel>[\s\S]*/i, '').trim()
  if (!isTrappedModel(raw)) return null

  const voiceNum = findVoiceInstrNum(raw)
  if (!voiceNum) return null

  const body = extractInstrBody(raw, voiceNum)
  if (!body) return null

  const params = parseParamComments(raw, voiceNum)
  const extraChn = buildExtraChn(params)
  const voice = `instr 1\n${remapTrappedBody(body, params)}\nendin`
  const ft = extractScoreFtLines(raw) || 'f1 0 8192 10 1'

  return buildPlayerCsd(`${CHN_BASE}${extraChn}`, voice, ft)
}

export function canTrappedPlayerAdapt(source: string): boolean {
  try {
    return trappedPlayerAdapt(source) !== null
  } catch {
    return false
  }
}
