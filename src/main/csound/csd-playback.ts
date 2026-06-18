import { stripCsOptionsHandledByCli } from '../../shared/csd-offline-prepare'
import { ensureCsoundLimiterCsOptions } from '../../shared/csd-realtime-options'
import { csdHasRealtimeDacOptions } from '../../shared/csd-realtime-options'
import { type AudioIoConfig, audioOpensInput, readAudioIoConfig } from './audio-flags'

/** @deprecated Use csdHasRealtimeDacOptions */
export function csdHasRealtimeOutputOptions(csd: string): boolean {
  return csdHasRealtimeDacOptions(csd)
}

/** True when the score schedules timed note events (not keyboard-driven hold). */
export function csdHasScheduledDemoScore(csd: string): boolean {
  const m = csd.match(/<CsScore>([\s\S]*?)<\/CsScore>/i)
  if (!m) return false
  const score = m[1]
  // i 1 0 3 … demo notes; skip channel-writer (100) and reverb bus (99)
  return /\bi\s+(?!99\b|100\b)\d+\s+\S+\s+\S+/i.test(score)
}

/** True when CsOptions request offline/file render (Agent default). */
export function csdHasOfflineRenderOptions(csd: string): boolean {
  const m = csd.match(/<CsOptions>([\s\S]*?)<\/CsOptions>/i)
  if (!m) return false
  const opts = m[1]
  return /(?:^|\s)-o\s+\S+/m.test(opts) || /(?:^|\s)-n(?:\s|$)/m.test(opts)
}

const PLAYER_HOLD_SCORE = `<CsScore>
i 99 0 36000
f 0 36000
</CsScore>`

const KEYBOARD_HOLD_SCORE = `<CsScore>
f 0 36000
</CsScore>`

/**
 * Laptop-safe orchestra headers: stereo out (`nchnls = 2`) with mono built-in mic.
 * Csound defaults to matching input channels to output; inject `nchnls_i` when absent.
 */
export function ensureRealtimeChannelHeaders(csd: string, opensInput: boolean): string {
  if (/\bnchnls_i\s*=/i.test(csd)) return csd

  const nchnls_i = opensInput ? 1 : 0
  const nchnlsLine = csd.match(/\bnchnls\s*=\s*\d+[^\n]*\n/i)
  if (nchnlsLine) {
    return csd.replace(/\bnchnls\s*=\s*\d+[^\n]*\n/i, `${nchnlsLine[0].trimEnd()}\nnchnls_i = ${nchnls_i}\n`)
  }

  const anchor = csd.match(/(\b(?:sr|ksmps|0dbfs)\s*=\s*[^\n]+\n)/i)
  if (anchor) {
    return csd.replace(anchor[0], `${anchor[0]}nchnls_i = ${nchnls_i}\n`)
  }

  return csd.replace(/<CsInstruments>\s*\n/i, `<CsInstruments>\nnchnls_i = ${nchnls_i}\n`)
}

/**
 * Strip offline Agent options and demo scores before Player realtime spawn.
 * Adapted CSDs often pass needsPlayerAdapt (chn_k + instr 100) but still carry
 * `-o /tmp/drc.wav` and a 12 s demo score — csound then renders to disk instead
 * of opening dac, and the 12 s startup timer fires with no keyboard audio.
 */
export function prepareCsdForRealtimePlay(csd: string, cfg: AudioIoConfig = readAudioIoConfig()): string {
  // Realtime dac via CLI (`-o dac -d -m0 -Lstdin`); strip duplicates from <CsOptions>.
  let s = ensureCsoundLimiterCsOptions(csd)
  s = stripCsOptionsHandledByCli(s)
  // Player sends tagged i-statements via stdin — strip native MIDI routing from adapted models.
  s = s.replace(/^\s*massign[^\n]*\n/gim, '')
  s = ensureRealtimeChannelHeaders(s, audioOpensInput(cfg))

  const hasReverbBus = /\binstr\s+99\b/.test(s)
  const hasChannelWriter = /\binstr\s+100\b/.test(s)
  const hasKeyboardVoice =
    /\binstr\s+1\b[\s\S]*?\bp4\b/.test(s) ||
    /\binstr\s+1\b[\s\S]*?cpsmidinn/i.test(s)

  const needsHoldScore =
    csdHasScheduledDemoScore(s) ||
    (hasKeyboardVoice && hasChannelWriter && !/\bf\s+0\s+\d{3,}\b/i.test(s))

  if (needsHoldScore) {
    if (hasReverbBus) {
      s = s.replace(/<CsScore>[\s\S]*?<\/CsScore>/i, PLAYER_HOLD_SCORE)
    } else if (hasKeyboardVoice) {
      s = s.replace(/<CsScore>[\s\S]*?<\/CsScore>/i, KEYBOARD_HOLD_SCORE)
    }
  }

  return s
}

/** Lines in csound stderr/stdout that mean realtime dac is open (not end-of-score). */
export function csoundOutputIndicatesRealtimeReady(text: string): boolean {
  return (
    /scoreless operation/i.test(text) ||
    /End of score|SECTION 1:/i.test(text) ||
    /writing \d+ sample blks of .+ to dac/i.test(text) ||
    /using callback interface|audio buffered in|rtaudio.*enabled|real ?time audio/i.test(text) ||
    /auhal:/i.test(text) ||
    /\d+:\s*dac\d+/i.test(text)
  )
}
