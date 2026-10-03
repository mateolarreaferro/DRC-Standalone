// Build Mermaid block diagrams from orchestra / CSD text for study and teaching.
// Heuristic parser — not a full Csound AST; optimized for Dr.C player + web-export patches.

import type { ChannelSpec } from './parseChannels'
import { extractOrchestra, parseChannels, usesKeyboard } from './parseChannels'

export interface SignalFlowStudy {
  title: string
  summary: string[]
  architectureMermaid: string
  signalFlowMermaid: string
  controlsMermaid: string
}

export interface SignalFlowStudyInput {
  title?: string
  /** Full CSD, orchestra body, or web-app HTML containing `const ORC =`. */
  source: string
  channels?: ChannelSpec[]
  hasKeyboard?: boolean
  hasReverbBus?: boolean
}

function mId(raw: string): string {
  return raw.replace(/[^a-zA-Z0-9_]/g, '_').replace(/_+/g, '_').slice(0, 48) || 'n'
}

/** Pull orchestra text from CSD, raw orc, or exported web-app HTML. */
export function extractStudyOrchestra(source: string): string {
  const trimmed = source.trim()
  const orcMatch = trimmed.match(/const\s+ORC\s*=\s*`([\s\S]*?)`;/)
  if (orcMatch) return orcMatch[1].trim()
  if (/<CsInstruments>/i.test(trimmed)) return extractOrchestra(trimmed)
  return trimmed
}

function listInstruments(orc: string): { num: number; body: string }[] {
  const out: { num: number; body: string }[] = []
  const re = /\binstr\s+(\d+)\s*\n([\s\S]*?)\nendin\b/gi
  let m: RegExpExecArray | null
  while ((m = re.exec(orc))) {
    out.push({ num: Number(m[1]), body: m[2] })
  }
  return out
}

function instrUsesP4(body: string): boolean {
  return /\bp4\b/.test(body)
}

function detectReverbBus(orc: string, instruments: { num: number; body: string }[]): boolean {
  if (/\binstr\s+99\b/i.test(orc)) return true
  return instruments.some((i) => i.num === 99)
}

function globalAudioBuses(orc: string): string[] {
  const names = new Set<string>()
  for (const m of orc.matchAll(/\b(ga[A-Za-z0-9_]+)\b/g)) names.add(m[1])
  for (const m of orc.matchAll(/chnmix\s+\w+\s*,\s*"([^"]+)"/gi)) names.add(m[1])
  return [...names].sort()
}

function voiceOpcodes(body: string): string[] {
  const tags: string[] = []
  const rules: [RegExp, string][] = [
    [/\bmadsr\b/i, 'madsr envelope'],
    [/\blinsegr\b/i, 'linsegr envelope'],
    [/\badsr\b/i, 'adsr envelope'],
    [/\bexpseg/i, 'expseg envelope'],
    [/\bvco2\b/i, 'vco2 oscillator'],
    [/\bfoscili\b/i, 'foscili oscillator'],
    [/\boscili\b/i, 'oscili oscillator'],
    [/\bgran\b/i, 'granular'],
    [/\bmoogladder\b/i, 'moogladder filter'],
    [/\bbutterlp\b/i, 'butterlp filter'],
    [/\bbutterbp\b/i, 'butterbp filter'],
    [/\btone\b/i, 'tone filter'],
    [/\breverbsc\b/i, 'reverbsc'],
    [/\bfreeverb\b/i, 'freeverb'],
    [/\bpan2\b/i, 'pan2'],
    [/\bouts\b/i, 'outs'],
    [/\bchnmix\b/i, 'chnmix send'],
  ]
  for (const [re, label] of rules) {
    if (re.test(body) && !tags.includes(label)) tags.push(label)
  }
  return tags
}

function chngetNames(body: string): string[] {
  const names: string[] = []
  for (const m of body.matchAll(/chnget\s+"([^"]+)"/gi)) {
    if (!names.includes(m[1])) names.push(m[1])
  }
  return names
}

function buildControlsDiagram(channels: ChannelSpec[]): string {
  if (!channels.length) return 'flowchart LR\n  empty[No chn_k controls declared]'
  const lines = ['flowchart TB', '  UI[Sliders · Presets · Randomize] --> SCC[setControlChannel]']
  for (const ch of channels.slice(0, 14)) {
    const id = mId(ch.name)
    const curve = ch.curve === 'exp' ? 'exp' : 'lin'
    lines.push(`  SCC --> ${id}["${ch.label || ch.name}<br/>${ch.min}…${ch.max}${ch.unit ? ' ' + ch.unit : ''} (${curve})"]`)
    lines.push(`  ${id} --> ORC["chnget \\"${ch.name}\\""]`)
  }
  if (channels.length > 14) {
    lines.push(`  more["+ ${channels.length - 14} more channels…"]`)
    lines.push('  SCC --> more')
  }
  return lines.join('\n')
}

