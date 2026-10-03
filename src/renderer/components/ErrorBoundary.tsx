import { Component, type ErrorInfo, type ReactNode } from 'react'

interface Props {
  children: ReactNode
  label?: string
  onError?: () => void
}

interface State {
  error: Error | null
}

/** Catches renderer crashes so the user sees an error instead of a blank screen. */
export default class ErrorBoundary extends Component<Props, State> {
  state: State = { error: null }

  static getDerivedStateFromError(error: Error): State {
    return { error }
  }

  componentDidCatch(error: Error, info: ErrorInfo): void {
    console.error('[Dr.C]', this.props.label ?? 'UI error', error, info.componentStack)
    if (this.props.onError) {
      this.props.onError()
      // Parent switches to a fallback (e.g. plain code view); clear error so we retry.
      queueMicrotask(() => this.setState({ error: null }))
    }
  }

  render() {
    if (!this.state.error) return this.props.children

    return (
      <div style={styles.wrap}>
        <h2 style={styles.title}>Dr.C hit a display error</h2>
        <p style={styles.body}>
          {this.props.label ? `${this.props.label}: ` : ''}
          {this.state.error.message || 'Unknown error'}
        </p>
        <p style={styles.hint}>
          Your session may still be running in the background. Quit Dr.C fully, relaunch from the
          Desktop icon, and try again. If it repeats, use History to reopen this chat.
        </p>
        <button type="button" style={styles.btn} onClick={() => this.setState({ error: null })}>
          Try to recover
        </button>
      </div>
    )
  }
}

const styles: Record<string, React.CSSProperties> = {
  wrap: {
    padding: 32,
    maxWidth: 520,
    margin: '40px auto',
    borderRadius: 12,
    border: '1px solid var(--border)',
    background: 'var(--bg-secondary)',
  },
  title: { margin: '0 0 12px', fontSize: 18, color: 'var(--text-primary)' },
  body: {
    margin: '0 0 12px',
    fontSize: 13,
    lineHeight: 1.5,
    fontFamily: 'var(--font-mono)',
    color: 'var(--warning)',
    wordBreak: 'break-word',
  },
  hint: { margin: '0 0 16px', fontSize: 12.5, lineHeight: 1.5, color: 'var(--text-muted)' },
  btn: {
    padding: '8px 14px',
    borderRadius: 8,
    border: '1px solid var(--border)',
    background: 'var(--bg-primary)',
    color: 'var(--text-primary)',
    cursor: 'pointer',
    fontSize: 13,
  },
}
