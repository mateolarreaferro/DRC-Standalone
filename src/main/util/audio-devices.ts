import { execFile } from 'child_process'
import { withCsoundPath } from './csound-path'
import { getCsoundEnvironment } from './csound-version'

// Csound 7 on macOS defaults to auhal; device indices from portaudio --devices
// do NOT match -odacN under auhal (silent/wrong output). Use one module everywhere.
export function realtimeAudioModule(): string {
  if (process.platform === 'darwin' && getCsoundEnvironment().major === 7) return 'auhal'
  return 'portaudio'
}

export function realtimeAudioFlag(): string {
  return `-+rtaudio=${realtimeAudioModule()}`
}

// Enumerate the audio + MIDI devices csound can see, by parsing `csound --devices`.
// The indices csound prints here are exactly what the `-odacN` / `-iadcN` / `-MN`
// flags expect — so selecting a device in Settings and passing its index back is a
// stable round-trip. We deliberately use csound's own view rather than CoreAudio
// directly: it guarantees the index we store is the one the play engine honors.

export interface AudioDevice {
  index: number // csound device index — used as -odacN / -iadcN
  id: string // e.g. "dac1" / "adc0"
  name: string // friendly name, e.g. "MacBook Pro Speakers"
}

export interface DeviceList {
  outputs: AudioDevice[]
  inputs: AudioDevice[]
  midiInputs: AudioDevice[]
}

function runAudio(args: string[]): Promise<string> {
  return new Promise((resolve) => {
    execFile('csound', [realtimeAudioFlag(), ...args], { timeout: 8000, env: withCsoundPath() }, (_err, stdout, stderr) => {
      resolve(`${stdout}\n${stderr}`)
    })
  })
}

function runRaw(args: string[]): Promise<string> {
  return new Promise((resolve) => {
    execFile('csound', args, { timeout: 8000, env: withCsoundPath() }, (_err, stdout, stderr) => {
      resolve(`${stdout}\n${stderr}`)
    })
  })
}

