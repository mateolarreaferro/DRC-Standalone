#!/usr/bin/env node
/**
 * Bundle Dr. B physical / waveguide models into the knowledge base.
 *
 *   node scripts/ingest-physical-models.mjs
 */

import {
  readFileSync, writeFileSync, mkdirSync, existsSync, copyFileSync, readdirSync, statSync,
} from 'node:fs'
import { join, dirname, basename, relative } from 'node:path'
import { fileURLToPath } from 'node:url'
import { homedir } from 'node:os'

const REPO = dirname(dirname(fileURLToPath(import.meta.url)))
const MODELS = join(homedir(), 'dB-Studio', 'Csound', 'MODELS')
const STUDENTS = join(homedir(), 'dB-Studio', 'Csound', 'Models - 4 students')
const OUT_DIR = join(REPO, 'resources/knowledge/physical-models')
const BUNDLE_OUT = join(REPO, 'resources/knowledge/bundle-physical-models.json')
const CATALOG_OUT = join(REPO, 'resources/knowledge/sources/physical-models-catalog.md')
const DRC_TERMINAL = join(homedir(), 'Dr.C', 'opencode', 'packages', 'opencode')

const OPCODE_RE =
  /\b(wgflute|wgclar|wgbow|wgbowedbar|wgpluck2?|wguid[12]|pluck|repluck|mode|delayr|delayw|tone|filter2|biquad|reson|butterlp|ftgen|oscil1i|upsamp|dcblock|reverbsc|vincr|turnon|cpsmidi|ampmidi)\b/gi

/** @type {object[]} */
const MANIFEST = []

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
  while ((m = re.exec(content)) !== null) found.add(m[1].toLowerCase())
  // custom opcodes
  for (const udo of ['WaveguidePipa', 'Damping', 'Tuning', 'Stiffness', 'Body']) {
    if (content.includes(`opcode ${udo}`)) found.add(udo.toLowerCase())
  }
  return [...found].sort()
}

function inferTechniques(opcodes, content) {
  const t = new Set(['physical-model'])
  if (opcodes.some((o) => o.startsWith('wg'))) t.add('waveguide')
  if (content.includes('WaveguidePipa') || content.includes('delayr')) t.add('karplus-strong')
  if (opcodes.includes('mode')) t.add('modal')
  if (opcodes.includes('pluck') || opcodes.includes('repluck')) t.add('pluck')
  return [...t]
}

function addEntry(id, relPath, collection, author, title, content, opts = {}) {
  const opcodes = extractOpcodes(content)
  const entry = {
    id,
    relPath,
    collection,
    author,
    title,
    opcodes,
    techniques: opts.techniques ?? inferTechniques(opcodes, content),
    primaryTechnique: opts.primaryTechnique ?? 'waveguide',
    domain: 'synthesis',
    filename: basename(relPath),
    description: opts.description ?? `${title} — ${author}`,
    qualityScore: opts.qualityScore ?? 0.9,
    workshopReady: opts.workshopReady ?? false,
  }
  MANIFEST.push(entry)
  const dest = join(OUT_DIR, relPath)
  mkdirSync(dirname(dest), { recursive: true })
  writeFileSync(dest, content)
  return { id, content, entry }
}

function walkCsds(dir) {
  const out = []
  for (const name of readdirSync(dir)) {
    const full = join(dir, name)
    if (statSync(full).isDirectory()) {
      out.push(...walkCsds(full))
      continue
    }
    if (name.toLowerCase().endsWith('.csd')) out.push(full)
  }
  return out
}

function syncToDrcTerminal() {
  if (!existsSync(DRC_TERMINAL)) return
  const termKnowledge = join(DRC_TERMINAL, 'resources', 'knowledge')
  mkdirSync(join(termKnowledge, 'sources'), { recursive: true })
  copyFileSync(BUNDLE_OUT, join(termKnowledge, 'bundle-physical-models.json'))
  copyFileSync(CATALOG_OUT, join(termKnowledge, 'sources', 'physical-models-catalog.md'))
  console.log('Synced → Dr.C Terminal', termKnowledge)
}

function buildCatalog() {
  const byColl = new Map()
  for (const e of MANIFEST) {
    if (!byColl.has(e.collection)) byColl.set(e.collection, [])
    byColl.get(e.collection).push(e)
  }
  const lines = [
    '# Physical / Waveguide Models — Workshop Foundation',
    '',
    'Curated physical modeling authorities for Dr.C. Adapt these for **waveguide**, **wg***, **pluck**, **Karplus-Strong**, **modal**, and **Chinese pipa** prompts.',
    '',
    `**${MANIFEST.length} models** · RAG IDs \`physical-*\` · \`bundle-physical-models.json\``,
    '',
    '## Priority',
    '',
    '- `physical-ningxin-waveguide-pipa` — custom waveguide pipa UDO (student model, workshop-ready)',
    '- `physical-wgflute` / `physical-wgpluck2` — Perry Cook waveguide opcodes',
    '- `physical-handpan-v1` — modal `mode()` handpan',
    '- `physical-gutwein-bambooflute1` — bamboo flute physical model',
    '- `physical-karplusmath` — Karplus-Strong delay-line pedagogy',
    '',
    '## Collections',
    '',
  ]
  for (const [coll, items] of [...byColl.entries()].sort((a, b) => a[0].localeCompare(b[0]))) {
    lines.push(`### ${coll}`)
    lines.push('')
    for (const e of items.sort((a, b) => a.title.localeCompare(b.title))) {
      const star = e.workshopReady ? ' ★' : ''
      lines.push(`- **${e.title}**${star} — \`${e.id}\` — ${e.opcodes.slice(0, 8).join(', ')}`)
    }
    lines.push('')
  }
  return lines.join('\n')
}

