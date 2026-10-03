import { useState, type CSSProperties } from 'react'
import type { SignalFlowStudyInput } from '../../lib/signalFlowStudy'
import SignalFlowStudyModal from './SignalFlowStudyModal'

interface Props {
  studyInput: SignalFlowStudyInput | null
  disabled?: boolean
  label?: string
  title?: string
  style?: CSSProperties
  /** Match Player/Web Apps toolbar vs Agent artifact footer */
  variant?: 'toolbar' | 'compact'
}

export default function StudyFlowButton({
  studyInput,
  disabled,
  label = 'Study flow',
  title = 'Block diagrams — architecture, signal flow, and controls',
  style,
  variant = 'toolbar',
}: Props) {
  const [open, setOpen] = useState(false)
  const off = disabled || !studyInput?.source?.trim()

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        disabled={off}
        title={off ? 'Load an instrument first' : title}
        style={{ ...(variant === 'toolbar' ? styles.toolbar : styles.compact), ...style }}
      >
        ◫ {label}
      </button>
      <SignalFlowStudyModal
        open={open}
        onClose={() => setOpen(false)}
        studyInput={studyInput}
      />
    </>
  )
}

const styles: Record<string, CSSProperties> = {
  toolbar: {
    padding: '6px 12px',
    borderRadius: 8,
    border: '1px solid var(--border)',
    background: 'transparent',
    color: 'var(--text-secondary)',
    fontSize: 12,
    fontFamily: 'var(--font-primary)',
    fontWeight: 500,
    cursor: 'pointer',
  },
  compact: {
    padding: '4px 10px',
    borderRadius: 6,
    border: '1px solid var(--border)',
    background: 'transparent',
    color: 'var(--text-secondary)',
    fontSize: 11,
    fontWeight: 500,
    fontFamily: 'var(--font-primary)',
    cursor: 'pointer',
  },
}
