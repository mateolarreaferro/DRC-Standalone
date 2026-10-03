/** Display helpers for token/cost usage (mirrors main process estimates). */

export interface UsageRecord {
  providerID: string
  modelID: string
  inputTokens: number
  outputTokens: number
  totalTokens: number
  costUSD: number
  freeTier: boolean
  phase: 'main' | 'narration' | 'suggestions' | 'player' | 'other'
}

export interface SessionUsageTotals {
  totalTokens: number
  totalCostUSD: number
  turnCount: number
}

export function formatTokenCount(n: number | null | undefined): string {
  const v = Number(n)
  return (Number.isFinite(v) ? v : 0).toLocaleString('en-US')
}

/** Short model label for the footer, e.g. gemini-2.5-flash */
export function shortModelName(modelID: string): string {
  const slash = modelID.lastIndexOf('/')
  return slash >= 0 ? modelID.slice(slash + 1) : modelID
}

export function formatCostUSD(usd: number | null | undefined, freeTier?: boolean): string {
  const v = Number(usd)
  if (!Number.isFinite(v) || (v === 0 && freeTier)) return '$0.00'
  if (v > 0 && v < 0.0001) return '<$0.0001'
  if (v < 0.01) return `$${v.toFixed(4)}`
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 4,
  }).format(v)
}

export function sumUsage(records: UsageRecord[]): SessionUsageTotals {
  let totalTokens = 0
  let totalCostUSD = 0
  for (const r of records) {
    const tok = Number(r.totalTokens)
    const cost = Number(r.costUSD)
    totalTokens += Number.isFinite(tok) ? tok : 0
    totalCostUSD += Number.isFinite(cost) ? cost : 0
  }
  return { totalTokens, totalCostUSD, turnCount: records.length }
}
