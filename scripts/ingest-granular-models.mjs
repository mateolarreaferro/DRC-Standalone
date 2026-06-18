#!/usr/bin/env node
/**
 * Bundle Dr. B's granular synthesis models into the knowledge base.
 *
 *   node scripts/ingest-granular-models.mjs
 */

import {
  readFileSync, writeFileSync, mkdirSync, existsSync, copyFileSync,
} from 'node:fs'
import { join, dirname, basename } from 'node:path'
import { fileURLToPath } from 'node:url'
import { homedir } from 'node:os'

const REPO = dirname(dirname(fileURLToPath(import.meta.url)))
const MODELS = join(homedir(), 'dB-Studio', 'Csound', 'MODELS')
const OUT_DIR = join(REPO, 'resources/knowledge/granular-models')
const BUNDLE_OUT = join(REPO, 'resources/knowledge/bundle-granular-models.json')
const CATALOG_OUT = join(REPO, 'resources/knowledge/sources/granular-models-catalog.md')
const DRC_TERMINAL = join(homedir(), 'Dr.C', 'opencode', 'packages', 'opencode')

const OPCODE_RE =
  /\b(grain|sndwarp|partikkel|granule|fog|fof2?|diskin2?|tableng|tablewa|phasor|hilbert|oversample|midic7|cpsmidib|ampmidi|linenr|ftgen|timout|oscil1|oscili|linseg|rand)\b/gi

/** @type {{ id: string, relPath: string, collection: string, author: string, title: string, techniques: string[], opcodes: string[], description: string, qualityScore: number, workshopReady?: boolean }[]} */
const MANIFEST = []

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
    const candidates = [
      join(baseDir, inc),
      join(baseDir, 'inc', inc),
      join(dirname(baseDir), inc),
      join(dirname(baseDir), 'PartikkelArgs - Include file', inc),
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
  return [...found].sort()
}

function wrapOrcSco(orcPath, scoPath, title) {
  const orc = readFileSync(orcPath, 'utf-8')
  const sco = readFileSync(scoPath, 'utf-8')
  return sanitizeCsd(`<CsoundSynthesizer>
<CsOptions>
-n -d -m0
--limiter=0.9
</CsOptions>
<CsInstruments>
${orc}
</CsInstruments>
<CsScore>
${sco}
</CsScore>
</CsoundSynthesizer>`)
}

function wrapInstrumentsOnly(body, title, comment = '') {
  return sanitizeCsd(`<CsoundSynthesizer>
<CsOptions>
-n -d -m0
--limiter=0.9
</CsOptions>
<CsInstruments>
; ${title}
${comment}
${body}
</CsInstruments>
<CsScore>
f 0 1
</CsScore>
</CsoundSynthesizer>`)
}

function addEntry(id, relPath, collection, author, title, content, opts = {}) {
  const opcodes = extractOpcodes(content)
  const techniques = opts.techniques ?? (
    opcodes.includes('partikkel') ? ['partikkel', 'granular']
      : opcodes.includes('sndwarp') ? ['sndwarp', 'granular']
        : opcodes.includes('grain') ? ['grain', 'granular']
          : ['granular']
  )
  const entry = {
    id,
    relPath,
    collection,
    author,
    title,
    opcodes,
    techniques,
    primaryTechnique: techniques[0],
    domain: 'synthesis',
    filename: basename(relPath),
    description: opts.description ?? `${title} — ${author} granular model`,
    qualityScore: opts.qualityScore ?? 0.92,
    workshopReady: opts.workshopReady ?? false,
  }
  MANIFEST.push(entry)
  const dest = join(OUT_DIR, relPath)
  mkdirSync(dirname(dest), { recursive: true })
  writeFileSync(dest, content)
  return { id, content, entry }
}

function syncToDrcTerminal() {
  if (!existsSync(DRC_TERMINAL)) {
    console.warn('Dr.C Terminal not found — skip sync')
    return
  }
  const termKnowledge = join(DRC_TERMINAL, 'resources', 'knowledge')
  mkdirSync(join(termKnowledge, 'sources'), { recursive: true })
  copyFileSync(BUNDLE_OUT, join(termKnowledge, 'bundle-granular-models.json'))
  copyFileSync(CATALOG_OUT, join(termKnowledge, 'sources', 'granular-models-catalog.md'))
  console.log('Synced → Dr.C Terminal', termKnowledge)
}

