import { stripCabbageJunk } from './mechanicalPlayerAdapt'
import { REALTIME_CSOPTIONS } from '../../shared/csd-realtime-options'

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

const CHN_GRANULAR = `
chn_k "amplitude", 3, 2, 0.38, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "reverbMix", 3, 2, 0.35, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.85, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"
chnset 0.38, "amplitude"
chnset 0.35, "reverbMix"
chnset 0.85, "reverbSize"
giGrainGain = 0.62
`

const CHN_STANDARD = `
chn_k "amplitude", 3, 2, 0.55, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "reverbMix", 3, 2, 0.35, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.85, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"
chnset 0.55, "amplitude"
chnset 0.35, "reverbMix"
chnset 0.85, "reverbSize"
`

interface CcDef {
  macro: string
  num: number
  defaultVal: number
}

function parseCtrlinitCcDefs(instrBlock: string): CcDef[] {
  const defs: CcDef[] = []
  const seen = new Set<number>()
  const re = /ctrlinit\s+\d+\s*,\s*([\d,\s.]+)/gi
  let m: RegExpExecArray | null
  while ((m = re.exec(instrBlock)) !== null) {
    const nums = m[1].split(',').map((s) => parseFloat(s.trim()))
    for (let i = 0; i + 1 < nums.length; i += 2) {
      const cc = nums[i]
      const val = nums[i + 1]
      if (Number.isNaN(cc) || Number.isNaN(val) || seen.has(cc)) continue
      seen.add(cc)
      defs.push({
        macro: `CC${cc}`,
        num: cc,
        defaultVal: val <= 1 ? val : val / 127,
      })
    }
  }
  return defs
}

function parseCcDefs(instrBlock: string): CcDef[] {
  const defs = parseCtrlinitCcDefs(instrBlock)
  const seen = new Set(defs.map((d) => d.num))
  const defineRe = /#define\s+(C\d+)\s+#(\d+)#/gi
  let m: RegExpExecArray | null
  while ((m = defineRe.exec(instrBlock)) !== null) {
    const num = parseInt(m[2], 10)
    if (seen.has(num)) continue
    seen.add(num)
    defs.push({ macro: m[1], num, defaultVal: 0.5 })
  }
  for (const d of defs) {
    const ctrlinit = new RegExp(`ctrlinit\\s+\\d+,\\s*\\$${d.macro},\\s*([\\d.]+)`, 'i').exec(instrBlock)
    if (ctrlinit) d.defaultVal = parseFloat(ctrlinit[1]) / 127
    const initc7 = new RegExp(`initc7\\s+\\d+,\\s*\\$${d.macro},\\s*([\\d.]+)`, 'i').exec(instrBlock)
    if (initc7) d.defaultVal = parseFloat(initc7[1])
  }
  return defs
}

function labelFromMidiVar(name: string): string {
  const n = name.toLowerCase()
  if (/vol|gain|level/.test(n) && !/ampoff/.test(n)) return 'Volume'
  if (/dens/.test(n)) return 'Grain_Density'
  if (/gdur|grain.*dur/.test(n)) return 'Grain_Duration'
  if (/ptchoff|pitchoff|pitch.*off/.test(n)) return 'Pitch_Spread'
  if (/kampoff|ampoff/.test(n)) return 'Amp_Spread'
  if (/morf|vowel/.test(n)) return 'Vowel_Morph'
  if (/oct/.test(n)) return 'Octave_Drop'
  if ((/filt|cut|frq|freq|cps/.test(n) || n.includes('cf')) && !/res/.test(n)) return 'Pitch_Scatter'
  if (/res|rez|q\b/.test(n)) return 'Resonance'
  if (/pan/.test(n)) return 'Pan'
  if (/mod|index|fm|depth/.test(n)) return 'Modulation'
  if (/pw|width|pulse/.test(n)) return 'Pulse_Width'
  if (/verb|rev|echo/.test(n)) return 'Reverb_Send'
  const trimmed = name.replace(/^k/i, '').replace(/_/g, ' ')
  return trimmed ? trimmed.charAt(0).toUpperCase() + trimmed.slice(1) : 'Control'
}

function inferCcLabels(voiceBody: string, defs: CcDef[]): Map<number, string> {
  const macroNum = new Map(defs.map((d) => [d.macro, d.num]))
  const labels = new Map<number, string>()
  let m: RegExpExecArray | null
  const macroRe = /^\s*(\w+)\s+midic7\s+\$(C\d+)\s*,/gim
  while ((m = macroRe.exec(voiceBody)) !== null) {
    const num = macroNum.get(m[2])
    if (num !== undefined) labels.set(num, labelFromMidiVar(m[1]))
  }
  const numRe = /^\s*(\w+)\s+midic7\s+(\d+)\s*,/gim
  while ((m = numRe.exec(voiceBody)) !== null) {
    labels.set(parseInt(m[2], 10), labelFromMidiVar(m[1]))
  }
  return labels
}

