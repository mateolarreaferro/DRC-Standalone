import { csoundLimiterCsOptionsLine } from '../../shared/csd-realtime-options'

export type ConvertTarget = 'webapp' | 'vst' | 'csd' | 'player'

const WEBAPP_TEMPLATE = `Convert the Csound project below into a web-ready orchestra CSD. DrC's web host builds the entire UI (controls, on/off, keyboard) deterministically from the \`chn_k\` declarations you emit — your ONLY job is the Csound. Do not write any HTML or JavaScript.

OUTPUT FORMAT (strict):
- Emit exactly ONE complete CSD: \`<CsoundSynthesizer>…</CsoundSynthesizer>\`.
- No <Cabbage>, no HTML, no JavaScript, no code fences, no prose.
- <CsOptions> is exactly:
-o dac
-d
${csoundLimiterCsOptionsLine()}

HOW THE WEB HOST USES YOUR CSD (so you emit the right thing):
- It compiles ONLY your <CsInstruments> body (via compileOrc) and DISCARDS <CsScore>. So every function table MUST be created with \`ftgen\` at orchestra scope — NEVER as a score \`f\` statement (score f-statements will not run).
- It builds one slider per \`chn_k\` declaration and writes values live with setControlChannel while audio runs. Responsive sliders depend on you reading channels k-rate INSIDE instruments (see rule 4).
- It provides the master Start/Stop and (for note-based patches) a keyboard. It fires your always-on instruments for you — do NOT pre-schedule them in the score.

ADAPTATION RULES — follow precisely:

1. **Preserve the source's character.** FM stays FM, a filter synth stays a filter synth, a granular texture keeps its grains. You are re-wiring, not re-composing.

2. **Declare every control with \`chn_k\` at orchestra scope** (top of <CsInstruments>, before any \`instr\`). Pick 4–10 controls that meaningfully shape THIS patch. Signature:

       chn_k "<channelName>", 3, <itype>, <dflt>, <min>, <max>, 0, 0, 0, 0, "unit=<unit> label=<Label>"

   - \`channelName\`: camelCase, unique (e.g. \`cutoff\`, \`fmIndex\`, \`grainDensity\`)
   - \`3\` = both (host writes, orchestra reads)
   - \`itype\`: 1 = integer, 2 = linear, 3 = exponential (use 3 for frequency / time / decibel ranges; 2 for mix/depth/ratio; 1 for discrete counts)
   - \`dflt\`, \`min\`, \`max\` = default and bounds
   - Trailing metadata string: label and unit are SINGLE tokens. Underscores become spaces in the UI. **DO NOT escape quotes inside the string** (Csound has no \\" escape); use an underscore for a space in a label.

   Examples (NO escaped quotes anywhere):

       chn_k "cutoff",     3, 3, 1200, 20,    18000, 0, 0, 0, 0, "unit=Hz label=Cutoff"
       chn_k "resonance",  3, 2, 0.3,  0,     1,     0, 0, 0, 0, "unit= label=Resonance"
       chn_k "fmIndex",    3, 2, 6,    0,     30,    0, 0, 0, 0, "unit= label=FM_Index"
       chn_k "attack",     3, 3, 0.01, 0.001, 2,     0, 0, 0, 0, "unit=s label=Attack"
       chn_k "release",    3, 3, 0.5,  0.01,  6,     0, 0, 0, 0, "unit=s label=Release"
       chn_k "reverbMix",  3, 2, 0.3,  0,     1,     0, 0, 0, 0, "unit= label=Reverb_Mix"

3. **Initialize each channel.** Right after the chn_k block, emit \`chnset <dflt>, "<name>"\` for every channel, using the same defaults you declared.

4. **Read channels INSIDE instrument bodies, never at global scope** (a global chnget runs once at init and returns 0 — that is the #1 cause of dead sliders). Port-smooth slow-moving knobs:

       instr 1
         kCut chnget "cutoff"
         kRes chnget "resonance"
         kCut port kCut, 0.02
         kRes port kRes, 0.02
         ; ... use kCut, kRes in the signal path

   Drop any \`gk<Name> init …\` knob globals from the source — they become \`chn_k\` + in-instrument \`chnget\` instead.

5. **Choose the patch shape:**

   **A. Note-based** (a played/melodic/percussive instrument) — \`instr 1\` is the voice:
   - \`p4\` = pitch in Hz (the keyboard delivers Hz; if the source used MIDI/cpspch, convert at the boundary). \`p5\` = velocity 0..1.
   - \`p3 = -1\`: notes are held and turned off by the host. Use a release-aware \`linsegr\` envelope.
   - **Envelope rates — CRITICAL.** \`linsegr\`, \`expsegr\`, \`linenr\`, \`madsr\` accept ONLY i-rate arguments — EVERY one: every time AND every breakpoint VALUE (attack, decay, **sustain level**, release). Read each of them via the i-rate form of chnget (output var starts with \`i\`). Read params you only use elsewhere in the signal path at k-rate:

         instr 1
           iAtt chnget "attack"
           iDec chnget "decay"
           iSus chnget "sustain"      ; the SUSTAIN LEVEL feeds linsegr, so read it i-rate
           iRel chnget "release"
           kAmp chnget "amplitude"    ; only multiplies the signal, so k-rate is fine
           kAmp port kAmp, 0.02
           iFreq = p4
           iVel  = p5
           kEnv linsegr 0, iAtt, 1, iDec, iSus, iRel, 0
           ; signal path uses kEnv * kAmp * iVel

     Passing ANY k-rate var to \`linsegr\`/\`expsegr\` (a k-rate sustain is the usual slip) causes "Unable to find opcode entry for 'linsegr' with matching argument types" and the WHOLE orchestra fails to compile — silent app. If a value goes into the envelope opcode, read it i-rate.

   **B. Continuous texture** (drone, granular cloud, generative pad, ambient bed) — \`instr 1\` runs always-on:
   - Do NOT reference \`p4\`. The host renders no keyboard and starts the instrument for you with \`i 1 0 -1\`.
   - Drive it entirely from \`chn_k\` controls (density, pitch center, filter, mix, etc.). Use a steady or self-evolving output; no note triggering.
   - Pick this shape whenever the source is fundamentally a texture rather than a played note.

6. **Optional reverb bus — \`instr 99\`** (always-on; the host fires \`i 99 0 -1\` if present). Voices send via \`chnmix\` to \`"revL"\`/\`"revR"\`:

       instr 99
         kMix  chnget "reverbMix"
         kSize chnget "reverbSize"
         aL chnget "revL"
         aR chnget "revR"
         awL, awR reverbsc aL, aR, kSize, 12000
         outs awL * kMix, awR * kMix
         chnclear "revL"
         chnclear "revR"
       endin

   Voices still \`outs\` their dry signal; reverb is additive. If the source had its own reverb, REPLACE it with this bus.

7. **Function tables**: create them all with \`ftgen\` in the orchestra (the score is discarded). Keep wavetables and init-time setup. Drop MIDI opcodes, OSC, and hard-coded score melodies.

8. **Score** — put this ONLY inside \`<CsScore>\`, never in \`<CsInstruments>\`. Score \`f\` / \`i\` lines in the orchestra cause a parser error (e.g. \`f 0 3600\`).

       <CsScore>
       f 0 1
       </CsScore>

9. **Quality bar**: compiles with stock Csound 6/7, renders stereo to \`-o dac\`, and is audible with default control values — a held key for shape A, or immediately after Start for shape B.

SOURCE CSD:
<<<SOURCE>>>

Emit the adapted CSD now.`

