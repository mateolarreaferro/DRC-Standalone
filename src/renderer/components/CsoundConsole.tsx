import { useCallback, useEffect, useRef, useState } from 'react'
import type { CSSProperties } from 'react'
import {
  formatCsoundConsoleLines,
  isConsoleVisible,
  isCsoundErrorLine,
  useCsoundConsoleStore,
} from '../stores/csoundConsoleStore'

const PANEL_HEIGHT = 200

export default function CsoundConsole() {
  const userPinned = useCsoundConsoleStore((s) => s.userPinned)
  const errorReveal = useCsoundConsoleStore((s) => s.errorReveal)
  const editorHidesConsole = useCsoundConsoleStore((s) => s.editorHidesConsole)
  const visible = isConsoleVisible({ userPinned, errorReveal, editorHidesConsole })
  const expanded = useCsoundConsoleStore((s) => s.expanded)
  const lines = useCsoundConsoleStore((s) => s.lines)
  const append = useCsoundConsoleStore((s) => s.append)
  const clear = useCsoundConsoleStore((s) => s.clear)
  const setExpanded = useCsoundConsoleStore((s) => s.setExpanded)
  const dismiss = useCsoundConsoleStore((s) => s.dismiss)
  const scrollRef = useRef<HTMLDivElement>(null)
  const [copyHint, setCopyHint] = useState<string | null>(null)
  const [saveHint, setSaveHint] = useState<string | null>(null)

  const plainText = formatCsoundConsoleLines(lines)

  const copyAll = useCallback(async () => {
    if (!plainText) return
    try {
      await navigator.clipboard.writeText(plainText)
      setCopyHint('Copied!')
      setTimeout(() => setCopyHint(null), 2000)
    } catch {
      setCopyHint('Copy failed — use Save log')
      setTimeout(() => setCopyHint(null), 3000)
    }
  }, [plainText])

  const saveLog = useCallback(async () => {
    if (!plainText || !window.api?.csound?.saveConsoleLog) return
    try {
      const { path } = await window.api.csound.saveConsoleLog(plainText)
      setSaveHint('Saved')
      setTimeout(() => setSaveHint(null), 2500)
      await window.api.export?.revealFile?.(path)
    } catch {
      setSaveHint('Save failed')
      setTimeout(() => setSaveHint(null), 2500)
    }
  }, [plainText])

  useEffect(() => {
    const unsub = window.api?.csound?.onOutput?.((chunk) => {
      append(chunk)
    })
    return () => unsub?.()
  }, [append])

  useEffect(() => {
    const el = scrollRef.current
    if (!el) return
    el.scrollTop = el.scrollHeight
  }, [lines])

  if (!visible) return null

  return (
    <div style={{ ...styles.shell, ...(expanded ? {} : styles.shellCollapsed) }}>
      <div style={styles.header}>
        <span style={styles.title}>Csound output</span>
        <span style={styles.hint}>
          {errorReveal && !userPinned
            ? 'Opened for error — hide with ▼ or sidebar >_'
            : lines.length === 0
              ? 'Compile and play messages appear here'
              : `${lines.length} lines`}
        </span>
        <div style={{ flex: 1 }} />
        <button
          type="button"
          onClick={() => void copyAll()}
          disabled={lines.length === 0}
          style={styles.headerBtn}
          title="Copy all lines to clipboard (paste into chat or email)"
        >
          {copyHint ?? 'Copy all'}
        </button>
        <button
          type="button"
          onClick={() => void saveLog()}
          disabled={lines.length === 0}
          style={styles.headerBtn}
          title="Save log to Desktop and reveal in Finder"
        >
          {saveHint ?? 'Save log'}
        </button>
        <button type="button" onClick={clear} style={styles.headerBtn} title="Clear console">
          Clear
        </button>
        <button
          type="button"
          onClick={() => (expanded ? dismiss() : setExpanded(true))}
          style={styles.headerBtn}
          title={expanded ? 'Hide panel' : 'Expand'}
        >
          {expanded ? '▼' : '▲'}
        </button>
      </div>
      {expanded && (
        <div ref={scrollRef} style={styles.body}>
          {lines.length === 0 ? (
            <div style={styles.placeholder}>
              On errors the panel opens automatically — use{' '}
              <strong>Copy all</strong> or <strong>Save log</strong>, or drag to select text.
            </div>
          ) : (
            lines.map((line, i) => (
              <div
                key={`${line.ts}-${i}`}
                style={{
                  ...styles.line,
                  ...(line.stream === 'info' ? styles.lineInfo : {}),
                  ...(isCsoundErrorLine(line.text) ? styles.lineError : {}),
                }}
              >
                {line.text}
              </div>
            ))
          )}
        </div>
      )}
    </div>
  )
}

export const CSOUND_CONSOLE_HEIGHT = PANEL_HEIGHT

const styles: Record<string, CSSProperties> = {
  shell: {
    flexShrink: 0,
    height: PANEL_HEIGHT,
    display: 'flex',
    flexDirection: 'column',
    borderTop: '1px solid var(--border)',
    background: 'var(--bg-secondary)',
  },
  shellCollapsed: {
    height: 'auto',
  },
  header: {
    display: 'flex',
    alignItems: 'center',
    gap: 10,
    padding: '6px 12px',
    borderBottom: '1px solid var(--border-subtle)',
    flexShrink: 0,
  },
  title: {
    fontSize: 12,
    fontWeight: 600,
    color: 'var(--text-primary)',
  },
  hint: {
    fontSize: 11,
    color: 'var(--text-muted)',
  },
  headerBtn: {
    padding: '3px 10px',
    borderRadius: 6,
    border: '1px solid var(--border)',
    background: 'var(--bg-primary)',
    color: 'var(--text-secondary)',
    fontSize: 11,
    fontFamily: 'var(--font-primary)',
    cursor: 'pointer',
  },
  body: {
    flex: 1,
    overflow: 'auto',
    padding: '8px 12px',
    fontFamily: 'var(--font-mono), SF Mono, Menlo, monospace',
    fontSize: 11,
    lineHeight: 1.45,
    userSelect: 'text',
    WebkitUserSelect: 'text',
    cursor: 'text',
  },
  placeholder: {
    color: 'var(--text-muted)',
    fontStyle: 'italic',
  },
  line: {
    whiteSpace: 'pre-wrap',
    wordBreak: 'break-word',
    color: 'var(--text-secondary)',
  },
  lineInfo: {
    color: 'var(--accent)',
    fontWeight: 500,
  },
  lineError: {
    color: 'var(--warning, #f0b27a)',
    fontWeight: 600,
  },
}
