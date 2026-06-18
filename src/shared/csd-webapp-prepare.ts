import { stripCsOptionsHandledByCli } from './csd-offline-prepare'
import { ensureCsoundLimiterCsOptions } from './csd-realtime-options'

/** Score-only lines the LLM sometimes pastes into <CsInstruments> (breaks compileOrc). */
function isMisplacedScoreLine(line: string): boolean {
  const t = line.trim()
  if (!t || t.startsWith(';')) return false
  if (/^f\s+0\s+\d+\s*;?$/i.test(t)) return true
  if (/^f\s+\d+\s+0\s+\d+/i.test(t)) return true
  if (/^i\s+\d+\s+[\d.-]+\s+[\d.-]+/i.test(t)) return true
  return false
}

function extractOrchestraBody(csd: string): string {
  const m = csd.match(/<CsInstruments>([\s\S]*?)<\/CsInstruments>/i)
  return m ? m[1] : csd
}

/** Strip Player stdin helper and misplaced score lines from the orchestra body. */
export function cleanOrchestraForWebapp(orc: string): string {
  let body = orc.replace(/\binstr\s+100\b[\s\S]*?endin\s*/gi, '')
  body = body
    .split('\n')
    .filter((line) => !isMisplacedScoreLine(line))
    .join('\n')
  return body.trim()
}

/**
 * Web keyboard sends p4 = Hz and p5 = velocity 0..1 (not MIDI note / 0..127).
 * Player wraps and LLM conversions often still read cpsmidinn(p4) / ampmidi — fix here.
 */
export function adaptOrchestraPitchVelocityForWebKeyboard(orc: string): string {
  let b = orc
  b = b.replace(/\bcpsmidinn\s*\(\s*p4\s*\)/gi, 'p4')
  b = b.replace(/\bcpsmidinn\s*\(\s*p5\s*\)/gi, 'p5')
  b = b.replace(/^\s*(\w+)\s+cpsmidinn\s+p4\b([^\n]*)/gim, '$1 = p4$2')
  b = b.replace(/^\s*(\w+)\s+cpsmidinn\s+p5\b([^\n]*)/gim, '$1 = p5$2')
  b = b.replace(/^\s*(\w+)\s+cpsmidi\b([^\n;]*)/gim, (full, varName, rest) =>
    /p4/.test(rest) ? `${varName.trim()} = p4` : full,
  )
  b = b.replace(/^\s*(\w+)\s+cpsmidib\s+\d+\b([^\n;]*)/gim, '$1 = p4$2')
  b = b.replace(/^\s*(\w+)\s+cpsmidib\s+p4\b([^\n;]*)/gim, '$1 = p4$2')
  b = b.replace(/^\s*iamp\s+ampmidi\s+([^\n;]+)/gim, 'iAmp = p5 * ($1)')
  b = b.replace(/^\s*ilevl\s+ampmidi\s+([^\n;]+)/gim, 'iAmp = p5 * ($1)')
  b = b.replace(/^\s*iveloc\s+ampmidi\s+([^\n;]+)/gim, 'iveloc = p5 * ($1)')
  b = b.replace(/^\s*(\w+)\s+ampmidi\s+([^\n;]+)/gim, '$1 = p5 * ($2)')
  b = b.replace(/\bp5\s*\/\s*127\b/g, 'p5')
  return b
}

/**
 * Starter / LLM orchestras that send reverb via p6 + gaRvbL/R — the web keyboard
 * only sends p4 (Hz) and p5 (vel), so p6 is always 0 and the reverb bus is silent.
 * Route send amount through a control channel instead (Fractal / Player pattern).
 */
export function adaptGaRvbReverbForWebapp(orc: string): string {
  if (/chnmix\s+\w+\s*,\s*"revL"/i.test(orc)) return orc
  if (!/\bgaRvb[LR]\b/.test(orc)) return orc

  let b = orc
  const usesP6Send = /^\s*iRvb\s*=\s*p6\s*$/gim.test(b) || /\*\s*iRvb\b/.test(b)
  if (!usesP6Send) return b

  if (!/\bchn_k\s+"reverbSend"/i.test(b) && !/\bchnset\s+[\d.]+\s*,\s*"reverbSend"/i.test(b)) {
    const inject =
      'chn_k "reverbSend", 3, 2, 0.5, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Send"\n' +
      'chnset 0.5, "reverbSend"\n'
    const hdr = b.match(/^((?:\s*(?:sr|ksmps|nchnls|0dbfs)\s*=[^\n]*\n)+)/i)
    b = hdr ? b.replace(hdr[1], hdr[1] + inject) : inject + b
  }

  b = b.replace(/^\s*iRvb\s*=\s*p6\s*$/gim, 'kSend portk(chnget("reverbSend"), 0.05)')
  b = b.replace(/\*\s*iRvb\b/g, '* kSend')

  // Ensure instr 99 reads live reverbMix (and optional masterVolume) at k-rate.
  b = b.replace(/chnget:k\s*\(\s*"([^"]+)"\s*\)/gi, 'chnget("$1")')

  return b
}

/** Orchestra body safe for @csound/browser compileOrc (no score lines, no instr 100). */
export function prepareOrchestraForWebapp(csd: string): string {
  return adaptGaRvbReverbForWebapp(
    adaptOrchestraPitchVelocityForWebKeyboard(
      cleanOrchestraForWebapp(extractOrchestraBody(csd)),
    ),
  )
}

const MINIMAL_WEBAPP_SCORE = `<CsScore>
f 0 1
</CsScore>`

/** Full CSD for compile-check before wrapping into HTML. */
export function prepareCsdForWebappCompile(csd: string): string {
  let s = ensureCsoundLimiterCsOptions(csd.trim())
  s = stripCsOptionsHandledByCli(s)
  s = s.replace(/<CsInstruments>([\s\S]*?)<\/CsInstruments>/i, (_, orch: string) => {
    return `<CsInstruments>\n${cleanOrchestraForWebapp(orch)}\n</CsInstruments>`
  })
  if (/<CsScore>[\s\S]*?<\/CsScore>/i.test(s)) {
    s = s.replace(/<CsScore>[\s\S]*?<\/CsScore>/i, MINIMAL_WEBAPP_SCORE)
  } else {
    s = s.replace(/<\/CsoundSynthesizer>/i, `${MINIMAL_WEBAPP_SCORE}\n</CsoundSynthesizer>`)
  }
  return s
}
