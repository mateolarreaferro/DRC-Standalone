import { create } from 'zustand'

const RICH_EDITOR_KEY = 'drc-rich-editor'

export function preferPlainEditor(): boolean {
  if (typeof window === 'undefined' || !window.api) return false
  try {
    return localStorage.getItem(RICH_EDITOR_KEY) !== '1'
  } catch {
    return true
  }
}

export function setPreferRichEditor(enabled: boolean): void {
  try {
    localStorage.setItem(RICH_EDITOR_KEY, enabled ? '1' : '0')
  } catch { /* ignore */ }
}

interface EditorState {
  csdContent: string
  filePath: string | null
  isDirty: boolean
  signalFlow: string | null
  forcePlain: boolean
  setCsdContent: (content: string) => void
  setFilePath: (path: string | null) => void
  setDirty: (dirty: boolean) => void
  setSignalFlow: (flow: string | null) => void
  setForcePlain: (forcePlain: boolean) => void
}

export const useEditorStore = create<EditorState>((set) => ({
  csdContent: '',
  filePath: null,
  isDirty: false,
  signalFlow: null,
  forcePlain: false,

  setCsdContent: (content) => set({ csdContent: content, isDirty: true }),
  setFilePath: (path) => set({ filePath: path }),
  setDirty: (dirty) => set({ isDirty: dirty }),
  setSignalFlow: (flow) => set({ signalFlow: flow }),
  setForcePlain: (forcePlain) => set({ forcePlain }),
}))
