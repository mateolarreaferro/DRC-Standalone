import { useEffect, useState, type CSSProperties } from 'react'
import { useSessionStore } from '../../stores/sessionStore'

// Line-art thumb icons (feather style, currentColor) to match the app's minimal
// glyph aesthetic — no emoji.
function ThumbUp({ filled }: { filled: boolean }) {
  return (
    <svg
      width="14"
      height="14"
      viewBox="0 0 24 24"
      fill={filled ? 'currentColor' : 'none'}
      stroke="currentColor"
      strokeWidth={1.8}
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3zM7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3" />
    </svg>
  )
}

function ThumbDown({ filled }: { filled: boolean }) {
  return (
    <svg
      width="14"
      height="14"
      viewBox="0 0 24 24"
      fill={filled ? 'currentColor' : 'none'}
      stroke="currentColor"
      strokeWidth={1.8}
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M10 15v4a3 3 0 0 0 3 3l4-9V2H5.72a2 2 0 0 0-2 1.7l-1.38 9a2 2 0 0 0 2 2.3zm7 0h2.67A2.31 2.31 0 0 0 22 13V4a2.31 2.31 0 0 0-2.33-2H17" />
    </svg>
  )
}

// Quick-pick reasons for a thumbs-down, tuned to this app's failure modes. The
// model uses the chosen reason + free text to distill a durable avoidance rule.
const DOWN_REASONS = [
  'Wrong sound',
  'Errors / would not play',
  'Ignored my request',
  'Too generic',
] as const

