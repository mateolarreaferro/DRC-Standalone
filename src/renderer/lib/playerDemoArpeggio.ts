/** Per-instrument load demo phrases — varied rhythm, voicing, and harmony. */

export interface DemoArpeggioHints {
  id?: string
  title?: string
  demoGroup?: string
  filename?: string
  csd?: string
}

export type DemoPhraseStep =
  | { kind: 'rest'; ms: number }
  | { kind: 'note'; midi: number; ms: number; vel?: number }
  | { kind: 'chord'; midis: number[]; ms: number; vel?: number }
  | { kind: 'repeat'; midi: number; times: number; ms: number; gapMs: number; vel?: number }

type ChordShape = readonly number[]

const CHORD: Record<string, ChordShape> = {
  maj: [0, 4, 7, 12],
  min: [0, 3, 7, 12],
  min7: [0, 3, 7, 10],
  maj7: [0, 4, 7, 11],
  dom7: [0, 4, 7, 10],
  sus4: [0, 5, 7, 12],
  sus2: [0, 2, 7, 12],
  fifth: [0, 7, 12, 19],
  pentMaj: [0, 2, 4, 7, 11],
  pentMin: [0, 3, 5, 7, 10],
  quartal: [0, 5, 10, 15],
  whole: [0, 2, 4, 6, 8],
  dim: [0, 3, 6, 9],
  aug: [0, 4, 8],
  cluster: [0, 1, 5, 6],
  maj7sharp11: [0, 4, 7, 11, 18],
  locrian: [0, 3, 6, 10],
  add9: [0, 2, 4, 7, 14],
}

type TimbreFamily =
  | 'subBass'
  | 'bass'
  | 'pluckBass'
  | 'bell'
  | 'brass'
  | 'pad'
  | 'strings'
  | 'wind'
  | 'mallet'
  | 'granular'
  | 'trapped'
  | 'synth'
  | 'perc'
  | 'default'

type VoicingMode = 'closed' | 'open' | 'cluster' | 'octaveStack'

type PatternId =
  | 'block'
  | 'arpUp'
  | 'arpDown'
  | 'arpSyncopated'
  | 'repeatRoot'
  | 'stutter'
  | 'twoChordsBlock'
  | 'twoChordsArp'
  | 'openHold'
  | 'sparse'

interface FamilyRecipe {
  roots: readonly number[]
  chords: readonly ChordShape[]
  strange: readonly ChordShape[]
}

const RECIPES: Record<TimbreFamily, FamilyRecipe> = {
  subBass: {
    roots: [28, 31, 33, 36],
    chords: [CHORD.fifth, CHORD.min, CHORD.min7, CHORD.sus4],
    strange: [CHORD.dim, CHORD.quartal, CHORD.cluster],
  },
  bass: {
    roots: [36, 38, 40, 41, 43],
    chords: [CHORD.min, CHORD.min7, CHORD.fifth, CHORD.sus4, CHORD.dom7],
    strange: [CHORD.dim, CHORD.quartal, CHORD.locrian],
  },
  pluckBass: {
    roots: [36, 38, 40, 43],
    chords: [CHORD.min7, CHORD.min, CHORD.sus2, CHORD.fifth],
    strange: [CHORD.dim, CHORD.cluster],
  },
  bell: {
    roots: [72, 74, 76, 79, 84],
    chords: [CHORD.maj7, CHORD.maj, CHORD.pentMaj, CHORD.quartal, CHORD.sus4],
    strange: [CHORD.whole, CHORD.maj7sharp11, CHORD.add9, CHORD.cluster],
  },
  brass: {
    roots: [58, 60, 62, 65, 67],
    chords: [CHORD.maj, CHORD.sus4, CHORD.fifth, CHORD.dom7],
    strange: [CHORD.quartal, CHORD.aug, CHORD.cluster],
  },
  pad: {
    roots: [48, 50, 52, 55, 57],
    chords: [CHORD.maj7, CHORD.maj, CHORD.min7, CHORD.sus4, CHORD.quartal],
    strange: [CHORD.whole, CHORD.maj7sharp11, CHORD.add9],
  },
  strings: {
    roots: [50, 52, 55, 57, 60],
    chords: [CHORD.maj, CHORD.min, CHORD.maj7, CHORD.sus4],
    strange: [CHORD.quartal, CHORD.whole, CHORD.add9],
  },
  wind: {
    roots: [60, 62, 64, 67, 69],
    chords: [CHORD.pentMaj, CHORD.pentMin, CHORD.sus2, CHORD.min7],
    strange: [CHORD.whole, CHORD.quartal, CHORD.cluster],
  },
  mallet: {
    roots: [55, 57, 60, 62, 64],
    chords: [CHORD.pentMaj, CHORD.quartal, CHORD.sus4, CHORD.maj],
    strange: [CHORD.whole, CHORD.cluster, CHORD.add9],
  },
  granular: {
    roots: [52, 55, 57, 60, 62],
    chords: [CHORD.whole, CHORD.quartal, CHORD.min7, CHORD.pentMin],
    strange: [CHORD.cluster, CHORD.locrian, CHORD.dim],
  },
  trapped: {
    roots: [48, 50, 53, 55, 57],
    chords: [CHORD.min, CHORD.min7, CHORD.sus4, CHORD.pentMin],
    strange: [CHORD.quartal, CHORD.dim, CHORD.cluster],
  },
  synth: {
    roots: [52, 55, 57, 60, 64],
    chords: [CHORD.maj, CHORD.min, CHORD.maj7, CHORD.sus4, CHORD.dom7],
    strange: [CHORD.whole, CHORD.aug, CHORD.maj7sharp11, CHORD.cluster],
  },
  perc: {
    roots: [48, 50, 52, 55],
    chords: [CHORD.fifth, CHORD.quartal, CHORD.sus4],
    strange: [CHORD.cluster, CHORD.dim],
  },
  default: {
    roots: [57, 60, 62, 64, 67],
    chords: [CHORD.maj, CHORD.min, CHORD.maj7, CHORD.pentMaj],
    strange: [CHORD.quartal, CHORD.whole, CHORD.add9],
  },
}