function stripAnsi(s: string): string {
  // eslint-disable-next-line no-control-regex
  return s.replace(/\x1b\[[0-9;]*m/g, '')
}

// Lines look like: " 1: dac1 (MacBook Pro Speakers [Core Audio, 0 in, 2 out]) [ch:2]"
// or for MIDI:      " 0: In Name"
function parseDeviceLine(line: string): AudioDevice | null {
  const m = line.match(/^\s*(\d+):\s*(\S+)\s*(.*)$/)
  if (!m) return null
  const index = parseInt(m[1], 10)
  const id = m[2]
  let rest = m[3].trim()
  // Prefer the friendly name inside the first parentheses, before the [Core Audio…]
  const paren = rest.match(/^\(([^[\]]+?)\s*(?:\[|\))/)
  const name = (paren ? paren[1] : rest).replace(/[()]/g, '').trim() || id
  return { index, id, name }
}

export async function listAudioDevices(): Promise<DeviceList> {
  const audioRaw = stripAnsi(await runAudio(['--devices']))
  const midiRaw = stripAnsi(await runRaw(['-+rtmidi=portmidi', '--midi-devices']))

  const outputs: AudioDevice[] = []
  const inputs: AudioDevice[] = []
  let section: 'in' | 'out' | null = null
  for (const line of audioRaw.split('\n')) {
    if (/audio input devices/i.test(line)) { section = 'in'; continue }
    if (/audio output devices/i.test(line)) { section = 'out'; continue }
    if (!section) continue
    const dev = parseDeviceLine(line)
    if (!dev) continue
    if (section === 'in' && /^adc/i.test(dev.id)) inputs.push(dev)
    if (section === 'out' && /^dac/i.test(dev.id)) outputs.push(dev)
  }

  // MIDI lines have no dac/adc id token (e.g. " 0: IAC Driver Bus 1"), so take the
  // index and treat the entire remainder as the name.
  const midiInputs: AudioDevice[] = []
  let inMidiIn = false
  for (const line of midiRaw.split('\n')) {
    if (/MIDI input devices/i.test(line)) { inMidiIn = true; continue }
    if (/MIDI output devices/i.test(line)) { inMidiIn = false; continue }
    if (!inMidiIn) continue
    const m = line.match(/^\s*(\d+):\s*(.+?)\s*$/)
    if (m) midiInputs.push({ index: parseInt(m[1], 10), id: `midi${m[1]}`, name: m[2] })
  }

  return { outputs, inputs, midiInputs }
}

/** Map Settings list index → csound `-o` token (e.g. index 0 → `dac1`, not `dac0`). */
export function resolveDacOutputArg(indexStr: string, outputs: AudioDevice[]): string {
  const dev = outputs.find((d) => String(d.index) === indexStr)
  if (dev?.id && /^dac/i.test(dev.id) && dev.name.trim() && !isPoorDefaultOutput(dev)) return dev.id
  return resolveDefaultDacOutputArg(outputs)
}

/** Map Settings list index → csound input flag (e.g. index 0 → `-iadc1`). */
export function resolveAdcInputFlag(indexStr: string, inputs: AudioDevice[]): string {
  const dev = inputs.find((d) => String(d.index) === indexStr)
  if (dev?.id && /^adc/i.test(dev.id)) return `-i${dev.id}`
  const n = parseInt(indexStr, 10)
  return Number.isFinite(n) ? `-iadc${n + 1}` : '-iadc'
}

/** Skip virtual/loopback devices when picking a sensible default output. */
export function isPoorDefaultOutput(dev: AudioDevice): boolean {
  const blob = `${dev.id} ${dev.name}`.toLowerCase()
  if (!dev.name.trim()) return true
  return (
    /blackhole|soundflower|loopback|vb-?audio|virtual desktop|screen recording|landr sessions|zoomaudio|aggregate|multi[- ]output/i.test(
      blob,
    )
  )
}

function listDacOutputs(outputs: AudioDevice[]): AudioDevice[] {
  return outputs.filter((d) => /^dac/i.test(d.id))
}

/**
 * Best physical output for workshop Player — Mac speakers, then headphones/AirPods,
 * then any non-virtual dac. Never BlackHole / Zoom / loopback.
 */
export function findPreferredDefaultOutput(outputs: AudioDevice[]): AudioDevice | null {
  const dacs = listDacOutputs(outputs)
  if (!dacs.length) return null

  const tiers: Array<(d: AudioDevice) => boolean> = [
    (d) => /macbook.*speaker|built-?in.*speaker/i.test(d.name),
    (d) => /airpod|beats|powerbeats/i.test(d.name),
    (d) => /headphone|speakers?/i.test(d.name),
    (d) => /usb|hdmi|display|external/i.test(d.name),
    () => true,
  ]

  for (const match of tiers) {
    const dev = dacs.find((d) => match(d) && !isPoorDefaultOutput(d))
    if (dev) return dev
  }
  return null
}

/** Clear stale or virtual saved indices; empty string = Auto (resolved at play time only). */
export function resolveStoredOutputIndex(indexStr: string, outputs: AudioDevice[]): string {
  if (!indexStr) return ''
  if (/^\d+$/.test(indexStr)) {
    const dev = outputs.find((d) => String(d.index) === indexStr)
    if (dev && !isPoorDefaultOutput(dev)) return indexStr
  }
  return ''
}

/**
 * When Settings output is "system default", csound's bare `-o dac` often follows macOS
 * routing to BlackHole / Zoom. Always pick an explicit physical `dacN` when possible.
 */
export function resolveDefaultDacOutputArg(outputs: AudioDevice[]): string {
  const pref = findPreferredDefaultOutput(outputs)
  if (pref) return pref.id
  return 'dac'
}

export function outputLabelForIndex(indexStr: string, outputs: AudioDevice[]): string {
  if (!indexStr) return 'system default'
  const dev = outputs.find((d) => String(d.index) === indexStr)
  return dev ? `${dev.name} (${dev.id})` : `index ${indexStr}`
}

/** Best-effort Mac speakers index for workshop playback. */
export function findMacSpeakersIndex(outputs: AudioDevice[]): number | null {
  const mac = outputs.find((d) => /macbook.*speaker|built-?in.*speaker/i.test(d.name))
  return mac?.index ?? null
}
