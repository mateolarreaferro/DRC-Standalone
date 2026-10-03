import { IpcMain, BrowserWindow } from 'electron'
import { SessionManager } from '../session/session'
import { MemoryStore } from '../memory/store'
import '../tool/registry'
import { Log } from '../util/log'

export function handleAgentIPC(ipcMain: IpcMain): void {
  ipcMain.handle('session:create', async (_event, agentName: string) => {
    const session = SessionManager.create(agentName)
    return { id: session.id, agent: agentName }
  })

  ipcMain.handle('session:cancel', async (_event, sessionID: string) => {
    SessionManager.cancel(sessionID)
    return { ok: true }
  })

  ipcMain.handle('session:send', async (event, sessionID: string, content: string, opts?: { retry?: boolean; variant?: boolean }) => {
    const window = BrowserWindow.fromWebContents(event.sender)
    if (!window) return { ok: false, error: 'No window' }

    // Run streaming in the background — don't await in the handler
    // This lets the IPC call return immediately while chunks stream
    ;(async () => {
      try {
        Log.info(`Processing message in session ${sessionID}`)
        const stream = SessionManager.send(sessionID, content, opts ?? {})
        for await (const chunk of stream) {
          if (window.isDestroyed()) break
          window.webContents.send('stream:chunk', {
            sessionID,
            type: chunk.type,
            content: chunk.content,
            toolName: chunk.toolName,
          })
        }
        if (!window.isDestroyed()) {
          window.webContents.send('stream:complete', { sessionID })
        }
        Log.info(`Stream complete for session ${sessionID}`)
      } catch (err: any) {
        Log.error('Session send error:', err.message, err.stack)
        if (!window.isDestroyed()) {
          window.webContents.send('stream:chunk', {
            sessionID,
            type: 'error',
            content: `Error: ${err.message}`,
          })
          window.webContents.send('stream:complete', { sessionID, error: err.message })
        }
      }
    })()

    // Return immediately so renderer isn't blocked
    return { ok: true }
  })

  ipcMain.handle('session:list', async () => {
    return SessionManager.list().map((s) => ({
      id: s.id,
      agent: s.agentName,
      title: s.title ?? null,
      messageCount: s.messages.length || MemoryStore.messageCount(s.id),
      createdAt: s.createdAt,
    }))
  })

  ipcMain.handle('session:get', async (_event, id: string) => {
    const session = SessionManager.get(id)
    if (!session) return null
    return {
      id: session.id,
      agent: session.agentName,
      messages: session.messages,
      createdAt: session.createdAt,
    }
  })
}
