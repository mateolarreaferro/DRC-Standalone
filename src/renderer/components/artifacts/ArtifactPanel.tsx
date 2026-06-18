import { useEffect, useRef, useState, useCallback, type CSSProperties } from 'react'
import { useArtifactStore, primaryContent, type Artifact, type ArtifactType } from '../../stores/artifactStore'
import { usePlaybackStore } from '../../stores/playbackStore'
import { playArtifact, stopPlayback } from '../../lib/playback'
import FileTabs from './FileTabs'
import FileEditor from './FileEditor'
import ConvertMenu from './ConvertMenu'
import WebAppPreview from './WebAppArtifact'
import StudyFlowButton from '../study/StudyFlowButton'
import type { SignalFlowStudyInput } from '../../lib/signalFlowStudy'

const TYPE_LABELS: Record<ArtifactType, string> = { csd: 'Csound', webapp: 'Web App', vst: 'Cabbage Plugin' }
const TYPE_ICONS: Record<ArtifactType, string> = { csd: '♪', webapp: '◫', vst: '⬡' }

interface Props {
  onConvert?: (targetType: 'webapp' | 'vst' | 'csd') => void
}

// Web app artifacts show a synthetic Preview tab at index 0.
// Other artifact types show their file tabs directly.
function panelTabs(a: Artifact): { name: string; kind: 'preview' | 'file'; fileIndex?: number; derived?: boolean }[] {
  const fileTabs = a.files.map((f, i) => ({ name: f.name, kind: 'file' as const, fileIndex: i, derived: f.derived }))
  if (a.type === 'webapp') {
    return [{ name: 'Preview', kind: 'preview' as const }, ...fileTabs]
  }
  return fileTabs
}