const contents = {}

// Gutwein bamboo flute
{
  const dir = join(MODELS, 'SYNTH - Physical Model - Bamboo Flute - Dan Gutwein')
  for (const file of ['BambooFlute1.csd', 'BambooFlute2.csd']) {
    const csd = sanitizeCsd(readFileSync(join(dir, file), 'utf-8'))
    const id = `physical-gutwein-${slug(basename(file, '.csd'))}`
    addEntry(id, `gutwein/${file}`, 'Bamboo Flute', 'Dan Gutwein', basename(file, '.csd'), csd, {
      description: 'Bamboo flute physical model (Cook/Mikelson lineage)',
      qualityScore: 0.92,
    })
    contents[id] = csd
    console.log(' ', id)
  }
}

// HandPan
{
  const dir = join(MODELS, 'SYNTH - Physical Model - HandPan')
  for (const sub of ['handpan1', 'handpan2']) {
    const file = join(dir, sub, 'handpan.csd')
    if (!existsSync(file)) continue
    const csd = sanitizeCsd(readFileSync(file, 'utf-8'))
    const ver = sub.replace('handpan', 'v')
    const id = `physical-handpan-${ver}`
    addEntry(id, `handpan/${sub}/handpan.csd`, 'HandPan', 'Jeanette C.', `HandPan ${ver}`, csd, {
      techniques: ['modal', 'physical-model'],
      primaryTechnique: 'modal',
      description: 'MIDI handpan using mode() resonators',
      workshopReady: true,
      qualityScore: 0.93,
    })
    contents[id] = csd
    console.log(' ', id)
  }
}

// KarplusMATH
{
  const dir = join(MODELS, 'SYNTH - Physical Model - KarplusMATH')
  const csd = sanitizeCsd(readFileSync(join(dir, 'karplusMath.csd'), 'utf-8'))
  const id = 'physical-karplusmath'
  addEntry(id, 'karplusmath/karplusMath.csd', 'KarplusMATH', 'Richard Boulanger', 'KarplusMATH', csd, {
    techniques: ['karplus-strong', 'physical-model'],
    primaryTechnique: 'karplus-strong',
    description: 'Karplus-Strong delay-line demonstration',
    workshopReady: true,
    qualityScore: 0.94,
  })
  contents[id] = csd
  console.log(' ', id)
}

// Cook/Smith waveguide collection
{
  const dir = join(MODELS, 'SYNTH - Physical Models')
  for (const file of readdirSync(dir).filter((f) => f.endsWith('.csd'))) {
    const csd = sanitizeCsd(readFileSync(join(dir, file), 'utf-8'))
    const id = `physical-${slug(basename(file, '.csd'))}`
    addEntry(id, `waveguide/${file}`, 'Waveguide Collection', 'Perry Cook / Csound', basename(file, '.csd'), csd, {
      workshopReady: ['wgflute.csd', 'wgpluck2.csd', 'KarplusStrongPluckTechnique.csd'].includes(file),
    })
    contents[id] = csd
    console.log(' ', id)
  }
}

// Ningxin — Waveguide Pipa (student model)
{
  const dir = join(STUDENTS, 'WaveguidePipa - Ningxin')
  const csd = sanitizeCsd(readFileSync(join(dir, 'waveguide_Pipa.csd'), 'utf-8'))
  const id = 'physical-ningxin-waveguide-pipa'
  addEntry(id, 'students/ningxin/waveguide_Pipa.csd', 'Student Models', 'Ningxin', 'Waveguide Pipa', csd, {
    techniques: ['waveguide', 'karplus-strong', 'physical-model', 'chinese'],
    primaryTechnique: 'waveguide',
    description: 'Custom WaveguidePipa UDO: damping/tuning/stiffness/body filters, recorded excitation + IR',
    workshopReady: true,
    qualityScore: 0.97,
  })
  contents[id] = csd
  console.log(' ', id)
}

writeFileSync(BUNDLE_OUT, JSON.stringify({
  version: 'physical-models-v1',
  createdAt: Date.now(),
  count: MANIFEST.length,
  entries: MANIFEST,
  contents,
}))
writeFileSync(CATALOG_OUT, buildCatalog())
console.log(`\nWrote ${MANIFEST.length} physical models → ${BUNDLE_OUT}`)
syncToDrcTerminal()
