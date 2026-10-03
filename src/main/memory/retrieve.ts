import { MemoryStore } from './store'
import { Learning } from './learning'
import { BUILTIN_STANDING_RULES } from './builtin-lessons'
import type { ErrorFixRow } from './schema'

// Turns stored memory into token-bounded prompt blocks. Ranking deliberately
// mirrors the RAG engine's log-weighted token overlap (retrieval/passages.ts)
// rather than introducing embeddings — it's fast over the small error_fixes
// table and adds no dependencies.

// Query-independent importance of a stored fix, for the proactive previous-errors
// block: a distilled rule is worth far more than a raw pair, recurring mistakes
// (uses) outrank one-offs, and recent beats stale.
function rankFix(row: ErrorFixRow): number {
  const hasRule = row.diffSummary ? 100 : 0
  const ageDays = (Date.now() - row.createdAt) / 86_400_000
  const recency = Math.exp(-ageDays / 30)
  return hasRule + row.uses * 4 + recency
}

function scoreFix(queryTokens: Set<string>, row: ErrorFixRow, queryKind?: string): number {
  let overlap = 0
  for (const t of row.tokens) if (queryTokens.has(t)) overlap += 1
  if (overlap === 0) return 0
  const relevance = Math.log2(1 + overlap) + overlap * 0.25
  const ageDays = (Date.now() - row.createdAt) / 86_400_000
  const recency = Math.exp(-ageDays / 30)
  const kindBoost = queryKind && row.kind === queryKind ? 1.5 : 1
  return relevance * (0.7 + 0.3 * recency) * kindBoost
}

export namespace MemoryRetrieval {
  export function relevantErrorFixes(
    errorRaw: string,
    k = 2,
    kind?: string,
  ): ErrorFixRow[] {
    const all = MemoryStore.allErrorFixes()
    if (all.length === 0) return []
    const { tokens } = MemoryStore.signatureOf(errorRaw)
    const queryTokens = new Set(tokens)
    return all
      .map((row) => ({ row, score: scoreFix(queryTokens, row, kind) }))
      .filter((x) => x.score > 0)
      .sort((a, b) => b.score - a.score)
      .slice(0, k)
      .map((x) => x.row)
  }

  // Lessons whose wording overlaps the current request — these are the ones to
  // surface inline with the user's message so the model can't skip them.
  export function matchedLessons(userText: string, max = 3): string[] {
    const hits: string[] = [...BUILTIN_STANDING_RULES]
    const lessons = MemoryStore.allLessons()
    const userTokens = new Set(
      userText.toLowerCase().replace(/[^a-z0-9]+/g, ' ').split(/\s+/)
        .filter((t) => t.length >= 4)
        .map((t) => t.replace(/s$/, '')),
    )
    for (const l of lessons) {
      if (BUILTIN_STANDING_RULES.some((b) => b === l.text)) continue
      const lt = l.text.toLowerCase().replace(/[^a-z0-9]+/g, ' ').split(/\s+/).map((t) => t.replace(/s$/, ''))
      if (userTokens.size === 0 || lt.some((t) => t.length >= 4 && userTokens.has(t))) {
        hits.push(l.text)
      }
      if (hits.length >= max + BUILTIN_STANDING_RULES.length) break
    }
    return hits.slice(0, max + BUILTIN_STANDING_RULES.length)
  }

  export function lessonsBlock(maxChars = 2000): string {
    const userLessons = MemoryStore.allLessons().filter(
      (l) => !BUILTIN_STANDING_RULES.some((b) => b === l.text),
    )
    const lines = [
      `<remembered-instructions>`,
      `Standing rules from Dr. Richard Boulanger and this user. BINDING — override defaults. Realize each rule in generated code, not prose:`,
    ]
    let budget = maxChars
    for (const rule of BUILTIN_STANDING_RULES) {
      const entry = `- ${rule}`
      if (entry.length > budget) break
      lines.push(entry)
      budget -= entry.length
    }
    for (const l of userLessons) {
      const entry = `- ${l.text}`
      if (entry.length > budget) break
      lines.push(entry)
      budget -= entry.length
    }
    if (lines.length <= 2) return ''
    lines.push(`</remembered-instructions>`)
    return lines.join('\n')
  }

