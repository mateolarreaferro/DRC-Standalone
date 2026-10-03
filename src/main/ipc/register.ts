import { ipcMain } from 'electron'
import { handleAgentIPC } from './agent.ipc'
import { handleCsoundIPC } from './csound.ipc'
import { handleGraphIPC } from './graph.ipc'
import { handleExportIPC } from './export.ipc'
import { handleMemoryIPC } from './memory.ipc'
import { handleConfigIPC } from './config.ipc'
import { handleRetrievalIPC } from './retrieval.ipc'
import { handleLlmIPC } from './llm.ipc'
import { handleWorkshopIPC } from './workshop.ipc'

export function registerAllIPC(): void {
  handleConfigIPC(ipcMain)  // Load saved keys first
  handleAgentIPC(ipcMain)
  handleCsoundIPC(ipcMain)
  handleGraphIPC(ipcMain)
  handleRetrievalIPC(ipcMain)
  handleExportIPC(ipcMain)
  handleMemoryIPC(ipcMain)
  handleLlmIPC(ipcMain)
  handleWorkshopIPC(ipcMain)
}