function ensureCcDefs(body: string, defs: CcDef[]): CcDef[] {
  const out = [...defs]
  const seen = new Set(out.map((d) => d.num))
  const re = /^\s*\w+\s+midic7\s+(\d+)\s*,\s*([^,]+)\s*,\s*([^\n]+)/gim
  let m: RegExpExecArray | null
  while ((m = re.exec(body)) !== null) {
    const num = parseInt(m[1], 10)
    if (seen.has(num)) continue
    seen.add(num)
    const hi = parseFloat(m[3].replace(/;.*$/, '').trim())
    out.push({ macro: `CC${num}`, num, defaultVal: hi <= 1 ? 0.5 : 0.5 })
  }
  return out
}

function buildCcChannels(defs: CcDef[], labels: Map<number, string>): string {
  if (!defs.length) return ''
  const decls = defs
    .map((d) => {
      const id = `cc${d.num}`
      const def = d.defaultVal
      const max = def <= 1 ? 1 : 127
      const norm = def <= 1 ? def : def / 127
      const label = (labels.get(d.num) ?? `CC ${d.num}`).replace(/ /g, '_')
      return `chn_k "${id}", 3, 2, ${norm}, 0, ${max <= 1 ? 1 : max}, 0, 0, 0, 0, "unit= label=${label}"`
    })
    .join('\n')
  const inits = defs
    .map((d) => {
      const id = `cc${d.num}`
      const def = d.defaultVal
      const norm = def <= 1 ? def : def / 127
      return `chnset ${norm}, "${id}"`
    })
    .join('\n')
  return `${decls}\n${inits}\n`
}

function lerpMidic7(varName: string, lo: string, hi: string, id: string): string {
  const hiClean = hi.replace(/;.*$/, '').trim()
  const loClean = lo.trim()
  return `${varName} = (${loClean}) + chnget("${id}") * ((${hiClean}) - (${loClean}))`
}

function replaceCcReads(body: string, defs: CcDef[]): string {
  let out = body
  for (const d of defs) {
    const id = `cc${d.num}`
    const macro = d.macro.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
    out = out.replace(
      new RegExp(`^(\\s*\\w+)\\s+midic7\\s+\\$${macro}\\s*,\\s*([^,]+)\\s*,\\s*([^\\n]+)`, 'gim'),
      (_, varName, lo, hi) => lerpMidic7(varName.trim(), lo, hi, id),
    )
    out = out.replace(
      new RegExp(`^(\\s*\\w+)\\s+ctrl7\\s+\\d+\\s*,\\s*\\$${macro}\\s*,\\s*([^,]+)\\s*,\\s*([^\\n]+)`, 'gim'),
      (_, varName, lo, hi) => lerpMidic7(varName.trim(), lo, hi, id),
    )
    out = out.replace(
      new RegExp(`^(\\s*\\w+)\\s+midic7\\s+${d.num}\\s*,\\s*([^,]+)\\s*,\\s*([^\\n]+)`, 'gim'),
      (_, varName, lo, hi) => lerpMidic7(varName.trim(), lo, hi, id),
    )
  }
  return out
}

function routeVoiceToReverb(body: string): string {
  if (/chnmix/i.test(body)) {
    let b = body.replace(/^\s*chnmix[^\n]*$/gim, '')
    b = b.replace(/^\s*outs\s+[^\n]+$/gim, '').trim()
    return routeVoiceToReverb(b)
  }
  const outsLines = body.match(/^\s*outs\s+([^\n]+)$/gim) ?? []
  const cleaned = body.replace(/^\s*outs\s+[^\n]+$/gim, '').trim()
  if (!outsLines.length) return cleaned
  const last = outsLines[outsLines.length - 1]
  const stereo = last.match(/^\s*outs\s+([^,\n]+)\s*,\s*([^\n]+)$/i)
  if (stereo) {
    const l = stereo[1].trim()
    const r = stereo[2].trim()
    return `${cleaned}\n  chnmix ${l}, "revL"\n  chnmix ${r}, "revR"\n  outs ${l}, ${r}`
  }
  const mono = last.match(/^\s*outs\s+(.+)$/i)
  const s = mono?.[1]?.trim() ?? 'aSig'
  return `${cleaned}\n  chnmix ${s}, "revL"\n  chnmix ${s}, "revR"\n  outs ${s}, ${s}`
}

