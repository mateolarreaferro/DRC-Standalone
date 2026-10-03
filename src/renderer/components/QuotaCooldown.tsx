import { useEffect, useState, type CSSProperties } from 'react'
import { Link } from 'react-router-dom'
import { formatCountdown } from '../lib/providerGuide'

interface Props {
  until: number
  providerLabel?: string | null
  onExpired?: () => void
  compact?: boolean
}

/** Countdown after free-tier rate limits — shown on Agent and Player. */
export default function QuotaCooldown({ until, providerLabel, onExpired, compact }: Props) {
  const [remaining, setRemaining] = useState(() => Math.max(0, until - Date.now()))

  useEffect(() => {
    const tick = () => {
      const next = Math.max(0, until - Date.now())
      setRemaining(next)
      if (next === 0) onExpired?.()
    }
    tick()
    const id = window.setInterval(tick, 250)
    return () => window.clearInterval(id)
  }, [until, onExpired])

  if (remaining <= 0) return null

  const who = providerLabel ? `${providerLabel} ` : ''

  return (
    <div style={compact ? styles.compact : styles.box} role="status" aria-live="polite">
      <span style={styles.timerLabel}>
        {compact ? 'Rate limit' : `${who}rate limit — wait before retrying`}
      </span>
      <span style={compact ? styles.timerCompact : styles.timer}>{formatCountdown(remaining)}</span>
      {!compact && (
        <>
          <span style={styles.hint}>
            Wait for the timer, then use Try again. Dr.C switches between Groq and Gemini automatically when both keys are saved.
            For the best Agent results, use <strong>your own</strong> Anthropic, OpenAI, or OpenRouter API key.
          </span>
          <Link to="/settings" style={styles.link}>
            Add keys in Settings →
          </Link>
        </>
      )}
      {compact && (
        <span style={styles.hintCompact}>
          {' '}— wait, then try again
        </span>
      )}
    </div>
  )
}

const styles: Record<string, CSSProperties> = {
  box: {
    width: '100%',
    marginBottom: 10,
    padding: '12px 14px',
    borderRadius: 10,
    border: '1px solid var(--border)',
    background: 'var(--bg-secondary)',
    display: 'flex',
    flexDirection: 'column',
    gap: 6,
  },
  compact: {
    display: 'inline-flex',
    alignItems: 'baseline',
    flexWrap: 'wrap',
    gap: 4,
    marginBottom: 8,
    fontSize: 12,
    color: 'var(--text-muted)',
  },
  timerLabel: {
    fontSize: 11,
    fontWeight: 600,
    letterSpacing: '0.06em',
    textTransform: 'uppercase',
    color: 'var(--warning)',
  },
  timer: {
    fontSize: 22,
    fontWeight: 500,
    fontFamily: 'var(--font-mono)',
    color: 'var(--text-primary)',
    letterSpacing: '0.04em',
  },
  timerCompact: {
    fontSize: 13,
    fontWeight: 600,
    fontFamily: 'var(--font-mono)',
    color: 'var(--warning)',
  },
  hint: {
    fontSize: 12,
    lineHeight: 1.45,
    color: 'var(--text-muted)',
  },
  hintCompact: {
    fontSize: 11,
    color: 'var(--text-muted)',
  },
  link: {
    fontSize: 12,
    color: 'var(--accent)',
    textDecoration: 'underline',
    marginTop: 2,
  },
}
