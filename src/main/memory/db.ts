import { join } from 'path'
import { existsSync, mkdirSync } from 'fs'
import { app } from 'electron'
import type DatabaseType from 'better-sqlite3'
import { Log } from '../util/log'
import { SCHEMA_DDL, SINGLETON_ID } from './schema'

// Single owner of the better-sqlite3 handle for the memory DB.
//
// The DB lives next to config.json under userData/drc (same convention as
// config.ipc.ts), so it survives app restarts and reinstalls.
//
// better-sqlite3 is a native addon compiled against a specific Node/Electron
// ABI. If it fails to load (ABI mismatch in dev, missing binary in a packaged
// build), we DO NOT crash the agent — we flip `disabled` and every memory call
// becomes a no-op. The app keeps streaming; it just stops remembering.

let db: DatabaseType.Database | null = null
let disabled = false
let initError: string | null = null

function dbPath(): string {
  const dir = join(app.getPath('userData'), 'drc')
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true })
  return join(dir, 'memory.db')
}

export namespace MemoryDB {
  export function init(): void {
    if (db || disabled) return
    try {
      // Lazy require so a load failure is caught here rather than at import time.
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const Database = require('better-sqlite3') as typeof DatabaseType
      const path = dbPath()
      db = new Database(path)
      db.pragma('journal_mode = WAL')
      db.pragma('synchronous = NORMAL')
      db.exec(SCHEMA_DDL)
      seedProfile()
      Log.info(`MemoryDB ready at ${path}`)
    } catch (err: any) {
      disabled = true
      db = null
      initError = err?.message ?? String(err)
      Log.error(`MemoryDB disabled (memory features off): ${initError}`)
    }
  }

  export function status(): { ready: boolean; path?: string; error?: string } {
    if (db && !disabled) {
      return { ready: true, path: dbPath() }
    }
    return { ready: false, error: initError ?? 'Memory database not initialized' }
  }

  export function isReady(): boolean {
    return db !== null && !disabled
  }

  export function raw(): DatabaseType.Database {
    if (!db) throw new Error('MemoryDB not initialized')
    return db
  }

  function seedProfile(): void {
    if (!db) return
    db.prepare(
      `INSERT OR IGNORE INTO learning (id, updated_at) VALUES (?, ?)`,
    ).run(SINGLETON_ID, Date.now())
  }
}
