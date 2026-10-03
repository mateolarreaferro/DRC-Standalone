import { existsSync, readFileSync } from 'fs'
import { join } from 'path'
import { findUserDemoPath } from './user-demos'

export interface WorkshopStarterMeta {
  id: string
  title: string
  filename: string
  /** Player-ready — no LLM adapt needed */
  playerReady?: boolean
  /** Shown in Player “Demos — No API Key Required” menu */
  playerDemo?: boolean
  demoGroup?: string
  demoOrder?: number
  description: string
}

function loadPlayerModelDemos(): WorkshopStarterMeta[] {
  const candidates = [
    join(__dirname, '../../resources/workshop-starters/player-model-demos.json'),
    join(__dirname, '../../../resources/workshop-starters/player-model-demos.json'),
    join(process.cwd(), 'resources/workshop-starters/player-model-demos.json'),
  ]
  for (const p of candidates) {
    if (!existsSync(p)) continue
    try {
      const raw = JSON.parse(readFileSync(p, 'utf-8')) as WorkshopStarterMeta[]
      return Array.isArray(raw) ? raw : []
    } catch {
      return []
    }
  }
  return []
}

function loadChowningPlayerDemos(): WorkshopStarterMeta[] {
  const candidates = [
    join(__dirname, '../../resources/workshop-starters/chowning-player-demos.json'),
    join(__dirname, '../../../resources/workshop-starters/chowning-player-demos.json'),
    join(process.cwd(), 'resources/workshop-starters/chowning-player-demos.json'),
  ]
  for (const p of candidates) {
    if (!existsSync(p)) continue
    try {
      const raw = JSON.parse(readFileSync(p, 'utf-8')) as WorkshopStarterMeta[]
      return Array.isArray(raw) ? raw : []
    } catch {
      return []
    }
  }
  return []
}

const MIDI_MODEL_DEMOS: WorkshopStarterMeta[] = [
  { id: 'model_moog', title: 'Moog Synth', filename: 'models/MoogSynth1V2.csd', playerDemo: true, demoGroup: 'MIDI Synths', demoOrder: 111, description: 'Dual VCO2 + moogvcf2 — from Models MIDI Synths collection' },
  { id: 'model_vco_moog', title: 'VCO + Moog Filter', filename: 'models/VCO+MoogFilterV2.csd', playerDemo: true, demoGroup: 'MIDI Synths', demoOrder: 112, description: 'VCO through moogvcf with filter envelope' },
  { id: 'model_fm_rand_pan', title: 'FM Lazer Gun', filename: 'models/FM+RandPan+Verb-Shradha_GaneshV2.csd', playerDemo: true, demoGroup: 'MIDI Synths', demoOrder: 114, description: 'FM laser-gun timbre with random pan and reverb send' },
  { id: 'model_random_timbre', title: 'Random Timbre + Pan', filename: 'models/RandomTimbre+Pan+VerbV2.csd', playerDemo: true, demoGroup: 'MIDI Synths', demoOrder: 115, description: 'Random timbre layers with stereo pan' },
  { id: 'model_henon_v1', title: 'ffitch Henon Marimba V1', filename: 'models/ffitch-HenonV1a.csd', playerDemo: true, demoGroup: 'ffitch Henon', demoOrder: 118, description: 'ffitch Henon marimba model — MIDI version 1' },
  { id: 'model_henon_v2', title: 'ffitch Henon Marimba V2', filename: 'models/ffitch-HenonV2a.csd', playerDemo: true, demoGroup: 'ffitch Henon', demoOrder: 119, description: 'ffitch Henon marimba model — MIDI version 2' },
  { id: 'model_henon_v3', title: 'ffitch Henon Marimba V3', filename: 'models/ffitch-HenonV3a.csd', playerDemo: true, demoGroup: 'ffitch Henon', demoOrder: 120, description: 'ffitch Henon marimba model — MIDI version 3' },
]

