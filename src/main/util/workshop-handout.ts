import { existsSync } from 'fs'
import { join } from 'path'
import { WORKSHOP_HANDOUT_FILENAME } from '../../shared/workshop-links'

export function findWorkshopHandoutPath(): string | null {
  const candidates = [
    join(__dirname, '../../resources/workshop', WORKSHOP_HANDOUT_FILENAME),
    join(__dirname, '../../../resources/workshop', WORKSHOP_HANDOUT_FILENAME),
    join(process.cwd(), 'resources/workshop', WORKSHOP_HANDOUT_FILENAME),
  ]
  for (const p of candidates) {
    if (existsSync(p)) return p
  }
  return null
}