export default function ArtifactPanel({ onConvert }: Props) {
  const { activeArtifactId, artifacts, closePanel, setActive, setActiveFile, getVersions, updatePrimary } = useArtifactStore()
  const active = artifacts.find((a) => a.id === activeArtifactId)
  const [tabIndex, setTabIndex] = useState(0)
  const [menuOpen, setMenuOpen] = useState(false)
  const menuRef = useRef<HTMLDivElement>(null)

  const playbackArtifactId = usePlaybackStore((s) => s.artifactId)
  const playbackStatus = usePlaybackStore((s) => s.status)
  const playbackMessage = usePlaybackStore((s) => s.message)
  const isPlayingThis = active ? playbackArtifactId === active.id : false
  const playing = isPlayingThis && (playbackStatus === 'playing' || playbackStatus === 'compiling')
  const status = isPlayingThis ? playbackMessage : ''

  useEffect(() => {
    if (!active) return
    // When switching artifact, reset to first tab
    setTabIndex(0)
  }, [active?.id])

  useEffect(() => {
    if (!menuOpen) return
    const handler = (e: MouseEvent) => {
      if (!menuRef.current?.contains(e.target as Node)) setMenuOpen(false)
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [menuOpen])

  const handlePlay = useCallback(() => {
    if (!active) return
    void playArtifact(active)
  }, [active])

  const handleStop = useCallback(() => {
    void stopPlayback()
  }, [])

  // Cabbage launch state — local to the panel because the message is short-
  // lived and we don't need it visible elsewhere.
  const [cabbageStatus, setCabbageStatus] = useState<string>('')
  // When a launch fails we keep the saved path around so the user can reveal it
  // in Finder/Explorer and open it manually.
  const [cabbageSavedPath, setCabbageSavedPath] = useState<string>('')
  const [csoundQtStatus, setCsoundQtStatus] = useState<string>('')
  const [csoundQtSavedPath, setCsoundQtSavedPath] = useState<string>('')
  const [browserStatus, setBrowserStatus] = useState<string>('')
  const [browserSavedPath, setBrowserSavedPath] = useState<string>('')
  const handleOpenInCabbage = useCallback(async () => {
    if (!active || active.type !== 'vst') return
    setCabbageStatus('Saving and launching Cabbage…')
    setCabbageSavedPath('')
    const res = await window.api?.export?.openInCabbage?.(primaryContent(active), active.title)
    if (res?.success) {
      setCabbageStatus(`Opened ${res.path?.split('/').pop() ?? 'CSD'} in Cabbage`)
      setTimeout(() => setCabbageStatus(''), 6000)
    } else {
      setCabbageStatus(res?.error ? `Cabbage: ${String(res.error).slice(0, 200)}` : 'Cabbage launch failed')
      if (res?.path) setCabbageSavedPath(res.path)
    }
  }, [active])

  const handleRevealCabbageFile = useCallback(() => {
    if (cabbageSavedPath) void window.api?.export?.revealFile?.(cabbageSavedPath)
  }, [cabbageSavedPath])

  const handleOpenInCsoundQt = useCallback(async () => {
    if (!active || active.type === 'webapp') return
    setCsoundQtStatus('Saving and launching CsoundQt…')
    setCsoundQtSavedPath('')
    const res = await window.api?.export?.openInCsoundQt?.(primaryContent(active), active.title)
    if (res?.success) {
      setCsoundQtStatus(`Opened ${res.path?.split('/').pop() ?? 'CSD'} in CsoundQt`)
      setTimeout(() => setCsoundQtStatus(''), 6000)
    } else {
      setCsoundQtStatus(res?.error ? `CsoundQt: ${String(res.error).slice(0, 200)}` : 'CsoundQt launch failed')
      if (res?.path) setCsoundQtSavedPath(res.path)
    }
  }, [active])

  const handleRevealCsoundQtFile = useCallback(() => {
    if (csoundQtSavedPath) void window.api?.export?.revealFile?.(csoundQtSavedPath)
  }, [csoundQtSavedPath])

  const handleOpenInBrowser = useCallback(async () => {
    if (!active || active.type !== 'webapp') return
    setBrowserStatus('Saving and opening in browser…')
    setBrowserSavedPath('')
    const res = await window.api?.export?.openInBrowser?.(primaryContent(active), active.title)
    if (res?.success) {
      setBrowserStatus(`Opened ${res.path?.split('/').pop() ?? 'index.html'} in browser`)
      setTimeout(() => setBrowserStatus(''), 6000)
    } else {
      setBrowserStatus(res?.error ? `Browser: ${String(res.error).slice(0, 200)}` : 'Browser launch failed')
      if (res?.path) setBrowserSavedPath(res.path)
    }
  }, [active])

  const handleRevealBrowserFile = useCallback(() => {
    if (browserSavedPath) void window.api?.export?.revealFile?.(browserSavedPath)
  }, [browserSavedPath])

  const handleSave = useCallback(() => {
    if (!active) return
    const tabs = panelTabs(active)
    const tab = tabs[tabIndex]
    let fileName: string
    let content: string
    if (tab.kind === 'preview') {
      fileName = 'index.html'
      content = primaryContent(active)
    } else {
      const file = active.files[tab.fileIndex!]
      fileName = file.name
      content = file.content
    }
    const blob = new Blob([content], { type: 'text/plain' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `${active.title.replace(/\s+/g, '_')}_v${active.version}_${fileName}`
    a.click()
    URL.revokeObjectURL(url)
  }, [active, tabIndex])

  if (!active) return null

  const tabs = panelTabs(active)
  const activeTab = tabs[tabIndex] ?? tabs[0]
  const versions = getVersions(active.id)
  const canPlay = active.type !== 'webapp'
  const studyInput: SignalFlowStudyInput = {
    title: active.title,
    source: primaryContent(active),
  }

  return (
    <div style={styles.panel}>
      {/* Header */}
      <div style={styles.header}>
        <div style={styles.headerLeft}>
          <span style={styles.typeIcon}>{TYPE_ICONS[active.type]}</span>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
            <span style={styles.title}>{active.title}</span>
            <div style={styles.meta}>
              <span style={styles.typeBadge}>{TYPE_LABELS[active.type]}</span>
              <span style={styles.versionChip}>v{active.version}</span>
            </div>
          </div>
        </div>
        <div style={styles.headerRight}>
          {versions.length > 1 && (
            <div ref={menuRef} style={styles.historyWrap}>
              <button onClick={() => setMenuOpen((v) => !v)} style={styles.iconBtn} title="Version history">⋯</button>
              {menuOpen && (
                <div style={styles.historyMenu}>
                  <div style={styles.historyLabel}>History</div>
                  {versions.slice().reverse().map((v) => (
                    <button
                      key={v.id}
                      onClick={() => { setActive(v.id); setMenuOpen(false) }}
                      style={{
                        ...styles.historyItem,
                        ...(v.id === active.id ? styles.historyItemActive : {}),
                      }}
                    >
                      <span style={styles.historyVer}>v{v.version}</span>
                      <span style={styles.historyTime}>
                        {new Date(v.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </span>
                    </button>
                  ))}
                </div>
              )}
            </div>
          )}
          <button onClick={closePanel} style={styles.iconBtn} title="Close">×</button>
        </div>
      </div>

      {/* File tabs */}
      <FileTabs
        files={tabs.map((t) => ({
          name: t.name,
          language: t.kind === 'preview' ? 'html' : active.files[t.fileIndex!].language,
          content: '',
          derived: t.derived,
        }))}
        activeIndex={tabIndex}
        onSelect={(i) => {
          setTabIndex(i)
          const t = tabs[i]
          if (t.kind === 'file') setActiveFile(active.id, t.fileIndex!)
        }}
      />

      {/* Content */}
      <div style={styles.content}>
        {activeTab.kind === 'preview' ? (
          <WebAppPreview artifact={active} />
        ) : (
          (() => {
            const file = active.files[activeTab.fileIndex!]
            const isPrimary = !file.derived
            return (
              <FileEditor
                file={file}
                editable={isPrimary}
                onChange={isPrimary ? (next) => updatePrimary(active.id, next) : undefined}
              />
            )
          })()
        )}
      </div>

      {/* Actions */}
      <div style={styles.footer}>
        {active.type === 'webapp' && (
          <button
            onClick={handleOpenInBrowser}
            style={styles.primary}
            title="Save HTML and open in Chrome or your chosen browser (Settings → Web Browser)"
          >
            Open in Browser
          </button>
        )}
        {canPlay && (
          <button
            onClick={playing ? handleStop : handlePlay}
            style={{ ...styles.primary, ...(playing ? styles.primaryActive : {}) }}
          >
            {playing ? '■ Stop' : '▶ Play'}
          </button>
        )}
        <button onClick={handleSave} style={styles.secondary}>↓ Save</button>
        <StudyFlowButton studyInput={studyInput} variant="compact" label="Study flow" />
        {active.type !== 'webapp' && (
          <button onClick={handleOpenInCsoundQt} style={styles.secondary}>
            ⌨ Open in CsoundQt
          </button>
        )}
        {active.type === 'vst' && (
          <button onClick={handleOpenInCabbage} style={styles.secondary}>
            ⬡ Open in Cabbage
          </button>
        )}
        {browserSavedPath && (
          <button onClick={handleRevealBrowserFile} style={styles.secondary}>
            Reveal HTML
          </button>
        )}
        {csoundQtSavedPath && (
          <button onClick={handleRevealCsoundQtFile} style={styles.secondary}>
            Reveal CSD
          </button>
        )}
        {cabbageSavedPath && (
          <button onClick={handleRevealCabbageFile} style={styles.secondary}>
            Reveal file
          </button>
        )}
        {onConvert && <ConvertMenu currentType={active.type} onConvert={onConvert} />}
        {(status || cabbageStatus || csoundQtStatus || browserStatus) && (
          <span style={styles.status}>{browserStatus || csoundQtStatus || cabbageStatus || status}</span>
        )}
      </div>
    </div>
  )
}

const styles: Record<string, CSSProperties> = {
  panel: {
    width: 560, height: '100%', display: 'flex', flexDirection: 'column',
    borderLeft: '1.5px solid var(--border)', background: 'var(--bg-secondary)', flexShrink: 0,
  },
  header: {
    display: 'flex', justifyContent: 'space-between', alignItems: 'center',
    padding: '12px 16px', borderBottom: '1px solid var(--border-subtle)', flexShrink: 0,
  },
  headerLeft: { display: 'flex', alignItems: 'center', gap: 10, minWidth: 0 },
  headerRight: { display: 'flex', alignItems: 'center', gap: 4 },
  typeIcon: { fontSize: 20, color: 'var(--accent)', flexShrink: 0 },
  title: { fontSize: 14, fontWeight: 600, color: 'var(--text-primary)',
    overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' },
  meta: { display: 'flex', alignItems: 'center', gap: 6 },
  typeBadge: {
    fontSize: 10, fontWeight: 500, color: 'var(--text-muted)',
    background: 'var(--bg-tertiary)', padding: '1px 7px', borderRadius: 4,
    letterSpacing: '0.04em',
  },
  versionChip: {
    fontSize: 10, fontWeight: 600, color: 'var(--accent)',
    fontFamily: 'var(--font-mono)',
  },
  iconBtn: {
    width: 28, height: 28, borderRadius: 7, border: '1px solid var(--border)',
    background: 'transparent', color: 'var(--text-muted)', fontSize: 14,
    display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
  },
  historyWrap: { position: 'relative' },
  historyMenu: {
    position: 'absolute', top: 'calc(100% + 6px)', right: 0,
    minWidth: 180, padding: 4, background: 'var(--bg-secondary)',
    border: '1px solid var(--border)', borderRadius: 10,
    boxShadow: '0 8px 20px rgba(0,0,0,0.3)', zIndex: 10,
  },
  historyLabel: {
    fontSize: 10, color: 'var(--text-muted)', textTransform: 'uppercase',
    letterSpacing: '0.06em', padding: '6px 10px 2px',
  },
  historyItem: {
    width: '100%', display: 'flex', justifyContent: 'space-between', alignItems: 'center',
    padding: '6px 10px', border: 'none', background: 'transparent',
    color: 'var(--text-primary)', fontSize: 12, cursor: 'pointer', borderRadius: 6,
  },
  historyItemActive: { background: 'var(--accent-muted)', color: 'var(--accent)' },
  historyVer: { fontFamily: 'var(--font-mono)', fontWeight: 600 },
  historyTime: { fontSize: 10, color: 'var(--text-muted)' },

  content: { flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column' },

  footer: {
    display: 'flex', gap: 8, alignItems: 'center',
    padding: '10px 16px', borderTop: '1px solid var(--border-subtle)', flexShrink: 0,
  },
  primary: {
    padding: '6px 14px', borderRadius: 8, border: 'none',
    background: 'var(--accent)', color: 'var(--bg-primary)',
    fontSize: 12, fontWeight: 600, fontFamily: 'var(--font-primary)', cursor: 'pointer',
  },
  primaryActive: { background: 'var(--warning, #f0b27a)', color: 'var(--bg-primary)' },
  secondary: {
    padding: '6px 12px', borderRadius: 8, border: '1px solid var(--border)',
    background: 'transparent', color: 'var(--text-secondary)',
    fontSize: 12, fontFamily: 'var(--font-primary)', cursor: 'pointer', fontWeight: 500,
  },
  status: {
    marginLeft: 'auto', fontSize: 11, color: 'var(--text-muted)',
    fontFamily: 'var(--font-mono)',
    maxWidth: 240, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
  },
}
