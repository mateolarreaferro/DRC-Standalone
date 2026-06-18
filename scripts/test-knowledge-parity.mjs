#!/usr/bin/env node
/**
 * Verify Dr.C-Standalone and Dr.C CLI knowledge bundles match.
 *   node scripts/test-knowledge-parity.mjs
 */

import { readFileSync, existsSync, readdirSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { homedir } from 'node:os'

const REPO = dirname(dirname(fileURLToPath(import.meta.url)))
const STANDALONE = join(REPO, 'resources/knowledge')
const CLI = join(homedir(), 'Dr.C', 'opencode', 'packages', 'opencode/resources/knowledge')

const REQUIRED = [
  'bundle-csd.json',
  'bundle-elected-models.json',
  'bundle-mccurdy-haiku.json',
  'bundle-selected-catalog-v25.json',
  'bundle-granular-models.json',
  'bundle-physical-models.json',
  'bundle-drum-models.json',
  'bundle-generative-models.json',
]

const MIN_COUNTS = {
  'bundle-csd.json': 500,
  'bundle-elected-models.json': 9,
  'bundle-mccurdy-haiku.json': 9,
  'bundle-selected-catalog-v25.json': 87,
  'bundle-granular-models.json': 10,
  'bundle-physical-models.json': 14,
  'bundle-drum-models.json': 30,
  'bundle-generative-models.json': 25,
}

const CATALOGS = [
  'sources/granular-models-catalog.md',
  'sources/physical-models-catalog.md',
  'sources/drum-models-catalog.md',
  'sources/generative-models-catalog.md',
  'sources/authoritative-sources.txt',
]

let failed = 0

function ok(msg) { console.log('  PASS', msg) }
function bad(msg, detail = '') { console.log('  FAIL', msg, detail); failed++ }

console.log('\n[knowledge parity — Standalone vs CLI]\n')

for (const bundle of REQUIRED) {
  const sPath = join(STANDALONE, bundle)
  const cPath = join(CLI, bundle)
  if (!existsSync(sPath)) { bad(`Standalone missing ${bundle}`); continue }
  if (!existsSync(cPath)) { bad(`CLI missing ${bundle}`); continue }
  const s = JSON.parse(readFileSync(sPath, 'utf-8'))
  const c = JSON.parse(readFileSync(cPath, 'utf-8'))
  const sN = s.count ?? Object.keys(s.contents ?? {}).length
  const cN = c.count ?? Object.keys(c.contents ?? {}).length
  const min = MIN_COUNTS[bundle] ?? 1
  if (sN < min) bad(`Standalone ${bundle} too small`, String(sN))
  else if (cN < min) bad(`CLI ${bundle} too small`, String(cN))
  else if (sN !== cN) bad(`${bundle} count mismatch`, `standalone=${sN} cli=${cN}`)
  else ok(`${bundle}: ${sN} models (both repos)`)
}

for (const cat of CATALOGS) {
  const sPath = cat === 'sources/authoritative-sources.txt'
    ? join(REPO, 'src/main/agent/prompts/authoritative-sources.txt')
    : join(STANDALONE, cat)
  if (!existsSync(sPath)) bad(`Standalone missing ${cat}`)
  else if (!existsSync(join(CLI, cat))) bad(`CLI missing ${cat}`)
  else ok(cat)
}

// CLI wiring checks
const cliEngine = readFileSync(join(homedir(), 'Dr.C/opencode/packages/opencode/src/retrieval/engine.ts'), 'utf-8')
const cliCsd = readFileSync(join(homedir(), 'Dr.C/opencode/packages/opencode/src/retrieval/csd-examples.ts'), 'utf-8')
const cliKs = readFileSync(join(homedir(), 'Dr.C/opencode/packages/opencode/src/retrieval/knowledge-sources.ts'), 'utf-8')

if (cliEngine.includes('bundle-generative-models.json') && cliEngine.includes('bundle-csd.json')) {
  ok('CLI engine loads catalog-csd + generative bundles')
} else bad('CLI engine missing generative or catalog-csd load')

if (cliCsd.includes('physical-') && cliCsd.includes('drum-') && cliCsd.includes('generative-')) {
  ok('CLI CSD search boosts physical + drum + generative')
} else bad('CLI CSD missing parity score boosts')

if (cliKs.includes('physical-models-catalog') && cliKs.includes('drum-models-catalog') && cliKs.includes('generative-models-catalog')) {
  ok('CLI knowledge-sources indexes all model catalogs')
} else bad('CLI knowledge-sources missing catalog indexing')

if (existsSync(join(homedir(), 'Dr.C/opencode/packages/opencode/src/retrieval/golden-patterns.ts'))) {
  ok('CLI golden-patterns module present')
} else bad('CLI golden-patterns missing')

console.log(`\n${failed === 0 ? 'All parity checks passed' : `${failed} parity check(s) failed`}\n`)
process.exit(failed > 0 ? 1 : 0)