function injectPitchAmp(body: string): string {
  let b = body
  b = b.replace(/^\s*ipitch\s+cpsmidi\b[^\n]*/gim, 'iFreq = p4')
  b = b.replace(/^\s*ifqc\s+cpsmidi\b[^\n]*/gim, 'iFreq = p4')
  b = b.replace(/^\s*icps\s+cpsmidi\b[^\n]*/gim, 'iFreq = p4')
  b = b.replace(/\bicps\s+cpsmidib(?:\s+\d+)?\b[^\n]*/gi, 'iFreq = p4')
  b = b.replace(/\biFreq\s+cpsmidib(?:\s+\d+)?\b[^\n]*/gi, 'iFreq = p4')
  b = b.replace(/^\s*knote\s+cpsmidib\b[^\n]*/gim, 'knote = p4')
  b = b.replace(/^\s*kcps\s+cpsmidib(?:\s+\d+)?\b[^\n]*/gim, 'kcps = p4')
  b = b.replace(/^\s*iamp\s+ampmidi\s+([^\n;]+)/gim, (_, scale) => {
    const s = scale.trim()
    const n = parseFloat(s)
    if (!Number.isNaN(n) && n <= 1) return `iAmp = p5 * chnget("amplitude") * (${s})`
    return `iAmp = p5 * chnget("amplitude") * (${s}) / 10000`
  })
  b = b.replace(/^\s*iAmp\s+ampmidi\s+([^\n;]+)/gim, (_, scale) => {
    const s = scale.trim()
    const n = parseFloat(s)
    if (!Number.isNaN(n) && n <= 1) return `iAmp = p5 * chnget("amplitude") * (${s})`
    return `iAmp = p5 * chnget("amplitude") * (${s}) / 10000`
  })
  b = b.replace(/^\s*ilevl\s+ampmidi\s+([^\n;]+)/gim, (_, scale) => {
    const s = scale.trim()
    const n = parseFloat(s)
    if (!Number.isNaN(n) && n <= 1) return `iAmp = p5 * chnget("amplitude") * (${s})`
    return `iAmp = p5 * chnget("amplitude") * (${s}) / 10000`
  })
  b = b.replace(/^\s*iveloc\s+ampmidi\s+([^\n;]+)/gim, 'iveloc = p5 * chnget("amplitude") * ($1)')
  b = b.replace(/\bifqc\b/g, 'iFreq')
  b = b.replace(/\bicps\b/g, 'iFreq')
  b = b.replace(/\bipitch\b/g, 'iFreq')
  if (!/\biAmp\b/.test(b) && /\biamp\b/.test(b)) b = b.replace(/\biamp\b/g, 'iAmp')
  if (/\biAmp\b/.test(b)) b = b.replace(/\biamp\b/g, 'iAmp')
  if (!/\biAmp\b/.test(b) && /\bilevl\b/.test(b)) b = b.replace(/\bilevl\b/g, 'iAmp')
  if (!/\biAmp\b/.test(b) && /\biveloc\b/.test(b)) b = b.replace(/\biveloc\b/g, 'iAmp')
  b = b.replace(/^\s*iAmp\s*=\s*(\d+)\s*$/gim, (_, n) => {
    const scale = parseInt(n, 10) / 10000
    return `iAmp = p5 * chnget("amplitude") * ${scale}`
  })
  b = b.replace(/^\s*ifc\s*=\s*cpspch\s*\([^)]+\)/gim, 'ifc = p4')
  b = b.replace(/\bcontinue\s*:/gi, 'kcontinue:')
  b = b.replace(/\bgoto\s+continue\b/gi, 'goto kcontinue')
  b = b.replace(/,\s*continue\b/gi, ', kcontinue')
  b = b.replace(/^\s*out\s+(.+)$/gim, 'outs $1, $1')
  if (/\bgrain\s*\(/i.test(b)) {
    b = b.replace(/\bgrain\s*\(\s*iAmp\b/gi, 'grain(iAmp * giGrainGain')
  }
  return routeVoiceToReverb(b)
}

function normalizeScore(score: string): string {
  let s = score.trim()
  s = s.replace(/^\s*f0\s+z\s*$/gim, '')
  s = s.replace(/^\s*f0\s+\d+\s*$/gim, '')
  s = s.replace(/\bi\s+99\s+0\s+-1/gi, '')
  s = s.replace(/\bi198\s+0\s+\d+/gi, '')
  s = s.replace(/\bi\s+98\s+0\s+\d+/gi, '')
  s = s.replace(/^e\s*$/gim, '')
  const ft = s
    .split('\n')
    .filter((line) => /^\s*f\d+\s+/i.test(line))
    .join('\n')
    .trim()
  return `${ft}\ni 99 0 36000\nf 0 36000`.trim()
}

function findInstrBlocks(instrBlock: string): { num: string; body: string; index: number }[] {
  const headers: { num: string; index: number }[] = []
  let offset = 0
  for (const line of instrBlock.split('\n')) {
    const code = line.includes(';') ? line.slice(0, line.indexOf(';')) : line
    const m = /^\s*instr\s+([A-Za-z_]\w*|\d+)\s*$/i.exec(code)
    if (m) headers.push({ num: m[1], index: offset })
    offset += line.length + 1
  }

  const instruments: { num: string; body: string; index: number }[] = []
  for (let h = 0; h < headers.length; h++) {
    const { num, index } = headers[h]
    const afterHeader = instrBlock.indexOf('\n', index) + 1
    const endMatch = /\n\s*endin\s*(?:\n|$)/gi
    endMatch.lastIndex = afterHeader
    const end = endMatch.exec(instrBlock)
    if (!end) continue
    const body = instrBlock.slice(afterHeader, end.index)
    instruments.push({ num, body, index })
  }
  return instruments
}

function extractInstruments(instrBlock: string): { globals: string; instruments: { num: string; body: string; index: number }[] } {
  const instruments = findInstrBlocks(instrBlock)
  const globals = instruments.length ? instrBlock.slice(0, instruments[0].index) : instrBlock
  return { globals, instruments }
}

function cleanMidiGlobals(globals: string): string {
  return globals
    .replace(/^\s*#define\b[^\n]*\n/gim, '')
    .replace(/^\s*massign[^\n]*\n/gim, '')
    .replace(/^\s*ctrlinit[^\n]*\n/gim, '')
    .replace(/^\s*initc7[^\n]*\n/gim, '')
    .replace(/^\s*maxalloc[^\n]*\n/gim, '')
    .replace(/^\s*nchnls\s*=.*\n/gim, '')
    .replace(/^\s*0dbfs\s*=.*\n/gim, '')
    .trim()
}

function isVoiceInstr(body: string): boolean {
  return /\b(cpsmidi|ampmidi|cpsmidib)\b/i.test(body)
}

function isOpcodeBlock(text: string): boolean {
  return /^\s*opcode\s+/im.test(text)
}

/** Offline wrap for bundled MIDI synth models — keyboard p4/p5, chn_k for former MIDI CC. */
export function wrapMidiModelForPlayer(source: string): string | null {
  const raw = stripCabbageJunk(source.trim())
  if (!/\b(cpsmidi|ampmidi|cpsmidib)\b/i.test(raw)) return null

  const synth = raw.match(/<CsoundSynthesizer[\s\S]*?<\/CsoundSynthesizer>/i)?.[0]
  if (!synth) return null

  const instrBlock = synth.match(/<CsInstruments>([\s\S]*?)<\/CsInstruments>/i)?.[1]
  const scoreBlock = synth.match(/<CsScore>([\s\S]*?)<\/CsScore>/i)?.[1]
  if (!instrBlock) return null

  let ccDefs = parseCcDefs(instrBlock)
  const { globals, instruments } = extractInstruments(instrBlock)
  if (!instruments.length) return null

  const voiceIdx = instruments.findIndex((i) => isVoiceInstr(i.body))
  if (voiceIdx < 0) return null

  let cleanGlobals = cleanMidiGlobals(globals)
  if (!/\bgi\w+\s+ftgen\b/i.test(cleanGlobals) && !/\bftgen\b/i.test(cleanGlobals) && !isOpcodeBlock(cleanGlobals)) {
    cleanGlobals = `giSine ftgen 0, 0, 16384, 10, 1\n\n${cleanGlobals}`.trim()
  }
  if (!/\bsr\s*=/i.test(cleanGlobals)) {
    cleanGlobals = `sr = 44100\nksmps = 64\nnchnls = 2\n0dbfs = 1\n\n${cleanGlobals}`
  }

  const voiceBody = instruments[voiceIdx].body
  ccDefs = ensureCcDefs(voiceBody, ccDefs)
  const ccLabels = inferCcLabels(voiceBody, ccDefs)
  const ccChn = buildCcChannels(ccDefs, ccLabels)

  let b = injectPitchAmp(voiceBody)
  b = replaceCcReads(b, ccDefs)
  const voice = `instr 1\n${b.trim()}\nendin`
  const score = normalizeScore(scoreBlock ?? '')
  const isGranular = /\bgrain\s*\(/i.test(voiceBody)
  const chnBlock = isGranular ? CHN_GRANULAR : CHN_STANDARD

  return `<CsoundSynthesizer>
${REALTIME_CSOPTIONS}
<CsInstruments>
${cleanGlobals}

${chnBlock}
${ccChn}
${voice}
${PLAYER_INSTR_100}
${PLAYER_INSTR_99}
</CsInstruments>
<CsScore>
${score}
</CsScore>
</CsoundSynthesizer>`
}
