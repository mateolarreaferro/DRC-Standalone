import { app } from 'electron'
import { existsSync, mkdirSync, readFileSync, writeFileSync, unlinkSync } from 'fs'
import { join } from 'path'
import type { WorkshopStarterMeta } from './workshop-starters'

const MANIFEST = 'manifest.json'

export interface UserDemoEntry {
  id: string
  title: string
  filename: string
  createdAt: number
  updatedAt: number
}

function demosDir(): string {
  const dir = join(app.getPath('userData'), 'player-demos')
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true })
  return dir
}

function manifestPath(): string {
  return join(demosDir(), MANIFEST)
}

function readManifest(): UserDemoEntry[] {
  const path = manifestPath()
  if (!existsSync(path)) return []
  try {
    const raw = JSON.parse(readFileSync(path, 'utf-8'))
    return Array.isArray(raw) ? raw : []
  } catch {
    return []
  }
}

function writeManifest(entries: UserDemoEntry[]): void {
  writeFileSync(manifestPath(), JSON.stringify(entries, null, 2), 'utf-8')
}

function slugId(title: string): string {
  const base = title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_|_$/g, '')
    .slice(0, 40) || 'demo'
  return `user_${base}_${Date.now().toString(36)}`
}

export function listUserDemos(): WorkshopStarterMeta[] {
  return readManifest()
    .filter((e) => existsSync(join(demosDir(), e.filename)))
    .map((e) => ({
      id: e.id,
      title: e.title,
      filename: join('user', e.filename),
      playerDemo: true,
      demoGroup: 'My Demos',
      demoOrder: 1000 + e.updatedAt,
      description: 'Saved from Player CSD editor',
    }))
}

export function readUserDemo(id: string): string | null {
  const entry = readManifest().find((e) => e.id === id)
  if (!entry) return null
  const path = join(demosDir(), entry.filename)
  if (!existsSync(path)) return null
  try {
    return readFileSync(path, 'utf-8')
  } catch {
    return null
  }
}

export function saveUserDemo(title: string, content: string): { ok: true; meta: WorkshopStarterMeta } | { ok: false; error: string } {
  const trimmed = title.trim()
  if (!trimmed) return { ok: false, error: 'Title is required' }
  if (!content.trim()) return { ok: false, error: 'CSD is empty' }

  const entries = readManifest()
  const now = Date.now()
  const id = slugId(trimmed)
  const filename = `${id}.csd`
  const path = join(demosDir(), filename)

  try {
    writeFileSync(path, content, 'utf-8')
    entries.push({ id, title: trimmed, filename, createdAt: now, updatedAt: now })
    writeManifest(entries)
    return {
      ok: true,
      meta: {
        id,
        title: trimmed,
        filename: join('user', filename),
        playerDemo: true,
        demoGroup: 'My Demos',
        demoOrder: 1000 + now,
        description: 'Saved from Player CSD editor',
      },
    }
  } catch (err: any) {
    return { ok: false, error: err?.message ?? 'Failed to save demo' }
  }
}

export function updateUserDemo(id: string, title: string, content: string): { ok: true; meta: WorkshopStarterMeta } | { ok: false; error: string } {
  const entries = readManifest()
  const idx = entries.findIndex((e) => e.id === id)
  if (idx < 0) return { ok: false, error: 'Demo not found' }

  const trimmed = title.trim()
  if (!trimmed) return { ok: false, error: 'Title is required' }

  const path = join(demosDir(), entries[idx].filename)
  try {
    writeFileSync(path, content, 'utf-8')
    entries[idx] = { ...entries[idx], title: trimmed, updatedAt: Date.now() }
    writeManifest(entries)
    const e = entries[idx]
    return {
      ok: true,
      meta: {
        id: e.id,
        title: e.title,
        filename: join('user', e.filename),
        playerDemo: true,
        demoGroup: 'My Demos',
        demoOrder: 1000 + e.updatedAt,
        description: 'Saved from Player CSD editor',
      },
    }
  } catch (err: any) {
    return { ok: false, error: err?.message ?? 'Failed to update demo' }
  }
}

export function deleteUserDemo(id: string): boolean {
  const entries = readManifest()
  const idx = entries.findIndex((e) => e.id === id)
  if (idx < 0) return false
  const path = join(demosDir(), entries[idx].filename)
  try {
    unlinkSync(path)
  } catch { /* ignore */ }
  entries.splice(idx, 1)
  writeManifest(entries)
  return true
}

export function findUserDemoPath(filename: string): string | null {
  if (!filename.startsWith('user/')) return null
  const base = filename.slice('user/'.length)
  const path = join(demosDir(), base)
  return existsSync(path) ? path : null
}
