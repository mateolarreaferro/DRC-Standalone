import { IpcMain } from 'electron'
import { MemoryStore } from '../memory/store'
import { MemoryRetrieval } from '../memory/retrieve'
import { Learning, type FeedbackEvent } from '../memory/learning'
import { ErrorLessons } from '../memory/error_lessons'
import { FeedbackLessons } from '../memory/feedback_lessons'
import { MemoryDB } from '../memory/db'
import { Log } from '../util/log'

export function handleMemoryIPC(ipcMain: IpcMain): void {
  ipcMain.handle('memory:status', async () => MemoryDB.status())

  // Generic recall: top error→fix pairs relevant to a free-text query.
  ipcMain.handle('memory:recall', async (_event, query: string) => {
    return { results: MemoryRetrieval.relevantErrorFixes(query, 5) }
  })

  // Typed save entry point (kept for the original contract).
  ipcMain.handle('memory:save', async (_event, type: string, data: any) => {
    switch (type) {
      case 'error_fix':
        return { id: MemoryStore.saveErrorFix(data) }
      case 'feedback':
        return { id: MemoryStore.saveFeedback(data) }
      default:
        return { success: false, error: `unknown memory save type: ${type}` }
    }
  })

  // What the agent has learned from feedback (favored/disfavored techniques).
  ipcMain.handle('memory:profile', async () => Learning.get())

  // Durable instructions the user has given (remembered across sessions).
  ipcMain.handle('memory:lessons', async () => MemoryStore.allLessons())
  ipcMain.handle('memory:deleteLesson', async (_e, id: string) => {
    MemoryStore.deleteLesson(id)
    return { success: true }
  })

  // Unified feedback channel used by the renderer. `accepted_fix` additionally
  // stores the error→fix pair so the agent can reuse it next time.
  ipcMain.handle('memory:feedback', async (_event, kind: string, payload: any = {}) => {
    if (!MemoryDB.isReady()) {
      return { id: null, error: 'memory_disabled' }
    }

    if (kind === 'accepted_fix' && payload?.fixedCsd) {
      const fixKind = payload.kind === 'runtime' ? 'runtime' : 'compile'
      const errorRaw = String(payload.errorRaw ?? '')
      const fixedCsd = String(payload.fixedCsd)
      const id = MemoryStore.saveErrorFix({
        sessionId: payload.sessionId ?? null,
        kind: fixKind,
        errorRaw,
        brokenCsd: payload.brokenCsd ?? null,
        fixedCsd,
        diffSummary: payload.diffSummary ?? null,
      })
      // Background: distill a durable avoidance rule from this fix so the
      // proactive <previous-errors> block can prevent the same mistake next time.
      void ErrorLessons.distill({
        id,
        kind: fixKind,
        errorRaw,
        brokenCsd: payload.brokenCsd ?? null,
        fixedCsd,
      })
    }

    const ev: FeedbackEvent = {
      kind: kind as FeedbackEvent['kind'],
      rating: payload.rating ?? null,
      signals: {
        techniques: payload.techniques,
        opcodes: payload.opcodes,
        content: payload.content ?? payload.fixedCsd,
        // Captured from the thumbs-down composer for telemetry + distillation.
        reason: payload.reason,
        critique: payload.critique,
      },
    }
    const id = MemoryStore.saveFeedback({
      sessionId: payload.sessionId ?? null,
      messageId: payload.messageId ?? null,
      kind: ev.kind,
      rating: ev.rating,
      signals: ev.signals,
    })
    Learning.applyFeedback(ev)

    // A thumbs-down WITH a stated reason becomes a durable avoidance rule, so the
    // critique improves future generations instead of being an opaque -1.
    if (kind === 'thumbs_down' && (payload.reason || payload.critique)) {
      void FeedbackLessons.fromCritique({
        reason: payload.reason ?? null,
        critique: payload.critique ?? null,
        content: payload.content ?? null,
        sessionId: payload.sessionId ?? null,
      })
    }

    Log.info(`memory:feedback ${kind}`)
    return { id }
  })
}