const VST_TEMPLATE = `Convert the Csound project below into a Cabbage VST/AU plugin.

OUTPUT FORMAT (strict):
- Emit exactly ONE CSD file with a <Cabbage>...</Cabbage> section directly BEFORE <CsoundSynthesizer>...</CsoundSynthesizer>.
- No code fences. No prose before or after.

CABBAGE LAYOUT:
- form caption("<Title>") size(620, 360) pluginId("Dcb1") guiMode("queue") colour(17,17,16)
  * \`pluginId(...)\` is MANDATORY and MUST be exactly 4 alphanumeric characters starting with a letter (e.g. \`Dcb1\`). An empty or missing pluginId — \`pluginId("")\` — makes the plugin invalid and Cabbage rejects it.
- groupbox bounds(10, 10, 600, 90) text("Controls") colour(30,30,28) fontColour(224,224,224)
- For every \`gk<Name> init <value>\` in the source, add an rslider inside the groupbox with:
    channel("<Name>") text("<Name>") trackerColour(124,184,164)
    range(<min>, <max>, <init>, 1, 0.001)
  Same range heuristics as a web UI: 0..1 if init is in [0,1]; 0..127 if init is in [0,127]; else [init*0.1, init*3].
  Lay out sliders left-to-right with 70px width and 10px gap.
- If the source uses p4 as a MIDI note, add: keyboard bounds(10, 110, 600, 160).

CSD CHANGES:
- Add <CsOptions> flags: -n -d -+rtmidi=NULL -M0
- **Read Cabbage controls at PERF-TIME, never at global scope.** A \`chnget\` written at global/orchestra scope is "perf-time code in global space" and is SILENTLY IGNORED by Csound — the sliders would do nothing and the plugin plays frozen/silent. So DO NOT add \`gk<Name> chnget\` lines next to the global \`init\`s. Instead:
  - Keep each existing \`gk<Name> init <value>\` line (it is the startup default).
  - Add ONE always-on reader instrument that refreshes every gk global each k-cycle:

        instr 1000   ; Cabbage control reader — always on
          gk<NameA> chnget "<NameA>"
          gk<NameB> chnget "<NameB>"
          ; ...one line per control channel
        endin

  - Activate it at orchestra scope (i-time, so this is allowed in global space) by adding, right after the gk \`init\` block: \`alwayson 1000\`
- **MIDI note input — the #1 cause of a silent Cabbage plugin.** The Cabbage \`keyboard\` widget (and the host) send notes to Csound as MIDI, NOT as score p-fields. A MIDI-activated instrument has p4 = p5 = 0, so any voice that reads pitch/velocity from p-fields plays note 0 at amplitude 0 → total silence. So when the voice is note-based (a keyboard was added):
  - Route MIDI to the voice: add \`massign 0, 1\` at orchestra scope (all channels → instr 1).
  - In \`instr 1\`, read pitch and velocity from MIDI, replacing any p4/p5 pitch/velocity reads from the source:

        instr 1
          iFreq cpsmidi        ; frequency of the played MIDI note (Hz)
          iVel  ampmidi 1      ; note velocity, 0..1
          ; ... the rest of the voice is unchanged; multiply the signal by iVel

  - **MIDI opcode syntax — CRITICAL.** \`cpsmidi\` and \`ampmidi\` are output opcodes: the variable name comes FIRST with NO equals sign. These are WRONG and will not compile:

        iFreq = cpsmidi      ; WRONG — syntax error in Csound 7
        iAmp  = ampmidi 1    ; WRONG

    Emit exactly:

        iFreq cpsmidi
        iVel  ampmidi 1

  - **Envelope rates — CRITICAL.** \`linsegr\`, \`expsegr\`, \`linenr\`, and \`madsr\` accept ONLY i-rate time and value arguments — every segment time AND every breakpoint level. Read any envelope parameter that feeds these opcodes with an \`i\`-prefixed variable (or a numeric literal). Do NOT pass \`gk…\` globals or \`k…\` variables into \`expsegr\`/\`linsegr\` — Csound 7 rejects k-rate args (e.g. \`ival1 is zero\` or opcode type mismatch). When the source used k-rate envelope math, snapshot the needed values at note-on into \`i…\` locals first, then call \`expsegr\`/\`linsegr\`. Do NOT suffix literals with \`:c\` on envelope opcode lines.
  - Keep the release-aware envelope (\`linsegr\`/\`expsegr\`) so MIDI note-off releases the tail cleanly.
  - Do NOT use \`cpsmidinn(p4)\`, \`= p4\`, or \`= p5\` for a MIDI voice — those are 0 under MIDI activation.
- Everything else in the CsInstruments and CsScore sections stays verbatim.

SOURCE CSD:
<<<SOURCE>>>

Emit the Cabbage CSD now.`

