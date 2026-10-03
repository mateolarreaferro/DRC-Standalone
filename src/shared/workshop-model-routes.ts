/** Dr. B workshop model routing — maps user intent to bundled collection CSDs. */

export interface WorkshopModelRoute {
  /** Workshop starter id (player-model-demos.json when applicable) */
  starterId: string
  /** Relative path under resources/workshop-starters/ */
  filename: string
  intro: string
}

export interface ModelRouteRule {
  test: (q: string) => boolean
  route: WorkshopModelRoute
}

const DR_B = 'Dr. B collection'

export const WORKSHOP_MODEL_ROUTES: ModelRouteRule[] = [
  {
    test: (q) =>
      /\b(trumpet|brass|flugel|cornet|bugle|trombone|fanfare)\b/.test(q) &&
      !/\b(bell|shimmer|chime|glock|marimba|wood|clarinet|pad)\b/.test(q),
    route: {
      starterId: 'model_models_misc_synths_waveshapebrass',
      filename: 'models/misc_synths/WaveshapeBrass.csd',
      intro: `Rajmil Fischman waveshaping brass (WaveshapeBrass.csd) — beating oscillators + dynamic waveshaper from the ${DR_B}.`,
    },
  },
  {
    test: (q) => /\b(french\s*horn|horn\s*solo|horn\b)/.test(q) && !/\b(alto|tenor|sax|english)\b/.test(q),
    route: {
      starterId: 'model_models_misc_synths_frenchhorn',
      filename: 'models/misc_synths/FrenchHorn.csd',
      intro: `Wavetable French horn (FrenchHorn.csd, instr 25) — vibrato + brightness tables from the ${DR_B}.`,
    },
  },
  {
    test: (q) => /\b(clarinet|bass\s*clarinet)\b/.test(q) && !/\b(brass|bell|pad|waveshape)\b/.test(q),
    route: {
      starterId: 'chowning_fm_clarinet',
      filename: 'models/chowning/chowning_fm_clarinet.csd',
      intro: `Chowning FM clarinet — 9:8 ratio (fc=900 fm=800 @ A440), classic preset from the ${DR_B}.`,
    },
  },
  {
    // Bare "FM bell" → fm_bell_starter (golden-shortcut). Chowning model is Player-only (p4 in Hz).
    test: (q) => /\bchowning\b/.test(q) && /\b(bell|chime)\b/.test(q),
    route: {
      starterId: 'chowning_fm_bell',
      filename: 'models/chowning/chowning_fm_bell.csd',
      intro: `Chowning FM bell — classic 5:7 inharmonic ratio (fc=200 fm=280 @ A440), split from the multi-timbre orchestra.`,
    },
  },
  {
    test: (q) => /\b(chowning|fm\s*clarinet|clarinet.*fm)\b/.test(q) && !/\b(waveshape|dsf)\b/.test(q),
    route: {
      starterId: 'chowning_fm_clarinet',
      filename: 'models/chowning/chowning_fm_clarinet.csd',
      intro: `Chowning FM clarinet — 9:8 ratio (fc=900 fm=800 @ A440), isolated from the classic multi-timbre CSD.`,
    },
  },
  {
    test: (q) => /\b(chowning|fm\s*wood|wood\s*drum)\b/.test(q) && !/\b(williams|waveshape)\b/.test(q),
    route: {
      starterId: 'chowning_fm_wood',
      filename: 'models/chowning/chowning_fm_wood.csd',
      intro: `Chowning FM wood drum — 16:11 ratio (fc=80 fm=55 @ A440), classic Mathews/Chowning preset.`,
    },
  },
  {
    test: (q) => /\b(chowning|fm\s*bass|brasslike|dsf\s*brass)\b/.test(q) && !/\b(trumpet|trombone|waveshape)\b/.test(q),
    route: {
      starterId: 'chowning_fm_bass',
      filename: 'models/chowning/chowning_fm_bass.csd',
      intro: `Chowning FM bass/brass — 1:1 ratio (fc=fm=440), brasslike preset from the classic orchestra.`,
    },
  },
  {
    test: (q) => /\b(fat\s*pad|step\s*sequencer|moog\s*seq)\b/.test(q),
    route: {
      starterId: 'model_models_misc_synths_stepsequencer',
      filename: 'models/misc_synths/StepSequencer.csd',
      intro: `Fat Pad 1 (StepSequencer.csd) — dual VCO + Moog VCF sequencer pad from the ${DR_B}.`,
    },
  },
]

/** Match bundled Dr. B model for a user query (lowercased, normalized). */
export function matchWorkshopModelRoute(userText: string): WorkshopModelRoute | null {
  const q = userText.toLowerCase().replace(/\s+/g, ' ')
  if (q.length < 4) return null
  if (/\b(change|modify|add|remove|fix|convert|adapt|make it|more|less)\b/.test(q) && q.length > 40) {
    return null
  }
  for (const { test, route } of WORKSHOP_MODEL_ROUTES) {
    if (test(q)) return route
  }
  return null
}
