#!/usr/bin/env node
/**
 * Sync all knowledge bundles + catalogs from Dr.C-Standalone → Dr.C CLI.
 *   node scripts/sync-knowledge-to-cli.mjs
 */

import { existsSync, mkdirSync, copyFileSync, readdirSync, statSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { homedir } from 'node:os'

const REPO = dirname(dirname(fileURLToPath(import.meta.url)))
const SRC = join(REPO, 'resources/knowledge')
const CLI = join(homedir(), 'Dr.C', 'opencode', 'packages', 'opencode/resources/knowledge')

if (!existsSync(CLI)) {
  console.error('Dr.C CLI not found at', CLI)
  process.exit(1)
}

mkdirSync(join(CLI, 'sources'), { recursive: true })

const bundles = readdirSync(SRC).filter((f) => f.startsWith('bundle-') && f.endsWith('.json'))
for (const f of bundles) {
  copyFileSync(join(SRC, f), join(CLI, f))
  const mb = (statSync(join(CLI, f)).size / 1024 / 1024).toFixed(1)
  console.log('bundle', f, `${mb} MB`)
}

for (const f of readdirSync(join(SRC, 'sources'))) {
  copyFileSync(join(SRC, 'sources', f), join(CLI, 'sources', f))
  console.log('catalog', f)
}

const authSrc = join(REPO, 'src/main/agent/prompts/authoritative-sources.txt')
if (existsSync(authSrc)) {
  copyFileSync(authSrc, join(CLI, 'sources/authoritative-sources.txt'))
  console.log('catalog authoritative-sources.txt')
}

console.log(`\nSynced ${bundles.length} bundles + catalogs → ${CLI}`)
console.log('Workshop bundles are tracked in git — participants get knowledge on clone.')