const FAMILY_PATTERNS: Record<TimbreFamily, readonly PatternId[]> = {
  subBass: ['block', 'repeatRoot', 'arpUp', 'twoChordsBlock'],
  bass: ['block', 'arpUp', 'repeatRoot', 'twoChordsArp', 'stutter'],
  pluckBass: ['arpSyncopated', 'stutter', 'repeatRoot', 'twoChordsArp'],
  bell: ['openHold', 'arpUp', 'block', 'sparse', 'twoChordsBlock'],
  brass: ['arpUp', 'repeatRoot', 'block', 'twoChordsArp'],
  pad: ['openHold', 'block', 'sparse', 'twoChordsBlock', 'arpDown'],
  strings: ['openHold', 'arpUp', 'block', 'twoChordsBlock'],
  wind: ['sparse', 'arpUp', 'repeatRoot', 'block'],
  mallet: ['arpSyncopated', 'arpUp', 'twoChordsArp', 'block'],
  granular: ['sparse', 'arpSyncopated', 'openHold', 'twoChordsArp'],
  trapped: ['repeatRoot', 'arpUp', 'block', 'stutter', 'twoChordsBlock'],
  synth: ['arpUp', 'arpSyncopated', 'block', 'twoChordsArp', 'stutter'],
  perc: ['stutter', 'repeatRoot', 'block'],
  default: ['arpUp', 'block', 'twoChordsArp', 'sparse'],
}

/** Hand-picked harmony; pattern still varies by demo id. */
const ID_CHORD_OVERRIDES: Record<string, { c1: readonly number[]; c2?: readonly number[] }> = {
  dr_c_thick_analog_bass: { c1: [36, 39, 43, 48], c2: [36, 39, 42, 48] },
  player_pluck_bass: { c1: [38, 41, 45, 50], c2: [36, 43, 50] },
  dr_c_fm_bell_reverb: { c1: [74, 77, 81, 86] },
  player_fm_bell: { c1: [76, 79, 83, 88], c2: [72, 76, 79, 83] },
  player_fm_trumpet: { c1: [60, 64, 67, 72] },
  player_trapped_blue: { c1: [50, 53, 57, 62], c2: [48, 55, 60] },
  player_trapped_sand: { c1: [48, 52, 55, 60], c2: [50, 57, 62] },
  model_moog: { c1: [43, 47, 50, 55] },
  model_vco_moog: { c1: [40, 44, 47, 52] },
  chowning_fm_bell: { c1: [72, 76, 79, 84] },
  chowning_fm_bass: { c1: [43, 47, 50, 55] },
  chowning_fm_clarinet: { c1: [60, 64, 67, 72] },
  chowning_fm_wood: { c1: [48, 55, 60, 64] },
}

function hashString(s: string): number {
  let h = 2166136261
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i)
    h = Math.imul(h, 16777619)
  }
  return h >>> 0
}

function pick<T>(arr: readonly T[], seed: string, salt: string): T {
  return arr[hashString(`${seed}\0${salt}`) % arr.length]
}

