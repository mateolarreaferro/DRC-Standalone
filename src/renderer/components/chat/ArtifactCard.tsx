import type { CSSProperties } from 'react'
import { primaryContent, type Artifact } from '../../stores/artifactStore'
import StudyFlowButton from '../study/StudyFlowButton'

const TYPE_ICONS = { csd: '♪', webapp: '◫', vst: '⬡' }
const TYPE_LABELS = { csd: 'Csound Instrument', webapp: 'Web App', vst: 'Cabbage Plugin' }

interface Props {
  artifact: Artifact
  isPlaying: boolean
  onClick: () => void
  onPlay: () => void
  onStop: () => void
  onOpenInBrowser?: () => void
}

export default function ArtifactCard({ artifact, isPlaying, onClick, onPlay, onStop, onOpenInBrowser }: Props) {
  const content = primaryContent(artifact)
  const lines = content.split('\n')
  const instrCount = (content.match(/\binstr\b/g) || []).length
  const preview = artifact.type === 'webapp'
    ? '<!DOCTYPE html> … interactive web app preview'
    : lines.slice(0, 3).join('\n')
  const fileCount = artifact.files.length
  const canPlay = artifact.type !== 'webapp'

  return (
    <div style={styles.card}>
      <button onClick={onClick} style={styles.cardBody}>
        <div style={styles.cardHeader}>
          <span style={styles.icon}>{TYPE_ICONS[artifact.type]}</span>
          <div style={styles.cardInfo}>
            <span style={styles.cardTitle}>{artifact.title}</span>
            <span style={styles.cardMeta}>
              {TYPE_LABELS[artifact.type]} · v{artifact.version} · {fileCount} file{fileCount === 1 ? '' : 's'} · {instrCount} instr
            </span>
          </div>
        </div>
        <pre style={styles.preview}>{preview}</pre>
      </button>
      <div style={styles.cardActions}>
        {canPlay && (
          <button
            onClick={(e) => { e.stopPropagation(); isPlaying ? onStop() : onPlay() }}
            style={{ ...styles.actionBtn, ...(isPlaying ? styles.stopBtn : styles.playBtn) }}
          >
            {isPlaying ? '■ Stop' : '▶ Play'}
          </button>
        )}
        {onOpenInBrowser && (
          <button
            onClick={(e) => { e.stopPropagation(); onOpenInBrowser() }}
            style={{ ...styles.actionBtn, ...styles.browserBtn }}
            title="Save HTML and open in Chrome or your chosen browser"
          >
            Open in Browser
          </button>
        )}
        <div onClick={(e) => e.stopPropagation()}>
          <StudyFlowButton
            studyInput={{ title: artifact.title, source: content }}
            variant="compact"
            label="Study flow"
          />
        </div>
        <button onClick={onClick} style={styles.actionBtn}>
          Open →
        </button>
      </div>
    </div>
  )
}

const styles: Record<string, CSSProperties> = {
  card: {
    borderRadius: 12, border: '1.5px solid var(--border)', background: 'var(--bg-secondary)',
    overflow: 'hidden', margin: '6px 0',
  },
  cardBody: {
    display: 'block', width: '100%', border: 'none', background: 'transparent',
    textAlign: 'left', cursor: 'pointer', padding: 0,
  },
  cardHeader: {
    display: 'flex', alignItems: 'center', gap: 10, padding: '12px 16px 8px',
  },
  icon: { fontSize: 18, color: 'var(--accent)' },
  cardInfo: { display: 'flex', flexDirection: 'column' },
  cardTitle: { fontSize: 13, fontWeight: 600, color: 'var(--text-primary)' },
  cardMeta: { fontSize: 11, color: 'var(--text-muted)', marginTop: 1 },
  preview: {
    margin: 0, padding: '4px 16px 10px', fontSize: 11, fontFamily: 'var(--font-mono)',
    lineHeight: 1.4, color: 'var(--text-muted)', whiteSpace: 'pre', overflow: 'hidden',
    maxHeight: 48,
  },
  cardActions: {
    display: 'flex', gap: 6, padding: '8px 12px', alignItems: 'center', flexWrap: 'wrap',
    borderTop: '1px solid var(--border-subtle)', background: 'var(--bg-tertiary)',
  },
  actionBtn: {
    padding: '4px 12px', borderRadius: 6, border: '1px solid var(--border)',
    background: 'transparent', color: 'var(--text-secondary)', fontSize: 11,
    fontWeight: 500, fontFamily: 'var(--font-primary)', cursor: 'pointer',
  },
  playBtn: { borderColor: 'var(--accent)', color: 'var(--accent)' },
  browserBtn: {
    borderColor: 'var(--accent)',
    background: 'var(--accent-muted)',
    color: 'var(--accent)',
    fontWeight: 600,
  },
  stopBtn: { background: 'var(--accent)', borderColor: 'var(--accent)', color: 'var(--bg-primary)' },
}
