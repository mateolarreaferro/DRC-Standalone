import { IpcMain, shell } from 'electron'
import { listWorkshopStarters, listPlayerDemos, readWorkshopStarter, WORKSHOP_STARTERS } from '../util/workshop-starters'
import { deleteUserDemo, listUserDemos, readUserDemo, saveUserDemo, updateUserDemo } from '../util/user-demos'
import { findWorkshopHandoutPath } from '../util/workshop-handout'

export function handleWorkshopIPC(ipcMain: IpcMain): void {
  ipcMain.handle('workshop:list', async () => listWorkshopStarters())

  ipcMain.handle('workshop:listDemos', async () => [...listPlayerDemos(), ...listUserDemos()])

  ipcMain.handle('workshop:saveUserDemo', async (_event, payload: { title: string; content: string; id?: string }) => {
    if (payload.id) return updateUserDemo(payload.id, payload.title, payload.content)
    return saveUserDemo(payload.title, payload.content)
  })

  ipcMain.handle('workshop:deleteUserDemo', async (_event, id: string) => {
    if (!id?.startsWith('user_')) return { ok: false, error: 'Only saved demos can be deleted' }
    return deleteUserDemo(id) ? { ok: true } : { ok: false, error: 'Demo not found' }
  })

  ipcMain.handle('workshop:openHandout', async () => {
    const path = findWorkshopHandoutPath()
    if (!path) return { ok: false, error: 'Workshop handout PDF not found in resources/workshop/' }
    const err = await shell.openPath(path)
    return err ? { ok: false, error: err, path } : { ok: true, path }
  })

  ipcMain.handle('workshop:revealHandout', async () => {
    const path = findWorkshopHandoutPath()
    if (!path) return { ok: false, error: 'Workshop handout PDF not found' }
    shell.showItemInFolder(path)
    return { ok: true, path }
  })

  ipcMain.handle('workshop:read', async (_event, id: string) => {
    const userContent = readUserDemo(id)
    if (userContent) {
      const meta = listUserDemos().find((d) => d.id === id)
      if (!meta) return { ok: false, error: 'User demo metadata missing' }
      return { ok: true, meta, content: userContent }
    }
    const meta = WORKSHOP_STARTERS.find((s) => s.id === id)
    if (!meta) return { ok: false, error: 'Unknown workshop starter' }
    const content = readWorkshopStarter(meta.filename)
    if (!content) return { ok: false, error: `Missing file: ${meta.filename}` }
    return { ok: true, meta, content }
  })
}