function pickInt(seed: string, salt: string, min: number, max: number): number {
  if (max <= min) return min
  return min + (hashString(`${seed}\0${salt}`) % (max - min + 1))
}

function demoSeed(h: DemoArpeggioHints): string {
  return h.id ?? h.filename ?? h.title ?? 'player-demo'
}

function detectFamily(h: DemoArpeggioHints): TimbreFamily {
  const label = [
    h.id ?? '',
    h.title ?? '',
    h.demoGroup ?? '',
    h.filename ?? '',
    (h.csd ?? '').slice(0, 5000),
  ]
    .join(' ')
    .toLowerCase()

  if (/\b(trapped|gbuzz)\b/.test(label)) return 'trapped'
  if (/\b(grain|granular|sndwarp)\b/.test(label)) return 'granular'
  if (/\b(bell|chime|glock|celeste|shimmer)\b/.test(label)) return 'bell'
  if (/\b(trumpet|brass|horn|flugel|trombone|fanfare|clarinet|sax)\b/.test(label)) return 'brass'
  if (/\b(flute|bamboo|oboe|wind|vow|fof|choir|voice)\b/.test(label)) return 'wind'
  if (/\b(marimba|henon|mallet|vibraphone|xylophone)\b/.test(label)) return 'mallet'
  if (/\b(pad|string\s*pad|strings)\b/.test(label)) return 'strings'
  if (/\bpad\b/.test(label)) return 'pad'
  if (/\b(pluck|ping.?pong)\b/.test(label) && /\bbass\b/.test(label)) return 'pluckBass'
  if (/\b(sub\s*bass|808|tb303)\b/.test(label)) return 'subBass'
  if (/\bbass\b/.test(label)) return 'bass'
  if (/\b(drum|perc|woodblock|kick|snare|cricket)\b/.test(label)) return 'perc'
  if (/\b(handpan|physical|waveguide|pipa)\b/.test(label)) return 'mallet'
  if (/\b(fm|synth|analog|moog|vco|cz)\b/.test(label)) return 'synth'
  if (h.demoGroup?.toLowerCase().includes('trapped')) return 'trapped'
  if (h.demoGroup?.toLowerCase().includes('granular')) return 'granular'
  if (h.demoGroup?.toLowerCase().includes('chowning')) return 'brass'
  if (h.demoGroup?.toLowerCase().includes('fm')) return 'synth'
  if (h.demoGroup?.toLowerCase().includes('pad')) return 'pad'
  if (h.demoGroup?.toLowerCase().includes('bass')) return 'bass'
  return 'default'
}

function voicing(root: number, shape: readonly number[], mode: VoicingMode): number[] {
  const base = shape.map((semi) => root + semi)
  switch (mode) {
    case 'closed':
      return [...new Set(base)].sort((a, b) => a - b)
    case 'open': {
      const third = root + (shape[1] ?? 4)
      const fifth = root + (shape[2] ?? 7)
      const top = root + (shape[3] ?? 12)
      return [...new Set([root, fifth, third + 12, top + 12])].sort((a, b) => a - b)
    }
    case 'cluster':
      return [...new Set([root, root + 1, root + 2, root + (shape[2] ?? 6)])].sort((a, b) => a - b)
    case 'octaveStack':
      return [...new Set([root, root + 12, root + 24, root + (shape[2] ?? 7) + 12])].sort((a, b) => a - b)
    default:
      return base
  }
}

function chordMaterial(
  family: TimbreFamily,
  seed: string,
  slot: 'a' | 'b',
  useStrange: boolean,
): number[] {
  const recipe = RECIPES[family]
  const pool = useStrange ? recipe.strange : recipe.chords
  const root = pick(recipe.roots, seed, `root-${slot}`)
  const shape = pick(pool, seed, `shape-${slot}`)
  const mode = pick(
    ['closed', 'open', 'cluster', 'octaveStack'] as const,
    seed,
    `voicing-${slot}`,
  )
  const transposed = slot === 'b' ? root + pick([3, 4, 5, 7, 8], seed, 'transpose-b') : root
  return voicing(transposed, shape, mode)
}

function resolveChords(h: DemoArpeggioHints): { c1: number[]; c2: number[] | null } {
  const id = h.id ?? ''
  const override = id ? ID_CHORD_OVERRIDES[id] : undefined
  if (override) {
    return {
      c1: [...override.c1],
      c2: override.c2 ? [...override.c2] : null,
    }
  }

  const seed = demoSeed(h)
  const family = detectFamily(h)
  const strange = hashString(`${seed}\0strange`) % 5 === 0
  const c1 = chordMaterial(family, seed, 'a', strange)
  const wantSecond = hashString(`${seed}\0second`) % 3 !== 0
  const c2 = wantSecond ? chordMaterial(family, seed, 'b', strange && hashString(`${seed}\0strange2`) % 2 === 0) : null
  return { c1, c2 }
}

