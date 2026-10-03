#!/usr/bin/env node
/**
 * Inject `--limiter=0.9` into every workshop-starter CSD that lacks it.
 *
 *   node scripts/ensure-limiter-on-csds.mjs
 *   node scripts/ensure-limiter-on-csds.mjs --dry-run
 */

import { readFileSync, writeFileSync, readdirSync, statSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const REPO = dirname(dirname(fileURLToPath(import.meta.url)))
const ROOT = join(REPO, 'resources/workshop-starters')
const DRY = process.argv.includes('--dry-run')
const LIMITER = '--limiter=0.9'

function ensureLimiter(csd) {
  if (/(?:^|\s)--limiter(?:=\S+)?(?:\s|$)/im.test(csd)) return csd
  const line = LIMITER
  if (!/<CsOptions>/i.test(csd)) {
    return csd.replace(
      /<CsInstruments>/i,
      `<CsOptions>\n${line}\n</CsOptions>\n<CsInstruments>`,
    )
  }
  return csd.replace(/<CsOptions>([\s\S]*?)<\/CsOptions>/i, (_, body) => {
    const lines = body
      .split('\n')
      .map((l) => l.trim())
      .filter(Boolean)
    lines.push(line)
    return `<CsOptions>\n${lines.join('\n')}\n</CsOptions>`
  })
}

function walk(dir, out = []) {
  for (const name of readdirSync(dir)) {
    const path = join(dir, name)
    if (statSync(path).isDirectory()) walk(path, out)
    else if (name.endsWith('.csd')) out.push(path)
  }
  return out
}

let updated = 0
for (const path of walk(ROOT)) {
  const raw = readFileSync(path, 'utf-8')
  const next = ensureLimiter(raw)
  if (next === raw) continue
  updated++
  const rel = path.slice(REPO.length + 1)
  if (DRY) console.log(`would update ${rel}`)
  else {
    writeFileSync(path, next, 'utf-8')
    console.log(`updated ${rel}`)
  }
}

console.log(DRY ? `dry-run: ${updated} file(s) would get ${LIMITER}` : `done: ${updated} file(s) updated`)
