import { useCallback, useEffect, useMemo, useState, type CSSProperties } from 'react'
import Editor, { type OnMount } from '@monaco-editor/react'
import { useAppStore } from '../../stores/appStore'
import { monacoThemeFor } from '../editor/monacoThemes'

interface Props {
  csd: string
  onChange: (value: string) => void
  onApply: () => void
  onSaveToMenu: (title: string, opts?: { updateExisting?: boolean }) => Promise<void>
  onRevert: () => void
  onHide: () => void
  onDeleteDemo?: () => Promise<void>
  applyBusy?: boolean
  canRevert?: boolean
  currentDemoTitle?: string
  currentDemoId?: string
  fillHeight?: boolean
}

export default function PlayerCsdPanel({
  csd,
  onChange,
  onApply,
  onSaveToMenu,
  onRevert,
  onHide,
  onDeleteDemo,
  applyBusy,
  canRevert,
  currentDemoTitle,
  currentDemoId,
  fillHeight = false,
}: Props) {
  const theme = useAppStore((s) => s.theme)
  const [saveTitle, setSaveTitle] = useState(currentDemoTitle ?? '')
  const [saving, setSaving] = useState(false)
  const [saveHint, setSaveHint] = useState<string | null>(null)

  const isUserDemo = Boolean(currentDemoId?.startsWith('user_'))
  const titleUnchanged = saveTitle.trim() === (currentDemoTitle?.trim() ?? '')
  const saveUpdatesExisting = isUserDemo && titleUnchanged

  const saveButtonLabel = useMemo(() => {
    if (saving) return 'Saving…'
    if (saveUpdatesExisting) return 'Update saved demo'
    if (isUserDemo && !titleUnchanged) return 'Save under new name'
    return 'Save to demo menu'
  }, [isUserDemo, saveUpdatesExisting, saving, titleUnchanged])

  useEffect(() => {
    setSaveTitle(currentDemoTitle ?? '')
  }, [currentDemoTitle, currentDemoId])

  const handleMount: OnMount = (_editor, monaco) => {
    monaco.editor.setTheme(monacoThemeFor(theme))
  }

  const handleSave = useCallback(async () => {
    const title = saveTitle.trim()
    if (!title) {
      setSaveHint('Enter a menu name first')
      return
    }
    setSaving(true)
    setSaveHint(null)
    try {
      await onSaveToMenu(title, { updateExisting: saveUpdatesExisting })
      setSaveHint(saveUpdatesExisting ? 'Demo updated' : 'Saved to demo menu')
      setTimeout(() => setSaveHint(null), 2500)
    } catch (err: any) {
      setSaveHint(err?.message ?? 'Save failed')
    } finally {
      setSaving(false)
    }
  }, [onSaveToMenu, saveTitle, saveUpdatesExisting])

  return (
    <div style={{ ...styles.shell, ...(fillHeight ? styles.shellFill : {}) }}>
      <div style={styles.toolbar}>
        <span style={styles.title}>Csound source</span>
        <label style={styles.nameLabel}>
          Menu name
          <input
            type="text"
            value={saveTitle}
            onChange={(e) => setSaveTitle(e.target.value)}
            placeholder="Name when saving to demo menu"
            style={styles.nameInput}
          />
        </label>
        <div style={{ flex: 1 }} />
        <button
          type="button"
          style={styles.btn}
          onClick={onRevert}
          disabled={!canRevert || applyBusy}
          title="Restore the last version that played successfully"
        >
          Revert
        </button>
        <button type="button" style={styles.btn} onClick={onApply} disabled={applyBusy || !csd.trim()}>
          {applyBusy ? 'Applying…' : 'Apply & play'}
        </button>
        <button
          type="button"
          style={styles.btnPrimary}
          onClick={() => void handleSave()}
          disabled={saving || !csd.trim()}
          title={saveUpdatesExisting ? 'Overwrite your saved copy' : 'Add to My Demos in the menu'}
        >
          {saveButtonLabel}
        </button>
        {isUserDemo && onDeleteDemo && (
          <button
            type="button"
            style={styles.btnDanger}
            onClick={() => void onDeleteDemo()}
            disabled={saving}
            title="Remove this demo from your menu"
          >
            Delete
          </button>
        )}
        <button type="button" style={styles.btn} onClick={onHide} title="Hide the Csound editor">
          Hide
        </button>
        {saveHint && <span style={styles.saveHint}>{saveHint}</span>}
      </div>
      <div style={{ ...styles.editorWrap, ...(fillHeight ? styles.editorWrapFill : {}) }}>
        <Editor
          height={fillHeight ? '100%' : 'min(52vh, 520px)'}
          language="plaintext"
          value={csd}
          onChange={(v) => onChange(v ?? '')}
          onMount={handleMount}
          theme={monacoThemeFor(theme)}
          options={{
            fontFamily: 'var(--font-mono), SF Mono, Menlo, monospace',
            fontSize: 10,
            lineHeight: 1.45,
            tabSize: 2,
            minimap: { enabled: false },
            scrollBeyondLastLine: false,
            wordWrap: 'on',
            automaticLayout: true,
            padding: { top: 6, bottom: 6 },
          }}
        />
      </div>
    </div>
  )
}