function buildCatalog() {
  const lines = [
    '# Granular Synthesis Models — Workshop Foundation',
    '',
    'Curated granular authorities for Dr.C. Users ask about **granular**, **grain**, **partikkel**, **sndwarp** — adapt these before inventing.',
    '',
    `**${MANIFEST.length} models** · RAG IDs \`granular-*\` · \`bundle-granular-models.json\``,
    '',
    '## Collections',
    '',
    '### Ezine — Hans Mikelson (Csound Magazine)',
    'Classic `grain` opcode tutorial: density envelopes, pitch scatter, sampled `limit.wav` source (instr 2).',
    '',
    '### GrainMIDI & SndWarpMIDI — Richard Boulanger',
    'MIDI-controlled `grain` and `sndwarp` with `midic7` controllers for density, offsets, warp rate.',
    '',
    '### Granular+FM — Kim Ervik / Øyvind Brandtsegg patterns',
    'Three `partikkel` instruments with **FM on grain rate and/or pitch** (`PartikkelArgs.inc` inlined).',
    '',
    '### Partikkel+ — Øyvind Brandtsegg',
    '- **Starter kit** — live-input buffer + `partikkel` effect processing (workshop-ready)',
    '- **Oversampling** — anti-aliased granular processing UDOs',
    '- **Hadron partikkel_instr** — full parameter surface from Hadron',
    '- **ImproSculpt** — performance granular suite (reference; large patch)',
    '',
    '## Priority rule',
    '',
    'For granular prompts: prefer `granular-brandtsegg-partikkel-starter-kit` for live-input FX, `granular-boulanger-grainmidi` for classic `grain` opcode, `granular-fm-grain-rate-and-pitch` for FM grains.',
    '',
    '## Models',
    '',
  ]
  for (const e of MANIFEST) {
    const tag = e.workshopReady ? ' **(workshop-ready)**' : ''
    lines.push(`- **${e.title}**${tag} — \`${e.id}\` — ${e.opcodes.slice(0, 8).join(', ')}`)
  }
  lines.push('')
  return lines.join('\n')
}

// --- ingest sources ---
const contents = {}

// Ezine granula.orc + granula.sco
{
  const dir = join(MODELS, 'GRANULAR - Ezine')
  const csd = wrapOrcSco(join(dir, 'granula.orc'), join(dir, 'granula.sco'), 'Granula Ezine')
  const { id, entry } = addEntry(
    'granular-ezine-granula',
    'ezine/granula.csd',
    'Ezine',
    'Hans Mikelson',
    'Granula (Csound Magazine)',
    csd,
    { description: 'Classic grain opcode — dual channels, oscil-driven density/pitch envelopes', workshopReady: true },
  )
  contents[id] = csd
  console.log(' ', id)
}

// GrainMIDI + SndWarpMIDI
for (const file of ['grainmidi.csd', 'sndwarpmidi.csd']) {
  const dir = join(MODELS, 'GRANULAR - GrainMIDI & SndWarpMIDI')
  const raw = inlineIncludes(readFileSync(join(dir, file), 'utf-8'), dir)
  const csd = sanitizeCsd(raw)
  const slug = basename(file, '.csd')
  const { id } = addEntry(
    `granular-boulanger-${slug}`,
    `grainmidi-sndwarp/${file}`,
    'GrainMIDI & SndWarpMIDI',
    'Richard Boulanger',
    slug === 'grainmidi' ? 'GrainMIDI' : 'SndWarpMIDI',
    csd,
    {
      techniques: slug === 'grainmidi' ? ['grain', 'midi', 'granular'] : ['sndwarp', 'midi', 'granular'],
      workshopReady: slug === 'grainmidi',
    },
  )
  contents[id] = csd
  console.log(' ', id)
}

