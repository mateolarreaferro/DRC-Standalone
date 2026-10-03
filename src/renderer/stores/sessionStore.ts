import { create } from 'zustand'
import type { UsageRecord } from '../lib/usageFormat'
import { useUsageStore } from './usageStore'

export type AgentMode = 'csound' | 'csound-sine'

export interface Message {
  id: string
  role: 'user' | 'assistant'
  content: string
  type?: 'text' | 'tool_call' | 'tool_result' | 'narration' | 'error'
  toolName?: string
  timestamp: number
  suggestions?: string[] // one-click follow-up prompts (on narration messages)
  usage?: UsageRecord
}

// What failed last, so a subsequent successful play can be recorded as an
// error→fix pair in memory. Set by playback.ts before it requests an autofix.
export interface LastFailure {
  errorRaw: string
  brokenCsd: string
  kind: 'compile' | 'runtime'
  artifactId?: string
}

interface SessionState {
  sessionID: string | null
  messages: Message[]
  agentMode: AgentMode
  isStreaming: boolean
  agentActivity: string | null
  agentActivityStartedAt: number | null
  lastFailure: LastFailure | null
  /** Artifact being auto-fixed — fix responses update this, not a new artifact. */
  pendingAutofixArtifactId: string | null
  setSessionID: (id: string) => void
  addMessage: (msg: Message) => void
  appendToLast: (content: string) => void
  appendById: (id: string, content: string) => void
  setMessageSuggestions: (id: string, suggestions: string[]) => void
  setAgentMode: (mode: AgentMode) => void
  setStreaming: (streaming: boolean) => void
  setAgentActivity: (label: string | null) => void
  clearMessages: () => void
  startNewSession: () => void
  setLastFailure: (f: LastFailure | null) => void
  setPendingAutofixArtifactId: (id: string | null) => void
  attachUsageToMessage: (messageId: string, usage: UsageRecord) => void
  removeFailedAssistantTurn: () => void
  sendFeedback: (kind: string, payload?: Record<string, unknown>) => Promise<{ id?: string | null; error?: string } | void>
}

export const useSessionStore = create<SessionState>((set, get) => ({
  sessionID: null,
  messages: [],
  agentMode: 'csound',
  isStreaming: false,
  agentActivity: null,
  agentActivityStartedAt: null,
  lastFailure: null,
  pendingAutofixArtifactId: null,

  setSessionID: (id) => set({ sessionID: id }),

  addMessage: (msg) =>
    set((s) => ({ messages: [...s.messages, msg] })),

  appendToLast: (content) =>
    set((s) => {
      const msgs = [...s.messages]
      if (msgs.length > 0) {
        msgs[msgs.length - 1] = {
          ...msgs[msgs.length - 1],
          content: msgs[msgs.length - 1].content + content,
        }
      }
      return { messages: msgs }
    }),

  appendById: (id, content) =>
    set((s) => {
      const idx = s.messages.findIndex((m) => m.id === id)
      if (idx === -1) return {}
      const msgs = [...s.messages]
      msgs[idx] = { ...msgs[idx], content: msgs[idx].content + content }
      return { messages: msgs }
    }),

  setMessageSuggestions: (id, suggestions) =>
    set((s) => {
      const idx = s.messages.findIndex((m) => m.id === id)
      if (idx === -1) return {}
      const msgs = [...s.messages]
      msgs[idx] = { ...msgs[idx], suggestions }
      return { messages: msgs }
    }),

  setAgentMode: (mode) => set({ agentMode: mode }),
  setStreaming: (streaming) =>
    set((s) => ({
      isStreaming: streaming,
      ...(streaming && !s.agentActivityStartedAt
        ? { agentActivityStartedAt: Date.now(), agentActivity: s.agentActivity ?? 'Starting…' }
        : {}),
      ...(!streaming ? { agentActivity: null, agentActivityStartedAt: null } : {}),
    })),
  setAgentActivity: (label) =>
    set((s) => ({
      agentActivity: label,
      agentActivityStartedAt: label ? (s.agentActivityStartedAt ?? Date.now()) : null,
    })),
  clearMessages: () => set({ messages: [], agentActivity: null, agentActivityStartedAt: null }),

  // Drop back to a clean slate; the next send() mints a fresh persisted session.
  startNewSession: () => {
    useUsageStore.getState().resetArea('agent')
    set({
      sessionID: null,
      messages: [],
      lastFailure: null,
      pendingAutofixArtifactId: null,
      agentActivity: null,
      agentActivityStartedAt: null,
    })
  },

  setLastFailure: (f) => set({ lastFailure: f }),

  setPendingAutofixArtifactId: (id) => set({ pendingAutofixArtifactId: id }),

  attachUsageToMessage: (messageId, usage) =>
    set((s) => {
      const idx = s.messages.findIndex((m) => m.id === messageId)
      if (idx === -1) return {}
      const msgs = [...s.messages]
      msgs[idx] = { ...msgs[idx], usage }
      return { messages: msgs }
    }),

  removeFailedAssistantTurn: () =>
    set((s) => {
      const msgs = [...s.messages]
      while (msgs.length > 0) {
        const last = msgs[msgs.length - 1]
        if (last.role !== 'assistant') break
        if (last.type === 'error') {
          msgs.pop()
          continue
        }
        if (last.type === 'narration') {
          msgs.pop()
          continue
        }
        const hasCompleteCsd = /<CsoundSynthesizer[\s\S]*<\/CsoundSynthesizer>/i.test(last.content)
        const hasWebApp = /<!DOCTYPE\s+html[\s\S]*<\/html>/i.test(last.content)
        if (!hasCompleteCsd && !hasWebApp) {
          msgs.pop()
          continue
        }
        break
      }
      return { messages: msgs }
    }),

  sendFeedback: (kind, payload) => {
    const sessionID = get().sessionID
    const p = window.api?.memory?.feedback?.(kind, { sessionId: sessionID, ...payload })
    return Promise.resolve(p).then((result) => {
      window.dispatchEvent(new CustomEvent('drc:profile-changed'))
      return result as { id?: string | null; error?: string } | void
    })
  },
}))
