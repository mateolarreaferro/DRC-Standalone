import { useCallback, useEffect, useMemo, useRef, useState, type CSSProperties } from 'react'
import {
  buildSignalFlowStudy,
  type SignalFlowStudy,
  type SignalFlowStudyInput,
} from '../../lib/signalFlowStudy'

type Tab = 'architecture' | 'signal' | 'controls'

interface Props {
  open: boolean
  onClose: () => void
  studyInput: SignalFlowStudyInput | null
}

async function renderMermaid(el: HTMLElement, code: string): Promise<void> {
  el.removeAttribute('data-processed')
  el.textContent = code
  const mod = await import('https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs')
  const mermaid = mod.default
  mermaid.initialize({
    startOnLoad: false,
    theme: 'dark',
    securityLevel: 'loose',
    flowchart: { curve: 'basis', htmlLabels: true },
  })
  await mermaid.run({ nodes: [el] })
}

function DiagramBlock({ code, label }: { code: string; label: string }) {
  const ref = useRef<HTMLDivElement>(null)
  const [err, setErr] = useState('')

  useEffect(() => {
    const el = ref.current
    if (!el || !code) return
    let cancelled = false
    setErr('')
    renderMermaid(el, code).catch((e: Error) => {
      if (!cancelled) setErr(e.message || 'Diagram render failed')
    })
    return () => { cancelled = true }
  }, [code])

  return (
    <div style={styles.diagramWrap}>
      <div style={styles.diagramLabel}>{label}</div>
      {err ? (
        <pre style={styles.fallback}>{code}</pre>
      ) : (
        <div ref={ref} className="mermaid" style={styles.mermaid} />
      )}
    </div>
  )
}

export default function SignalFlowStudyModal({ open, onClose, studyInput }: Props) {
  const [tab, setTab] = useState<Tab>('architecture')

  const study: SignalFlowStudy | null = useMemo(() => {
    if (!studyInput?.source?.trim()) return null
    try {
      return buildSignalFlowStudy(studyInput)
    } catch {
      return null
    }
  }, [studyInput])

  const copyMermaid = useCallback(() => {
    if (!study) return
    const text =
      tab === 'architecture' ? study.architectureMermaid
      : tab === 'signal' ? study.signalFlowMermaid
      : study.controlsMermaid
    void navigator.clipboard.writeText(text)
  }, [study, tab])

  useEffect(() => {
    if (!open) return
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose() }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [open, onClose])

  if (!open) return null

  return (
    <div style={styles.overlay} onClick={onClose} role="presentation">
      <div
        style={styles.modal}
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-labelledby="study-flow-title"
      >
        <div style={styles.header}>
          <div>
            <h2 id="study-flow-title" style={styles.title}>
              Study — signal flow
            </h2>
            <p style={styles.subtitle}>{study?.title ?? studyInput?.title ?? 'Instrument'}</p>
          </div>
          <button type="button" onClick={onClose} style={styles.closeBtn} title="Close">×</button>
        </div>

        {study && (
          <ul style={styles.summary}>
            {study.summary.map((line) => (
              <li key={line}>{line}</li>
            ))}
          </ul>
        )}

        <div style={styles.tabs}>
          {(['architecture', 'signal', 'controls'] as Tab[]).map((t) => (
            <button
              key={t}
              type="button"
              onClick={() => setTab(t)}
              style={{ ...styles.tab, ...(tab === t ? styles.tabActive : {}) }}
            >
              {t === 'architecture' ? 'Architecture' : t === 'signal' ? 'Signal flow' : 'Controls'}
            </button>
          ))}
          <button type="button" onClick={copyMermaid} style={styles.copyBtn} title="Copy Mermaid source">
            Copy Mermaid
          </button>
        </div>

        <div style={styles.body}>
          {!study ? (
            <p style={styles.empty}>No orchestra found to diagram. Load a CSD or web app with an ORC block.</p>
          ) : tab === 'architecture' ? (
            <DiagramBlock code={study.architectureMermaid} label="Host · WASM · instruments · output" />
          ) : tab === 'signal' ? (
            <DiagramBlock code={study.signalFlowMermaid} label="Voice path inside instr 1 (heuristic)" />
          ) : (
            <DiagramBlock code={study.controlsMermaid} label="chn_k manifest → setControlChannel → chnget" />
          )}
        </div>

        <p style={styles.footerNote}>
          Diagrams are auto-generated for study. Refine the orchestra, then reopen Study flow to refresh.
        </p>
      </div>
    </div>
  )
}

const styles: Record<string, CSSProperties> = {
  overlay: {
    position: 'fixed', inset: 0, zIndex: 9000,
    background: 'rgba(0,0,0,0.62)', display: 'flex', alignItems: 'center', justifyContent: 'center',
    padding: 24,
  },
  modal: {
    width: 'min(920px, 96vw)', maxHeight: '90vh', overflow: 'hidden',
    display: 'flex', flexDirection: 'column',
    background: 'var(--bg-secondary)', border: '1px solid var(--border)',
    borderRadius: 14, boxShadow: '0 24px 48px rgba(0,0,0,0.45)',
  },
  header: {
    display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start',
    padding: '16px 20px 8px', borderBottom: '1px solid var(--border-subtle)',
  },
  title: { margin: 0, fontSize: 18, fontWeight: 600, color: 'var(--text-primary)' },
  subtitle: { margin: '4px 0 0', fontSize: 12, color: 'var(--text-muted)' },
  closeBtn: {
    width: 32, height: 32, borderRadius: 8, border: '1px solid var(--border)',
    background: 'transparent', color: 'var(--text-muted)', fontSize: 20, cursor: 'pointer',
  },
  summary: {
    margin: '10px 20px 0', paddingLeft: 18, fontSize: 12, color: 'var(--text-secondary)', lineHeight: 1.5,
  },
  tabs: {
    display: 'flex', gap: 6, alignItems: 'center', flexWrap: 'wrap',
    padding: '12px 20px 0',
  },
  tab: {
    padding: '6px 12px', borderRadius: 8, border: '1px solid var(--border)',
    background: 'transparent', color: 'var(--text-secondary)', fontSize: 12, cursor: 'pointer',
  },
  tabActive: {
    background: 'var(--accent-muted)', color: 'var(--accent)', borderColor: 'var(--accent)',
    fontWeight: 600,
  },
  copyBtn: {
    marginLeft: 'auto', padding: '6px 10px', borderRadius: 8,
    border: '1px solid var(--border)', background: 'transparent',
    color: 'var(--text-muted)', fontSize: 11, cursor: 'pointer',
  },
  body: {
    flex: 1, minHeight: 0, overflow: 'auto', padding: '12px 20px 16px',
  },
  diagramWrap: {
    background: 'var(--bg-tertiary)', borderRadius: 10, border: '1px solid var(--border-subtle)',
    padding: 12,
  },
  diagramLabel: {
    fontSize: 10, letterSpacing: '0.08em', textTransform: 'uppercase',
    color: 'var(--text-muted)', marginBottom: 10, fontWeight: 600,
  },
  mermaid: { display: 'flex', justifyContent: 'center', overflow: 'auto' },
  fallback: {
    fontSize: 11, fontFamily: 'var(--font-mono)', color: 'var(--text-secondary)',
    whiteSpace: 'pre-wrap', margin: 0,
  },
  empty: { color: 'var(--text-muted)', fontSize: 13 },
  footerNote: {
    margin: 0, padding: '10px 20px 14px', fontSize: 11, color: 'var(--text-muted)',
    borderTop: '1px solid var(--border-subtle)',
  },
}
