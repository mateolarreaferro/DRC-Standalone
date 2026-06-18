#!/usr/bin/env node
/**
 * Bundle Dr. B selected + MODELS drum / drum-machine CSDs into the knowledge base.
 *
 *   node scripts/ingest-drum-models.mjs
 */

import {
  readFileSync, writeFileSync, mkdirSync, existsSync, copyFileSync,
} from 'node:fs'
import { join, dirname, basename } from 'node:path'
import { fileURLToPath } from 'node:url'
import { homedir } from 'node:os'

const REPO = dirname(dirname(fileURLToPath(import.meta.url)))
const SELECTED = join(homedir(), 'dB-Studio', 'Csound', 'Models - Selected')
const MODELS = join(homedir(), 'dB-Studio', 'Csound', 'MODELS')
const OUT_DIR = join(REPO, 'resources/knowledge/drum-models')
const BUNDLE_OUT = join(REPO, 'resources/knowledge/bundle-drum-models.json')
const CATALOG_OUT = join(REPO, 'resources/knowledge/sources/drum-models-catalog.md')
const DRC_TERMINAL = join(homedir(), 'Dr.C', 'opencode', 'packages', 'opencode')

const OPCODE_RE =
  /\b(noise|rand|unirand|oscil|oscil3|oscili|phasor|table|tablei|expon|linen|butterlp|butterhp|buthp|comb|metro|schedkwhen|random|exprand|schedule|event_i|vco2|expseg|expsegr|tanh|delayr|deltap3|port|portk|ftgen|ftgentmp|ampmidi|cpsmidi|midion|midinoteon|chn|vincr|reverbsc|outc|outs|guiro|tambourine|bamboo|mvclpf3|alwayson|turnon)\b/gi

/** @type {object[]} */
const MANIFEST = []

/** @type {Record<string, string>} */
const contents = {}

function slug(s) {
  return s.replace(/[^a-zA-Z0-9]+/g, '-').replace(/^-|-$/g, '').toLowerCase()
}