function arpSteps(
  midis: number[],
  seed: string,
  salt: string,
  direction: 'up' | 'down' | 'syncopated',
): DemoPhraseStep[] {
  const order =
    direction === 'down'
      ? [...midis].reverse()
      : direction === 'syncopated'
        ? [...midis].sort(
            (a, b) =>
              (hashString(`${seed}\0${salt}\0${a}`) % 100) -
              (hashString(`${seed}\0${salt}\0${b}`) % 100),
          )
        : midis
  const steps: DemoPhraseStep[] = []
  for (let i = 0; i < order.length; i++) {
    const ms = pickInt(seed, `${salt}-dur-${i}`, 90, 320)
    steps.push({ kind: 'note', midi: order[i], ms })
    if (i < order.length - 1) {
      steps.push({ kind: 'rest', ms: pickInt(seed, `${salt}-gap-${i}`, 40, 180) })
    }
  }
  return steps
}

function buildPattern(
  pattern: PatternId,
  c1: number[],
  c2: number[] | null,
  seed: string,
): DemoPhraseStep[] {
  const vel = 0.52 + (pickInt(seed, 'vel', 0, 8) / 100)
  const v = vel

  switch (pattern) {
    case 'block':
      return [{ kind: 'chord', midis: c1, ms: pickInt(seed, 'block', 700, 1100), vel: v }]

    case 'openHold':
      return [{ kind: 'chord', midis: c1, ms: pickInt(seed, 'open', 900, 1400), vel: v * 0.9 }]

    case 'arpUp':
      return arpSteps(c1, seed, 'arp-up', 'up')

    case 'arpDown':
      return arpSteps(c1, seed, 'arp-down', 'down')

    case 'arpSyncopated':
      return arpSteps(c1, seed, 'arp-sync', 'syncopated')

    case 'repeatRoot': {
      const root = c1[0]
      const times = pickInt(seed, 'rep-n', 2, 4)
      return [
        { kind: 'repeat', midi: root, times, ms: pickInt(seed, 'rep-ms', 100, 200), gapMs: pickInt(seed, 'rep-gap', 60, 120), vel: v },
        { kind: 'rest', ms: pickInt(seed, 'rep-rest', 80, 160) },
        ...arpSteps(c1.slice(1).length ? [root, ...c1.slice(1)] : c1, seed, 'rep-tail', 'up'),
      ]
    }

    case 'stutter': {
      const n = c1[pickInt(seed, 'stutter-idx', 0, c1.length - 1)]
      return [{
        kind: 'repeat',
        midi: n,
        times: pickInt(seed, 'stutter-n', 3, 6),
        ms: pickInt(seed, 'stutter-ms', 70, 130),
        gapMs: pickInt(seed, 'stutter-gap', 45, 90),
        vel: v,
      }]
    }

    case 'twoChordsBlock': {
      const steps: DemoPhraseStep[] = [
        { kind: 'chord', midis: c1, ms: pickInt(seed, 'c1-ms', 320, 520), vel: v },
        { kind: 'rest', ms: pickInt(seed, 'between', 100, 220) },
      ]
      if (c2?.length) {
        steps.push({ kind: 'chord', midis: c2, ms: pickInt(seed, 'c2-ms', 400, 700), vel: v })
      } else {
        steps.push(...arpSteps(c1, seed, 'c1-again', 'down'))
      }
      return steps
    }

    case 'twoChordsArp': {
      const steps: DemoPhraseStep[] = [
        ...arpSteps(c1, seed, 'first', 'up'),
        { kind: 'rest', ms: pickInt(seed, 'mid-rest', 120, 240) },
      ]
      if (c2?.length) steps.push(...arpSteps(c2, seed, 'second', 'syncopated'))
      else steps.push({ kind: 'chord', midis: c1, ms: pickInt(seed, 'final-block', 500, 800), vel: v })
      return steps
    }

    case 'sparse': {
      const pick1 = c1[pickInt(seed, 's0', 0, c1.length - 1)]
      const pick2 = c1[pickInt(seed, 's1', 0, c1.length - 1)]
      return [
        { kind: 'note', midi: pick1, ms: pickInt(seed, 's-ms1', 400, 700), vel: v * 0.85 },
        { kind: 'rest', ms: pickInt(seed, 's-rest', 200, 400) },
        { kind: 'note', midi: pick2, ms: pickInt(seed, 's-ms2', 300, 600), vel: v },
        ...(c1.length > 2
          ? [{ kind: 'chord' as const, midis: c1, ms: pickInt(seed, 's-chord', 500, 900), vel: v * 0.75 }]
          : []),
      ]
    }

    default:
      return arpSteps(c1, seed, 'default', 'up')
  }
}

