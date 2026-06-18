import { lazy, Suspense, useCallback, useEffect, useRef, useState, type CSSProperties } from 'react'
import type { OnMount } from '@monaco-editor/react'
import type { ArtifactFile, FileLanguage } from '../../stores/artifactStore'
import { useAppStore } from '../../stores/appStore'
import { preferPlainEditor, setPreferRichEditor, useEditorStore } from '../../stores/editorStore'
import { registerEditorThemes, monacoThemeFor } from '../editor/monacoThemes'
import PlainCodeView from './PlainCodeView'

const MonacoEditor = lazy(async () => {
  await import('../../lib/monacoSetup')
  const mod = await import('@monaco-editor/react')
  return { default: mod.default }
})

const MONACO_LANG: Record<FileLanguage, string> = {
  csd: 'csound',
  cabbage: 'csound',
  html: 'html',
  js: 'javascript',
  css: 'css',
}

function registerCsoundLanguage(monaco: any) {
  if (monaco.languages.getLanguages().some((l: any) => l.id === 'csound')) return
  monaco.languages.register({ id: 'csound', extensions: ['.csd', '.orc', '.sco'] })
  monaco.languages.setMonarchTokensProvider('csound', {
    keywords: [
      'instr', 'endin', 'opcode', 'endop', 'if', 'then', 'else', 'elseif', 'endif',
      'while', 'do', 'od', 'until', 'goto', 'igoto', 'kgoto',
    ],
    tokenizer: {
      root: [
        [/;.*$/, 'comment'],
        [/<[!\/]?[A-Za-z][A-Za-z0-9]*>/, 'tag'],
        [/\b[akig][A-Za-z_][A-Za-z0-9_]*\b/, 'variable'],
        [/\b(instr|endin|opcode|endop|if|then|else|elseif|endif|while|do|od)\b/, 'keyword'],
        [/"([^"\\]|\\.)*"/, 'string'],
        [/\b\d+\.?\d*\b/, 'number'],
      ],
    },
  } as any)
}

interface Props {
  file: ArtifactFile
  onChange?: (content: string) => void
  editable: boolean
}

export default function FileEditor({ file, onChange, editable }: Props) {
  const forcePlain = useEditorStore((s) => s.forcePlain)
  const [usePlain, setUsePlain] = useState(() => preferPlainEditor() || forcePlain)
  const [value, setValue] = useState(file.content)
  const [dirty, setDirty] = useState(false)
  const originalRef = useRef(file.content)
  const monacoRef = useRef<any>(null)
  const theme = useAppStore((s) => s.theme)

  useEffect(() => {
    if (forcePlain) setUsePlain(true)
  }, [forcePlain])

  useEffect(() => {
    setValue(file.content)
    originalRef.current = file.content
    setDirty(false)
  }, [file])

  useEffect(() => {
    if (monacoRef.current) monacoRef.current.editor.setTheme(monacoThemeFor(theme))
  }, [theme, usePlain])

  const handleMount: OnMount = (_editor, monaco) => {
    monacoRef.current = monaco
    registerCsoundLanguage(monaco)
    registerEditorThemes(monaco)
    monaco.editor.setTheme(monacoThemeFor(theme))
  }

  const handleEdit = (v: string | undefined) => {
    const next = v ?? ''
    setValue(next)
    setDirty(next !== originalRef.current)
  }

  const apply = () => {
    if (!onChange || !dirty) return
    onChange(value)
  }

  const revert = () => {
    setValue(originalRef.current)
    setDirty(false)
  }

  const enableRichEditor = useCallback(() => {
    setPreferRichEditor(true)
    setUsePlain(false)
  }, [])

  const readOnly = !editable || !onChange
  const canEnableRich = typeof window !== 'undefined' && !!window.api

  const banner = (
    <div style={styles.banner}>
      <span style={styles.filename}>{file.name}</span>
      {file.derived && <span style={styles.badge}>derived view · read-only</span>}
      {!file.derived && !editable && <span style={styles.badge}>read-only</span>}
      {dirty && <span style={styles.dirty}>● unsaved</span>}
      <div style={{ flex: 1 }} />
      {usePlain && canEnableRich && (
        <button type="button" onClick={enableRichEditor} style={styles.neutralBtn}>
          Syntax highlighting
        </button>
      )}
      {dirty && (
        <>
          <button type="button" onClick={revert} style={styles.neutralBtn}>Revert</button>
          <button type="button" onClick={apply} style={styles.primaryBtn}>Apply · New Version</button>
        </>
      )}
    </div>
  )

  if (usePlain) {
    return (
      <div style={styles.container}>
        {banner}
        <PlainCodeView content={value} filename={file.name} />
      </div>
    )
  }

  return (
    <div style={styles.container}>
      {banner}
      <div style={styles.editorWrap}>
        <Suspense fallback={<PlainCodeView content={value} filename={file.name} />}>
          <MonacoEditor
            height="100%"
            language={MONACO_LANG[file.language]}
            value={value}
            onMount={handleMount}
            onChange={handleEdit}
            options={{
              readOnly,
              minimap: { enabled: false },
              fontSize: 12,
              fontFamily: 'var(--font-mono), SF Mono, monospace',
              lineNumbers: 'on',
              scrollBeyondLastLine: false,
              renderLineHighlight: 'line',
              tabSize: 2,
              wordWrap: 'off',
              padding: { top: 12, bottom: 12 },
            }}
            theme={monacoThemeFor(theme)}
          />
        </Suspense>
      </div>
    </div>
  )
}

const styles: Record<string, CSSProperties> = {
  container: { flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden', minHeight: 0 },
  banner: {
    display: 'flex', alignItems: 'center', gap: 10,
    padding: '6px 14px', borderBottom: '1px solid var(--border-subtle)',
    background: 'var(--bg-secondary)', flexShrink: 0, fontSize: 11,
  },
  filename: { fontFamily: 'var(--font-mono)', color: 'var(--text-secondary)', fontWeight: 500 },
  badge: {
    fontSize: 10, color: 'var(--text-muted)', background: 'var(--bg-tertiary)',
    padding: '1px 7px', borderRadius: 4, letterSpacing: '0.04em', textTransform: 'uppercase',
  },
  dirty: { fontSize: 10, color: 'var(--accent)', fontWeight: 600 },
  neutralBtn: {
    padding: '4px 10px', borderRadius: 6, border: '1px solid var(--border)',
    background: 'transparent', color: 'var(--text-muted)', fontSize: 11,
    fontFamily: 'var(--font-primary)', cursor: 'pointer',
  },
  primaryBtn: {
    padding: '4px 10px', borderRadius: 6, border: 'none',
    background: 'var(--accent)', color: 'var(--bg-primary)', fontSize: 11,
    fontWeight: 600, fontFamily: 'var(--font-primary)', cursor: 'pointer',
  },
  editorWrap: { flex: 1, minHeight: 0 },
}