/** @type {object[]} */
const COLLECTIONS = [
  // ── Models - Selected ──────────────────────────────────────────────
  {
    root: SELECTED,
    dir: 'DRUM - DrumMachine',
    collection: 'Drum Machine',
    author: 'Csound Workshop',
    files: [{ file: 'DrumMachine.csd', id: 'drum-drummachine', title: 'DrumMachine', workshopReady: true, qualityScore: 0.92 }],
  },
  {
    root: SELECTED,
    dir: 'DRUM - Electronic DrumKits',
    collection: 'Electronic Drum Kits',
    author: 'Richard Boulanger',
    files: [{
      file: 'Synthesis_Electric_Drum_Kit_1.csd', id: 'drum-electric-kit-1', title: 'Synthesis Electric Drum Kit 1',
      workshopReady: true, qualityScore: 0.94,
      description: 'Multi-instrument electric kit with rhythm tables and send buses',
    }],
  },
  {
    root: SELECTED,
    dir: 'DRUM - FullKit',
    collection: 'Full Kit',
    author: 'Richard Boulanger',
    files: [{ file: 'FullKit.csd', id: 'drum-fullkit', title: 'FullKit', workshopReady: true, qualityScore: 0.94 }],
  },
  {
    root: SELECTED,
    dir: 'DRUM - Generative - Iain McCurdy',
    collection: 'Generative Drums',
    author: 'Iain McCurdy',
    files: [{
      file: '05E04.csd', id: 'drum-mccurdy-generative-05e04', title: 'Generative Drum Ensemble (05E04)',
      workshopReady: true, qualityScore: 0.96,
      description: 'metro + schedkwhen random drum hits',
      techniques: ['generative', 'schedkwhen', 'metro', 'electronic-drums'],
      primaryTechnique: 'generative',
    }],
  },
  {
    root: SELECTED,
    dir: 'DRUM - Glitch - Anton Kholomiov',
    collection: 'Glitch Drums',
    author: 'Anton Kholomiov',
    files: [
      { file: 'dely-glitch.csd', id: 'drum-kholomiov-dely-glitch', title: 'Dely Glitch', qualityScore: 0.88,
        techniques: ['glitch', 'delay'], primaryTechnique: 'glitch' },
      { file: 'del-dance-glitch.csd', id: 'drum-kholomiov-del-dance-glitch', title: 'Del Dance Glitch', qualityScore: 0.88,
        techniques: ['glitch', 'delay'], primaryTechnique: 'glitch' },
    ],
  },
  {
    root: SELECTED,
    dir: 'DRUM - K35 - Yi',
    collection: 'K35 MS-20 Drums',
    author: 'Steven Yi',
    files: [{
      file: 'k35.csd', id: 'drum-yi-k35-ms20', title: 'K35 MS-20 Drum & Bass Player',
      workshopReady: true, qualityScore: 0.95, inlineIncludes: true,
      description: 'k35 filters + ms20_drum + beat_player scheduler',
      techniques: ['ms20', 'k35-filter', 'schedule'],
    }],
  },

  // ── MODELS — individual elements & kits ────────────────────────────
  {
    root: MODELS,
    dir: 'DRUM - Individual ELements - Clap, Hat, Kick, Crash',
    collection: 'Individual Drum Elements',
    author: 'Richard Boulanger',
    files: [
      { file: 'Kick1.csd', id: 'drum-element-kick1', title: 'Kick 1', workshopReady: true },
      { file: 'Kick2.csd', id: 'drum-element-kick2', title: 'Kick 2', workshopReady: true },
      { file: 'Kick3.csd', id: 'drum-element-kick3', title: 'Kick 3', workshopReady: true },
      { file: 'Kick-Techno.csd', id: 'drum-element-kick-techno', title: 'Kick Techno', workshopReady: true },
      { file: 'Hi-Hat.csd', id: 'drum-element-hihat', title: 'Hi-Hat', workshopReady: true },
      { file: 'HandClap.csd', id: 'drum-element-clap', title: 'Hand Clap', workshopReady: true },
      { file: 'Crash.csd', id: 'drum-element-crash', title: 'Crash', workshopReady: true },
    ],
  },
  {
    root: MODELS,
    dir: 'DRUM - Iteritive with Schedule of a Schedule',
    collection: 'Iterative Scheduling',
    author: 'Csound Workshop',
    files: [{
      file: 'iterativeDrums.csd', id: 'drum-iterative-schedule', title: 'Iterative Drums (schedule of schedule)',
      workshopReady: true, qualityScore: 0.91,
      techniques: ['schedule', 'recursive', 'electronic-drums'],
    }],
  },
  {
    root: MODELS,
    dir: 'DRUM - Kick',
    collection: 'Kick Drum',
    author: 'Csound Workshop',
    files: [{ file: 'drum.csd', id: 'drum-kick-basic', title: 'Basic Kick', workshopReady: true }],
  },
  {
    root: MODELS,
    dir: 'DRUM - Machine - SimpleLoopSequencer - Iain McCurdy',
    collection: 'Drum Machine Sequencer',
    author: 'Iain McCurdy',
    files: [{
      file: '-Iain McCurdy - Drum Machine - SimpleLoopSequencer.csd',
      id: 'drum-mccurdy-simple-loop-sequencer',
      title: 'Simple Loop Sequencer Drum Machine',
      workshopReady: true, qualityScore: 0.96,
      description: '16-step ftgen patterns + schedkwhen loop sequencer',
      techniques: ['sequencer', 'schedkwhen', 'metro', 'drum-machine'],
      primaryTechnique: 'sequencer',
    }],
  },
  {
    root: MODELS,
    dir: 'DRUM - Matrix+ToneMatrix-FLTK-Anton_Kholomiov',
    collection: 'Tone Matrix',
    author: 'Anton Kholomiov',
    files: [
      { file: 'tonematrix.csd', id: 'drum-kholomiov-tonematrix', title: 'Tone Matrix', qualityScore: 0.9 },
      { file: 'tonematrix-hangdrum.csd', id: 'drum-kholomiov-tonematrix-hangdrum', title: 'Tone Matrix Hang Drum', qualityScore: 0.9 },
    ],
  },
  {
    root: MODELS,
    dir: 'DRUM - Percussion Instrument Model Opcodes',
    collection: 'Percussion Opcodes',
    author: 'Perry Cook / Csound Manual',
    files: [{
      file: 'PercussionModels.csd', id: 'drum-percussion-opcodes', title: 'Percussion Model Opcodes',
      workshopReady: true, qualityScore: 0.93,
      description: 'guiro, tambourine, bamboo, cabasa, sandpaper, etc.',
      techniques: ['physical-model', 'percussion-opcodes'],
      primaryTechnique: 'physical-model',
    }],
  },
  {
    root: MODELS,
    dir: 'DRUM - Peter Gunn with Drums',
    collection: 'Peter Gunn',
    author: 'Csound Workshop',
    files: [{ file: 'PeterGunnWithDrums.csd', id: 'drum-peter-gunn', title: 'Peter Gunn with Drums', workshopReady: true }],
  },
  {
    root: MODELS,
    dir: 'DRUM - RecursiveDrum Victor Lazzarini ',
    collection: 'Recursive Drum',
    author: 'Victor Lazzarini',
    files: [{
      file: 'Victor Lazzarini - RecursiveDrum.csd', id: 'drum-lazzarini-recursive', title: 'Recursive Drum',
      workshopReady: true, qualityScore: 0.94,
      description: 'event_i recursive harmonic drum synthesis',
      techniques: ['recursive', 'oscil3', 'event_i'],
    }],
  },
  {
    root: MODELS,
    dir: 'DRUM - Replacement',
    collection: 'Drum Replacement',
    author: 'Iain McCurdy',
    files: [{
      file: '05L04_Drum_Replacement.csd', id: 'drum-replacement-05l04', title: 'Drum Replacement (05L04)',
      workshopReady: true, qualityScore: 0.92,
      techniques: ['live-input', 'replacement'],
    }],
  },
  {
    root: MODELS,
    dir: 'DRUM - Sequencer1 - Jacob Joaquin',
    collection: 'Thumbuki Sequencer',
    author: 'Jacob Joaquin',
    files: [{
      file: 'thumbuki20070502.csd', id: 'drum-joaquin-thumbuki', title: 'Thumbuki Sequencer',
      workshopReady: true, qualityScore: 0.9,
      techniques: ['sequencer', 'drum-machine'],
    }],
  },
  {
    root: MODELS,
    dir: 'DRUM - Sequencer2 +Article - Jacob Joaquin',
    collection: 'dseq Drum Machine Language',
    author: 'Jacob Joaquin',
    subdir: 'dseq',
    files: [
      { file: 'dseqQuickStart.csd', id: 'drum-joaquin-dseq-quickstart', title: 'dseq Quick Start',
        workshopReady: true, qualityScore: 0.96, inlineIncludes: true,
        description: 'dseq micro-language drum machine quick start', techniques: ['dseq', 'sequencer', 'drum-machine'] },
      { file: 'dseqDesign.csd', id: 'drum-joaquin-dseq-design', title: 'dseq Design', inlineIncludes: true, qualityScore: 0.93 },
      { file: 'dseqRhythmNotation.csd', id: 'drum-joaquin-dseq-rhythm-notation', title: 'dseq Rhythm Notation', inlineIncludes: true },
      { file: 'dseqPsy.csd', id: 'drum-joaquin-dseq-psy', title: 'dseq Psy', inlineIncludes: true },
      { file: 'dseqLibrary.csd', id: 'drum-joaquin-dseq-library', title: 'dseq Library', inlineIncludes: true },
    ],
  },
  {
    root: MODELS,
    dir: 'DRUM - Subtractive DrumKit',
    collection: 'Subtractive Drum Kit',
    author: 'Richard Boulanger',
    files: [{
      file: 'DrumKitSubtractive.csd', id: 'drum-subtractive-kit', title: 'Subtractive DrumKit',
      workshopReady: true, qualityScore: 0.93,
    }],
  },
  {
    root: MODELS,
    dir: 'DRUMS -  + drum machines',
    collection: 'Drum Machines Archive',
    author: 'Various',
    files: [
      { file: 'Drum.csd', id: 'drum-archive-kick-score', title: 'Kick with Score Pattern', workshopReady: true,
        description: 'Named Kick instr + scored groove (expsegr/mvclpf3)' },
      { file: 'beatFox-Micah_Frank/Beatfox.csd', id: 'drum-frank-beatfox', title: 'Beatfox', author: 'Micah Frank',
        workshopReady: true, qualityScore: 0.91 },
      { file: 'beatMangler-Amen_Break/beat_mangler_x.csd', id: 'drum-amen-beat-mangler', title: 'Amen Beat Mangler',
        author: 'Csound Workshop', workshopReady: true, qualityScore: 0.9,
        techniques: ['amen-break', 'sample', 'drum-machine'] },
    ],
  },
]

