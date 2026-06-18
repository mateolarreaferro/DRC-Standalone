import { create } from 'zustand'
import type { UsageRecord, SessionUsageTotals } from '../lib/usageFormat'

export type UsageArea = 'agent' | 'player'

interface AreaUsage {
  last: UsageRecord | null
  totals: SessionUsageTotals
}

const emptyTotals = (): SessionUsageTotals => ({
  totalTokens: 0,
  totalCostUSD: 0,
  turnCount: 0,
})

interface UsageState {
  agent: AreaUsage
  player: AreaUsage
  record: (area: UsageArea, usage: UsageRecord) => void
  resetArea: (area: UsageArea) => void
  combinedTotals: () => SessionUsageTotals
}

export const useUsageStore = create<UsageState>((set, get) => ({
  agent: { last: null, totals: emptyTotals() },
  player: { last: null, totals: emptyTotals() },

  record: (area, usage) =>
    set((s) => {
      const cur = s[area]
      const tok = Number(usage.totalTokens)
      const cost = Number(usage.costUSD)
      const totalTokens = Number.isFinite(tok) ? tok : 0
      const costUSD = Number.isFinite(cost) ? cost : 0
      return {
        [area]: {
          last: { ...usage, totalTokens, costUSD },
          totals: {
            totalTokens: cur.totals.totalTokens + totalTokens,
            totalCostUSD: cur.totals.totalCostUSD + costUSD,
            turnCount: cur.totals.turnCount + 1,
          },
        },
      } as Pick<UsageState, UsageArea>
    }),

  resetArea: (area) =>
    set({ [area]: { last: null, totals: emptyTotals() } } as Pick<UsageState, UsageArea>),

  combinedTotals: () => {
    const { agent, player } = get()
    return {
      totalTokens: agent.totals.totalTokens + player.totals.totalTokens,
      totalCostUSD: agent.totals.totalCostUSD + player.totals.totalCostUSD,
      turnCount: agent.totals.turnCount + player.totals.turnCount,
    }
  },
}))
