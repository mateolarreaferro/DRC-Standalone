/** Paid / workshop Pro+ tier — Gemini Pro+, no free-tier rate-limit UX. */
export function isProPlus(): boolean {
  return process.env.DRC_PRO_PLUS !== '0'
}

/** One cheap model call per turn (Groq 8b). Off when Pro+ (narration + consults enabled). */
export function isWorkshopLite(): boolean {
  if (isProPlus()) return false
  return process.env.DRC_WORKSHOP_LITE !== '0'
}
