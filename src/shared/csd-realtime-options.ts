/** Default output ceiling — Csound `--limiter` CsOptions / CLI flag. */
export const CSOUND_OUTPUT_LIMITER = 0.9

export function csoundLimiterCsOptionsLine(ceiling = CSOUND_OUTPUT_LIMITER): string {
  return `--limiter=${ceiling}`
}

/** CsOptions block for realtime dac — CsoundQt, Player, and adapted instruments. */
export const REALTIME_CSOPTIONS = `<CsOptions>
-o dac
-d
${csoundLimiterCsOptionsLine()}
</CsOptions>`

/** True when <CsOptions> already targets realtime dac output. */
export function csdHasRealtimeDacOptions(csd: string): boolean {
  const m = csd.match(/<CsOptions>([\s\S]*?)<\/CsOptions>/i)
  if (!m) return false
  const opts = m[1]
  return (
    /(?:^|\s)-odac\d*(?:\s|$)/m.test(opts) ||
    /(?:^|\s)-o\s+dac\d*(?:\s|$)/m.test(opts)
  )
}

/** Inject `--limiter` into CsOptions when absent (protects speakers on live play). */
export function ensureCsoundLimiterCsOptions(
  csd: string,
  ceiling = CSOUND_OUTPUT_LIMITER,
): string {
  if (/(?:^|\s)--limiter(?:=\S+)?(?:\s|$)/im.test(csd)) return csd
  const line = csoundLimiterCsOptionsLine(ceiling)
  if (!/<CsOptions>/i.test(csd)) {
    return csd.replace(
      /<CsInstruments>/i,
      `<CsOptions>\n${line}\n</CsOptions>\n<CsInstruments>`,
    )
  }
  return csd.replace(/<CsOptions>([\s\S]*?)<\/CsOptions>/i, (_, body: string) => {
    const lines = body
      .split('\n')
      .map((l) => l.trim())
      .filter(Boolean)
    lines.push(line)
    return `<CsOptions>\n${lines.join('\n')}\n</CsOptions>`
  })
}

/**
 * Rewrite CsOptions for CsoundQt: `-o dac` so Run plays through speakers,
 * not `-o /tmp/drc.wav` from Agent offline preview.
 */
export function prepareCsdForCsoundQt(csd: string): string {
  let s = csd.trim()
  if (/<CsOptions>/i.test(s)) {
    s = s.replace(/<CsOptions>[\s\S]*?<\/CsOptions>/i, REALTIME_CSOPTIONS)
  } else {
    s = s.replace(/<CsInstruments>/i, `${REALTIME_CSOPTIONS}\n<CsInstruments>`)
  }
  return s
}