// Thumbs on a completed assistant turn. The single manual learning signal the
// user can give per message — it feeds the heuristic profile + technique
// preferences in main/memory. Once given it locks, so we don't double-count.
//
// Thumbs-up sends immediately. Thumbs-down opens an inline composer (reason chips
// + free text, like Claude on the web) so the user can say WHY — that critique is
// distilled into a remembered avoidance rule on the backend.
export default function MessageFeedback({
  messageId,
  content,
}: {
  messageId: string
  content: string
}) {
  const sendFeedback = useSessionStore((s) => s.sendFeedback)
  const [memoryReady, setMemoryReady] = useState<boolean | null>(null)
  const [picked, setPicked] = useState<'up' | 'down' | null>(null)
  const [composing, setComposing] = useState(false)
  const [reason, setReason] = useState<string | null>(null)
  const [text, setText] = useState('')
  const [feedbackNote, setFeedbackNote] = useState<string | null>(null)

  useEffect(() => {
    window.api?.memory?.status?.()
      .then((s: { ready?: boolean }) => setMemoryReady(Boolean(s?.ready)))
      .catch(() => setMemoryReady(false))
  }, [])

  const sendUp = async () => {
    if (picked) return
    setPicked('up')
    const result = await sendFeedback('thumbs_up', { messageId, content })
    if (result?.error === 'memory_disabled') {
      setFeedbackNote('Memory is off — fix in Settings')
      setPicked(null)
    } else {
      setFeedbackNote("noted — I'll remember")
    }
  }

  const openDown = () => {
    if (picked) return
    setComposing(true)
  }

  // Submit with whatever detail was given; Skip records the bare down signal.
  const submitDown = async (withDetail: boolean) => {
    setPicked('down')
    setComposing(false)
    const critique = text.trim()
    const result = await sendFeedback('thumbs_down', {
      messageId,
      content,
      ...(withDetail && reason ? { reason } : {}),
      ...(withDetail && critique ? { critique } : {}),
    })
    if (result?.error === 'memory_disabled') {
      setFeedbackNote('Memory is off — fix in Settings')
      setPicked(null)
    } else {
      setFeedbackNote("noted — I'll remember")
    }
  }

  return (
    <div style={styles.wrap}>
      <div style={styles.row}>
        <button
          title="This was good"
          aria-label="Good response"
          onClick={sendUp}
          style={{ ...styles.btn, ...(picked === 'up' ? styles.activeUp : {}) }}
        >
          <ThumbUp filled={picked === 'up'} />
        </button>
        <button
          title="Not what I wanted"
          aria-label="Bad response"
          onClick={openDown}
          style={{ ...styles.btn, ...(picked === 'down' || composing ? styles.activeDown : {}) }}
        >
          <ThumbDown filled={picked === 'down'} />
        </button>
        {feedbackNote && (
          <span style={{ ...styles.note, ...(feedbackNote.includes('off') ? styles.noteWarn : {}) }}>
            {feedbackNote}
          </span>
        )}
        {memoryReady === false && !feedbackNote && (
          <span style={styles.noteWarn}>Memory off</span>
        )}
      </div>

      {composing && (
        <div style={styles.composer}>
          <div style={styles.composerTitle}>What went wrong?</div>
          <div style={styles.chips}>
            {DOWN_REASONS.map((r) => (
              <button
                key={r}
                onClick={() => setReason((cur) => (cur === r ? null : r))}
                style={{ ...styles.chip, ...(reason === r ? styles.chipActive : {}) }}
              >
                {r}
              </button>
            ))}
          </div>
          <textarea
            autoFocus
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="Optional: tell me what to do differently next time (e.g. brighter tone, longer decay, no clipping)…"
            style={styles.textarea}
            rows={3}
          />
          <div style={styles.actions}>
            <button onClick={() => submitDown(false)} style={styles.skip}>
              Skip
            </button>
            <button
              onClick={() => submitDown(true)}
              disabled={!reason && !text.trim()}
              style={{
                ...styles.submit,
                ...(!reason && !text.trim() ? styles.submitDisabled : {}),
              }}
            >
              Submit
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

const styles: Record<string, CSSProperties> = {
  wrap: { display: 'flex', flexDirection: 'column', gap: 0 },
  row: { display: 'flex', alignItems: 'center', gap: 2, marginTop: 6 },
  composer: {
    marginTop: 8,
    padding: 12,
    maxWidth: 460,
    border: '1px solid var(--border)',
    borderRadius: 10,
    background: 'var(--bg-secondary)',
    display: 'flex',
    flexDirection: 'column',
    gap: 8,
  },
  composerTitle: {
    fontSize: 12,
    fontWeight: 600,
    color: 'var(--text-secondary)',
  },
  chips: { display: 'flex', flexWrap: 'wrap', gap: 6 },
  chip: {
    fontSize: 11,
    padding: '4px 9px',
    borderRadius: 999,
    border: '1px solid var(--border)',
    background: 'transparent',
    color: 'var(--text-secondary)',
    cursor: 'pointer',
    transition: 'background 120ms ease, color 120ms ease, border-color 120ms ease',
  },
  chipActive: {
    background: 'var(--accent-muted)',
    color: 'var(--accent)',
    borderColor: 'var(--accent)',
  },
  textarea: {
    width: '100%',
    boxSizing: 'border-box',
    resize: 'vertical',
    fontSize: 12,
    lineHeight: 1.5,
    padding: 8,
    borderRadius: 8,
    border: '1px solid var(--border)',
    background: 'var(--bg-tertiary)',
    color: 'var(--text-primary)',
    fontFamily: 'inherit',
  },
  actions: { display: 'flex', justifyContent: 'flex-end', gap: 8 },
  skip: {
    fontSize: 12,
    padding: '5px 12px',
    borderRadius: 7,
    border: 'none',
    background: 'transparent',
    color: 'var(--text-muted)',
    cursor: 'pointer',
  },
  submit: {
    fontSize: 12,
    fontWeight: 600,
    padding: '5px 14px',
    borderRadius: 7,
    border: 'none',
    background: 'var(--accent)',
    color: 'var(--bg-primary)',
    cursor: 'pointer',
  },
  submitDisabled: {
    opacity: 0.45,
    cursor: 'not-allowed',
  },
  btn: {
    display: 'inline-flex',
    alignItems: 'center',
    justifyContent: 'center',
    border: 'none',
    background: 'transparent',
    cursor: 'pointer',
    padding: 5,
    borderRadius: 7,
    color: 'var(--text-muted)',
    opacity: 0.7,
    transition: 'color 120ms ease, background 120ms ease, opacity 120ms ease',
  },
  activeUp: { color: 'var(--accent)', opacity: 1, background: 'var(--accent-muted)' },
  activeDown: { color: 'var(--text-secondary)', opacity: 1, background: 'var(--bg-tertiary)' },
  note: {
    fontSize: 11,
    color: 'var(--text-muted)',
    fontStyle: 'italic',
    marginLeft: 4,
  },
  noteWarn: {
    color: '#c45c5c',
    fontStyle: 'normal',
  },
}
