import { type CSSProperties } from 'react'

/** Readable code view — default in Dr.C Standalone (Monaco is opt-in). */
export default function PlainCodeView({
  content,
  filename,
}: {
  content: string
  filename: string
}) {
  return (
    <div style={styles.wrap}>
      <div style={styles.banner}>
        <span style={styles.name}>{filename}</span>
        <span style={styles.note}>plain view</span>
      </div>
      <pre style={styles.pre}>{content}</pre>
    </div>
  )
}

const styles: Record<string, CSSProperties> = {
  wrap: { flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0, overflow: 'hidden' },
  banner: {
    display: 'flex',
    alignItems: 'center',
    gap: 10,
    padding: '6px 14px',
    borderBottom: '1px solid var(--border-subtle)',
    background: 'var(--bg-secondary)',
    fontSize: 11,
  },
  name: { fontFamily: 'var(--font-mono)', color: 'var(--text-secondary)' },
  note: { color: 'var(--text-muted)', fontStyle: 'italic' },
  pre: {
    flex: 1,
    margin: 0,
    padding: 12,
    overflow: 'auto',
    fontSize: 12,
    lineHeight: 1.5,
    fontFamily: 'var(--font-mono), SF Mono, monospace',
    color: 'var(--text-primary)',
    background: 'var(--bg-primary)',
    whiteSpace: 'pre-wrap',
    wordBreak: 'break-word',
  },
}
