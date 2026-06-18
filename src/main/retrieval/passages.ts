// Book passages extracted offline by scripts/extract-knowledge.mjs.
// Bundled via Vite's ?raw import so the main-process bundle doesn't need to
// read from disk at runtime. If the file is empty (extractor not run yet),
// the index is empty and narration falls back to the raw book search.

import passagesRaw from '../../../resources/knowledge/book-passages.json?raw'
import { Log } from '../util/log'

interface Passage {
  id: string
  topic_tags: string[]
  content: string
  source_book: string
  source_page: number | null
}

let passages: Passage[] | null = null
let tokenIndex: Map<string, number[]> | null = null

function ensureLoaded(): void {
  if (passages !== null) return
  try {
    const data = JSON.parse(passagesRaw) as { passages?: Passage[] }
    passages = Array.isArray(data.passages) ? data.passages : []
  } catch (err: any) {
    passages = []
    Log.warn(`passages: failed to parse book-passages.json — ${err?.message ?? 'unknown'}`)
  }
  buildIndex()
  Log.info(`passages: loaded ${passages!.length} extracted book passages`)
}

function tokenize(s: string): string[] {
  return s
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .split(/\s+/)
    .filter((t) => t.length >= 3)
}

function buildIndex(): void {
  tokenIndex = new Map()
  if (!passages) return
  for (let i = 0; i < passages.length; i++) {
    const p = passages[i]
    const tokens = new Set<string>()
    for (const t of p.topic_tags) for (const tok of tokenize(t)) tokens.add(tok)
    for (const tok of tokenize(p.content)) tokens.add(tok)
    for (const tok of tokens) {
      if (!tokenIndex.has(tok)) tokenIndex.set(tok, [])
      tokenIndex.get(tok)!.push(i)
    }
  }
}

export function searchPassages(query: string, max = 3): Passage[] {
  ensureLoaded()
  if (!passages || !tokenIndex || passages.length === 0) return []

  const terms = tokenize(query)
  if (terms.length === 0) return []

  // Score = sum of log2(1 + postings hits), with a boost for topic_tag matches.
  const scores = new Map<number, number>()
  for (const term of terms) {
    const postings = tokenIndex.get(term)
    if (!postings) continue
    const weight = Math.log2(1 + postings.length) // rarer terms weigh more slightly
    for (const idx of postings) {
      scores.set(idx, (scores.get(idx) ?? 0) + 1 / (1 + weight))
    }
  }

  // Boost passages whose topic_tags directly contain any query term.
  for (const [idx, score] of scores.entries()) {
    const p = passages[idx]
    const tagText = p.topic_tags.join(' ').toLowerCase()
    let boost = 1
    for (const t of terms) if (tagText.includes(t)) boost += 0.8
    scores.set(idx, score * boost)
  }

  const ranked = Array.from(scores.entries())
    .sort((a, b) => {
      const pa = passageSourcePriority(passages![a[0]].source_book)
      const pb = passageSourcePriority(passages![b[0]].source_book)
      if (pa !== pb) return pb - pa
      return b[1] - a[1]
    })
    .slice(0, max)
    .map(([idx]) => passages![idx])
  return ranked
}

function passageSourcePriority(sourceBook: string): number {
  const s = sourceBook.toLowerCase()
  if (s.includes('floss')) return 10
  if (s.includes('lazzarini')) return 8
  if (s.includes('boulanger') || s.includes('csound-book')) return 7
  return 1
}

export function passageCount(): number {
  ensureLoaded()
  return passages?.length ?? 0
}
