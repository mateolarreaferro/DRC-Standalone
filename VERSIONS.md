# LAC 2026 — Product & Version Guide

One page describing **what each Dr.C product is**, **which version to ship**, and **how they differ.

---

## The four workshop products

| Product | What it is | Best for | API key? |
|---------|------------|----------|----------|
| **Dr.C Standalone** | Electron desktop app — Agent, Player, Web Apps, Settings | Beginners, visual workflow, Ireland workshop | Optional (offline demos work without) |
| **Dr.C Terminal** | TUI in the terminal — full agent + CSD panel + tools | Experienced devs, Linux power users | Yes (or Ollama) |
| **CsoundLive Web** | Browser app — sampler/mixer/FX (Csound 7 WASM) | No install friction, performance mixing | No |
| **CsoundQt 7** | Official Csound IDE | Edit CSDs, manual, McCurdy examples | No |

---

## Version matrix (June 2026 workshop build)

| Component | Version / tag | Repo / path | Branch |
|-----------|-------------|-------------|--------|
| Dr.C Standalone | **1.3.1** (`lac-2026-csound7`) | [Dr.C-Standalone](https://github.com/mateolarreaferro/Dr.C-Standalone) | `lac-2026-csound7` |
| Dr.C Terminal | **1.2.5** (opencode package) | [Dr.C](https://github.com/mateolarreaferro/Dr.C) | `main` (+ local TUI fixes) |
| Csound CLI | **7.0** (beta) | User install `~/Applications/Csound` or distro package | — |
| Csound WASM (web exports) | **@csound/browser@7.0.0-beta31** | CDN in converted web apps | — |
| CsoundQt | **7.0.0-beta4.1** or newer | [CsoundQt releases](https://github.com/CsoundQt/CsoundQt/releases) | — |
| CsoundLive Web | build tag in `js/app.js` | `_CsoundLive/web` | `main` |
| Node (Standalone) | **22.x** | Required for `better-sqlite3` / Electron | — |
| Bun (Terminal) | **1.3.9+** | Required for Dr.C Terminal | — |

**Do not distribute the old v1.3.0 `.app` alone** — it predates Csound 7 workshop fixes.

---

## Launch modes (Standalone)

Two environment profiles control behavior:

| Mode | Script | `DRC_PRO_PLUS` | `DRC_WORKSHOP_LITE` | Who |
|------|--------|----------------|---------------------|-----|
| **Pro+ (Richard / demo)** | `./scripts/launch-drc.sh` | `1` | `0` | Full narration, Gemini Pro, specialist consults |
| **Attendee (free tier)** | `./scripts/launch-workshop-attendee.sh` | `0` | `1` | One LLM call/turn, Groq-first, rate-limit countdown |

Both scripts prepend `~/bin` and `~/Applications/Csound` so Electron finds Csound 7.

---

## What changed in Standalone 1.3.1 (workshop)

See `WORKSHOP.md` for detail. Summary:

- Unified **Csound 7** prompts (removed 6.18 contradictions)
- **PATH** + runtime version detection for Csound
- **Player compile-check** — shortens `f 0 36000` hold scores so compile does not hang
- **Provider fallback** Groq ↔ Gemini + rate-limit countdown UI
- **Offline workshop path** — `player_fm_bell.csd`, mechanical Player adapt, **Demos** dropdown
- **Web app WASM 7** + Open in Browser + Settings → Web Browser
- **Workshop starters** + **ingest-player-model-demos.mjs** for MIDI model menu
- Automated tests: `npm test` on **macOS and Linux** (platform launchers + **126** smoke checks + build)

---

## What changed in Terminal (local, pre-push)

Uncommitted on `~/Dr.C/opencode` as of June 2026:

- Versioned **Cabbage.app** detection (`Cabbage-2.10.x.app`)
- CSD panel **Open in Cabbage** with auto-convert for plain CSDs
- Workshop smoke: `npm run test:workshop` in `Dr.C/opencode` (**macOS/Linux**)

---

## File map (Standalone workshop additions)

| Path | Purpose |
|------|---------|
| `resources/workshop-starters/` | Verified CSDs (FM bell, pad, player demo, MIDI template) |
| `src/main/csound/compile-check.ts` | Short hold scores before dry-run compile |
| `src/renderer/lib/mechanicalPlayerAdapt.ts` | Offline Player wrap (no LLM) |
| `src/main/ipc/workshop.ipc.ts` | Load starters from renderer |
| `scripts/smoke-test.mjs` | **126** automated checks |
| `scripts/ingest-player-model-demos.mjs` | Refresh Player MIDI demo menu from source folders |
| `scripts/test-platform-launchers.mjs` | cross-platform launcher contract |
| `scripts/workshop-test.mjs` | smoke + memory + production build |
| `scripts/launch-workshop-attendee.sh` | Attendee env vars |

---

## Install doc locations

| Audience | Document |
|----------|----------|
| Standalone install (all OS) | `README.md`, `PARTICIPANTS.md` |
| Workshop handouts (Mac / Linux / QR) | [csounder/Dr.C-Workshop-Demo](https://github.com/csounder/Dr.C-Workshop-Demo) |
| Branch / feature notes | `WORKSHOP.md` |
| Verify your build | `TESTING.md` |

---

## Desktop / USB launchers (`~/Dr.C-Workshop-Demo`)

| File | Runs |
|------|------|
| `Dr.C-Standalone.command` | Standalone from source (Pro+ via `launch-drc.sh`) |
| `Dr.C-Terminal.command` | Terminal TUI in `~/Dr.C-Workshop-Demo` |
| `Csound7-WASM-Smoke-Test.command` | Browser WASM sanity check |

For **attendee USB sticks**, copy `launch-workshop-attendee.sh` wrapper or set env in a `.command` that exports `DRC_PRO_PLUS=0 DRC_WORKSHOP_LITE=1`.
