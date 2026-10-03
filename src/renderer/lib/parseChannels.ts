// Parse chn_k declarations from a CSD orchestra into a knob manifest.
//
// The Player UI used to hardcode 8 knobs (frequency / amplitude / modIndex / …)
// and the LLM rewrote every CSD to fit that mold. Now the LLM emits whatever
// knobs the patch needs as `chn_k` declarations and the host parses them into
// a dynamic ChannelSpec[] that drives the knob grid.
//
// The Csound chn_k signature (see csound.com/docs/manual/chn.html):
//
//   chn_k Sname, imode [, itype, idflt, imin, imax, ix, iy, iw, ih, Sattrs]
//
//     imode  : 1=input, 2=output, 3=both — we keep 1 and 3 (writable from host)
//     itype  : 0=default, 1=integer, 2=linear, 3=exponential
//     Sattrs : free-form metadata string. We expect "unit=Hz label=Cutoff step=1"
//
// Anything we can't parse with confidence falls back to a sane default rather
// than throwing, since a malformed knob is recoverable but a thrown parse kills
// the whole UI render.

export type ChannelCurve = 'lin' | 'exp' | 'int'

export interface ChannelSpec {
  name: string
  label: string
  min: number
  max: number
  default: number
  step: number
  unit: string
  curve: ChannelCurve
}

// Strip block / line comments inside the orchestra so a `; chn_k ...` doesn't
// trip the matcher. Keep everything else intact.
function stripComments(src: string): string {
  return src
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/;[^\n]*/g, '')
}

// Pull the orchestra body. If we can't find the section we just operate on the
// whole string — chn_k declarations only appear at orchestra scope so spurious
// matches outside <CsInstruments> are unlikely.
//
// Exported because the web harness reuses it verbatim as the `ORC` template
// literal (`compileOrc` wants the orchestra body, not the full CSD).
export function extractOrchestra(csd: string): string {
  const m = csd.match(/<CsInstruments>([\s\S]*?)<\/CsInstruments>/i)
  return m ? m[1].trim() : csd.trim()
}

// Decide whether a web-ready orchestra is keyboard-driven (shape A: instr 1 IS the
// voice the keyboard fires) vs an always-on texture (shape B: instr 1 runs on its
// own and the host must fire `i 1 0 -1`).
//
// The discriminator is whether `instr 1`'s OWN body reads p4 — not whether p4
// appears anywhere in the orchestra. A texture whose instr 1 is a scheduler
// (metro → schedkwhen) that fires a p4-based SUB-voice (instr 2) has p4 in the orc
// but NOT in instr 1; treating it as a keyboard patch left the scheduler unfired,
// so the whole patch was silent. Checking instr 1's body fixes that case while
// still detecting a true keyboard voice.
export function usesKeyboard(orc: string): boolean {
  const block = orc.match(/\binstr\s+1\b([\s\S]*?)\bendin\b/i)
  if (!block) return /\bp4\b/.test(orc) // no instr 1 — fall back to whole-orc scan
  return /\bp4\b/.test(block[1])
}

// Tokenize a chn_k argument list, keeping double-quoted strings intact. We
// can't just split on commas because Sattributes is a quoted string that may
// contain spaces.
function tokenize(args: string): string[] {
  const out: string[] = []
  let buf = ''
  let inStr = false
  for (let i = 0; i < args.length; i++) {
    const c = args[i]
    if (c === '"') {
      inStr = !inStr
      buf += c
      continue
    }
    if (c === ',' && !inStr) {
      out.push(buf.trim())
      buf = ''
      continue
    }
    buf += c
  }
  if (buf.trim()) out.push(buf.trim())
  return out
}

function unquote(s: string): string {
  return s.startsWith('"') && s.endsWith('"') ? s.slice(1, -1) : s
}

// Sattributes is freeform but we standardize on `key=value` pairs separated by
// whitespace: `unit=Hz label=Cutoff_Freq step=1`. Underscores in values become
// spaces (since Csound string literals don't support escaped quotes, we can't
// rely on quoted values inside the already-quoted Sattributes blob — and an
// LLM that tries `\"...\"` produces literal backslash-quote sequences).
function parseAttrs(raw: string): Record<string, string> {
  const out: Record<string, string> = {}
  if (!raw) return out
  // Strip any literal backslash-quote sequences a model may have leaked in —
  // they don't survive Csound's string parser cleanly and just confuse us.
  const cleaned = raw.replace(/\\"/g, '').replace(/\\\\/g, '')
  const re = /([a-zA-Z_][a-zA-Z0-9_]*)=(?:"([^"]*)"|(\S+))/g
  let m: RegExpExecArray | null
  while ((m = re.exec(cleaned))) {
    let val = m[2] ?? m[3] ?? ''
    // Underscores → spaces so `label=Reverb_Mix` reads as "Reverb Mix".
    val = val.replace(/_/g, ' ')
    out[m[1]] = val
  }
  return out
}

