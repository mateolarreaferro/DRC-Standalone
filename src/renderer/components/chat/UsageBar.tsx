import type { CSSProperties } from 'react'
import { useUsageStore, type UsageArea } from '../../stores/usageStore'
import { formatCostUSD, formatTokenCount, shortModelName } from '../../lib/usageFormat'

interface Props {
  area: UsageArea
  /** footer = Agent input strip; inline = Player transport row */
  variant?: 'footer' | 'inline'
  sessionLabel?: string
}

/** Token/cost strip — matches Dr.C Terminal session footer. */
export default function UsageBar({ area, variant = 'footer', sessionLabel }: Props) {
  const lastTurn = useUsageStore((s) => s[area].last)
  const sessionTotal = useUsageStore((s) => s[area].totals)

  if (!lastTurn && sessionTotal.turnCount === 0) return null

  const costLabel = formatCostUSD(sessionTotal.totalCostUSD, sessionTotal.totalCostUSD === 0)
  const label = sessionLabel ?? (area === 'player' ? 'Player adapts' : 'Session')

  return (
    <div
      style={variant === 'inline' ? styles.inline : styles.bar}
      title={`Estimated API usage — ${area}`}
    >
      {lastTurn && (
        <span style={styles.last}>
          {shortModelName(lastTurn.modelID)}
          {' · '}
          {formatTokenCount(lastTurn.totalTokens)} tokens
          {' · '}
          <span style={lastTurn.freeTier ? styles.free : styles.paid}>
            {formatCostUSD(lastTurn.costUSD, lastTurn.freeTier)}
            {lastTurn.freeTier ? ' (free tier)' : ''}
          </span>
        </span>
      )}
      {sessionTotal.turnCount > 0 && (
        <span style={styles.session}>
          {label}: {formatTokenCount(sessionTotal.totalTokens)} tok · {costLabel}
        </span>
      )}
    </div>
  )
}

const styles: Record<string, CSSProperties> = {
  bar: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: '6px 16px',
    padding: '6px 28px 2px',
    fontSize: 11,
    color: 'var(--text-muted)',
    fontFamily: 'var(--font-mono)',
    borderTop: '1px solid var(--border-subtle)',
  },
  inline: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'flex-start',
    gap: 2,
    fontSize: 10,
    color: 'var(--text-muted)',
    fontFamily: 'var(--font-mono)',
    marginLeft: 'auto',
    maxWidth: 420,
    textAlign: 'right',
  },
  last: { flex: '1 1 auto', minWidth: 0 },
  session: { flexShrink: 0, opacity: 0.85 },
  free: { color: 'var(--accent)' },
  paid: { color: 'var(--text-secondary)' },
}