const CSD_TEMPLATE = `Extract the <CsoundSynthesizer>...</CsoundSynthesizer> from the project below as a standalone CSD.

OUTPUT FORMAT (strict):
- Emit ONLY the <CsoundSynthesizer>...</CsoundSynthesizer> block. No <Cabbage>. No HTML. No code fences. No prose.
- Keep <CsOptions> as \`-o dac\`, \`-d\`, and \`${csoundLimiterCsOptionsLine()}\` (remove MIDI or renderer flags).
- Keep all instruments and score events unchanged.

SOURCE:
<<<SOURCE>>>

Emit the CSD now.`

// The Player UI now reads its knob list from `chn_k` declarations in the
// adapted CSD instead of forcing a hardcoded 8-channel template. PLAYER_CHANNELS
// is kept around as a small set of *suggested* well-known names the model can
// reuse when the source patch maps cleanly onto them — but the model is free
// to add or omit any channel as long as each is declared with chn_k.
export const PLAYER_CHANNELS = [
  { name: 'amplitude',  default: 0.5,  range: '0..1',          role: 'output gain for the voice' },
  { name: 'attack',     default: 0.01, range: '0.001..2 s',    role: 'envelope attack time' },
  { name: 'release',    default: 0.5,  range: '0.01..6 s',     role: 'envelope release tail (linsegr)' },
  { name: 'reverbMix',  default: 0.3,  range: '0..1',          role: 'wet reverb level on the master bus' },
  { name: 'reverbSize', default: 0.8,  range: '0..1',          role: 'reverb feedback / room size' },
] as const

