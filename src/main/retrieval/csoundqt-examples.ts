import { readFileSync, readdirSync, existsSync } from 'fs'
import { join, relative } from 'path'
import { homedir } from 'os'
import { Log } from '../util/log'

export interface QtExample {
  id: string
  collection: string
  content: string
}

const COLLECTIONS: { dir: string; idPrefix: string; boost: number; maxFiles: number }[] = [
  { dir: 'McCurdy Collection', idPrefix: 'csoundqt-mccurdy', boost: 4, maxFiles: 180 },
  { dir: 'FLOSS Manual Examples', idPrefix: 'csoundqt-floss', boost: 4.5, maxFiles: 120 },
  { dir: 'McCurdy Haikus', idPrefix: 'csoundqt-haiku', boost: 3.5, maxFiles: 40 },
]

let examples: Map<string, QtExample> = new Map()
const collectionBoost = new Map<string, number>()
let initialized = false

function macExamplesRoot(): string | null {
  for (const base of ['/Applications', join(homedir(), 'Applications')]) {
    try {
      for (const name of readdirSync(base)) {
        if (!name.toLowerCase().startsWith('csoundqt') || !name.endsWith('.app')) continue
        const root = join(base, name, 'Contents/Resources/Examples')
        if (existsSync(root)) return root
      }
    } catch {
      /* skip */
    }
  }
  return null
}

function walkCsds(
  dir: string,
  collectionRoot: string,
  collection: string,
  idPrefix: string,
  maxFiles: number,
  count: { n: number },
): void {
  if (count.n >= maxFiles) return
  let entries
  try {
    entries = readdirSync(dir, { withFileTypes: true })
  } catch {
    return
  }

  for (const entry of entries) {
    if (count.n >= maxFiles) return
    const full = join(dir, entry.name)
    if (entry.isDirectory()) {
      walkCsds(full, collectionRoot, collection, idPrefix, maxFiles, count)
      continue
    }
    if (!entry.name.toLowerCase().endsWith('.csd')) continue
    try {
      const content = readFileSync(full, 'utf-8')
      if (!content.includes('<CsoundSynthesizer')) continue
      const rel = relative(collectionRoot, full).replace(/[^\w.-]+/g, '-')
      const id = `${idPrefix}-${rel}`.toLowerCase()
      examples.set(id, { id, collection, content: content.slice(0, 4000) })
      count.n += 1
    } catch {
      /* skip unreadable */
    }
  }
}

export function initCsoundQtExamples(): void {
  if (initialized) return
  initialized = true

  try {
    const root = process.platform === 'darwin' ? macExamplesRoot() : null
    if (!root) {
      Log.info('CsoundQt examples: no local CsoundQt.app found (optional)')
      return
    }

    for (const { dir, idPrefix, boost, maxFiles } of COLLECTIONS) {
      const collectionRoot = join(root, dir)
      if (!existsSync(collectionRoot)) continue
      collectionBoost.set(idPrefix, boost)
      walkCsds(collectionRoot, collectionRoot, dir, idPrefix, maxFiles, { n: 0 })
    }

    Log.info(`CsoundQt examples indexed: ${examples.size} CSDs from ${root}`)
  } catch (err: any) {
    Log.warn(`CsoundQt examples indexing skipped: ${err?.message ?? err}`)
  }
}

export function searchCsoundQtExamples(
  query: string,
  max = 3,
): { id: string; content: string; score: number; collection: string }[] {
  if (examples.size === 0) return []
  const terms = query.toLowerCase().split(/\s+/).filter((t) => t.length > 2)
  if (terms.length === 0) return []

  const scored: { id: string; content: string; score: number; collection: string }[] = []
  for (const [id, ex] of examples) {
    const lower = (id + '\n' + ex.content).toLowerCase()
    let score = 0
    for (const term of terms) {
      const esc = term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
      const count = (lower.match(new RegExp(esc, 'g')) || []).length
      if (count > 0) score += Math.log2(1 + count)
    }
    const prefix = id.startsWith('csoundqt-mccurdy')
      ? 'csoundqt-mccurdy'
      : id.startsWith('csoundqt-floss')
        ? 'csoundqt-floss'
        : 'csoundqt-haiku'
    score *= collectionBoost.get(prefix) ?? 1
    if (terms.some((t) => id.includes(t))) score *= 1.5
    if (score > 0) scored.push({ id, content: ex.content.slice(0, 2000), score, collection: ex.collection })
  }

  scored.sort((a, b) => b.score - a.score)
  return scored.slice(0, max)
}

export function csoundQtExampleCount(): number {
  return examples.size
}
