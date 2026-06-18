import { create } from 'zustand'
import { isQuotaError, parseQuotaRetryMs } from '../lib/providerGuide'

/** Shared free-tier cooldown — Agent, Player adapt, and activity bar. */
interface RateLimitState {
  until: number | null
  /** Provider that last reported a limit (for display). */
  providerLabel: string | null
  setCooldown: (until: number, providerLabel?: string | null) => void
  clearCooldown: () => void
}

export const useRateLimitStore = create<RateLimitState>((set) => ({
  until: null,
  providerLabel: null,
  setCooldown: (until, providerLabel = null) => set({ until, providerLabel }),
  clearCooldown: () => set({ until: null, providerLabel: null }),
}))

export function rateLimitRemainingMs(): number {
  const until = useRateLimitStore.getState().until
  if (!until) return 0
  return Math.max(0, until - Date.now())
}

export function isRateLimited(): boolean {
  return rateLimitRemainingMs() > 0
}

/** Start countdown when an error message looks like a free-tier quota hit. */
export function applyQuotaCooldownFromMessage(message: string): void {
  if (!isQuotaError(message)) return
  let providerLabel: string | null = null
  if (/gemini|google/i.test(message)) providerLabel = 'Google AI (Gemini)'
  else if (/groq/i.test(message)) providerLabel = 'Groq'
  useRateLimitStore.getState().setCooldown(Date.now() + parseQuotaRetryMs(message), providerLabel)
}