export function buildSignalFlowStudy(input: SignalFlowStudyInput): SignalFlowStudy {
  const orc = extractStudyOrchestra(input.source)
  const channels = input.channels?.length ? input.channels : parseChannels(orc)
  const instruments = listInstruments(orc)
  const hasKeyboard = input.hasKeyboard ?? usesKeyboard(orc)
  const hasReverb = input.hasReverbBus ?? detectReverbBus(orc, instruments)
  const globals = globalAudioBuses(orc)
  const voice = instruments.find((i) => i.num === 1) ?? instruments[0]
  const fx = instruments.find((i) => i.num === 99)
  const setter = instruments.find((i) => i.num === 100)

  const summary: string[] = []
  summary.push(`${instruments.length} instrument(s): ${instruments.map((i) => i.num).join(', ') || 'none detected'}`)
  if (channels.length) summary.push(`${channels.length} host control channel(s) from chn_k`)
  if (hasKeyboard) summary.push('Keyboard / MIDI note path (instr 1 reads p4)')
  else summary.push('Always-on or scheduler texture (no p4 in instr 1)')
  if (hasReverb) summary.push('Global effect bus (instr 99 or reverb send)')
  if (globals.length) summary.push(`Global audio buses: ${globals.join(', ')}`)
  if (setter) summary.push('instr 100 — score-driven chnset bridge (Player / MIDI CC path)')

  const arch: string[] = ['flowchart TB']
  arch.push('  subgraph Host["Browser / Dr.C host"]')
  if (channels.length) arch.push('    Sliders[chn_k sliders]')
  if (hasKeyboard) {
    arch.push('    Keys[On-screen keyboard · QWERTY]')
    arch.push('    MIDI[USB MIDI]')
  }
  arch.push('    WASM[Csound WASM compileOrc · start]')
  arch.push('  end')
  if (channels.length) {
    arch.push('  Sliders -->|setControlChannel| WASM')
  }
  if (hasKeyboard) {
    arch.push('  Keys -->|inputMessage| WASM')
    arch.push('  MIDI -->|inputMessage| WASM')
  }
  if (voice) {
    arch.push(`  WASM --> I${voice.num}["instr ${voice.num} — voice"]`)
  }
  if (fx) {
    arch.push(`  I${voice?.num ?? 1} -->|send| I99["instr ${fx.num} — FX bus"]`)
    arch.push('  I99 --> Out["Stereo output"]')
  } else if (voice) {
    arch.push(`  I${voice.num} --> Out["Stereo output"]`)
  }
  if (hasKeyboard && hasReverb) {
    arch.push('  Viz[Waveform · FFT analyser tap] -.-> Out')
  }

  const sig: string[] = ['flowchart TB']
  if (voice) {
    const ops = voiceOpcodes(voice.body)
    const chn = chngetNames(voice.body)
    if (instrUsesP4(voice.body)) {
      sig.push('  p4["p4 → frequency (Hz)"]')
      sig.push('  p5["p5 → velocity"]')
    }
    if (chn.length) {
      sig.push('  subgraph CTL["Live controls (chnget)"]')
      for (const name of chn.slice(0, 10)) {
        const id = mId(name)
        sig.push(`    ${id}["${name}"]`)
      }
      if (chn.length > 10) sig.push(`    morec["+ ${chn.length - 10} more…"]`)
      sig.push('  end')
      sig.push('  CTL --> VOICE')
    }
    sig.push(`  VOICE["instr ${voice.num}"]`)
    if (instrUsesP4(voice.body)) {
      sig.push('  p4 --> VOICE')
      sig.push('  p5 --> VOICE')
    }
    let prev = 'VOICE'
    for (let i = 0; i < Math.min(ops.length, 8); i++) {
      const id = mId(`op${i}`)
      sig.push(`  ${id}["${ops[i]}"]`)
      sig.push(`  ${prev} --> ${id}`)
      prev = id
    }
    if (fx || globals.length) {
      sig.push('  DRY["dry outs"]')
      sig.push(`  ${prev} --> DRY`)
      if (globals.length) {
        const bus = mId(globals[0])
        sig.push(`  ${bus}["${globals[0]} send"]`)
        sig.push(`  ${prev} --> ${bus}`)
        sig.push(`  ${bus} --> IFX["instr ${fx?.num ?? 99} reverb"]`)
        sig.push('  IFX --> OUT["outs + clear bus"]')
      } else {
        sig.push('  DRY --> OUT["outs"]')
      }
    } else {
      sig.push(`  ${prev} --> OUT["outs"]`)
    }
  } else {
    sig.push('  nodetect[Could not parse instr blocks — open the orchestra source]')
  }

  return {
    title: input.title?.trim() || 'Instrument signal flow',
    summary,
    architectureMermaid: arch.join('\n'),
    signalFlowMermaid: sig.join('\n'),
    controlsMermaid: buildControlsDiagram(channels),
  }
}

/** Extract study source from a CSD or web-app HTML artifact body. */
export function studySourceFromContent(content: string, artifactType?: 'csd' | 'webapp' | 'vst'): string {
  if (artifactType === 'webapp' || /const\s+ORC\s*=/i.test(content)) {
    return extractStudyOrchestra(content)
  }
  return content
}
