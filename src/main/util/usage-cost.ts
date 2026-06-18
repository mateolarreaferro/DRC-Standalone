/** Token usage + USD cost estimates for models Dr.C Standalone actually calls. */

export interface UsageRecord {
  providerID: string
  modelID: string
  inputTokens: number
  outputTokens: number
  totalTokens: number
  costUSD: number
  /** True when the model is on a known free tier (Gemini/Groq workshop keys). */
  freeTier: boolean
  phase: 'main' | 'narration' | 'suggestions' | 'player' | 'other'
}

// USD per 1M tokens (input / output). Matches models.dev-style pricing.
const PRICING: Record<string, { input: number; output: number; free?: boolean }> = {
  'google:gemini-2.5-flash': { input: 0, output: 0, free: true },
  'groq:llama-3.3-70b-versatile': { input: 0, output: 0, free: true },
  'groq:llama-3.1-8b-instant': { input: 0, output: 0, free: true },
  'anthropic:claude-sonnet-4-5': { input: 3, output: 15 },
  'anthropic:claude-haiku-4-5': { input: 0.8, output: 4 },
  'openai:gpt-4.1': { input: 2, output: 8 },
  'openai:gpt-4.1-mini': { input: 0.4, output: 1.6 },
}

function pricingKey(providerID: string, modelID: string): string {
  return `${providerID}:${modelID}`
}

function lookupPricing(providerID: string, modelID: string) {
  const exact = PRICING[pricingKey(providerID, modelID)]
  if (exact) return exact
  // Fuzzy: same provider family
  if (providerID === 'google') return PRICING['google:gemini-2.5-flash']
  if (providerID === 'groq') return PRICING['groq:llama-3.3-70b-versatile']
  if (providerID === 'ollama') return { input: 0, output: 0, free: true }
  if (providerID === 'anthropic' && modelID.includes('haiku')) {
    return PRICING['anthropic:claude-haiku-4-5']
  }
  if (providerID === 'anthropic') return PRICING['anthropic:claude-sonnet-4-5']
  if (providerID === 'openai' && modelID.includes('mini')) {
    return PRICING['openai:gpt-4.1-mini']
  }
  if (providerID === 'openai') return PRICING['openai:gpt-4.1']
  if (providerID === 'openrouter') {
    if (modelID.includes('haiku')) return PRICING['anthropic:claude-haiku-4-5']
    if (modelID.startsWith('anthropic/')) return PRICING['anthropic:claude-sonnet-4-5']
    if (modelID.includes('mini')) return PRICING['openai:gpt-4.1-mini']
    if (modelID.startsWith('openai/')) return PRICING['openai:gpt-4.1']
    if (modelID.startsWith('google/')) return PRICING['google:gemini-2.5-flash']
  }
  return { input: 0, output: 0 }
}

export function computeCost(
  providerID: string,
  modelID: string,
  inputTokens: number,
  outputTokens: number,
): { costUSD: number; freeTier: boolean } {
  const p = lookupPricing(providerID, modelID)
  const costUSD =
    (inputTokens * p.input + outputTokens * p.output) / 1_000_000
  return { costUSD, freeTier: p.free === true || providerID === 'ollama' || (p.input === 0 && p.output === 0 && providerID === 'google') }
}

function asTokenCount(v: unknown): number {
  const n = Number(v)
  return Number.isFinite(n) && n > 0 ? Math.floor(n) : 0
}

/** Normalize AI SDK v4 usage objects (field names vary by provider). */
export function usageFromSdk(
  providerID: string,
  modelID: string,
  raw: unknown,
  phase: UsageRecord['phase'] = 'main',
): UsageRecord | null {
  if (!raw || typeof raw !== 'object') return null
  const u = raw as Record<string, unknown>
  const inputTokens = asTokenCount(u.promptTokens ?? u.inputTokens)
  const outputTokens = asTokenCount(u.completionTokens ?? u.outputTokens)
  const totalTokens = asTokenCount(u.totalTokens) || inputTokens + outputTokens
  if (totalTokens <= 0 && inputTokens <= 0 && outputTokens <= 0) return null

  const { costUSD, freeTier } = computeCost(providerID, modelID, inputTokens, outputTokens)
  return {
    providerID,
    modelID,
    inputTokens,
    outputTokens,
    totalTokens,
    costUSD,
    freeTier,
    phase,
  }
}