const PLAYER_TEMPLATE = `Adapt the Csound project below so it runs in the DrC Player.

The Player renders a piano keyboard (MIDI 48..72 / C3..C5) and a knob grid that is built dynamically from your \`chn_k\` declarations. The keyboard sustains notes for as long as a key is held: noteOn dispatches \`i 1.NNN 0 -1 <freq> <vel>\` and noteOff dispatches \`i -1.NNN 0 0\` (turnoff for that tagged instance). Your voice MUST use a release-aware envelope (\`linsegr\`) so the tail completes after turnoff.

The host writes knob values via score events: \`i 100 0 0 "<channelName>" <value>\`.

OUTPUT FORMAT (strict):
- Emit exactly ONE complete CSD: \`<CsoundSynthesizer>…</CsoundSynthesizer>\`.
- No <Cabbage>, no HTML, no code fences, no prose.
- <CsOptions> is exactly:
-o dac
-d
${csoundLimiterCsOptionsLine()}

ADAPTATION RULES — follow precisely:

1. **Preserve the source's character.** If the source is an FM voice, keep FM; a filter synth, keep the filter; a granular texture, keep the grains. Your job is re-wiring, not re-composing.

2. **Declare every knob with \`chn_k\` at orchestra scope (top of <CsInstruments>, before any \`instr\`).** Pick 4–10 knobs that meaningfully shape THIS patch. Each declaration MUST follow:

       chn_k "<channelName>", 3, <itype>, <dflt>, <min>, <max>, 0, 0, 0, 0, "unit=<unit> label=<Label>"

   Where:
   - \`channelName\` is camelCase and unique (e.g. \`cutoff\`, \`fmIndex\`, \`grainDensity\`)
   - \`3\` = both input + output (host writes, orchestra reads)
   - \`itype\`: 1 = integer, 2 = linear, 3 = exponential (use 3 for frequency / time / decibel-ish ranges; 2 for mix/depth/ratio; 1 for discrete counts)
   - \`dflt\`, \`min\`, \`max\` = the default and bounds the knob will use
   - The trailing string is metadata. The label and unit are SINGLE tokens — the host auto-prettifies camelCase, and converts underscores to spaces. **DO NOT escape quotes inside the string** (Csound string literals do not support \`\\"\`); if the label needs a space, use an underscore.

   Examples (note: NO escaped quotes anywhere):

       chn_k "cutoff",      3, 3, 1200, 20,    18000,  0, 0, 0, 0, "unit=Hz label=Cutoff"
       chn_k "resonance",   3, 2, 0.3,  0,     1,      0, 0, 0, 0, "unit= label=Resonance"
       chn_k "fmIndex",     3, 2, 6,    0,     30,     0, 0, 0, 0, "unit= label=FM_Index"
       chn_k "attack",      3, 3, 0.01, 0.001, 2,      0, 0, 0, 0, "unit=s label=Attack"
       chn_k "release",     3, 3, 0.5,  0.01,  6,      0, 0, 0, 0, "unit=s label=Release"
       chn_k "reverbMix",   3, 2, 0.3,  0,     1,      0, 0, 0, 0, "unit= label=Reverb_Mix"
       chn_k "reverbSize",  3, 2, 0.8,  0,     1,      0, 0, 0, 0, "unit= label=Reverb_Size"

   Any source parameter that doesn't map cleanly to a well-known name should still be exposed under whatever name fits the patch — invent a name, don't drop the knob.

3. **Initialize each channel.** Right after the chn_k block, emit \`chnset <dflt>, "<name>"\` for every channel using the same defaults you declared. This guarantees the first k-cycle reads sensible values.

4. **Read channels INSIDE each instrument body**, never at global scope (global chnget runs once at init and returns 0). Pattern:

       instr 1
         kCut  chnget "cutoff"
         kRes  chnget "resonance"
         kCut  port  kCut, 0.02      ; smoothing for slow-moving knobs
         kRes  port  kRes, 0.02
         ; ... use kCut, kRes in signal path

5. **Voice instrument contract — \`instr 1\`.**
   - \`p4\` is pitch in Hz delivered by the keyboard. If the source originally used MIDI note numbers or cpspch, convert at the boundary so the body still operates on Hz.
   - \`p5\` is normalized velocity (0..1).
   - \`p3 = -1\` for keyboard-triggered notes (the host turns them off via \`i -1.NNN\`). DO NOT reach for p3 arithmetic for envelope timing — the envelope is release-aware.
   - **Envelope rates — CRITICAL.** \`linsegr\` only accepts **i-rate** time/value arguments. You MUST read envelope parameters at i-rate via the i-rate form of chnget (output variable starts with \`i\`):

         instr 1
           ; i-rate snapshots — these are what linsegr can use
           iAtt   chnget  "attack"
           iRel   chnget  "release"
           ; k-rate reads — for parameters you want to modulate while the note holds
           kAmp   chnget  "amplitude"
           kIdx   chnget  "fmIndex"
           kAmp   port    kAmp, 0.02
           kIdx   port    kIdx, 0.02

           iFreq = p4
           iVel  = p5

           kEnv linsegr 0, iAtt, 1, iAtt + 0.05, 0.7, iRel, 0
           ; ...signal path uses kEnv * kAmp * iVel

     Passing k-rate variables (\`kAtt\`, \`kRel\`) to \`linsegr\` produces **"Unable to find opcode entry for 'linsegr' with matching argument types"** — that is the most common adapter failure. Use \`i\`-prefixed reads for any envelope time/value you put into \`linsegr\`.
   - \`linsegr\`'s last segment is the release — it triggers automatically on turnoff. Do not invent your own release logic.
   - Multiply your audio path by \`kEnv * kAmp * iVel\` (or the equivalent of your amplitude knob × velocity).

6. **Channel-writer helper (\`instr 100\`) — MANDATORY, verbatim:**

       instr 100
         Schan strget p4
         iVal  = p5
         chnset iVal, Schan
         turnoff
       endin

   Do not switch to \`kVal\` / k-rate \`chnset\` — with p3=0 no k-cycles fire and the write is silently dropped. Do not rename the instrument or change the p-field layout.

7. **Always-on reverb bus (\`instr 99\`).** Voices send to \`"revL"\` / \`"revR"\` via \`chnmix\`; the bus reads them, applies reverbsc, and outputs the wet signal:

       instr 99
         kMix  chnget "reverbMix"
         kSize chnget "reverbSize"
         aInL  chnget "revL"
         aInR  chnget "revR"
         aL, aR reverbsc aInL, aInR, kSize, 12000
         outs  aL * kMix, aR * kMix
         chnclear "revL"
         chnclear "revR"
       endin

   Voices still \`outs\` their dry signal; reverb is additive. If the source already had its own reverb, REPLACE it with this bus — do not double up. If you don't expose \`reverbMix\`/\`reverbSize\` as knobs, hardcode reasonable defaults but keep the bus.

8. **Score.** Replace <CsScore> with exactly:

       i 99 0 36000       ; reverb bus runs the whole session
       f 0 36000          ; keep the engine alive for keyboard triggering

   No pre-scheduled notes for instr 1 — the keyboard triggers them live.

9. **Drop anything the Player can't drive**: MIDI opcodes, OSC listeners, \`gk<Name> init …\` knob globals (those become \`chn_k\` + \`chnget\` instead), hard-coded score melodies. Keep ftables, wavetables, and init-time setup.

10. **Quality bar**: the output must compile with stock Csound 6/7, render stereo to \`-o dac\`, and produce audible output when the user holds a keyboard key with default knob values. The note must sustain while held and release cleanly when released.

SUGGESTED WELL-KNOWN CHANNEL NAMES (use these names when they fit so users get familiar bindings):

<<<CHANNELS>>>

SOURCE CSD:
<<<SOURCE>>>

Emit the adapted CSD now.`

