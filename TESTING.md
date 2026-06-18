# Testing Guide — LAC 2026

Automated checks you can run in minutes, plus a manual pass Richard should do once on his laptop before pushing to GitHub.

---

## Automated — Dr.C Standalone

From repo root, with Csound 7 on PATH:

```bash
export PATH="$HOME/bin:$HOME/Applications/Csound:$PATH"
cd ~/Dr.C-Standalone
npm test
```

This runs:

1. **`scripts/test-platform-launchers.mjs`** — launcher files + PATH contract (macOS and Linux)
2. **`scripts/smoke-test.mjs`** — 126 checks (**macOS and Linux only** — exits immediately on Windows)
3. **`scripts/check-memory.mjs`** — better-sqlite3 loads under Electron
4. **`npm run build`** — production bundle compiles

Quick smoke only:

```bash
npm run test:smoke
```

Platform launchers only:

```bash
npm run test:platform
```

**Expected:** `126 passed, 0 failed` (smoke) + platform launcher checks, then `Workshop tests passed`.

---

## Automated — Dr.C Terminal (CLI)

```bash
export PATH="$HOME/bin:$HOME/Applications/Csound:$HOME/.local/bin:$PATH"
cd ~/Dr.C/opencode
npm run test:platform    # launcher + GET-STARTED.md (run on each OS)
npm run test:workshop
```

Participant guide: **`Dr.C/opencode/GET-STARTED.md`**

**Expected:** `12 passed, 0 failed` (Csound 7, CLI help, demo CSDs, shared starters, bash tool tests).

> **Note:** Full `bun test` in `packages/opencode` runs 983 upstream tests; ~17 fail on network/skill-discovery fixtures. That is **not** a workshop blocker. Use `test:workshop` for LAC.

---

## Cross-platform gate (macOS & Linux — LAC 2026)

Run the full automated gate on **macOS and Linux** before LAC:

| OS | Dr.C Standalone | Dr.C Terminal |
|----|-----------------|---------------|
| **macOS** | `npm test` | `npm run test:platform && npm run test:workshop` |
| **Linux** | `npm test` | `npm run test:platform && npm run test:workshop` |

**Verified on macOS (darwin arm64):** Standalone 27 platform + 126 smoke; Terminal 18 platform + 12 workshop — all passed (2026-06-15).

Linux: `csound`/`bun` runtime checks skip gracefully if not installed on the CI/VM host.

**Linux caveat (verified on Ubuntu 22.04 VM):** `apt install csound` ships **6.17** — `test:platform` reports a **SKIP** for Csound 7; `test:smoke` may still pass (98/98). Full workshop gate needs Csound 7 built from source. See `PARTICIPANTS.md` Linux section.

---

## Automated — CsoundLive Web

```bash
cd ~/Dr.C-WebApps/_CsoundLive/web
./scripts/compile-check.sh
```

**Expected:** `OK: orchestra compiled` (merged orchestra, Csound 7).

---

## Manual checklist — Richard (before GitHub release)

Do this once after `npm test` passes. Restart Dr.C between main-process changes.

### A. No API key (beginner path)

Launch attendee mode:

```bash
~/Dr.C-Standalone/scripts/launch-workshop-attendee.sh
```

| # | Step | Pass? |
|---|------|-------|
| A1 | Agent → **Load workshop FM bell (no key)** — CSD appears in panel | |
| A2 | **Web Apps** tab opens without key prompt | |
| A3 | Player → **Demos** dropdown → load FM-Bell or any MIDI model → “Live — click keyboard” | |
| A4 | Click keyboard (or QWERTY keys) — hear sound at normal level | |
| A5 | Settings → **Done** returns to Agent; gear toggles Settings off | |
| A6 | Web App artifact → **Open in Browser** (set browser in Settings if needed) → **Start Audio** | |

### B. With API keys (Gemini + Groq)

Launch Pro+ or attendee with keys in Settings:

```bash
~/Dr.C-Standalone/scripts/launch-drc.sh
# or attendee script + keys saved
```

