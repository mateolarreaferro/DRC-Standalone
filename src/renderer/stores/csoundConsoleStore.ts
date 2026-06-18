import { create } from 'zustand'

const STORAGE_KEY = 'drc-csound-console-pinned'

export type CsoundOutputStream = 'stdout' | 'stderr' | 'info'

export interface CsoundOutputLine {
  stream: CsoundOutputStream
  text: string
  ts: number
}

const ERROR_LINE =
  /error|cannot|unexpected|failed|syntax|undefined|INIT ERROR|PERF ERROR|too many arguments/i

/** Benign Csound summary lines that mention "error" but are not failures. */
const BENIGN_ERROR_LINE =
  /^\d+\s+errors?\s+in\s+performance/i

export function isCsoundErrorLine(text: string): boolean {
  const line = text.trim()
  if (!line || BENIGN_ERROR_LINE.test(line)) return false
  return ERROR_LINE.test(line)
}

export function formatCsoundConsoleLines(lines: CsoundOutputLine[]): string {
  return lines.map((l) => l.text).join('\n')
}

function loadUserPinned(): boolean {
  try {
    const pinned = localStorage.getItem(STORAGE_KEY)
    if (pinned !== null) return pinned === '1'
    // Migrate legacy “always show” preference from before userPinned/errorReveal split.
    return localStorage.getItem('drc-csound-console-enabled') === '1'
  } catch {
    return false
  }
}

function persistUserPinned(pinned: boolean): void {
  try {
    localStorage.setItem(STORAGE_KEY, pinned ? '1' : '0')
  } catch { /* ignore */ }
}

/** Panel is shown when the user opted in, or Csound reported an error this session. */
export function isConsoleVisible(state: {
  userPinned: boolean
  errorReveal: boolean
  editorHidesConsole?: boolean
}): boolean {
  if (state.editorHidesConsole) return false
  return state.userPinned || state.errorReveal
}

interface CsoundConsoleState {
  /** User chose “always show” in Settings or sidebar — persisted across launches. */
  userPinned: boolean
  /** Session-only — set when Csound stderr/stdout matches an error pattern. */
  errorReveal: boolean
  /** Player “Show Csound” editor — hide console so the Monaco pane gets vertical space. */
  editorHidesConsole: boolean
  expanded: boolean
  lines: CsoundOutputLine[]
  setUserPinned: (pinned: boolean) => void
  setEditorHidesConsole: (hide: boolean) => void
  toggle: () => void
  dismiss: () => void
  setExpanded: (expanded: boolean) => void
  append: (chunk: { stream: CsoundOutputStream; text: string }) => void
  clear: () => void
}

export const useCsoundConsoleStore = create<CsoundConsoleState>((set, get) => ({
  userPinned: loadUserPinned(),
  errorReveal: false,
  editorHidesConsole: false,
  expanded: false,
  lines: [],
  setUserPinned: (pinned) => {
    persistUserPinned(pinned)
    const { errorReveal } = get()
    set({
      userPinned: pinned,
      expanded: pinned || errorReveal,
    })
  },
  setEditorHidesConsole: (hide) => {
    set((s) => ({
      editorHidesConsole: hide,
      expanded: hide ? false : (s.userPinned || s.errorReveal),
    }))
  },
  toggle: () => {
    const visible = isConsoleVisible(get())
    if (visible) {
      persistUserPinned(false)
      set({ userPinned: false, errorReveal: false, expanded: false })
    } else {
      persistUserPinned(true)
      set({ userPinned: true, expanded: true })
    }
  },
  dismiss: () => {
    if (!get().userPinned) {
      set({ errorReveal: false, expanded: false })
    } else {
      set({ expanded: false })
    }
  },
  setExpanded: (expanded) => set({ expanded }),
  append: (chunk) => {
    const text = chunk.text.trimEnd()
    if (!text) return
    const hasError = chunk.stream === 'stderr' && isCsoundErrorLine(text)
    set((s) => {
      const nextLines = [
        ...s.lines,
        { stream: chunk.stream, text, ts: Date.now() },
      ].slice(-800)
      if (!hasError) return { lines: nextLines }
      return { lines: nextLines, errorReveal: true, expanded: true }
    })
  },
  clear: () => set({ lines: [] }),
}))