// FM Grain trio
for (const file of ['FM_Grain_Rate.csd', 'FM_Grain_Pitch.csd', 'FM_Grain_Rate_and_Pitch.csd']) {
  const dir = join(MODELS, 'GRANULAR - Granular+FM')
  const raw = inlineIncludes(readFileSync(join(dir, file), 'utf-8'), dir)
  const csd = sanitizeCsd(raw)
  const slug = file.replace(/\.csd$/i, '').replace(/_/g, '-').toLowerCase()
  const { id } = addEntry(
    `granular-fm-${slug.replace('fm-grain-', '')}`,
    `granular-fm/${file}`,
    'Granular+FM',
    'Kim Ervik / Øyvind Brandtsegg',
    file.replace('.csd', ''),
    csd,
    { techniques: ['partikkel', 'fm', 'granular'], qualityScore: 0.94, workshopReady: file.includes('Rate_and_Pitch') },
  )
  contents[id] = csd
  console.log(' ', id)
}

const partikkelRoot = join(MODELS, 'GRANULAR - Partikkel+ - Oeyvind Brandtsegg')

// Partikkel starter kit
{
  const dir = join(partikkelRoot, 'Oeyvind Brandtsegg - Partikkel starter kit - efx')
  const raw = inlineIncludes(readFileSync(join(dir, 'partikkel_starter_kit_efx.csd'), 'utf-8'), dir)
  const csd = sanitizeCsd(raw)
  const id = 'granular-brandtsegg-partikkel-starter-kit'
  addEntry(id, 'brandtsegg/partikkel_starter_kit_efx.csd', 'Partikkel+', 'Øyvind Brandtsegg', 'Partikkel starter kit (live FX)', csd, {
    description: 'Live input buffer + partikkel granular effect — canonical workshop model',
    qualityScore: 0.98,
    workshopReady: true,
  })
  contents[id] = csd
  console.log(' ', id)
}

// Oversampling
{
  const dir = join(partikkelRoot, 'Oeyvind Brandtsegg - Oversampling')
  const raw = inlineIncludes(readFileSync(join(dir, 'oversampling.csd'), 'utf-8'), dir)
  const csd = sanitizeCsd(raw)
  const id = 'granular-brandtsegg-oversampling'
  addEntry(id, 'brandtsegg/oversampling.csd', 'Partikkel+', 'Øyvind Brandtsegg', 'Granular oversampling UDOs', csd, {
    techniques: ['oversampling', 'granular', 'hilbert'],
    qualityScore: 0.9,
  })
  contents[id] = csd
  console.log(' ', id)
}

// Hadron partikkel_instr.inc
{
  const incPath = join(partikkelRoot, 'Oeyvind Brandtsegg - Hadron - Granular/Hadron/inc/partikkel_instr.inc')
  const body = readFileSync(incPath, 'utf-8')
  const csd = wrapInstrumentsOnly(body, 'Hadron partikkel_instr', '; From Øyvind Brandtsegg Hadron — full partikkel parameter wiring')
  const id = 'granular-brandtsegg-hadron-partikkel-instr'
  addEntry(id, 'brandtsegg/hadron_partikkel_instr.csd', 'Partikkel+', 'Øyvind Brandtsegg', 'Hadron partikkel_instr', csd, {
    description: 'Hadron granular engine — partikkel opcode parameter surface',
    qualityScore: 0.95,
  })
  contents[id] = csd
  console.log(' ', id)
}

// ImproSculpt (reference)
{
  const path = join(partikkelRoot, 'Oeyvind Brandtsegg - ImproSculpt-cs6/ImproSculpt_2017.csd')
  const csd = sanitizeCsd(readFileSync(path, 'utf-8'))
  const id = 'granular-brandtsegg-improsculpt'
  addEntry(id, 'brandtsegg/ImproSculpt_2017.csd', 'Partikkel+', 'Øyvind Brandtsegg', 'ImproSculpt 2017', csd, {
    description: 'Full performance granular suite — reference architecture (large patch)',
    qualityScore: 0.88,
  })
  contents[id] = csd
  console.log(' ', id, `(${(csd.length / 1024).toFixed(0)} KB)`)
}

const bundle = {
  version: 'granular-models-v1',
  createdAt: Date.now(),
  source: MODELS,
  count: MANIFEST.length,
  entries: MANIFEST,
  contents,
}

writeFileSync(BUNDLE_OUT, JSON.stringify(bundle))
writeFileSync(CATALOG_OUT, buildCatalog())
console.log(`\nWrote ${MANIFEST.length} granular models → ${BUNDLE_OUT}`)
syncToDrcTerminal()