function curveFor(itype: number): ChannelCurve {
  if (itype === 1) return 'int'
  if (itype === 3) return 'exp'
  return 'lin'
}

// Reasonable step size given range + curve. Integer curves snap to 1, log
// sliders use a relative step so big-range knobs (20Hz..20kHz) feel right at
// the low end.
function defaultStep(min: number, max: number, curve: ChannelCurve): number {
  if (curve === 'int') return 1
  const range = Math.abs(max - min)
  if (range >= 1000) return 1
  if (range >= 100) return 0.1
  if (range >= 10) return 0.01
  return 0.001
}

// Pretty-print a camelCase channel name as a label when no explicit one was set.
// Handles all-caps prefixes like "fmIndex" → "Fm Index" and "FMIndex" → "FM Index"
// by inserting a space before any uppercase letter that *follows* lowercase OR
// precedes a lowercase letter.
function camelToTitle(name: string): string {
  if (!name) return name
  const spaced = name
    .replace(/([a-z0-9])([A-Z])/g, '$1 $2')
    .replace(/([A-Z])([A-Z][a-z])/g, '$1 $2')
    .replace(/[_-]+/g, ' ')
  return spaced.charAt(0).toUpperCase() + spaced.slice(1)
}

function clampChannelValue(min: number, max: number, v: number): number {
  return Math.min(max, Math.max(min, v))
}

/** Fallback spec for orchestra-header `chnset` lines (Fractal Explorer pattern). */
function specFromChnset(name: string, defaultVal: number): ChannelSpec | null {
  if (!name || !/^[A-Za-z_][A-Za-z0-9_]*$/.test(name)) return null
  if (!Number.isFinite(defaultVal)) return null

  const n = name.toLowerCase()
  const label = camelToTitle(name)

  if (/attack|att/.test(n)) {
    const min = 0.001
    const max = 2
    return {
      name,
      label,
      min,
      max,
      default: clampChannelValue(min, max, defaultVal),
      step: 0.001,
      unit: 's',
      curve: 'exp',
    }
  }
  if (/release|rel|decay/.test(n)) {
    const min = 0.01
    const max = 6
    return {
      name,
      label,
      min,
      max,
      default: clampChannelValue(min, max, defaultVal),
      step: 0.01,
      unit: 's',
      curve: 'exp',
    }
  }
  if ((/cutoff|freq|pitch/.test(n) && !/mix/.test(n)) || n === 'frequency') {
    const min = 20
    const max = 18000
    return {
      name,
      label,
      min,
      max,
      default: clampChannelValue(min, max, defaultVal),
      step: 1,
      unit: 'Hz',
      curve: 'exp',
    }
  }
  if (
    /volume|vol|mix|wet|dry|size|room|bright|depth|send|sustain|master|reverb|reson|index|mod|amp|level|gain/.test(
      n,
    )
  ) {
    const min = 0
    const max = 1
    return {
      name,
      label,
      min,
      max,
      default: clampChannelValue(min, max, defaultVal),
      step: 0.01,
      unit: '',
      curve: 'lin',
    }
  }

  const min = 0
  const max = defaultVal <= 1 ? 1 : Math.max(defaultVal * 2, 1)
  return {
    name,
    label,
    min,
    max,
    default: clampChannelValue(min, max, defaultVal),
    step: defaultStep(min, max, 'lin'),
    unit: '',
    curve: 'lin',
  }
}

