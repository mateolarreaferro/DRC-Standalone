/** Load bundled workshop / player demo CSDs — no API key required. */

export interface WorkshopStarterMeta {
  id: string
  title: string
  filename: string
  playerReady?: boolean
  playerDemo?: boolean
  demoGroup?: string
  demoOrder?: number
  description: string
}

export async function listWorkshopStarters(): Promise<WorkshopStarterMeta[]> {
  try {
    return (await window.api?.workshop?.list?.()) ?? []
  } catch {
    return []
  }
}

export async function listPlayerDemos(): Promise<WorkshopStarterMeta[]> {
  try {
    return (await window.api?.workshop?.listDemos?.()) ?? []
  } catch {
    return []
  }
}

export async function readWorkshopStarter(id: string): Promise<{ meta: WorkshopStarterMeta; content: string } | null> {
  try {
    const r: any = await window.api?.workshop?.read?.(id)
    if (!r?.ok || !r.content) return null
    return { meta: r.meta, content: r.content }
  } catch {
    return null
  }
}

export const WORKSHOP_PLAYER_FM_BELL_ID = 'player_fm_bell'

export async function loadWorkshopPlayerDemo(id: string): Promise<string | null> {
  const r = await readWorkshopStarter(id)
  return r?.content ?? null
}

export async function deletePlayerDemo(id: string): Promise<{ ok: boolean; error?: string }> {
  try {
    const r: any = await window.api?.workshop?.deleteUserDemo?.(id)
    return r?.ok ? { ok: true } : { ok: false, error: r?.error ?? 'Delete failed' }
  } catch (err: any) {
    return { ok: false, error: err?.message ?? 'Delete failed' }
  }
}
