#!/usr/bin/env node
/**
 * Ingest Dr. B's Selected Instruments from The Csound Catalog v2.5.
 *
 *   node scripts/ingest-selected-catalog-v25.mjs
 *   node scripts/ingest-selected-catalog-v25.mjs "/path/to/Selected_Instruments..."
 */

import {
  readFileSync, writeFileSync, mkdirSync, readdirSync, existsSync, statSync, copyFileSync,
} from 'node:fs'
import { join, dirname, basename, relative } from 'node:path'
import { fileURLToPath } from 'node:url'
import { homedir } from 'node:os'

const REPO = dirname(dirname(fileURLToPath(import.meta.url)))
const DEFAULT_SRC = join(
  homedir(),
  'Desktop',
  'Selected_Instruments_from_The_Csound_Catalog_v2.5',
)
const OUT_DIR = join(REPO, 'resources/knowledge/selected-catalog-v25')
const BUNDLE_OUT = join(REPO, 'resources/knowledge/bundle-selected-catalog-v25.json')
const CATALOG_OUT = join(REPO, 'resources/knowledge/sources/selected-catalog-v25.md')
const DRC_TERMINAL = join(homedir(), 'Dr.C', 'opencode', 'packages', 'opencode')

const AUTHOR_LABELS = {
  Comajuncosas: 'Josep Comajuncosas',
  Cook: 'Perry Cook',
  Costello: 'Mark D. Costello',
  Dodge: 'Charles Dodge',
  DrB_Favorites: 'Dr. Boulanger Selection',
  Harrington: 'Harrington',
  Lyon: 'Lyon',
  Mikelson: 'Mikelson',
  Risset: 'Jean-Claude Risset',
  Smaragdis: 'Panos Smaragdis',
  Varga: 'Varga',
  Varo: 'Varo (GM-style)',
  fromTheCsoundMailingList: 'Csound Mailing List',
  Esch: 'Esch',
  Hanna: 'Hanna',
  Misc_csd: 'Misc',
  Neuwirth: 'Neuwirth',
  Newton: 'Newton',
  Volkov: 'Volkov',
}

const OPCODE_RE =
  /\b(oscili?|poscil|vco2?|moogvcf|moogladder|lpf18|butterlp|butterhp|reverbsc|reverb2?|freeverb|delay[rw]?|vdelay3?|flanger|chorus|phaser[12]|distort1?|tanh|foscili?|buzz|gbuzz|grain3?|partikkel|fof2?|wgpluck2?|wguide[12]|wgflute|pluck|pinkish|rand[hi]?|jitter2?|linen|adsr|linseg|expseg|transeg|jspline|rspline|reson|compress2?|pan2?|metro|schedkwhen|hsboscil|table3|tonex|phasor|hilbert|markov|seqtime|alwayson|event_i)\b/gi

const TECHNIQUE_BY_OPCODE = {
  gbuzz: 'additive-buzz', buzz: 'additive-buzz', foscili: 'fm', foscil: 'fm',
  moogvcf: 'subtractive', moogladder: 'subtractive', butterlp: 'subtractive',
  reverbsc: 'reverb', freeverb: 'reverb', reverb: 'reverb',
  vdelay3: 'delay', delay: 'delay', vdelay: 'delay',
  wguide1: 'waveguide', wguide2: 'waveguide', wgpluck: 'waveguide',
  grain3: 'granular', partikkel: 'granular', fof2: 'granular',
  phaser2: 'phaser', chorus: 'chorus', flanger: 'flanger',
  schedkwhen: 'generative', metro: 'generative', seqtime: 'generative',
  hsboscil: 'wavetable', table3: 'wavetable', oscil3: 'wavetable',
}

function sanitizeCsd(text) {
  return text
    .replace(/<bsbPanel>[\s\S]*/i, '')
    .replace(/<MacOptions>[\s\S]*/i, '')
    .replace(/<MacGUI>[\s\S]*/i, '')
    .replace(/\r\n/g, '\n')
    .trim() + '\n'
}