export const WORKSHOP_STARTERS: WorkshopStarterMeta[] = [
  {
    id: 'dr_c_thick_analog_bass',
    title: 'Thick Analog Bass',
    filename: 'models/dr_c/thick_analog_bass.csd',
    playerReady: true,
    playerDemo: true,
    demoGroup: 'Dr.C Models',
    demoOrder: 6,
    description: 'Dual saw + moogladder squelch bass — Dr.C workshop export',
  },
  {
    id: 'dr_c_fm_bell_reverb',
    title: 'FM Stick + Reverb',
    filename: 'models/dr_c/fm_bell_reverb.csd',
    playerReady: true,
    playerDemo: true,
    demoGroup: 'Dr.C Models',
    demoOrder: 7,
    description: 'Stereo FM stick/mallet with global reverb bus — Dr.C workshop export',
  },
  {
    id: 'player_fm_trumpet',
    title: 'FM Trombone',
    filename: 'player_fm_trumpet.csd',
    playerReady: true,
    playerDemo: true,
    demoGroup: 'Csound Models',
    demoOrder: 11,
    description: 'Chowning harmonic FM trombone — keyboard + knobs, no API key',
  },
  {
    id: 'player_fm_bell',
    title: 'FM-Bell',
    filename: 'player_fm_bell.csd',
    playerReady: true,
    playerDemo: true,
    demoGroup: 'Csound Models',
    demoOrder: 10,
    description: 'Shimmering dual-modulator FM bell — keyboard + knobs, no API key',
  },
  {
    id: 'player_trapped_blue',
    title: 'Trapped Blue',
    filename: 'player_trapped_blue.csd',
    playerReady: true,
    playerDemo: true,
    demoGroup: 'Trapped in Convert',
    demoOrder: 20,
    description: 'Gbuzz timbre from Trapped in Convert (1979)',
  },
  {
    id: 'player_trapped_sand',
    title: 'Trapped Sand',
    filename: 'player_trapped_sand.csd',
    playerReady: true,
    playerDemo: true,
    demoGroup: 'Trapped in Convert',
    demoOrder: 22,
    description: 'Layered wavetable voice from Trapped in Convert',
  },
  ...MIDI_MODEL_DEMOS,
  ...loadChowningPlayerDemos(),
  ...loadPlayerModelDemos(),
  {
    id: 'player_pluck_bass',
    title: 'Ping-pong Bass (Player)',
    filename: 'player_pluck_bass.csd',
    playerReady: true,
    description: 'FM pluck bass with ping-pong delay — keyboard + knobs, no API key',
  },
  {
    id: 'player_fm_starter',
    title: 'Simple FM (Player)',
    filename: 'player_fm_starter.csd',
    playerReady: true,
    description: 'Workshop B2 golden model — 2-operator foscili FM, keyboard + knobs, no API key',
  },
  {
    id: 'fm_trumpet',
    title: 'FM Trumpet (Agent score)',
    filename: 'fm_trumpet_starter.csd',
    description: 'Chowning-style FM trumpet / brass — Agent golden starter',
  },
  {
    id: 'fm_bell',
    title: 'FM Bell (Agent score)',
    filename: 'fm_bell_starter.csd',
    description: 'Shimmering FM bell with descending melody — Agent golden starter',
  },
  {
    id: 'pluck_bass',
    title: 'Ping-pong Bass (Agent score)',
    filename: 'pluck_bass_starter.csd',
    description: 'FM pluck bass with cross-fed vdelay3 echo — Agent golden starter',
  },
  {
    id: 'fm',
    title: 'FM Synth',
    filename: 'fm_starter.csd',
    description: 'Simple 2-op FM demo score',
  },
  {
    id: 'fm_woodblock',
    title: 'FM Woodblock',
    filename: 'fm_woodblock_starter.csd',
    description: 'Short percussive FM woodblock — Agent golden starter',
  },
  {
    id: 'fm_woodblock_midi',
    title: 'FM Woodblock MIDI',
    filename: 'fm_woodblock_midi_starter.csd',
    description: 'fmpercfl woodblock with massign + MIDI CsOptions — Agent golden starter',
  },
  {
    id: 'fm_piano_reverb',
    title: 'FM Piano + Reverb',
    filename: 'fm_piano_reverb_starter.csd',
    description: 'FM piano tone with global ga-bus reverb (workshop default for “FM piano with reverb”)',
  },
  {
    id: 'pad',
    title: 'Warm Pad',
    filename: 'pad_starter.csd',
    description: 'Sustained pad texture',
  },
]

function starterPaths(filename: string): string[] {
  return [
    join(__dirname, '../../resources/workshop-starters', filename),
    join(__dirname, '../../../resources/workshop-starters', filename),
    join(process.cwd(), 'resources/workshop-starters', filename),
  ]
}

export function findWorkshopStarterPath(filename: string): string | null {
  const userPath = findUserDemoPath(filename)
  if (userPath) return userPath
  for (const p of starterPaths(filename)) {
    if (existsSync(p)) return p
  }
  return null
}

export function readWorkshopStarter(filename: string): string | null {
  const path = findWorkshopStarterPath(filename)
  if (!path) return null
  try {
    return readFileSync(path, 'utf-8')
  } catch {
    return null
  }
}

export function listWorkshopStarters(): WorkshopStarterMeta[] {
  return WORKSHOP_STARTERS.filter((s) => findWorkshopStarterPath(s.filename) != null)
}

export function listPlayerDemos(): WorkshopStarterMeta[] {
  return WORKSHOP_STARTERS.filter((s) => s.playerDemo && findWorkshopStarterPath(s.filename) != null)
    .sort((a, b) => (a.demoOrder ?? 999) - (b.demoOrder ?? 999))
}
