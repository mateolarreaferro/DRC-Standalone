#!/usr/bin/env node
/**
 * Bundle generative Groovy workshop models (Jagwani + Marston).
 *   node scripts/ingest-generative-models.mjs
 */

import {
  readFileSync, writeFileSync, mkdirSync, existsSync, readdirSync,
} from 'node:fs'
import { join, dirname, basename } from 'node:path'
import { fileURLToPath } from 'node:url'
import { homedir } from 'node:os'

const REPO = dirname(dirname(fileURLToPath(import.meta.url)))
const SELECTED = join(homedir(), 'dB-Studio', 'Csound', 'Models - Selected')
const MODELS = join(homedir(), 'dB-Studio', 'Csound', 'MODELS')
const OUT_DIR = join(REPO, 'resources/knowledge/generative-models')
const BUNDLE_OUT = join(REPO, 'resources/knowledge/bundle-generative-models.json')
const CATALOG_OUT = join(REPO, 'resources/knowledge/sources/generative-models-catalog.md')
const DRC_TERMINAL = join(homedir(), 'Dr.C', 'opencode', 'packages', 'opencode')

const OPCODE_RE =
  /\b(metro|schedkwhen|schedule|random|trandom|fillarray|gbuzz|vco2|moogvcf|phasor|ftgen|chn_a|chnset|alwayson|turnon|reverbsc|jspline|rspline|grain|partikkel|foscili|oscil|noise|buthp|butterlp|port|midinoteon|midion|cpsmidinn)\b/gi

/** @type {object[]} */
const MANIFEST = []
/** @type {Record<string, string>} */
const contents = {}

function slug(s) {
  return s.replace(/[^a-zA-Z0-9]+/g, '-').replace(/^-|-$/g, '').toLowerCase()
}

