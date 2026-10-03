/**
 * Mechanical fixes for LLM Cabbage conversions — Csound opcode syntax the model
 * often gets wrong even when the prompt is explicit.
 */

function extractOrchestraBody(csd: string): string {
  const m = csd.match(/<CsInstruments>([\s\S]*?)<\/CsInstruments>/i)
  return m ? m[1] : csd
}

/** `iFreq = cpsmidi` is a syntax error; output opcodes omit `=`. */
export function fixCabbageMidiOpcodeSyntax(orc: string): string {
  let b = orc
  b = b.replace(/^\s*(\w+)\s*=\s*(cpsmidi)\b([^\n;]*)/gim, '$1 $2$3')
  b = b.replace(/^\s*(\w+)\s*=\s*(ampmidi)\b([^\n;]*)/gim, '$1 $2$3')
  b = b.replace(/^\s*(\w+)\s*=\s*(cpsmidib)\b([^\n;]*)/gim, '$1 $2$3')
  return b
}

/**
 * expsegr/linsegr accept only i-rate time/value args. LLM output sometimes tags
 * literals with :c (k-rate) or assigns to k-vars while passing k-rate globals.
 */
export function fixCabbageEnvelopeRates(orc: string): string {
  let b = orc
  b = b.replace(
    /^\s*((?:k|i)(\w+))\s+(linsegr|expsegr|linenr|madsr)\s+([^\n]+)/gim,
    (full, outVar, _name, opcode, args) => {
      const cleaned = args.replace(/(\d+(?:\.\d+)?):c\b/g, '$1')
      if (cleaned !== args) {
        return full.replace(args, cleaned)
      }
      if (outVar.startsWith('k') && /\bk[A-Za-z]\w*\b/.test(args)) {
        return full.replace(outVar, `i${outVar.slice(1)}`)
      }
      return full
    },
  )
  return b
}

export function prepareOrchestraForCabbage(orc: string): string {
  return fixCabbageEnvelopeRates(fixCabbageMidiOpcodeSyntax(orc))
}

/** Full Cabbage CSD (with <Cabbage> header) ready to save or compile-check. */
export function prepareCsdForCabbage(csd: string): string {
  const trimmed = csd.trim()
  if (!/<CsInstruments>/i.test(trimmed)) return fixCabbageMidiOpcodeSyntax(trimmed)
  return trimmed.replace(/<CsInstruments>([\s\S]*?)<\/CsInstruments>/i, (_, orch: string) => {
    return `<CsInstruments>\n${prepareOrchestraForCabbage(orch)}\n</CsInstruments>`
  })
}
