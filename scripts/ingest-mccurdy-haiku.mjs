#!/usr/bin/env node
/**
 * Bundle Iain McCurdy's Csound Haiku (generative ambient) into the knowledge base.
 *
 *   node scripts/ingest-mccurdy-haiku.mjs
 *   node scripts/ingest-mccurdy-haiku.mjs "/path/to/Generative - Iain McCurdy - Haiku (2021)"
 */

import { readFileSync, writeFileSync, mkdirSync, readdirSync, existsSync } from 'node:fs'
import { join, dirname, basename } from 'node:path'
import { fileURLToPath } from 'node:url'
import { homedir } from 'node:os'

const REPO = dirname(dirname(fileURLToPath(import.meta.url)))
const DEFAULT_SRC = join(homedir(), 'Desktop', 'Generative - Iain McCurdy - Haiku (2021)')
const OUT_DIR = join(REPO, 'resources/knowledge/mccurdy-haiku')
const BUNDLE_OUT = join(REPO, 'resources/knowledge/bundle-mccurdy-haiku.json')
const CATALOG_OUT = join(REPO, 'resources/knowledge/sources/mccurdy-haiku-catalog.md')

/** @type {{ file: string, roman: string, title: string, opcodes: string[], character: string }[]} */
const HAIKU = [
  {
    file: 'I.csd',
    roman: 'I',
    title: 'Brass-like gbuzz drones',
    opcodes: ['gbuzz', 'transeg', 'rspline', 'jspline', 'metro', 'alwayson', 'reverbsc', 'event_i'],
    character: 'Six trombone voices: slow transeg glissandi, rspline/jspline timbre motion, global reverb bus.',
  },
  {
    file: 'II.csd',
    roman: 'II',
    title: 'Polyrhythmic inharmonic bells',
    opcodes: ['seqtime', 'metro', 'oscili', 'gbuzz', 'tonea (UDO)', 'ftgen -17', 'ftgen 9', 'reverbsc'],
    character: 'Layered rhythmic sequences with GEN 9 pseudo-inharmonic spectra and quiet gbuzz shadow.',
  },
  {
    file: 'III.csd',
    roman: 'III',
    title: 'Waveguide resonances',
    opcodes: ['wguid2', 'metro', 'rspline', 'vdelay', 'reverbsc', 'schedkwhen'],
    character: 'wguid2 physical models triggered by metro; spatial vdelay + reverbsc.',
  },
  {
    file: 'IV.csd',
    roman: 'IV',
    title: 'Morphing hsboscil clusters',
    opcodes: ['hsboscil', 'ringmod', 'rspline', 'metro', 'reverbsc'],
    character: 'Periodic gestural hsboscil spectra with ring modulation and rspline window motion.',
  },
  {
    file: 'V.csd',
    roman: 'V',
    title: 'Phaser resonances',
    opcodes: ['phaser2', 'metro', 'rspline', 'reverbsc'],
    character: 'Struck resonating objects via phaser2 with evolving rspline parameters.',
  },
  {
    file: 'VI.csd',
    roman: 'VI',
    title: 'Strummed waveguides',
    opcodes: ['wguid1', 'pinkish', 'metro', 'schedkwhen', 'reverbsc'],
    character: 'Six wguide1 strings with staggered pink-noise plucks — guitar strum simulation.',
  },
  {
    file: 'VII.csd',
    roman: 'VII',
    title: 'Bell garden',
    opcodes: ['seqtime', 'schedkwhennamed', 'oscili', 'gbuzz', 'vdelay', 'butlp', 'reverbsc'],
    character: 'seqtime rhythmic triggers; long_bell oscili partials crossfade with gbuzz_long_note.',
  },
  {
    file: 'VIII.csd',
    roman: 'VIII',
    title: 'Stochastic layers',
    opcodes: ['schedkwhen', 'metro', 'ftgen -17', 'hilbert', 'oscili', 'reverbsc'],
    character: 'Probability-driven note layers; Hilbert frequency shift on longer events.',
  },
  {
    file: 'IX.csd',
    roman: 'IX',
    title: 'Arpeggio clouds',
    opcodes: ['schedkwhennamed', 'metro', 'randomh', 'rspline', 'oscili', 'reverbsc'],
    character: 'Slow randomh metro rate triggers arpeggio streams with rspline harmonic motion.',
  },
]

const ROMAN_SLUG = {
  I: 'i', II: 'ii', III: 'iii', IV: 'iv', V: 'v', VI: 'vi', VII: 'vii', VIII: 'viii', IX: 'ix',
}

