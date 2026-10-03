/**
 * Agent preview: offline WAV render must have timed i-statements.
 * Player hold scores (f 0 36000) compile-check OK but render silence.
 */

import { ensureCsoundLimiterCsOptions } from './csd-realtime-options'

export function csdHasScheduledDemoScore(csd: string): boolean {
  const m = csd.match(/<CsScore>([\s\S]*?)<\/CsScore>/i)
  if (!m) return false
  return /\bi\s+(?!99\b|100\b)\d+\s+\S+\s+\S+/i.test(m[1])
}

export function needsHoldScoreShortening(csd: string): boolean {
  return /\bf\s+0\s+\d{3,}\b/i.test(csd) || /\bi\s+\d+\s+0\s+\d{3,}\b/i.test(csd)
}

export function shortenHoldScoreForCompile(csd: string): string {
  return csd.replace(/<CsScore>([\s\S]*?)<\/CsScore>/i, (_, score: string) => {
    let s = score
    s = s.replace(/\bf\s+0\s+(\d{3,})\b/gi, 'f 0 1')
    s = s.replace(/\bi\s+(\d+)\s+0\s+(\d{3,})\b/gi, 'i $1 0 1')
    return `<CsScore>${s}</CsScore>`
  })
}

/** ~10 s bass riff + echo bus — matches pluck_bass_starter pattern. */
export const BASS_OFFLINE_DEMO_SCORE = `<CsScore>
i 99 0 10
i 1 0   1.5 36 0.6
i 1 1   1.5 43 0.55
i 1 2   1.5 48 0.5
i 1 3   2.0 36 0.55
</CsScore>`

/** Descending bell melody — matches fm_bell_starter (MIDI p4 + cpsmidinn). */
export const BELL_OFFLINE_DEMO_SCORE = `<CsScore>
i 99 0 18
i 1 0   4.5  72 0.5 0.5
i 1 1.5 4.0  69 0.4 0.5
i 1 3   3.5  67 0.45 0.5
i 1 4.5 5.0  64 0.5 0.6
i 1 6   4.5  60 0.55 0.6
i 1 8   5.0  67 0.35 0.5
i 1 8.1 5.0  71 0.3  0.5
i 1 8.2 5.0  74 0.32 0.5
i 1 12  6.0  48 0.6 0.7
</CsScore>`

/** Chowning-style models use p4 as Hz — never inject MIDI note numbers (60 reads as 60 Hz bass). */
export const CHOWNING_HZ_DEMO_SCORE = `<CsScore>
i 99 0 14
i 1 0   4.5  523.25 0.5
i 1 1.5 4.0  440 0.45
i 1 3   3.5  392 0.45
i 1 4.5 5.0  349.23 0.5
i 1 6   4.5  293.66 0.55
i 1 8   5.0  392 0.35
i 1 8.1 5.0  440 0.3
i 1 8.2 5.0  493.88 0.32
</CsScore>`

export const GENERIC_OFFLINE_DEMO_SCORE = `<CsScore>
i 1 0.00 0.45 60 0.22
i 1 0.45 0.45 64 0.22
i 1 0.90 0.45 67 0.22
i 1 1.35 0.45 72 0.24
i 1 2.50 0.35 60 0.24
i 1 2.85 0.35 64 0.24
i 1 3.20 0.35 67 0.24
i 1 3.55 0.35 71 0.24
i 1 4.50 0.20 67 0.20
i 1 4.70 0.20 64 0.20
i 1 4.90 0.20 67 0.20
i 1 5.10 0.20 72 0.20
i 1 6.00 2.00 60 0.18
i 1 6.00 2.00 64 0.16
i 1 6.00 2.00 67 0.14
i 1 6.00 2.00 72 0.12
</CsScore>`

/** Flags the app passes on the csound CLI — duplicates in <CsOptions> make Csound 7 bail with "too many arguments". */
const CLI_HANDLED_CSOPTIONS = [
  /^-n\b/,
  /^-o\s+\S+/,
  /^-odac/,
  /^-iadc/,
  /^-d\b/,
  /^-m\d+/,
  /^-W\b/,
  /^-\+\s*rtaudio/,
  /^-\+\s*rtmidi/,
  /^-M\d+/,
  /^--limiter(?:=\S+)?$/,
]

export function stripCsOptionsHandledByCli(csd: string): string {
  let s = csd
  if (!/<CsOptions>/i.test(s)) return s
  s = s.replace(/<CsOptions>([\s\S]*?)<\/CsOptions>/i, (_, body: string) => {
    const lines = body
      .split('\n')
      .map((l) => l.trim())
      .filter(Boolean)
      .filter((l) => !CLI_HANDLED_CSOPTIONS.some((re) => re.test(l)))
    if (lines.length === 0) return ''
    return `<CsOptions>\n${lines.join('\n')}\n</CsOptions>`
  })
  return s.replace(/<CsOptions>\s*<\/CsOptions>\s*/gi, '')
}

function orchestraNeedsEchoBus(csd: string): boolean {
  const orch = csd.match(/<CsInstruments>([\s\S]*?)<\/CsInstruments>/i)?.[1] ?? ''
  return /\binstr\s+99\b/.test(orch) && /\b(gaEcho|vdelay3)\b/.test(orch)
}

export function orchestraUsesMidiPitch(csd: string): boolean {
  const orch = csd.match(/<CsInstruments>([\s\S]*?)<\/CsInstruments>/i)?.[1] ?? ''
  return (
    /\bcpsmidinn\s*\(\s*p4\s*\)/i.test(orch) ||
    /\bcpsmidi\s*\(/i.test(orch) ||
    /\bampmidi\b/i.test(orch) ||
    /\bmassign\b/i.test(orch)
  )
}

export function orchestraIsShimmerBell(csd: string): boolean {
  const orch = csd.match(/<CsInstruments>([\s\S]*?)<\/CsInstruments>/i)?.[1] ?? ''
  return /\bkMod1Idx\b/.test(orch) && /\bkMod2Idx\b/.test(orch) && /\boscili\b/i.test(orch)
}

function pickOfflineDemoScore(csd: string): string {
  if (orchestraIsShimmerBell(csd)) return BELL_OFFLINE_DEMO_SCORE
  if (orchestraNeedsEchoBus(csd)) return BASS_OFFLINE_DEMO_SCORE
  if (!orchestraUsesMidiPitch(csd)) return CHOWNING_HZ_DEMO_SCORE
  return GENERIC_OFFLINE_DEMO_SCORE
}

/** Prepare Agent CSD for offline WAV preview (afplay / file render). */
export function prepareCsdForOfflineRender(csd: string): string {
  let s = ensureCsoundLimiterCsOptions(csd.trim())
  s = stripCsOptionsHandledByCli(s)
  const hasVoice = /\binstr\s+1\b/.test(s)
  const hasDemo = csdHasScheduledDemoScore(s)

  if (hasVoice && !hasDemo) {
    const score = pickOfflineDemoScore(s)
    if (/<CsScore>[\s\S]*?<\/CsScore>/i.test(s)) {
      s = s.replace(/<CsScore>[\s\S]*?<\/CsScore>/i, score)
    } else {
      s = s.replace(/<\/CsoundSynthesizer>/i, `${score}\n</CsoundSynthesizer>`)
    }
  } else if (needsHoldScoreShortening(s)) {
    s = shortenHoldScoreForCompile(s)
  }

  return s
}

export function renderOutputWasSilent(combinedOutput: string): boolean {
  return /overall amps:\s+0\.0+\s+0\.0+/i.test(combinedOutput)
}