  // Feedback-learned guidance — what to lean toward and what to avoid, derived
  // from this user's 👍/👎 and accepted fixes. Soft preference, not a rule.
  // Empty until the user has actually given feedback.
  export function learningBlock(maxChars = 400): string {
    const p = Learning.get()
    const favored = p.favored.slice(0, 5)
    const disfavored = p.disfavored.slice(0, 4)
    const favoredOpcodes = p.favoredOpcodes.slice(0, 6)
    if (favored.length === 0 && disfavored.length === 0 && favoredOpcodes.length === 0) return ''
    const lines: string[] = [`<learned-guidance>`]
    if (favored.length)
      lines.push(`The user has responded well to: ${favored.join(', ')}.`)
    if (favoredOpcodes.length)
      lines.push(`Opcodes that landed well: ${favoredOpcodes.join(', ')}.`)
    if (disfavored.length)
      lines.push(`The user reacted poorly to: ${disfavored.join(', ')} — avoid unless asked.`)
    lines.push(`Treat as soft preference learned from feedback, not a hard requirement.`)
    lines.push(`</learned-guidance>`)
    return lines.join('\n').slice(0, maxChars)
  }

  // Proactive "previous errors" memory — injected on EVERY real generation turn
  // (next to remembered-instructions), NOT keyed to a current error. Surfaces the
  // distilled avoidance rules (diffSummary) from past autofixes so the model writes
  // code that sidesteps known failure modes from the start, instead of generating a
  // broken first draft and relying on the reactive autofix loop.
  //
  // Prioritizes pairs that (a) have a distilled rule, (b) recurred most (uses), and
  // (c) are most recent. Deduped by error signature so one class of mistake counts
  // once. Compact by design (no full CSDs — those belong in errorFixBlock).
  export function previousErrorsBlock(maxChars = 1200, max = 5): string {
    const all = MemoryStore.allErrorFixes()
    if (all.length === 0) return ''

    // Keep the strongest row per signature: prefer one with a distilled rule,
    // then more uses, then more recent.
    const bySig = new Map<string, ErrorFixRow>()
    for (const row of all) {
      const cur = bySig.get(row.signature)
      if (!cur || rankFix(row) > rankFix(cur)) bySig.set(row.signature, row)
    }

    const ranked = Array.from(bySig.values())
      .sort((a, b) => rankFix(b) - rankFix(a))
      .slice(0, max)

    // Only worth a prompt block once at least one rule has been distilled — a list
    // of raw error strings with no takeaway is noise.
    if (!ranked.some((r) => r.diffSummary)) return ''

    const lines = [
      `<previous-errors>`,
      `Mistakes that have broken your CSDs before. Write code that avoids these from the START — do not reproduce the broken pattern and lean on a later fix. Each rule is binding when it applies:`,
    ]
    let budget = maxChars
    for (const r of ranked) {
      const rule = r.diffSummary ?? `Avoid whatever caused: ${r.errorRaw.slice(0, 120)}`
      const entry = `- [${r.kind}] ${rule}`
      if (entry.length > budget) break
      lines.push(entry)
      budget -= entry.length
    }
    lines.push(`</previous-errors>`)
    return lines.length > 3 ? lines.join('\n') : ''
  }

  // Only injected on autofix turns: prior fixes for similar errors.
  export function errorFixBlock(errorRaw: string, kind?: string, maxChars = 1800): string {
    const hits = relevantErrorFixes(errorRaw, 2, kind)
    if (hits.length === 0) return ''
    const parts: string[] = [
      `<error-fix-memory>`,
      `You have fixed similar errors before. Reuse what worked:`,
    ]
    let budget = maxChars
    for (const h of hits) {
      MemoryStore.bumpErrorFixUse(h.id)
      const broken = (h.brokenCsd ?? '').slice(0, 800)
      const fixed = h.fixedCsd.slice(0, 800)
      const entry = [
        `--- past ${h.kind} error: ${h.errorRaw.slice(0, 200)}`,
        h.diffSummary ? `fix summary: ${h.diffSummary}` : '',
        broken ? `before:\n${broken}` : '',
        `after (worked):\n${fixed}`,
      ]
        .filter(Boolean)
        .join('\n')
      if (entry.length > budget) break
      parts.push(entry)
      budget -= entry.length
    }
    parts.push(`</error-fix-memory>`)
    return parts.join('\n')
  }
}
