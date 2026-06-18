# Handoff — Web App Keyboard & Export Path

**Pick up here:** Dr.C Standalone web-app keyboard is fixed in code but not yet fully hardened or shared with other keyboard UIs.

---

## Start Here Tomorrow

### 1. Smoke-test the fix (15 min)

```bash
cd /Users/richardboulanger/Dr.C-Standalone
npm run dev
```

- Convert a **melodic** patch (uses `p4`) to Web App.
- Check keyboard visually in iframe and in browser.
- Press a few QWERTY keys; confirm pitch rises left → right.
- If anything still looks wrong, compare side-by-side with **Player** page keyboard on the same patch.

### 2. Read the one file that matters

All export keyboard logic lives in:

`src/renderer/lib/webHarness.ts`

| Section | Lines (approx.) | What |
|---------|-----------------|------|
| HTML shell | ~169–177 | `#controls`, `#keyboard`, `#octaveLabels` order |
| `STYLES` | ~326–383 | Piano CSS (anchoring, sizes, colors) |
| `RUNTIME` → `buildKeyboard()` | ~668–760 | Key DOM, MIDI map, QWERTY handlers |

Do **not** edit FM Bell’s flex-wrap “keyboard” expecting it to match — that app is intentionally a button row.

---

## Likely Next Steps (priority order)

### A. Confirm black-key spacing on different screen sizes

`BLACK_SHIFT = 12` was copied from Fibonacci FM (18px white keys). We use 32px white keys. It may need tuning:

- Try `Math.round(WHITE_W * 12 / 18)` → **21** if black keys look slightly off-center between whites.
- Tune in browser DevTools on a generated export before changing the constant.

### B. Deduplicate keyboard logic (medium effort, high value)

Three similar implementations exist:

| Location | Tech |
|----------|------|
| `webHarness.ts` | DOM + inlined CSS/JS in export |
| `PianoKeyboard.tsx` | React SVG (Player) |
| `playerKeyboardBind.ts` | Shared QWERTY ↔ MIDI map (Player only) |

**Recommendation:** Extract a small shared module, e.g. `src/shared/pianoKeyboardLayout.ts`, exporting:

- `PIANO_PATTERN`, `WHITE_W`, `BLACK_SHIFT`, octave range
- `midiToKeyLabel`, `keyEventToMidi` (move from duplicated inline maps)
- Optional: pure functions for black-key `left` position

Then import from `webHarness.ts` (build-time string embed) and `PianoKeyboard.tsx`. Avoids the keyboard drifting again.

### C. Add a minimal automated check (optional)

No unit tests exist for `webHarness` today. Low-cost option:

- Export `buildWebApp()` with a tiny fixture CSD in a script or vitest test.
- Assert generated HTML contains `top: 0`, `PIANO_PATTERN`, and expected key count (21 white keys for 3 octaves).

### D. Commit when satisfied

Changes are local only until committed. Suggested message:

```
Fix exported web app piano keyboard layout and orientation.

Align webHarness keyboard with Player: data-driven white/black pattern,
correct black-key positioning, top-anchored keys, controls above keyboard.
```

---

## Pitfalls to Avoid

1. **Stale exports** — Users must re-convert; old `index.html` files keep the broken keyboard.
2. **Editing the wrong keyboard** — Web Apps gallery (`WebAppsPage.tsx`) serves bundled HTML (`fibonacci-fm.html`, etc.), not `webHarness.ts`.
3. **`bottom: 0` on black keys** — That was the upside-down bug. Keep all keys `top: 0`; black keys are shorter, so they naturally sit at the back.
4. **LLM HTML** — Modern path does not ask the model for HTML. Keyboard bugs are always in `webHarness.ts`, not the conversion prompt.
5. **MIDI vs Hz** — Web keyboard sends **Hz in p4** and **0..1 velocity in p5** via `adaptOrcForWebKeyboard()` in the same file. Player uses a different dispatch path; don’t conflate them when debugging sound.

---

## Related Files (reference only)

| File | Role |
|------|------|
| `src/renderer/pages/AgentPage.tsx` | Triggers convert, calls `buildWebApp()` |
| `src/renderer/lib/webappPrepare.ts` | Parses channels, `usesKeyboard()` |
| `src/renderer/components/artifacts/WebAppArtifact.tsx` | iframe preview |
| `src/main/ipc/export.ipc.ts` | Writes/opens `~/Documents/DrC/webapps/...` |
| `src/renderer/components/player/PianoKeyboard.tsx` | Gold-standard visual reference |
| `src/renderer/lib/playerKeyboardBind.ts` | Player QWERTY bindings |

---

## Open Questions

- [ ] Is keyboard orientation confirmed good on your machine after re-export?
- [ ] Should black-key labels be hidden (Player shows them; some UIs don’t)?
- [ ] Should exported keyboard match Player **exactly** (32px vs previous 36px width)?
- [ ] Worth adding octave shift buttons like Fibonacci FM for web exports?

---

## Quick Debug Checklist

| Symptom | Check |
|---------|--------|
| No keyboard at all | Orchestra must reference `p4`; `hasKeyboard` in generated HTML |
| Wrong pitch | `noteOn()` → Hz via `midiToFreq()`; orchestra expects Hz not MIDI |
| Black keys at bottom | CSS still using `bottom: 0` on `.piano .key` |
| Button grid not piano | Old artifact or FM Bell template — re-convert via Agent |
| Sliders dead | Separate issue — `chn_k` + in-instrument `chnget`, not keyboard |

---

## Contact Context

Session work: user reported export keyboard upside down and wrong layout → fixed layout + flip in `webHarness.ts`. User asked for this handoff doc to continue tomorrow.