function slug(s) {
  return s.replace(/[^a-zA-Z0-9]+/g, '-').replace(/^-|-$/g, '').toLowerCase()
}

function extractOpcodes(content) {
  const found = new Set()
  let m
  const re = new RegExp(OPCODE_RE.source, 'gi')
  while ((m = re.exec(content)) !== null) {
    found.add(m[1].toLowerCase())
  }
  return [...found].sort()
}

function inferTechniques(opcodes) {
  const t = new Set()
  for (const op of opcodes) {
    for (const [key, tech] of Object.entries(TECHNIQUE_BY_OPCODE)) {
      if (op.startsWith(key) || op === key) t.add(tech)
    }
  }
  if (t.size === 0) t.add('synthesis')
  return [...t]
}

function inferDomain(opcodes, techniques) {
  if (techniques.some((t) => ['reverb', 'delay', 'phaser', 'chorus', 'flanger'].includes(t))) return 'effects'
  if (techniques.includes('generative')) return 'modulation'
  return 'synthesis'
}

function walkCsds(dir, relBase = '') {
  const out = []
  for (const name of readdirSync(dir)) {
    const full = join(dir, name)
    if (statSync(full).isDirectory()) {
      out.push(...walkCsds(full, relBase ? join(relBase, name) : name))
      continue
    }
    if (!name.toLowerCase().endsWith('.csd')) continue
    out.push({ full, rel: relBase ? join(relBase, name) : name })
  }
  return out
}

function collectionFromRel(rel) {
  const parts = rel.split(/[/\\]/)
  if (parts[0] === 'fromTheCsoundMailingList' && parts.length > 2) {
    return { collection: 'fromTheCsoundMailingList', author: parts[1], subpath: parts.slice(1).join('/') }
  }
  return { collection: parts[0], author: parts[0], subpath: rel }
}

function makeId(collection, author, filename, drbFavorite) {
  const fileSlug = slug(basename(filename, '.csd'))
  if (drbFavorite) return `catalog-v25-drb-${fileSlug}`
  const authorSlug = slug(author === collection ? author : `${collection}-${author}`)
  return `catalog-v25-${authorSlug}-${fileSlug}`
}

function buildCatalog(entries) {
  const byCollection = new Map()
  for (const e of entries) {
    const key = e.collection
    if (!byCollection.has(key)) byCollection.set(key, [])
    byCollection.get(key).push(e)
  }

  const lines = [
    '# Selected Instruments — The Csound Catalog v2.5',
    '',
    '**Dr. Richard Boulanger** curated selection from *The Csound Catalog* (v2.5). These are **foundational models** — adapt before inventing when a prompt matches their synthesis domain.',
    '',
    `**${entries.length} instruments** · RAG IDs \`catalog-v25-*\` · bundle \`bundle-selected-catalog-v25.json\``,
    '',
    '## Priority',
    '',
    '- `catalog-v25-drb-*` — Dr. Boulanger favorites (highest boost)',
    '- Named composers: **Risset**, **Cook**, **Costello**, **Comajuncosas**, **Smaragdis**, **Varo** GM set, **Mikelson**, **Dodge**',
    '- When retrieval returns a catalog example, **adapt its opcode wiring and ftgen tables**.',
    '',
    '## Collections',
    '',
  ]

  for (const [coll, items] of [...byCollection.entries()].sort((a, b) => a[0].localeCompare(b[0]))) {
    const label = AUTHOR_LABELS[coll] ?? coll
    lines.push(`### ${label} (${items.length})`)
    lines.push('')
    for (const e of items.sort((a, b) => a.filename.localeCompare(b.filename))) {
      const star = e.drbFavorite ? ' ★' : ''
      lines.push(`- **${e.filename}**${star} — \`${e.id}\` — ${e.opcodes.slice(0, 6).join(', ')}`)
    }
    lines.push('')
  }

  lines.push('## Cross-cutting techniques')
  lines.push('')
  lines.push('- **Risset** — spectral mutation, endless glissandi, bell functions (Dodge book lineage)')
  lines.push('- **Cook** — classic Csound pedagogy (buzz, chant, fof choir, gbuzz bass)')
  lines.push('- **Comajuncosas / DrB_Favorites** — analog FM pads, TB-303, karplus, iterated sine')
  lines.push('- **Varo** — Yamaha-style GM instruments (marimba, strings, brass, pluck bass)')
  lines.push('- **Smaragdis** — granular / FM hybrids (anagrain, altfm)')
  lines.push('- **Mikelson** — additive + analog bass/drum workshop models')
  lines.push('')

  return lines.join('\n')
}