| # | Step | Pass? |
|---|------|-------|
| B1 | Agent → workshop FM prompt (see `WORKSHOP.md`) → CSD → compile → **hear sound** | |
| B2 | Rate limit: if throttled, **countdown** shows; **Try again** works after wait | |
| B3 | Player → **Load current CSD from Agent** → adapt → keyboard plays | |
| B4 | Artifact → **Open in CsoundQt** opens in your CS7 CsoundQt | |
| B5 | Convert to Web App → preview plays; **Open in Browser** works; keyboard uses Hz (no `cpsmidinn` errors) | |
| B6 | Player → load **Henon** or **Moog** demo — velocity loud enough (not ~127× too quiet) | |

### C. Dr.C Terminal

Double-click **`Dr.C-Terminal.command`** or:

```bash
cd ~/Dr.C/opencode && bun run dev -- ~/Dr.C-Workshop-Demo
```

| # | Step | Pass? |
|---|------|-------|
| C1 | TUI opens, project is `Dr.C-Workshop-Demo` | |
| C2 | Generate plain FM CSD with workshop prompt | |
| C3 | Compile / smoke from CSD panel | |
| C4 | **Open in Cabbage** (if Cabbage installed) | |

### D. CsoundLive (optional demo)

Double-click **`Launch Web App.command`** → Start audio → load a sample → hear mix.

---

## Known gotchas (not bugs if you know them)

| Symptom | Cause | Fix |
|---------|-------|-----|
| Player “Compiling…” forever | Hold score `f 0 36000` on raw `csound -n` | Fixed in app via `compile-check.ts`; tests shorten scores |
| “Playing” but no sound | `-iadc` with no mic | Fixed — no default ADC unless configured |
| Blank screen after send | Stale dev server on port 5173 | `launch-drc.sh` kills 5173 first |
| Gemini empty / no CSD | Free tier rate limit | Wait for countdown; use Groq; or attendee mode |
| Web app `cpsmidinn` out of range | Old export used MIDI opcodes with Hz keyboard | Re-convert; or use latest `webHarness` (adapts at compile) |
| Web app silent in browser | Skipped **Start Audio** or offline | Click Start Audio; need CDN network |
| Web app reverts to CSD after convert | Streaming/usage re-ran `detect()` on orchestra-CSD message after wrap | Fixed — permanent `webappFrozenMessageIds`, store-level `hasWebappForMessage` blocks, optimistic freeze, split autoplay effect |
| `better-sqlite3` error | Node/Electron ABI mismatch | `npx electron-builder install-app-deps` |
| Packaged app “damaged” (macOS) | Unsigned build | Right-click → Open, or notarize for wide release |

---

## Manual repro: web-app artifact survival (regression)

Use after any Agent / artifact-store change.

1. Agent → **Load workshop FM bell (no key)** (or golden FM bell prompt) — wait for CSD + autoplay.
2. Artifact panel → **Convert** → **Web App** — wait for Preview tab (orchestra wrap may take a few seconds).
3. Confirm panel stays on **Web App** / Preview (not `main.csd` orchestra text).
4. Click **Open in Browser** in panel footer or chat **ArtifactCard** — Chrome opens `~/Documents/DrC/webapps/.../index.html`.
5. In browser: **Start Audio** → keyboard plays bell.
6. **Wait 5–10 s while still in Preview** (do not send a follow-up yet) — panel must stay Web App; must **not** flip to orchestra `main.csd` or autoplay the original bell CSD.
7. Back in Agent: type a short follow-up (e.g. `add a reverb mix knob`) — web app must **not** revert to original CSD or autoplay CSD.
8. Switch to **Web Apps** tab and back to **Agent** — web app artifact still in panel.

Pass: steps 3–8 hold. Fail: panel flips to CSD, original bell autoplays, or **Open in Browser** missing.

---

## Test log template (fill when you return)

```
Date: ___________
Machine: MacBook ___ / macOS ___
Csound: csound --version → ___________
Node: node -v → ___
npm test: pass / fail
npm run test:workshop (Terminal): pass / fail
Manual A1–A5: pass / fail (notes: ___)
Manual B1–B5: pass / fail (notes: ___)
Ready for GitHub release: yes / no
```
