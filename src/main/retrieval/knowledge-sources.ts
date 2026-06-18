import { readFileSync } from 'fs'
import { Log } from '../util/log'

export interface KnowledgeChunk {
  id: string
  source: string
  content: string
  priority: number
}

/** Curated markdown/txt from resources/knowledge — antipatterns, patterns, syntax rules. */
const SOURCE_FILES: { file: string; label: string; priority: number }[] = [
  { file: 'sources/granular-models-catalog.md', label: 'Granular Synthesis Models (Dr.B foundation)', priority: 7 },
  { file: 'sources/physical-models-catalog.md', label: 'Physical / Waveguide Models (Dr.B foundation)', priority: 7 },
  { file: 'sources/drum-models-catalog.md', label: 'Synthetic Drum Models (Dr.B foundation)', priority: 7 },
  { file: 'sources/generative-models-catalog.md', label: 'Generative Groovy Models (Dr.B foundation)', priority: 7 },
  { file: 'sources/selected-catalog-v25.md', label: 'Csound Catalog v2.5 (Dr.B selected)', priority: 6 },
  { file: 'sources/mccurdy-haiku-catalog.md', label: 'McCurdy Haiku (generative ambient)', priority: 6 },
  { file: 'sources/elected-models-catalog.md', label: 'Elected Csound Models (Dr.B foundation)', priority: 6 },
  { file: 'sources/antipatterns.md', label: 'Csound 7 Anti-Patterns', priority: 5 },
  { file: 'sources/patterns.md', label: 'Csound 7 Patterns', priority: 4 },
  { file: 'sources/syntax-rules.md', label: 'Csound 7 Syntax Rules', priority: 4 },
  { file: 'sources/opcodes.md', label: 'Opcode Reference Notes', priority: 3 },
  { file: 'csound7-reference.txt', label: 'Csound 7 LLM Reference', priority: 3 },
  { file: 'sources/csound7-llms-reference.md', label: 'Csound 7 LLMs Reference', priority: 3 },
  { file: 'sources/lazzarini-web.md', label: 'Lazzarini Web Notes', priority: 2 },
]

let chunks: KnowledgeChunk[] = []
let initialized = false

function chunkMarkdown(content: string, sourceId: string, label: string, priority: number): KnowledgeChunk[] {
  const sections = content.split(/\n(?=## )/)
  const out: KnowledgeChunk[] = []
  for (let i = 0; i < sections.length; i++) {
    const body = sections[i].trim()
    if (body.length < 50) continue
    out.push({
      id: `${sourceId}#${i}`,
      source: label,
      content: body.slice(0, 1400),
      priority,
    })
  }
  if (out.length === 0 && content.trim().length > 50) {
    out.push({
      id: sourceId,
      source: label,
      content: content.trim().slice(0, 1400),
      priority,
    })
  }
  return out
}

export function initKnowledgeSources(findResource: (filename: string) => string | null): void {
  if (initialized) return
  for (const { file, label, priority } of SOURCE_FILES) {
    const path = findResource(file)
    if (!path) {
      Log.warn(`Knowledge source not found: ${file}`)
      continue
    }
    try {
      const text = readFileSync(path, 'utf-8')
      const sourceId = file.replace(/[^\w]+/g, '-')
      const added = chunkMarkdown(text, sourceId, label, priority)
      chunks.push(...added)
      Log.info(`Knowledge: ${label} → ${added.length} chunks`)
    } catch (err: any) {
      Log.warn(`Knowledge source read failed ${file}: ${err?.message ?? err}`)
    }
  }
  initialized = true
  Log.info(`Knowledge sources ready: ${chunks.length} searchable chunks`)
}

export function searchKnowledgeSources(
  query: string,
  max = 3,
): { id: string; source: string; content: string; score: number }[] {
  if (chunks.length === 0) return []
  const terms = query.toLowerCase().split(/\s+/).filter((t) => t.length > 2)
  if (terms.length === 0) return []

  const scored: { id: string; source: string; content: string; score: number }[] = []
  for (const chunk of chunks) {
    const lower = chunk.content.toLowerCase()
    let score = chunk.priority
    for (const term of terms) {
      const esc = term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
      const count = (lower.match(new RegExp(esc, 'g')) || []).length
      if (count > 0) score += Math.log2(1 + count)
    }
    // Surface granular catalog when grain/partikkel/sndwarp mentioned
    if (chunk.source.includes('Granular Synthesis Models') &&
        /\b(granular|grain|partikkel|sndwarp|brandtsegg|texture|cloud)\b/i.test(query)) {
      score += 5
    }
    // Surface physical-model catalog when waveguide/pluck/pipa/handpan mentioned
    if (chunk.source.includes('Physical / Waveguide Models') &&
        /\b(waveguide|wgflute|wgpluck|wgbow|karplus|pluck|pipa|handpan|physical\s*model|modal)\b/i.test(query)) {
      score += 5
    }
    // Surface drum-model catalog when percussion/drum kit mentioned
    if (chunk.source.includes('Synthetic Drum Models') &&
        /\b(drum|kick|snare|hi-?hat|cymbal|percussion|drum\s*machine|glitch\s*drum|ms-?20|k35|dseq)\b/i.test(query)) {
      score += 5
    }
    if (chunk.source.includes('Generative Groovy Models') &&
        /\b(generative|groovy|jagwani|marston|genjam|metro|schedkwhen|alwayson)\b/i.test(query)) {
      score += 5
    }
    // Surface Csound Catalog v2.5 when instrument/composer keywords appear
    if (chunk.source.includes('Csound Catalog v2.5') &&
        /\b(risset|cook|costello|comajuncosas|varo|smaragdis|mikelson|303|marimba|fof|catalog)\b/i.test(query)) {
      score += 4
    }
    // Surface McCurdy Haiku catalog for generative / ambient prompts
    if (chunk.source.includes('McCurdy Haiku') &&
        /\b(ambient|generative|haiku|mccurdy|soundscape|drone|alwayson|schedkwhen|rspline|jspline|evolving)\b/i.test(query)) {
      score += 4
    }
    // Surface elected-model catalog when domain keywords appear
    if (chunk.source.includes('Elected Csound Models') &&
        /\b(wobble|gbuzz|gendyc|sterrain|groovish|dizi|sheng|deep\s*note|thx|horner|microtonal)\b/i.test(query)) {
      score += 3
    }
    // Always surface anti-patterns when FM / envelope / expseg mentioned
    if (chunk.source.includes('Anti-Pattern') && /\b(fm|foscil|expseg|linsegr|envelope|vco2)\b/i.test(query)) {
      score += 2
    }
    if (score > chunk.priority) {
      scored.push({ id: chunk.id, source: chunk.source, content: chunk.content, score })
    }
  }

  scored.sort((a, b) => b.score - a.score)
  return scored.slice(0, max)
}

export function knowledgeChunkCount(): number {
  return chunks.length
}