function sanitizeCsd(text) {
  return text
    .replace(/<bsbPanel>[\s\S]*/i, '')
    .replace(/<MacOptions>[\s\S]*/i, '')
    .trim() + '\n'
}

function buildCatalog(contents) {
  const lines = [
    '# Csound Haiku — Generative Ambient Models (Iain McCurdy)',
    '',
    'Nine **real-time generative ambient** pieces (2011, exhibited as a sound-installation book). Bundled for the Dr.C workshop as **foundational models** for algorithmic composition without a traditional score.',
    '',
    '**RAG IDs:** `mccurdy-haiku-i` … `mccurdy-haiku-ix` in `bundle-mccurdy-haiku.json`',
    '',
    '**CSDs:** `resources/knowledge/mccurdy-haiku/`',
    '',
    '## Why these are foundational',
    '',
    '- Notes are **generated in the orchestra** (`metro`, `schedkwhen`, `schedkwhennamed`, `seqtime`, `event_i`) — no `i` statements in the score except `f 0` hold.',
    '- **`alwayson`** keeps master triggers and `reverb` alive for the whole piece.',
    '- **`rspline` / `jspline`** create natural flowing gestures on pitch, amp, pan, and timbre.',
    '- **`gasendL/R` + `reverbsc`** is the standard Haiku spatial template.',
    '',
    '## When to cite Haiku',
    '',
    'User asks for: **generative**, **ambient**, **soundscape**, **evolving drone**, **installation**, **no score**, **McCurdy**, **Haiku**, **schedkwhen**, **alwayson generative**.',
    '',
    '## Anti-patterns when adapting',
    '',
    '- Do not replace `alwayson` + `f 0` with a long `i` score — that breaks the generative design.',
    '- Preserve `seed 0` (or intentional seed) for reproducible installs.',
    '- Named instruments (`instr trombone`, `alwayson "reverb"`) are idiomatic — keep string instrument numbers.',
    '- Workshop **Agent offline render**: use short `f 0 30` hold instead of `f 0 [60*60*24*7]` for test renders only.',
    '',
  ]

  for (const h of HAIKU) {
    const id = `mccurdy-haiku-${ROMAN_SLUG[h.roman]}`
    lines.push(`## Haiku ${h.roman} — ${h.title}`)
    lines.push('')
    lines.push(h.character)
    lines.push('')
    lines.push(`**Opcodes:** ${h.opcodes.join(', ')}`)
    lines.push(`**File:** \`mccurdy-haiku/${h.file}\` → \`${id}\``)
    lines.push('')
  }

  lines.push('## Shared generative template')
  lines.push('')
  lines.push('```csound')
  lines.push('gasendL, gasendR init 0')
  lines.push('alwayson "trigger_instrument"')
  lines.push('alwayson "reverb"')
  lines.push('instr reverb')
  lines.push('  aL, aR reverbsc gasendL, gasendR, 0.85, 10000')
  lines.push('  outs aL, aR')
  lines.push('  clear gasendL, gasendR')
  lines.push('endin')
  lines.push('```')
  lines.push('')

  return lines.join('\n')
}

const srcRoot = process.argv[2] ?? DEFAULT_SRC
if (!existsSync(srcRoot)) {
  console.error('Source folder not found:', srcRoot)
  process.exit(1)
}

mkdirSync(OUT_DIR, { recursive: true })
const contents = {}

for (const h of HAIKU) {
  const srcPath = join(srcRoot, h.file)
  if (!existsSync(srcPath)) {
    console.warn('SKIP missing:', h.file)
    continue
  }
  const clean = sanitizeCsd(readFileSync(srcPath, 'utf-8'))
  const destPath = join(OUT_DIR, h.file)
  writeFileSync(destPath, clean)
  const id = `mccurdy-haiku-${ROMAN_SLUG[h.roman]}`
  contents[id] = clean
  console.log(' ', id, '←', h.file)
}

const bundle = {
  version: 'mccurdy-haiku-v1',
  createdAt: Date.now(),
  source: 'Iain McCurdy — Csound Haiku (2011)',
  author: 'Iain McCurdy',
  genre: 'generative-ambient',
  contents,
}

writeFileSync(BUNDLE_OUT, JSON.stringify(bundle))
writeFileSync(CATALOG_OUT, buildCatalog(contents))
console.log(`\nWrote ${Object.keys(contents).length} Haiku → ${BUNDLE_OUT}`)
console.log(`Wrote catalog → ${CATALOG_OUT}`)