const styles: Record<string, CSSProperties> = {
  shell: {
    width: '100%',
    borderRadius: 16,
    border: 'var(--border-width) solid var(--border)',
    background: 'var(--bg-secondary)',
    overflow: 'hidden',
  },
  shellFill: {
    flex: 1,
    minHeight: 0,
    display: 'flex',
    flexDirection: 'column',
    borderRadius: 12,
  },
  toolbar: {
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    padding: '8px 10px',
    borderBottom: '1px solid var(--border-subtle)',
    flexWrap: 'wrap',
  },
  title: { fontSize: 12, fontWeight: 600, color: 'var(--text-primary)', whiteSpace: 'nowrap' },
  nameLabel: {
    display: 'flex',
    alignItems: 'center',
    gap: 6,
    fontSize: 10,
    color: 'var(--text-muted)',
    whiteSpace: 'nowrap',
  },
  nameInput: {
    width: 'min(200px, 32vw)',
    padding: '4px 8px',
    borderRadius: 6,
    border: '1px solid var(--border)',
    background: 'var(--bg-primary)',
    color: 'var(--text-primary)',
    fontSize: 10,
    fontFamily: 'var(--font-primary)',
  },
  btn: {
    padding: '5px 10px',
    borderRadius: 7,
    border: '1px solid var(--border)',
    background: 'var(--bg-primary)',
    color: 'var(--text-secondary)',
    fontSize: 10,
    fontWeight: 600,
    cursor: 'pointer',
    fontFamily: 'var(--font-primary)',
    whiteSpace: 'nowrap',
  },
  btnPrimary: {
    padding: '5px 10px',
    borderRadius: 7,
    border: '1.5px solid var(--accent)',
    background: 'var(--accent-muted)',
    color: 'var(--accent)',
    fontSize: 10,
    fontWeight: 600,
    cursor: 'pointer',
    fontFamily: 'var(--font-primary)',
    whiteSpace: 'nowrap',
  },
  btnDanger: {
    padding: '5px 10px',
    borderRadius: 7,
    border: '1px solid #c44',
    background: 'transparent',
    color: '#e66',
    fontSize: 10,
    fontWeight: 600,
    cursor: 'pointer',
    fontFamily: 'var(--font-primary)',
    whiteSpace: 'nowrap',
  },
  saveHint: { fontSize: 10, color: 'var(--accent)' },
  editorWrap: {
    padding: '6px 8px 8px',
  },
  editorWrapFill: {
    flex: 1,
    minHeight: 0,
    display: 'flex',
    flexDirection: 'column',
    padding: '4px 6px 6px',
  },
}
