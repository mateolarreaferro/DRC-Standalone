import { useEffect, useRef } from 'react'
import { useSessionStore } from '../stores/sessionStore'
import { useUsageStore } from '../stores/usageStore'
import { applyQuotaCooldownFromMessage, useRateLimitStore } from '../stores/rateLimitStore'
import type { UsageRecord } from '../lib/usageFormat'

export function useStream() {
  const storeRef = useRef(useSessionStore)

  // IDs of the main-response and narration messages that are currently being
  // streamed, so each chunk appends to the right message regardless of what
  // the other stream emits in between. Reset on stream:complete.
  const mainIdRef = useRef<string | null>(null)
  const narrationIdRef = useRef<string | null>(null)
  const lastChunkAtRef = useRef(Date.now())

  useEffect(() => {
    return useSessionStore.subscribe((state, prev) => {
      if (state.isStreaming && !prev.isStreaming) {
        lastChunkAtRef.current = Date.now()
      }
    })
  }, [])

  useEffect(() => {
    if (!window.api?.stream) {
      console.warn('Stream API not available — running outside Electron?')
      return
    }

    const unsubChunk = window.api.stream.onChunk((chunk) => {
      lastChunkAtRef.current = Date.now()
      const store = storeRef.current.getState()

      if (chunk.type === 'status') {
        store.setAgentActivity(chunk.content)
      } else if (chunk.type === 'text') {
        useRateLimitStore.getState().clearCooldown()
        store.setAgentActivity('Writing your CSD…')
        if (mainIdRef.current) {
          store.appendById(mainIdRef.current, chunk.content)
        } else {
          const id = `msg_${Date.now()}_m_${Math.random().toString(36).slice(2, 6)}`
          mainIdRef.current = id
          store.addMessage({
            id,
            role: 'assistant',
            content: chunk.content,
            timestamp: Date.now(),
          })
        }
      } else if (chunk.type === 'narration') {
        if (narrationIdRef.current) {
          store.appendById(narrationIdRef.current, chunk.content)
        } else {
          const id = `msg_${Date.now()}_n_${Math.random().toString(36).slice(2, 6)}`
          narrationIdRef.current = id
          store.addMessage({
            id,
            role: 'assistant',
            content: chunk.content,
            type: 'narration',
            timestamp: Date.now(),
          })
        }
      } else if (chunk.type === 'suggestions') {
        if (narrationIdRef.current) {
          try {
            const arr = JSON.parse(chunk.content)
            if (Array.isArray(arr)) store.setMessageSuggestions(narrationIdRef.current, arr)
          } catch {
            /* ignore malformed suggestions */
          }
        }
      } else if (chunk.type === 'usage') {
        try {
          const usage = JSON.parse(chunk.content) as UsageRecord
          const tok = Number(usage.totalTokens)
          const cost = Number(usage.costUSD)
          const normalized: UsageRecord = {
            ...usage,
            totalTokens: Number.isFinite(tok) ? tok : 0,
            costUSD: Number.isFinite(cost) ? cost : 0,
          }
          useUsageStore.getState().record('agent', normalized)
          const targetId = mainIdRef.current ?? narrationIdRef.current
          if (targetId) store.attachUsageToMessage(targetId, normalized)
        } catch {
          /* ignore malformed usage */
        }
      } else if (chunk.type === 'error') {
        applyQuotaCooldownFromMessage(chunk.content)
        store.addMessage({
          id: `msg_${Date.now()}_e`,
          role: 'assistant',
          content: chunk.content,
          type: 'error',
          timestamp: Date.now(),
        })
        store.setAgentActivity(null)
        store.setStreaming(false)
        mainIdRef.current = null
        narrationIdRef.current = null
      }
    })

    const unsubComplete = window.api.stream.onComplete((_result) => {
      const store = storeRef.current.getState()
      store.setStreaming(false)
      store.setAgentActivity(null)
      mainIdRef.current = null
      narrationIdRef.current = null
    })

    // Backup if the main process stream never completes (should not happen after timeout).
    const watchdog = setInterval(() => {
      const store = storeRef.current.getState()
      if (!store.isStreaming) return
      if (Date.now() - lastChunkAtRef.current < 130_000) return
      store.addMessage({
        id: `msg_${Date.now()}_stuck`,
        role: 'assistant',
        content:
          'This request appears stuck. Tap Cancel or restart Dr.C, then try once.',
        type: 'error',
        timestamp: Date.now(),
      })
      store.setStreaming(false)
      store.setAgentActivity(null)
      mainIdRef.current = null
      narrationIdRef.current = null
    }, 10_000)

    return () => {
      unsubChunk()
      unsubComplete()
      clearInterval(watchdog)
    }
  }, [])
}
