#!/usr/bin/env node
/**
 * Copy Dr. B's elected Csound Models into resources/knowledge/elected-models/
 * and regenerate bundle-elected-models.json + elected-models-catalog.md.
 *
 * Source (default): ~/Desktop/elected Csound Models/
 *   node scripts/ingest-elected-models.mjs
 *   node scripts/ingest-elected-models.mjs "/path/to/elected Csound Models"
 */

import { readFileSync, writeFileSync, mkdirSync, copyFileSync, existsSync, readdirSync } from 'node:fs'
import { join, dirname, basename } from 'node:path'
import { fileURLToPath } from 'node:url'
import { homedir } from 'node:os'

const REPO = dirname(dirname(fileURLToPath(import.meta.url)))
const DEFAULT_SRC = join(homedir(), 'Desktop', 'elected Csound Models')
const OUT_DIR = join(REPO, 'resources/knowledge/elected-models')
const BUNDLE_OUT = join(REPO, 'resources/knowledge/bundle-elected-models.json')
const CATALOG_OUT = join(REPO, 'resources/knowledge/sources/elected-models-catalog.md')

/** @type {{ folder: string, slug: string, author: string, title: string, year?: string, keywords: string[], opcodes: string[], summary: string }[]} */
const MODELS = [
  {
    folder: 'Bass Wobble - Thorin Kerr',
    slug: 'bass-wobble-thorin-kerr',
    author: 'Thorin Kerr',
    title: 'Bass Wobble',
    keywords: ['wobble', 'gbuzz', 'bass', 'distort', 'jspline', 'dubstep'],
    opcodes: ['gbuzz', 'jspline', 'distort', 'oscil3', 'linseg', 'cpspch'],
    summary: 'Detuned dual gbuzz layers with oscil3 wobble depth, jspline pitch drift, and cubic distort — classic wobble bass.',
  },
  {
    folder: 'Chinese Instruments - Andrew Horner',
    slug: 'chinese-instruments-andrew-horner',
    author: 'Andrew Horner',
    title: 'Chinese Instruments',
    keywords: ['dizi', 'sheng', 'hulusi', 'chinese', 'horner', 'flute', 'reed', 'physical model'],
    opcodes: ['oscil', 'randi', 'tablei', 'linseg', 'reverb'],
    summary: 'Andrew Horner physical models: Dizi (bamboo flute), Sheng (mouth organ), Hulusi (gourd pipe), HornerXing (ensemble piece).',
  },
  {
    folder: 'DeepNote - Steven Yi',
    slug: 'deepnote-steven-yi',
    author: 'Steven Yi',
    title: 'Deep Note',
    keywords: ['deep note', 'thx', 'vco2', 'moogvcf', 'jitter', 'drone', 'glissando'],
    opcodes: ['vco2', 'moogvcf', 'jitter', 'linseg', 'ampdb'],
    summary: 'THX-style Deep Note: many vco2 voices gliss from high clusters to a low unison with jitter and Moog filter.',
  },
  {
    folder: 'DocB - SuperWaveTerrain',
    slug: 'sterrain-docb',
    author: 'Richard Boulanger',
    title: 'SuperWaveTerrain',
    keywords: ['sterrain', 'terrain', 'wavetable', 'docb', 'superwave'],
    opcodes: ['sterrain', 'reverbsc', 'dcblock', 'linseg'],
    summary: 'sterrain opcode etude — animated wavetable terrain with rotation LFO and reverbsc space.',
  },
  {
    folder: 'Groovish - Microtonal - Jim Aikin',
    slug: 'groovish-jim-aikin',
    author: 'Jim Aikin',
    title: 'Groovish',
    keywords: ['groovish', 'microtonal', 'schedkwhen', 'metro', 'algorithmic', 'generative'],
    opcodes: ['schedkwhen', 'metro', 'oscil', 'foscil', 'reverbsc', 'pan2', 'linsegr'],
    summary: 'Microtonal generative piece: metro-driven schedkwhen triggers layered sine/FM voices with global form lines.',
  },
  {
    folder: 'Richard Boulanger - GendyC (2021)',
    slug: 'gendyc-richard-boulanger',
    author: 'Richard Boulanger',
    title: 'GendyC',
    year: '2021',
    keywords: ['gendyc', 'stochastic', 'ffitch', 'freeverb', 'noise', 'boulanger'],
    opcodes: ['gendyc', 'birnd', 'freeverb', 'vincr', 'alwayson'],
    summary: 'GendyC etude (2021): stereo gendyc with birnd rate walk, garvb bus, alwayson freeverb master (instr 99).',
  },
]

