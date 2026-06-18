import { readWorkshopStarter } from '../util/workshop-starters'
import { matchWorkshopModelRoute } from '../../shared/workshop-model-routes'

export interface GoldenShortcut {
  intro: string
  csd: string
  starterId: string
}

interface Rule {
  test: (q: string) => boolean
  filename: string
  starterId: string
  intro: string
}

const RULES: Rule[] = [
  {
    test: (q) => /\b(wood\s*block|woodblock|temple\s*block|clave)\b/.test(q) && /\b(fm|percussion|perc)\b/.test(q),
    filename: 'fm_woodblock_midi_starter.csd',
    starterId: 'fm_woodblock_midi',
    intro:
      'FM woodblock from the Csound Manual fmpercfl opcode (kc1=5, decaying kc2) with MIDI routing — the textbook percussion-FM pattern, not a reinvented foscili patch.',
  },
  {
    test: (q) =>
      /\b(simple|plain|basic)\b/.test(q) &&
      /\b(fm|foscil|2-?\s*op)\b/.test(q) &&
      !/\b(bell|chime|shimmer|piano|bass|pad|reverb|wood|brass|horn|clarinet|trumpet)\b/.test(q),
    filename: 'fm_starter.csd',
    starterId: 'fm',
    intro: 'Simple 2-operator FM from the verified Dr.C golden starter.',
  },
  {
    test: (q) => /\b(shimmer|bell|chime)\b/.test(q) && /\b(fm|bell)\b/.test(q) && !/\b(brass|trumpet|horn)\b/.test(q),
    filename: 'fm_bell_starter.csd',
    starterId: 'fm_bell',
    intro: 'Shimmer FM bell from the verified Dr.C golden starter.',
  },
  {
    test: (q) => /\b(pluck|bass|ping-?pong)\b/.test(q) && /\b(fm|bass)\b/.test(q),
    filename: 'pluck_bass_starter.csd',
    starterId: 'pluck_bass',
    intro: 'FM pluck bass with ping-pong echo from the verified Dr.C golden starter.',
  },
]

/** User text from a wrapped artifact-edit payload (panel follow-ups). */
export function extractGoldenIntent(userText: string): string {
  const userNote = userText.match(/<user-note>\s*([\s\S]*?)\s*<\/user-note>/i)?.[1]
  if (userNote?.trim()) return userNote.trim()
  const afterArtifact = userText.match(/<\/current-artifact>\s*\n\n([\s\S]*)$/i)?.[1]
  if (afterArtifact?.trim()) return afterArtifact.trim()
  return userText.trim()
}

function isTimbreRescueIntent(q: string): boolean {
  return (
    /\b(bell|chime|shimmer|woodblock|bass|brass|clarinet)\b/.test(q) &&
    /\b(sound|sounds|like|wrong|fix|correct|actually|instead|not|too)\b/.test(q)
  )
}

function matchFmBellStarter(q: string): GoldenShortcut | null {
  const rule = RULES.find((r) => r.starterId === 'fm_bell')
  if (!rule?.test(q)) return null
  const csd = readWorkshopStarter(rule.filename)
  if (!csd?.trim()) return null
  return { intro: rule.intro, csd: csd.trim(), starterId: rule.starterId }
}

/** Deterministic golden CSD for common workshop requests — skips the LLM when matched. */
export function matchGoldenShortcut(userText: string): GoldenShortcut | null {
  const intent = extractGoldenIntent(userText)
  const q = intent.toLowerCase().replace(/\s+/g, ' ')
  if (q.length < 4) return null
  if (
    !isTimbreRescueIntent(q) &&
    /\b(change|modify|add|remove|fix|convert|adapt|make it|more|less)\b/.test(q) &&
    userText.length > 40
  ) {
    return null
  }

  // Workshop shimmer bell before Chowning Player models — "FM Bell" must not land on Hz p4 hold scores.
  const bell = matchFmBellStarter(q)
  if (bell) return bell

  const modelRoute = matchWorkshopModelRoute(intent)
  if (modelRoute) {
    const csd = readWorkshopStarter(modelRoute.filename)
    if (csd?.trim()) {
      return { intro: modelRoute.intro, csd: csd.trim(), starterId: modelRoute.starterId }
    }
  }

  for (const rule of RULES) {
    if (!rule.test(q)) continue
    const csd = readWorkshopStarter(rule.filename)
    if (!csd?.trim()) continue
    return { intro: rule.intro, csd: csd.trim(), starterId: rule.starterId }
  }
  return null
}
