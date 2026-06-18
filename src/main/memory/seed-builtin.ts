import { MemoryStore } from './store'
import { BUILTIN_STANDING_RULES } from './builtin-lessons'

/** Persist Dr. B's built-in standing rules into the memory DB (idempotent). */
export function seedBuiltinLessons(): void {
  for (const rule of BUILTIN_STANDING_RULES) {
    MemoryStore.saveLesson(rule, null)
  }
}