function sanitizeCsd(text) {
  return text
    .replace(/<bsbPanel>[\s\S]*/i, '')
    .replace(/<MacOptions>[\s\S]*/i, '')
    .trim() + '\n'
}

function slugFile(name) {
  return basename(name, '.csd').replace(/[^a-zA-Z0-9]+/g, '-').replace(/^-|-$/g, '').toLowerCase()
}

function buildCatalog(entries) {
  const lines = [
    '# Elected Csound Models — Workshop Foundation',
    '',
    'Curated by **Dr. Richard Boulanger** for the LAC 2026 workshop. These six collections are **foundational authorities** — adapt before inventing when a prompt matches their domain.',
    '',
    'Bundled CSDs: `resources/knowledge/elected-models/` · RAG IDs: `elected-*` in `bundle-elected-models.json`.',
    '',
    '## Priority rule',
    '',
    'When retrieval returns an `elected-*` catalog example or this doc, **adapt its opcode wiring and score structure** rather than generating from memory.',
    '',
  ]

  for (const m of MODELS) {
    const files = entries.filter((e) => e.modelSlug === m.slug)
    lines.push(`## ${m.title} — ${m.author}${m.year ? ` (${m.year})` : ''}`)
    lines.push('')
    lines.push(m.summary)
    lines.push('')
    lines.push(`**Keywords:** ${m.keywords.join(', ')}`)
    lines.push(`**Opcodes:** ${m.opcodes.join(', ')}`)
    lines.push('')
    if (files.length) {
      lines.push('**Files:**')
      for (const f of files) {
        lines.push(`- \`${f.relPath}\` → RAG id \`${f.id}\``)
      }
      lines.push('')
    }
  }

  lines.push('## Cross-model patterns')
  lines.push('')
  lines.push('- **Global reverb bus** — GendyC uses `garvbL/R` + `alwayson 99` + `freeverb`; Groovish uses `gaRevL/R` + instr `Reverb`.')
  lines.push('- **Named instruments** — Groovish uses string instrument numbers (`instr gControl`, `i "SourceA"`); valid in Csound 7.')
  lines.push('- **Long offline scores** — Deep Note and GendyC run 20–90 s; workshop Agent copies should shorten `i` durations.')
  lines.push('- **Chinese Horner models** — extensive `p-field` docs in orchestra; preserve parameter comments when adapting.')
  lines.push('')

  return lines.join('\n')
}

const srcRoot = process.argv[2] ? process.argv[2] : DEFAULT_SRC
if (!existsSync(srcRoot)) {
  console.error('Source folder not found:', srcRoot)
  process.exit(1)
}

const contents = {}
const entries = []

for (const m of MODELS) {
  const srcFolder = join(srcRoot, m.folder)
  const destFolder = join(OUT_DIR, m.slug)
  if (!existsSync(srcFolder)) {
    console.warn('SKIP missing folder:', srcFolder)
    continue
  }
  mkdirSync(destFolder, { recursive: true })

  const csds = readdirSync(srcFolder).filter((f) => f.toLowerCase().endsWith('.csd'))
  for (const file of csds) {
    const raw = readFileSync(join(srcFolder, file), 'utf-8')
    const clean = sanitizeCsd(raw)
    const destPath = join(destFolder, file)
    writeFileSync(destPath, clean)
    const fileSlug = slugFile(file)
    const prefix = {
      'bass-wobble-thorin-kerr': 'bass-wobble',
      'chinese-instruments-andrew-horner': 'chinese',
      'deepnote-steven-yi': 'deepnote',
      'sterrain-docb': 'sterrain',
      'groovish-jim-aikin': 'groovish',
      'gendyc-richard-boulanger': 'gendyc',
    }[m.slug]
    const id = `elected-${prefix}-${fileSlug}`
    const relPath = `elected-models/${m.slug}/${file}`
    contents[id] = clean
    entries.push({ id, modelSlug: m.slug, relPath, file })
    console.log('  ', id, '←', file)
  }
}

const bundle = {
  version: 'elected-models-v1',
  createdAt: Date.now(),
  source: srcRoot,
  models: MODELS.map((m) => ({ slug: m.slug, title: m.title, author: m.author })),
  contents,
}

writeFileSync(BUNDLE_OUT, JSON.stringify(bundle))
writeFileSync(CATALOG_OUT, buildCatalog(entries))
console.log(`\nWrote ${Object.keys(contents).length} CSDs → ${BUNDLE_OUT}`)
console.log(`Wrote catalog → ${CATALOG_OUT}`)
