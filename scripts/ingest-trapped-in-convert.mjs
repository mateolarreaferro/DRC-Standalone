#!/usr/bin/env node
/**
 * Build bundle-trapped.json from trapped_full_reference.csd for RAG retrieval.
 * Run after updating the reference CSD:
 *   node scripts/ingest-trapped-in-convert.mjs
 */

import { readFileSync, writeFileSync, existsSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const REPO = dirname(dirname(fileURLToPath(import.meta.url)))
const REF = join(REPO, 'resources/knowledge/trapped-in-convert/trapped_full_reference.csd')
const OUT = join(REPO, 'resources/knowledge/bundle-trapped.json')

const NAMES = [
  ['1', 'ivory', 'IVORY'],
  ['2', 'blue', 'BLUE'],
  ['3', 'violet', 'VIOLET'],
  ['4', 'black', 'BLACK'],
  ['5', 'green', 'GREEN'],
  ['6', 'copper', 'COPPER'],
  ['7', 'pewter', 'PEWTER'],
  ['8', 'red', 'RED'],
  ['9', 'sand', 'SAND'],
  ['10', 'taupe', 'TAUPE'],
  ['11', 'rust', 'RUST'],
  ['12', 'teal', 'TEAL'],
  ['13', 'foam', 'FOAM'],
  ['98', 'smear', 'SMEAR'],
  ['99', 'swirl', 'SWIRL'],
]

function extractInstr(src, num) {
  const re = new RegExp(`instr\\s+${num}\\b[\\s\\S]*?endin`, 'i')
  const m = src.match(re)
  return m ? m[0].trim() : null
}

function header() {
  return `<CsoundSynthesizer>
<CsOptions>
-n -d -m0
--limiter=0.9
</CsOptions>
<CsInstruments>
sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1
garvb init 0
gadel init 0
`
}

if (!existsSync(REF)) {
  console.error('Missing reference:', REF)
  process.exit(1)
}

const raw = readFileSync(REF, 'utf-8').replace(/<MacOptions>[\s\S]*/i, '').trim()
const ftgens = raw.match(/<CsScore>[\s\S]*?f22[\s\S]*?;/i)?.[0]?.replace(/<CsScore>/i, '').trim() ?? ''

const contents = {}
for (const [num, slug, label] of NAMES) {
  const body = extractInstr(raw, num)
  if (!body) continue
  const id = `trapped-${slug}-instr${num}`
  contents[id] =
    `${header()}\n; === ${label} (instr ${num}) from Trapped in Convert (1979) ===\n${body}\n</CsInstruments>\n<CsScore>\n${ftgens}\nf 0 1\n</CsScore>\n</CsoundSynthesizer>`
}

const bundle = {
  version: 'trapped-1979-boulanger',
  createdAt: Date.now(),
  source: 'Richard Boulanger — Trapped in Convert (1979)',
  contents,
}

writeFileSync(OUT, JSON.stringify(bundle, null, 0))
console.log(`Wrote ${Object.keys(contents).length} instruments to ${OUT}`)