function sanitizeCsd(text) {
  return text
    .replace(/<bsbPanel>[\s\S]*/i, '')
    .replace(/<MacOptions>[\s\S]*/i, '')
    .replace(/<MacGUI>[\s\S]*/i, '')
    .replace(/\r\n/g, '\n')
    .trim() + '\n'
}

function inlineIncludes(content, baseDir, depth = 0) {
  if (depth > 6) return content
  return content.replace(/#include\s+"([^"]+)"/gi, (_, inc) => {
    const bare = inc.replace(/^\.\//, '').replace(/^\.\.\//, '')
    const candidates = [
      join(baseDir, inc),
      join(baseDir, bare),
      join(dirname(baseDir), bare),
      join(baseDir, '..', bare),
    ]
    for (const p of candidates) {
      if (existsSync(p)) {
        const body = readFileSync(p, 'utf-8')
        return `; --- inlined: ${inc} ---\n${inlineIncludes(body, dirname(p), depth + 1)}\n; --- end ${inc} ---\n`
      }
    }
    return `; INCLUDE NOT FOUND: ${inc}\n`
  })
}

function extractOpcodes(content) {
  const found = new Set()
  let m
  const re = new RegExp(OPCODE_RE.source, 'gi')
  while ((m = re.exec(content)) !== null) found.add(m[1].toLowerCase())
  for (const udo of ['AnalogDelay', 'k35_lpf', 'k35_hpf', 'beat_dur', 'ms20_drum', 'dseq']) {
    if (content.includes(`opcode ${udo}`) || content.includes(`instr ${udo}`) || content.includes('# define dseq')) {
      found.add(udo.toLowerCase())
    }
  }
  return [...found].sort()
}