export function parseChannels(csd: string): ChannelSpec[] {
  if (!csd) return []
  const orchestra = stripComments(extractOrchestra(csd))

  // Match `chn_k <args>` at the start of a logical line (allow leading whitespace).
  // The args portion runs until end-of-line — chn_k doesn't span lines in any
  // CSD I've seen, and Csound's parser doesn't support it anyway.
  const re = /^[ \t]*chn_k\s+([^\n]+)$/gm
  const found = new Map<string, ChannelSpec>()

  let m: RegExpExecArray | null
  while ((m = re.exec(orchestra))) {
    const tokens = tokenize(m[1])
    if (tokens.length < 2) continue

    const nameTok = tokens[0]
    const name = unquote(nameTok)
    if (!name || !/^[A-Za-z_][A-Za-z0-9_]*$/.test(name)) continue

    const imode = parseInt(tokens[1], 10)
    if (!Number.isFinite(imode)) continue
    // Only host-writable channels appear as knobs. mode 2 (output-only) is for
    // metering / readback and we don't render those yet.
    if (imode !== 1 && imode !== 3) continue

    const itype = tokens.length > 2 ? parseInt(tokens[2], 10) : 0
    const dflt  = tokens.length > 3 ? parseFloat(tokens[3]) : 0
    const imin  = tokens.length > 4 ? parseFloat(tokens[4]) : 0
    const imax  = tokens.length > 5 ? parseFloat(tokens[5]) : 1

    // Sattributes is the 11th argument (index 10 after the 5 numeric position
    // hints). Some declarations skip the position hints entirely — accept the
    // last quoted token as the attributes blob if anything later looks quoted.
    let attrsRaw = ''
    for (let i = tokens.length - 1; i >= 6; i--) {
      if (tokens[i].startsWith('"') && tokens[i].endsWith('"')) {
        attrsRaw = unquote(tokens[i])
        break
      }
    }
    const attrs = parseAttrs(attrsRaw)

    const min = Number.isFinite(imin) ? imin : 0
    const max = Number.isFinite(imax) && imax > min ? imax : min + 1
    const safeDflt = Math.min(Math.max(Number.isFinite(dflt) ? dflt : min, min), max)
    const curve = curveFor(itype)
    const step = attrs.step ? parseFloat(attrs.step) : defaultStep(min, max, curve)

    found.set(name, {
      name,
      label: attrs.label || camelToTitle(name),
      min,
      max,
      default: safeDflt,
      step: Number.isFinite(step) && step > 0 ? step : defaultStep(min, max, curve),
      unit: attrs.unit || '',
      curve,
    })
  }

  // Fractal Explorer and workshop starters often use chnset at orchestra scope
  // without chn_k metadata — synthesize sliders from those defaults.
  const chnsetRe = /^[ \t]*chnset\s+([^,\n]+)\s*,\s*(?:"([^"]+)"|'([^']+)')\s*$/gm
  while ((m = chnsetRe.exec(orchestra))) {
    const defaultVal = parseFloat(m[1])
    const name = m[2] ?? m[3]
    if (!name || found.has(name)) continue
    const spec = specFromChnset(name, defaultVal)
    if (spec) found.set(name, spec)
  }

  // Preserve declaration order — Csound treats chn_k as a one-shot init, so the
  // order we hit them is the order the user wrote them.
  return Array.from(found.values())
}

// Legacy fallback for CSDs that haven't been adapted to the new chn_k contract
// (or have been hand-written without metadata). Matches the channel set the old
// PLAYER_TEMPLATE used to emit so existing patches keep working.
export const LEGACY_CHANNELS: ChannelSpec[] = [
  { name: 'frequency',  label: 'Frequency',  min: 20,    max: 12000, default: 440,  step: 1,     unit: 'Hz', curve: 'exp' },
  { name: 'amplitude',  label: 'Amplitude',  min: 0,     max: 1,     default: 0.5,  step: 0.01,  unit: '',   curve: 'lin' },
  { name: 'modIndex',   label: 'Mod Index',  min: 0,     max: 20,    default: 8,    step: 0.1,   unit: '',   curve: 'lin' },
  { name: 'modRatio',   label: 'Mod Ratio',  min: 0.5,   max: 10,    default: 3.5,  step: 0.1,   unit: '',   curve: 'lin' },
  { name: 'attack',     label: 'Attack',     min: 0.001, max: 2,     default: 0.01, step: 0.001, unit: 's',  curve: 'exp' },
  { name: 'decay',      label: 'Decay',      min: 0.01,  max: 10,    default: 2,    step: 0.01,  unit: 's',  curve: 'exp' },
  { name: 'reverbMix',  label: 'Reverb Mix', min: 0,     max: 1,     default: 0.3,  step: 0.01,  unit: '',   curve: 'lin' },
  { name: 'reverbSize', label: 'Reverb Size',min: 0,     max: 1,     default: 0.8,  step: 0.01,  unit: '',   curve: 'lin' },
]
