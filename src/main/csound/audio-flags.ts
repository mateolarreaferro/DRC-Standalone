import { getConfigValue } from '../util/config'
import { AUDIO_INPUT_OFF } from '../ipc/config-keys'
import {
  type AudioDevice,
  realtimeAudioFlag,
  resolveAdcInputFlag,
  resolveDacOutputArg,
  resolveDefaultDacOutputArg,
  outputLabelForIndex,
} from '../util/audio-devices'
import { CSOUND_OUTPUT_LIMITER, csoundLimiterCsOptionsLine } from '../../shared/csd-realtime-options'

export interface AudioIoConfig {
  output: string
  input: string
  midiInput: string
}

/** @deprecated Use CSOUND_OUTPUT_LIMITER from shared/csd-realtime-options */
export { CSOUND_OUTPUT_LIMITER }

export function csoundLimiterCliFlag(ceiling = CSOUND_OUTPUT_LIMITER): string {
  return csoundLimiterCsOptionsLine(ceiling)
}

export interface AudioDeviceContext {
  outputs: AudioDevice[]
  inputs: AudioDevice[]
}

export function readAudioIoConfig(): AudioIoConfig {
  const rawInput = (getConfigValue('audioInputDevice') ?? '').trim()
  return {
    output: (getConfigValue('audioOutputDevice') ?? '').trim(),
    input: rawInput === '' ? AUDIO_INPUT_OFF : rawInput,
    midiInput: (getConfigValue('midiInputDevice') ?? '').trim(),
  }
}

/** True when Player realtime spawn will pass `-iadc` / `-iadcN` (mic or interface input). */
export function audioOpensInput(cfg: Pick<AudioIoConfig, 'input'>): boolean {
  const input = (cfg.input ?? '').trim()
  return Boolean(input && input !== AUDIO_INPUT_OFF)
}

export interface RealtimeIoOptions {
  /**
   * Player routes USB MIDI through Web MIDI → stdin score events only.
   * When true, csound does not open rtmidi (avoids dual MIDI paths and layered voices).
   */
  webMidiOnly?: boolean
}

/** Build csound CLI I/O flags. Pass device lists from `csound --devices` for correct `-o dacN`. */
export function buildRealtimeIoFlags(
  _csdPath: string,
  cfg = readAudioIoConfig(),
  devices: AudioDeviceContext = { outputs: [], inputs: [] },
  opts: RealtimeIoOptions = {},
): string[] {
  const flags: string[] = [realtimeAudioFlag()]

  if (/^\d+$/.test(cfg.output)) {
    flags.push('-o', resolveDacOutputArg(cfg.output, devices.outputs))
  } else {
    flags.push('-o', resolveDefaultDacOutputArg(devices.outputs))
  }

  if (!audioOpensInput(cfg)) {
    // no input
  } else if (/^\d+$/.test(cfg.input)) {
    flags.push(resolveAdcInputFlag(cfg.input, devices.inputs))
  } else {
    flags.push('-iadc')
  }

  if (opts.webMidiOnly) {
    // Explicitly disable Csound's native MIDI — USB keyboard is routed Web MIDI → stdin only.
    // Without this, PortMIDI defaults can leave a stale csound process receiving hardware MIDI
    // while the on-screen keyboard talks to a different stdin-driven instance.
    flags.push('-+rtmidi=NULL', '-M0')
  } else if (/^\d+$/.test(cfg.midiInput)) {
    flags.push('-+rtmidi=portmidi', `-M${cfg.midiInput}`)
  }

  flags.push(csoundLimiterCliFlag())

  return flags
}

/** True when Settings override CSD output (explicit dac index chosen). */
export function usesExplicitOutputDevice(cfg = readAudioIoConfig()): boolean {
  return /^\d+$/.test(cfg.output)
}

export function describeAudioRouting(
  _csdPath: string,
  cfg = readAudioIoConfig(),
  devices: AudioDeviceContext = { outputs: [], inputs: [] },
  opts: RealtimeIoOptions = {},
): string {
  const flags = buildRealtimeIoFlags(_csdPath, cfg, devices, opts)
  const parts: string[] = []
  if (/^\d+$/.test(cfg.output)) {
    parts.push(`output: ${outputLabelForIndex(cfg.output, devices.outputs)}`)
  } else {
    const dac = resolveDefaultDacOutputArg(devices.outputs)
    const dev = devices.outputs.find((d) => d.id === dac)
    parts.push(dev ? `output: ${dev.name} (${dev.id}, system default)` : 'output: system default (-o dac)')
  }
  if (!audioOpensInput(cfg)) parts.push('input: none')
  else if (/^\d+$/.test(cfg.input)) {
    const dev = devices.inputs.find((d) => String(d.index) === cfg.input)
    parts.push(dev ? `input: ${dev.name}` : `input adc${cfg.input}`)
  } else parts.push('input: system default')
  if (opts.webMidiOnly) parts.push('MIDI: Web MIDI → stdin (-+rtmidi=NULL -M0)')
  else if (/^\d+$/.test(cfg.midiInput)) parts.push(`MIDI: rtmidi device ${cfg.midiInput}`)
  return `Audio: ${parts.join(', ')} → ${flags.join(' ')}`
}