function inferTechniques(opcodes, content) {
  const t = new Set(['electronic-drums'])
  if (opcodes.includes('schedkwhen') || opcodes.includes('metro')) t.add('generative')
  if (opcodes.includes('schedule') || content.includes('beat_player') || content.includes('dseq')) t.add('sequencer')
  if (opcodes.includes('noise') || opcodes.includes('rand')) t.add('noise-percussion')
  if (content.includes('k35_')) t.add('ms20')
  if (content.includes('AnalogDelay')) t.add('glitch')
  if (opcodes.includes('guiro') || opcodes.includes('tambourine')) t.add('percussion-opcodes')
  if (content.includes('event_i')) t.add('recursive')
  return [...t]
}

function addEntry(id, relPath, collection, author, title, content, opts = {}) {
  const opcodes = extractOpcodes(content)
  const entry = {
    id,
    relPath,
    collection,
    author: opts.author ?? author,
    title,
    opcodes,
    techniques: opts.techniques ?? inferTechniques(opcodes, content),
    primaryTechnique: opts.primaryTechnique ?? 'electronic-drums',
    domain: 'drums',
    filename: basename(relPath),
    description: opts.description ?? `${title} — ${opts.author ?? author}`,
    qualityScore: opts.qualityScore ?? 0.9,
    workshopReady: opts.workshopReady ?? false,
  }
  MANIFEST.push(entry)
  const dest = join(OUT_DIR, relPath)
  mkdirSync(dirname(dest), { recursive: true })
  writeFileSync(dest, content)
  contents[id] = content
  return entry
}

