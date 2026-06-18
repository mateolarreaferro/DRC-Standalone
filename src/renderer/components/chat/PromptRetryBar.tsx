import type { CSSProperties } from 'react'

/** One-click retry after a failed or empty generation — no retyping. */
export default function PromptRetryBar({
  prompt,
  disabled,
  onTryAgain,
  onEdit,
  onVariant,
}: {
  prompt: string
  disabled?: boolean
  onTryAgain: () => void
  onEdit: () => void
  onVariant: () => void
}) {
  const short = prompt.length > 72 ? `${prompt.slice(0, 69)}…` : prompt

  return (
    <div style={styles.bar}>
      <p style={styles.label}>
        Last prompt: <span style={styles.prompt}>{short}</span>
      </p>
      <div style={styles.actions}>
        <button type="button" style={styles.primary} disabled={disabled} onClick={onTryAgain}>
          Try again
        </button>
        <button type="button" style={styles.secondary} disabled={disabled} onClick={onEdit}>
          Edit
        </button>
        <button type="button" style={styles.secondary} disabled={disabled} onClick={onVariant} title="Same idea, different musical choices and Csound seed">
          Try variation
        </button>
      </div>
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
  label: {
    margin: '0 0 8px',
    fontSize: 11.5,
    lineHeight: 1.45,
    color: 'var(--text-muted)',
  },
  prompt: {
    color: 'var(--text-primary)',
    fontStyle: 'italic',
  },
  actions: {
    display: 'flex',
    flexWrap: 'wrap',
    gap: 8,
  },
  primary: {
    fontSize: 12,
    fontWeight: 600,
    padding: '6px 12px',
    borderRadius: 8,
    border: '1px solid var(--accent)',
    background: 'var(--accent-muted)',
    color: 'var(--accent)',
    cursor: 'pointer',
  },
  secondary: {
    fontSize: 12,
    fontWeight: 500,
    padding: '6px 12px',
    borderRadius: 8,
    border: '1px solid var(--border)',
    background: 'var(--bg-primary)',
    color: 'var(--text-secondary)',
    cursor: 'pointer',
  },
}