const COLLECTIONS = [
  {
    root: SELECTED,
    dir: 'GENERATIVE - Aman Jagwani - Subtractive',
    collection: 'Aman Jagwani',
    author: 'Aman Jagwani',
    files: [
      { file: 'Subtractive.csd', id: 'generative-jagwani-subtractive', title: 'Generative Subtractive', workshopReady: true, qualityScore: 0.95 },
      { file: 'aman-SubtractiveDrums.csd', id: 'generative-jagwani-subtractive-drums', title: 'Subtractive Drums', workshopReady: true, qualityScore: 0.94 },
    ],
  },
  {
    root: MODELS,
    dir: 'GENERATIVE - Aman Jagwani - FM',
    collection: 'Aman Jagwani',
    author: 'Aman Jagwani',
    files: [{
      file: 'FM_generative_AmanJ.csd', id: 'generative-jagwani-fm', title: 'Generative FM Ensemble',
      workshopReady: true, qualityScore: 0.96,
      description: 'Chowning FM voices + metro/schedkwhen generative sequencer',
    }],
  },
  {
    root: MODELS,
    dir: 'GENERATIVE - Aman Jagwani - Mumbai',
    collection: 'Aman Jagwani',
    author: 'Aman Jagwani',
    files: [{
      file: 'finalproject_AmanJagwani.csd', id: 'generative-jagwani-mumbai', title: 'Mumbai Final Project',
      workshopReady: true, qualityScore: 0.94,
      techniques: ['generative', 'sample', 'gbuzz', 'metro'],
    }],
  },
  {
    root: MODELS,
    dir: 'GENERATIVE - Aman Jagwani - Pop',
    collection: 'Aman Jagwani',
    author: 'Aman Jagwani',
    files: [{
      file: 'exercise7_subtractive_amanjagwani.csd', id: 'generative-jagwani-pop', title: 'Pop Subtractive Groove',
      workshopReady: true, qualityScore: 0.93,
    }],
  },
  {
    root: MODELS,
    dir: 'GENERATIVE - Sam Marston - GenerativeCSDs/The best ones',
    collection: 'Sam Marston — Best',
    author: 'Sam Marston',
    prefix: 'generative-marston-best',
    workshopReady: true,
    qualityScore: 0.92,
    globAll: true,
  },
  {
    root: MODELS,
    dir: 'GENERATIVE - Sam Marston - GenJams',
    collection: 'Sam Marston — GenJams',
    author: 'Sam Marston',
    prefix: 'generative-marston-genjam',
    workshopReady: true,
    qualityScore: 0.93,
    globAll: true,
  },
  {
    root: MODELS,
    dir: 'GENERATIVE - Sam Marston - Jams for Vienna',
    collection: 'Sam Marston — Vienna Jams',
    author: 'Sam Marston',
    files: [
      { file: "Sam's_Jam1-V1.csd", id: 'generative-marston-vienna-jam1', title: "Sam's Jam 1 V1", workshopReady: true },
      { file: "Sam's_Jam2-V1.csd", id: 'generative-marston-vienna-jam2', title: "Sam's Jam 2 V1", workshopReady: true },
    ],
  },
  {
    root: MODELS,
    dir: 'GENERATIVE - Sam Marston - Drum - regular Beat',
    collection: 'Sam Marston — Regular Beat',
    author: 'Sam Marston',
    files: [
      { file: 'triads attempt with drums.csd', id: 'generative-marston-beat-triads-drums', title: 'Triads with Drums', workshopReady: true, qualityScore: 0.91 },
      { file: 'metered attempt 4.csd', id: 'generative-marston-beat-metered4', title: 'Metered Beat 4', workshopReady: true, qualityScore: 0.91 },
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

function extractOpcodes(content) {
  const found = new Set()
  let m
  const re = new RegExp(OPCODE_RE.source, 'gi')
  while ((m = re.exec(content)) !== null) found.add(m[1].toLowerCase())
  return [...found].sort()
}

function inferTechniques(opcodes, content) {
  const t = new Set(['generative'])
  if (opcodes.includes('metro') || opcodes.includes('schedkwhen')) t.add('sequencer')
  if (content.includes('gbuzz') || content.includes('foscili')) t.add('subtractive')
  if (content.includes('grain') || content.includes('partikkel')) t.add('granular')
  if (content.includes('jspline') || content.includes('rspline')) t.add('ambient')
  return [...t]
}

function addEntry(id, relPath, collection, author, title, content, opts = {}) {
  const opcodes = extractOpcodes(content)
  MANIFEST.push({
    id, relPath, collection, author: opts.author ?? author, title, opcodes,
    techniques: opts.techniques ?? inferTechniques(opcodes, content),
    primaryTechnique: opts.primaryTechnique ?? 'generative',
    domain: 'generative',
    filename: basename(relPath),
    description: opts.description ?? `${title} — ${opts.author ?? author}`,
    qualityScore: opts.qualityScore ?? 0.9,
    workshopReady: opts.workshopReady ?? false,
  })
  const dest = join(OUT_DIR, relPath)
  mkdirSync(dirname(dest), { recursive: true })
  writeFileSync(dest, content)
  contents[id] = content
}

function buildCatalog() {
  const byColl = new Map()
  for (const e of MANIFEST) {
    if (!byColl.has(e.collection)) byColl.set(e.collection, [])
    byColl.get(e.collection).push(e)
  }
  const lines = [
    '# Generative Groovy Models — Workshop Foundation',
    '',
    `**${MANIFEST.length} models** · RAG IDs \`generative-*\` · \`bundle-generative-models.json\``,
    '',
    '## Priority',
    '',
    '- `generative-jagwani-subtractive` / `generative-jagwani-fm` — metro + schedkwhen generative ensembles ★',
    '- `generative-marston-best-in-the-park-randomized-start` — randomized generative jam ★',
    '- `generative-marston-genjam1a-100` … `genjam4` — self-playing GenJams',
    '- `generative-marston-beat-metered4` — regular beat + triads',
    '',
    '## Collections',
    '',
  ]
  for (const [coll, items] of [...byColl.entries()].sort((a, b) => a[0].localeCompare(b[0]))) {
    lines.push(`### ${coll}`)
    lines.push('')
    for (const e of items.sort((a, b) => a.title.localeCompare(b.title))) {
      const star = e.workshopReady ? ' ★' : ''
      lines.push(`- **${e.title}**${star} — \`${e.id}\``)
    }
    lines.push('')
  }
  return lines.join('\n')
}

for (const coll of COLLECTIONS) {
  const dir = join(coll.root, coll.dir)
  if (!existsSync(dir)) {
    console.warn('SKIP missing:', dir)
    continue
  }
  if (coll.globAll) {
    for (const file of readdirSync(dir).filter((f) => f.endsWith('.csd')).sort()) {
      const id = `${coll.prefix}-${slug(basename(file, '.csd'))}`
      const csd = sanitizeCsd(readFileSync(join(dir, file), 'utf-8'))
      addEntry(id, `${slug(coll.collection)}/${file}`, coll.collection, coll.author,
        basename(file, '.csd'), csd, { workshopReady: coll.workshopReady, qualityScore: coll.qualityScore })
      console.log(' ', id)
    }
    continue
  }
  for (const spec of coll.files) {
    const src = join(dir, spec.file)
    if (!existsSync(src)) { console.warn('SKIP', src); continue }
    const csd = sanitizeCsd(readFileSync(src, 'utf-8'))
    addEntry(spec.id, `${slug(coll.collection)}/${spec.file}`, coll.collection, coll.author, spec.title, csd, spec)
    console.log(' ', spec.id)
  }
}

writeFileSync(BUNDLE_OUT, JSON.stringify({
  version: 'generative-models-v1',
  createdAt: Date.now(),
  count: MANIFEST.length,
  entries: MANIFEST,
  contents,
}))
writeFileSync(CATALOG_OUT, buildCatalog())
console.log(`\nWrote ${MANIFEST.length} generative models → ${BUNDLE_OUT}`)