function renderChannelList(): string {
  return PLAYER_CHANNELS
    .map((c) => `- "${c.name}" (default ${c.default}, ${c.range}) — ${c.role}`)
    .join('\n')
}

// Strip CsoundQT-specific blocks that often trail real-world CSDs. <bsbPanel>
// and <bsbPresets> are CsoundQT's GUI metadata — they're hundreds of lines of
// XML that aren't part of the orchestra and just waste prompt budget while
// confusing the adapter ("the source defines a 'gain' widget so I should keep
// it" — no, you shouldn't, the Player has its own knobs).
//
// <MacOptions>, <MacGUI>, <EventPanel> are MacCsound holdovers in the same
// spirit. Anything after the closing </CsoundSynthesizer> tag is, by definition,
// not Csound — drop it.
export function cleanSource(source: string): string {
  let s = source.trim()
  const closeTag = s.search(/<\/CsoundSynthesizer\s*>/i)
  if (closeTag !== -1) {
    const end = s.indexOf('>', closeTag) + 1
    s = s.slice(0, end)
  }
  // Belt-and-suspenders for the rare CSD that puts the GUI block *inside*
  // <CsoundSynthesizer> (shouldn't be valid, but CsoundQT has been known to).
  s = s.replace(/<bsbPanel>[\s\S]*?<\/bsbPanel>/gi, '')
  s = s.replace(/<bsbPresets>[\s\S]*?<\/bsbPresets>/gi, '')
  s = s.replace(/<MacOptions>[\s\S]*?<\/MacOptions>/gi, '')
  s = s.replace(/<MacGUI>[\s\S]*?<\/MacGUI>/gi, '')
  s = s.replace(/<EventPanel>[\s\S]*?<\/EventPanel>/gi, '')
  return s.trim()
}