function syncToDrcTerminal() {
  const termKnowledge = join(DRC_TERMINAL, 'resources', 'knowledge')
  if (!existsSync(DRC_TERMINAL)) {
    console.warn('Dr.C Terminal not found at', DRC_TERMINAL, '— skip sync')
    return
  }
  mkdirSync(termKnowledge, { recursive: true })
  mkdirSync(join(termKnowledge, 'sources'), { recursive: true })
  mkdirSync(join(termKnowledge, 'selected-catalog-v25'), { recursive: true })

  copyFileSync(BUNDLE_OUT, join(termKnowledge, 'bundle-selected-catalog-v25.json'))
  copyFileSync(CATALOG_OUT, join(termKnowledge, 'sources', 'selected-catalog-v25.md'))

  // Sync elected + haiku bundles if present (workshop foundation parity)
  for (const extra of [
    'bundle-elected-models.json',
    'bundle-mccurdy-haiku.json',
    'sources/elected-models-catalog.md',
    'sources/mccurdy-haiku-catalog.md',
  ]) {
    const src = join(REPO, 'resources/knowledge', extra)
    if (existsSync(src)) copyFileSync(src, join(termKnowledge, extra))
  }

  console.log('Synced bundles + catalog → Dr.C Terminal', termKnowledge)
}

const srcRoot = process.argv[2] ?? DEFAULT_SRC
if (!existsSync(srcRoot)) {
  console.error('Source folder not found:', srcRoot)
  process.exit(1)
}

mkdirSync(OUT_DIR, { recursive: true })
const files = walkCsds(srcRoot)
const contents = {}
const entries = []

for (const { full, rel } of files) {
  const { collection, author, subpath } = collectionFromRel(rel)
  const drbFavorite = collection === 'DrB_Favorites'
  const raw = readFileSync(full, 'utf-8')
  const clean = sanitizeCsd(raw)
  const filename = basename(full)
  const id = makeId(collection, author, filename, drbFavorite)
  const opcodes = extractOpcodes(clean)
  const techniques = inferTechniques(opcodes)
  const domain = inferDomain(opcodes, techniques)
  const destDir = join(OUT_DIR, dirname(subpath))
  mkdirSync(destDir, { recursive: true })
  writeFileSync(join(OUT_DIR, subpath), clean)

  const authorLabel = AUTHOR_LABELS[author] ?? AUTHOR_LABELS[collection] ?? author
  const title = drbFavorite
    ? `Dr.B pick: ${basename(filename, '.csd')}`
    : `${authorLabel}: ${basename(filename, '.csd')}`

  entries.push({
    id,
    author: authorLabel,
    collection,
    filename,
    relPath: `selected-catalog-v25/${subpath.replace(/\\/g, '/')}`,
    opcodes,
    techniques,
    primaryTechnique: techniques[0],
    domain,
    drbFavorite,
    title,
    description: `${title} — selected from The Csound Catalog v2.5 (${techniques.join(', ')})`,
    qualityScore: drbFavorite ? 0.96 : 0.88,
  })
  contents[id] = clean
  console.log(' ', id, '←', rel)
}

const bundle = {
  version: 'catalog-v2.5-boulanger',
  createdAt: Date.now(),
  source: srcRoot,
  count: entries.length,
  entries,
  contents,
}

writeFileSync(BUNDLE_OUT, JSON.stringify(bundle))
writeFileSync(CATALOG_OUT, buildCatalog(entries))
console.log(`\nWrote ${entries.length} instruments → ${BUNDLE_OUT}`)
syncToDrcTerminal()