/** Full load-time demo phrase for this instrument (stable per demo id). */
export function demoPhraseFor(h: DemoArpeggioHints): DemoPhraseStep[] {
  const seed = demoSeed(h)
  const family = detectFamily(h)
  const { c1, c2 } = resolveChords(h)
  const pattern = pick(FAMILY_PATTERNS[family], seed, 'pattern')
  return buildPattern(pattern, c1, c2, seed)
}

/** All MIDI notes referenced by a phrase (for note-off cleanup). */
export function phraseMidiNotes(steps: readonly DemoPhraseStep[]): number[] {
  const seen = new Set<number>()
  for (const step of steps) {
    if (step.kind === 'note' || step.kind === 'repeat') seen.add(step.midi)
    if (step.kind === 'chord') for (const m of step.midis) seen.add(m)
  }
  return [...seen].sort((a, b) => a - b)
}

/** @deprecated Use demoPhraseFor — kept for callers that only need pitch lists. */
export function demoArpeggioNotesFor(h: DemoArpeggioHints): number[] {
  return phraseMidiNotes(demoPhraseFor(h))
}

export function allDemoArpeggioReleaseNotes(): number[] {
  const seen = new Set<number>()
  for (const o of Object.values(ID_CHORD_OVERRIDES)) {
    for (const n of o.c1) seen.add(n)
    if (o.c2) for (const n of o.c2) seen.add(n)
  }
  for (const recipe of Object.values(RECIPES)) {
    for (const root of recipe.roots) {
      for (const shape of [...recipe.chords, ...recipe.strange]) {
        for (const mode of ['closed', 'open', 'cluster', 'octaveStack'] as const) {
          for (const n of voicing(root, shape, mode)) seen.add(n)
        }
      }
    }
  }
  return [...seen].sort((a, b) => a - b)
}

export function arpeggioTag(midi: number): string {
  return `1.${midi.toString().padStart(3, '0')}`
}

function hzForMidi(midi: number): string {
  return (440 * 2 ** ((midi - 69) / 12)).toFixed(3)
}

async function startNote(
  emit: (line: string) => Promise<{ success?: boolean }>,
  midi: number,
  vel: number,
  isActive: () => boolean,
): Promise<boolean> {
  const tag = arpeggioTag(midi)
  for (let attempt = 0; attempt < 6; attempt++) {
    if (!isActive()) return false
    const r = await emit(`i ${tag} 0 -1 ${hzForMidi(midi)} ${vel.toFixed(3)}`)
    if (r?.success) return true
    await new Promise((r) => setTimeout(r, 80))
  }
  return false
}

async function stopNote(
  emit: (line: string) => Promise<{ success?: boolean }>,
  midi: number,
): Promise<void> {
  await emit(`i -${arpeggioTag(midi)} 0 0`).catch(() => {})
}

/** Play a rhythmic demo phrase through the live Csound stdin bus. */
export async function playDemoPhrase(
  steps: readonly DemoPhraseStep[],
  isActive: () => boolean,
  emit: (line: string) => Promise<{ success?: boolean }>,
): Promise<void> {
  for (const step of steps) {
    if (!isActive()) return

    if (step.kind === 'rest') {
      await new Promise((r) => setTimeout(r, step.ms))
      continue
    }

    const vel = step.vel ?? 0.55

    if (step.kind === 'note') {
      if (!(await startNote(emit, step.midi, vel, isActive))) return
      await new Promise((r) => setTimeout(r, step.ms))
      await stopNote(emit, step.midi)
      continue
    }

    if (step.kind === 'repeat') {
      for (let i = 0; i < step.times; i++) {
        if (!isActive()) return
        if (!(await startNote(emit, step.midi, vel, isActive))) return
        await new Promise((r) => setTimeout(r, step.ms))
        await stopNote(emit, step.midi)
        if (i < step.times - 1) await new Promise((r) => setTimeout(r, step.gapMs))
      }
      continue
    }

    if (step.kind === 'chord') {
      const started: number[] = []
      for (const midi of step.midis) {
        if (!isActive()) break
        if (await startNote(emit, midi, vel, isActive)) started.push(midi)
      }
      await new Promise((r) => setTimeout(r, step.ms))
      for (const midi of started) await stopNote(emit, midi)
    }
  }
}