export function buildConvertPrompt(target: ConvertTarget, source: string): string {
  const template =
    target === 'webapp' ? WEBAPP_TEMPLATE :
    target === 'vst' ? VST_TEMPLATE :
    target === 'player' ? PLAYER_TEMPLATE :
    CSD_TEMPLATE
  return template
    .replace('<<<CHANNELS>>>', renderChannelList())
    .replace('<<<SOURCE>>>', cleanSource(source))
}

// Quick heuristic: does this CSD already look Player-ready? If not, the caller
// should route through buildConvertPrompt('player', ...).
//
// The new contract relies on Player infrastructure being present, not on a
// fixed channel set — the knobs themselves are now declared by the CSD via
// chn_k. Required infrastructure:
//   - <CsoundSynthesizer> wrapper
//   - At least one chn_k declaration (otherwise the knob grid is empty)
//   - p4 referenced somewhere in the orchestra (keyboard pitch arrives there)
//   - instr 100 channel-writer helper (so live knob updates land)
//   - linsegr in the orchestra (so sustain-release with i -1.NNN works)
export function needsPlayerAdapt(source: string): boolean {
  if (!/<CsoundSynthesizer/i.test(source)) return true
  if (!/\bchn_k\s+/i.test(source)) return true
  if (!/\bp4\b/.test(source)) return true
  if (!/\binstr\s+100\b/.test(source)) return true
  if (
    !/\blinsegr\b/i.test(source) &&
    !/\b(madsr|linenr|linen|expon|expseg|linseg)\b/i.test(source)
  ) {
    return true
  }
  return false
}

// Detect when a free-text chat message is really a request to convert the
// active artifact into a *different* format ("make it a web app", "export as
// a VST", "give me the plain CSD"). When it is, the caller should route the
// message through buildConvertPrompt() — the same proven path the "Convert
// to" button uses — instead of a normal follow-up, which would otherwise be
// told to preserve the current format and ignore the switch.
//
// Conservative by design: only fires on phrasings that name a target format,
// and only returns a target that differs from the artifact already open.
const CONVERT_INTENT: { type: 'csd' | 'webapp' | 'vst'; re: RegExp }[] = [
  {
    type: 'webapp',
    re: /\b(export\s+(?:as\s+)?web\s?app|web\s?app|web\s?site|web version|html (?:page|app|document|version)|in the browser|as html|browser app)\b/i,
  },
  {
    type: 'vst',
    re: /\b(vst|au plugin|audio unit|cabbage|plugin|daw)\b/i,
  },
  {
    type: 'csd',
    re: /\b(plain csd|raw csd|back to (?:a )?csd|just (?:the )?csd|csd instrument|extract (?:the )?csd)\b/i,
  },
]

export function detectConvertIntent(
  text: string,
  activeType: 'csd' | 'webapp' | 'vst',
): 'csd' | 'webapp' | 'vst' | null {
  for (const { type, re } of CONVERT_INTENT) {
    if (type !== activeType && re.test(text)) return type
  }
  return null
}