function syncToDrcTerminal() {
  if (!existsSync(DRC_TERMINAL)) return
  const termKnowledge = join(DRC_TERMINAL, 'resources', 'knowledge')
  mkdirSync(join(termKnowledge, 'sources'), { recursive: true })
  copyFileSync(BUNDLE_OUT, join(termKnowledge, 'bundle-drum-models.json'))
  copyFileSync(CATALOG_OUT, join(termKnowledge, 'sources', 'drum-models-catalog.md'))
  console.log('Synced → Dr.C Terminal', termKnowledge)
}

function buildCatalog() {
  const byColl = new Map()
  for (const e of MANIFEST) {
    if (!byColl.has(e.collection)) byColl.set(e.collection, [])
    byColl.get(e.collection).push(e)
  }
  const lines = [
    '# Synthetic Drum Models — Workshop Foundation',
    '',
    'Curated electronic drum authorities for Dr.C. Adapt for **kick**, **snare**, **hi-hat**, **sequencer**, **dseq**, **generative drums**, **glitch**, and **MS-20** percussion prompts.',
    '',
    `**${MANIFEST.length} models** · RAG IDs \`drum-*\` · \`bundle-drum-models.json\``,
    '',
    '## Priority',
    '',
    '- `drum-joaquin-dseq-quickstart` — Jacob Joaquin dseq drum-machine micro-language ★',
    '- `drum-mccurdy-simple-loop-sequencer` — 16-step loop sequencer drum machine ★',
    '- `drum-mccurdy-generative-05e04` — metro + schedkwhen random generative kit',
    '- `drum-element-kick1` … `drum-element-hihat` — individual synthesized elements',
    '- `drum-yi-k35-ms20` — MS-20 k35 filter drums with beat_player',
    '- `drum-lazzarini-recursive` — recursive harmonic drum (event_i)',
    '- `drum-amen-beat-mangler` — amen break mangler',
    '- `drum-percussion-opcodes` — guiro/tambourine/bamboo Cook opcodes',
    '',
    '## Collections',
    '',
  ]
  for (const [coll, items] of [...byColl.entries()].sort((a, b) => a[0].localeCompare(b[0]))) {
    lines.push(`### ${coll}`)
    lines.push('')
    for (const e of items.sort((a, b) => a.title.localeCompare(b.title))) {
      const star = e.workshopReady ? ' ★' : ''
      lines.push(`- **${e.title}**${star} — \`${e.id}\` — ${e.opcodes.slice(0, 10).join(', ')}`)
    }
    lines.push('')
  }
  return lines.join('\n')
}

for (const coll of COLLECTIONS) {
  const dir = join(coll.root, coll.dir, coll.subdir ?? '')
  if (!existsSync(dir)) {
    console.warn('SKIP missing:', dir)
    continue
  }
  for (const spec of coll.files) {
    const src = join(coll.root, coll.dir, coll.subdir ? join(coll.subdir, spec.file) : spec.file)
    if (!existsSync(src)) {
      console.warn('SKIP missing:', src)
      continue
    }
    let raw = readFileSync(src, 'utf-8')
    const baseDir = dirname(src)
    if (spec.inlineIncludes) raw = inlineIncludes(raw, baseDir)
    const csd = sanitizeCsd(raw)
    const relPath = `${slug(coll.collection)}/${spec.file}`
    addEntry(spec.id, relPath, coll.collection, coll.author, spec.title, csd, spec)
    console.log(' ', spec.id, `(${(csd.length / 1024).toFixed(0)} KB)`)
  }
}

writeFileSync(BUNDLE_OUT, JSON.stringify({
  version: 'drum-models-v2',
  createdAt: Date.now(),
  count: MANIFEST.length,
  entries: MANIFEST,
  contents,
}))
writeFileSync(CATALOG_OUT, buildCatalog())
console.log(`\nWrote ${MANIFEST.length} drum models → ${BUNDLE_OUT}`)
syncToDrcTerminal()
