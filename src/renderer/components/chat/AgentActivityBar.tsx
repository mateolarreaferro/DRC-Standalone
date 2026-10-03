import { useEffect, useState, type CSSProperties } from 'react'
import { useSessionStore } from '../../stores/sessionStore'
import { usePlaybackStore } from '../../stores/playbackStore'
import QuotaCooldown from '../QuotaCooldown'
import { useRateLimitStore } from '../../stores/rateLimitStore'
/** Shows what Dr.C is doing right now — LLM, compile, play — with elapsed time. */
export default function AgentActivityBar({
  compact = false,
  onCancel,
}: {
  compact?: boolean
  onCancel?: () => void
}) {
  const activity = useSessionStore((s) => s.agentActivity)
  const startedAt = useSessionStore((s) => s.agentActivityStartedAt)
  const isStreaming = useSessionStore((s) => s.isStreaming)
  const playbackStatus = usePlaybackStore((s) => s.status)
  const playbackMessage = usePlaybackStore((s) => s.message)
  const playbackId = usePlaybackStore((s) => s.artifactId)
  const rateLimitUntil = useRateLimitStore((s) => s.until)
  const rateLimitProvider = useRateLimitStore((s) => s.providerLabel)
  const clearRateLimit = useRateLimitStore((s) => s.clearCooldown)

  const [, tick] = useState(0)
  useEffect(() => {
    if (!isStreaming && !activity && playbackStatus === 'idle') return
    const id = setInterval(() => tick((n) => n + 1), 1000)
    return () => clearInterval(id)
  }, [isStreaming, activity, playbackStatus])

  const elapsed =
    startedAt && (isStreaming || activity)
      ? Math.max(0, Math.floor((Date.now() - startedAt) / 1000))
      : 0

  let label = activity
  if (!label && isStreaming) label = 'Waiting for the model…'
  if (playbackId && playbackStatus === 'compiling') label = playbackMessage || 'Compiling with Csound…'
  if (playbackId && playbackStatus === 'playing') label = playbackMessage || 'Playing your sound…'
  if (playbackId && playbackStatus === 'error') label = playbackMessage || 'Playback error'

  if (!label) {
    if (rateLimitUntil != null && rateLimitUntil > Date.now()) {
      return (
        <QuotaCooldown
          until={rateLimitUntil}
          providerLabel={rateLimitProvider}
          onExpired={clearRateLimit}
          compact={compact}
        />
      )
    }
    return null
  }

  const showCancel = Boolean(onCancel) && isStreaming && elapsed > 5
  const hint =
    isStreaming && elapsed >= 90
      ? 'This is taking too long. Tap Cancel, then try once — do not resend the same prompt while a request is running.'
      : isStreaming && elapsed >= 45
        ? 'One request at a time. Dr.C is still working on this turn — text will appear, then Csound will compile and play automatically.'
        : isStreaming && elapsed > 8
          ? 'Complex prompts can take 15–30s on the first reply. You will hear the sound when the CSD compiles.'
          : null

  return (
    <div style={{ ...styles.bar, ...(compact ? styles.barCompact : {}) }}>
      {label && (
        <div style={styles.row}>
          <span style={styles.spinner} aria-hidden />
          <span style={styles.label}>{label}</span>
          {elapsed > 2 && (
            <span style={styles.elapsed}>{elapsed}s</span>
          )}
          {showCancel && (
            <button type="button" onClick={onCancel} style={styles.cancelBtn}>
              Cancel
            </button>
          )}
        </div>
      )}
      {!compact && hint && (
        <p style={styles.hint}>{hint}</p>
      )}
    </div>
  )
}

const styles: Record<string, CSSProperties> = {
  bar: {
    width: '100%',
    padding: '10px 14px',
    borderRadius: 12,
    border: '1px solid var(--border)',
    background: 'var(--bg-secondary)',
    marginBottom: 10,
  },
  barCompact: {
    marginBottom: 8,
    padding: '8px 12px',
  },
  row: {
    display: 'flex',
    alignItems: 'center',
    gap: 10,
  },
  spinner: {
    width: 10,
    height: 10,
    borderRadius: '50%',
    border: '2px solid var(--bg-tertiary)',
    borderTopColor: 'var(--accent)',
    animation: 'drc-spin 0.8s linear infinite',
    flexShrink: 0,
  },
  label: {
    fontSize: 13,
    color: 'var(--text-primary)',
    flex: 1,
    lineHeight: 1.4,
  },
  elapsed: {
    fontSize: 11,
    fontFamily: 'var(--font-mono)',
    color: 'var(--text-muted)',
    flexShrink: 0,
  },
  cancelBtn: {
    flexShrink: 0,
    fontSize: 11,
    fontWeight: 600,
    padding: '4px 10px',
    borderRadius: 8,
    border: '1px solid var(--border)',
    background: 'var(--bg-primary)',
    color: 'var(--text-secondary)',
    cursor: 'pointer',
  },
  hint: {
    margin: '8px 0 0',
    fontSize: 11.5,
    lineHeight: 1.45,
    color: 'var(--text-muted)',
  },
}
