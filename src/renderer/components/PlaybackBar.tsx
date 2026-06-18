import { type CSSProperties } from 'react'
import { usePlaybackStore } from '../stores/playbackStore'
import { useArtifactStore } from '../stores/artifactStore'
import { useCsoundConsoleStore, isConsoleVisible } from '../stores/csoundConsoleStore'
import { CSOUND_CONSOLE_HEIGHT } from './CsoundConsole'
import { stopPlayback } from '../lib/playback'

// Floating pill shown whenever audio is playing or in error state. Visible
// from every route so the user always has a way to stop what's playing.
export default function PlaybackBar() {
  const artifactId = usePlaybackStore((s) => s.artifactId)
  const status = usePlaybackStore((s) => s.status)
  const message = usePlaybackStore((s) => s.message)
  const setActive = useArtifactStore((s) => s.setActive)
  const artifact = useArtifactStore((s) => s.artifacts.find((a) => a.id === artifactId))
  const consoleVisible = useCsoundConsoleStore((s) =>
    isConsoleVisible({ userPinned: s.userPinned, errorReveal: s.errorReveal, editorHidesConsole: s.editorHidesConsole }),
  )
  const consoleExpanded = useCsoundConsoleStore((s) => s.expanded)
  const setConsoleExpanded = useCsoundConsoleStore((s) => s.setExpanded)

  if (!artifactId || status === 'idle') return null

  const isError = status === 'error'
  const consoleOffset = consoleVisible && consoleExpanded ? CSOUND_CONSOLE_HEIGHT + 14 : 14

  return (
    <div style={{ ...styles.bar, ...(isError ? styles.barError : {}), bottom: consoleOffset }}>
      <button
        onClick={() => artifact && setActive(artifact.id)}
        style={styles.titleBtn}
        title="Open artifact"
      >
        <span style={styles.dot}>
          {status === 'playing' ? (
            <span style={styles.pulse} />
          ) : status === 'compiling' ? (
            <span style={styles.spinner} />
          ) : (
            <span style={styles.errDot} />
          )}
        </span>
        <span style={styles.title}>{artifact?.title ?? 'Csound'}</span>
        <span style={styles.status}>{message || status}</span>
      </button>
      {isError && consoleVisible && !consoleExpanded && (
        <button
          type="button"
          onClick={() => setConsoleExpanded(true)}
          style={styles.consoleBtn}
          title="Show Csound output"
        >
          Console
        </button>
      )}
      <button onClick={() => void stopPlayback()} style={styles.stopBtn}>■ Stop</button>
    </div>
  )
}

const styles: Record<string, CSSProperties> = {
  bar: {
    position: 'fixed',
    left: '50%',
    transform: 'translateX(-50%)',
    display: 'flex',
    alignItems: 'center',
    gap: 4,
    padding: '6px 6px 6px 12px',
    borderRadius: 999,
    background: 'var(--bg-secondary)',
    border: '1.5px solid var(--accent)',
    boxShadow: '0 6px 22px rgba(0,0,0,0.35)',
    zIndex: 100,
    minWidth: 260,
    maxWidth: 520,
  },
  barError: { border: '1.5px solid var(--warning, #f0b27a)' },
  titleBtn: {
    flex: 1,
    minWidth: 0,
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    border: 'none',
    background: 'transparent',
    color: 'var(--text-primary)',
    fontFamily: 'var(--font-primary)',
    fontSize: 12,
    cursor: 'pointer',
    padding: '4px 6px',
    textAlign: 'left',
    overflow: 'hidden',
  },
  dot: { width: 12, height: 12, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 },
  pulse: {
    width: 8, height: 8, borderRadius: '50%', background: 'var(--accent)',
    boxShadow: '0 0 0 0 var(--accent)',
    animation: 'drc-pulse 1.4s ease-out infinite',
  },
  spinner: {
    width: 10, height: 10, borderRadius: '50%',
    border: '2px solid var(--bg-tertiary)', borderTopColor: 'var(--accent)',
    animation: 'drc-spin 0.8s linear infinite',
  },
  errDot: {
    width: 8, height: 8, borderRadius: '50%', background: 'var(--warning, #f0b27a)',
  },
  title: {
    fontWeight: 600,
    maxWidth: 180,
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    whiteSpace: 'nowrap',
  },
  status: {
    fontSize: 11,
    color: 'var(--text-muted)',
    fontFamily: 'var(--font-mono)',
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    whiteSpace: 'nowrap',
    flex: 1,
    minWidth: 0,
  },
  stopBtn: {
    padding: '6px 14px',
    borderRadius: 999,
    border: 'none',
    background: 'var(--accent)',
    color: 'var(--bg-primary)',
    fontSize: 11,
    fontWeight: 700,
    fontFamily: 'var(--font-primary)',
    cursor: 'pointer',
    flexShrink: 0,
  },
  consoleBtn: {
    padding: '6px 12px',
    borderRadius: 999,
    border: '1px solid var(--border)',
    background: 'var(--bg-primary)',
    color: 'var(--text-secondary)',
    fontSize: 11,
    fontFamily: 'var(--font-primary)',
    cursor: 'pointer',
    flexShrink: 0,
  },
}
