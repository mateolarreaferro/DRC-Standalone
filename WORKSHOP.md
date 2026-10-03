# Dr.C Standalone — LAC / Education Workshop Build

This branch targets **Csound 7** for native CLI compile/render and **@csound/browser 7** for web synth exports.

## What changed (v1.3.1+)

- System prompts unified for **Csound 7** (removed contradictory 6.18 rules)
- **First-turn simplicity**: simple requests emit one working CSD, not three alternatives
- **PATH** prefers `~/bin` and `~/Applications/Csound` (user-local Csound 7)
- **Runtime detection** injects detected Csound version into the agent environment
- **Web app conversion** compile-checks orchestra before wrapping HTML
- **Workshop starters** in `resources/workshop-starters/` (verified compile targets)
- **Player demo menu** — 70+ MIDI models + Trapped in Convert + FM-Bell (`player-model-demos.json`)
- **Web apps** — Csound 7 WASM harness; compile-then-start; Hz keyboard adapt; **Open in Browser**
- **Golden shortcuts** — FM woodblock → `fmpercfl` starter (Agent, no LLM)
- **Workshop-lite mode** (`DRC_WORKSHOP_LITE=1`): skips narration so each turn uses **one** cheap model call — useful for free-tier workshops only
- **Pro+ mode** (default in `scripts/launch-drc.sh` via `DRC_PRO_PLUS=1`): Gemini Pro, narration, specialist consults, full book RAG

## Agent models (workshops)

See **[LOCAL-LLM.md](./LOCAL-LLM.md)** for the full local-setup handout (Ollama install, model picks, troubleshooting).

| Path | Best for |
|------|----------|
| **Your own Anthropic/OpenAI key** | Best Csound output — encourage attendees to bring one |
| **Ollama (local)** | Best **free** option — no signup, no rate limits |
| Groq / Gemini (free tier) | Try-it backups — rate limits + variable quality |
| No model | Web Apps, Player workshop demos |

**Ollama quick start:** [ollama.com/download](https://ollama.com/download) → `ollama pull qwen2.5-coder:7b` → Settings → Use Ollama for Agent

**Attendee launchers** (macOS/Linux): `launch-workshop-attendee.sh`

## Quick start

**Participants:** see **[PARTICIPANTS.md](./PARTICIPANTS.md)** for per-OS download, install, and double-click launchers.

**Developers:**

```bash
git clone -b lac-2026-csound7 https://github.com/mateolarreaferro/Dr.C-Standalone.git
cd Dr.C-Standalone
npm install
cp .env.example .env   # add GEMINI_API_KEY or other provider key
chmod +x scripts/launch-drc.sh launchers/*.command launchers/*.sh
./scripts/launch-drc.sh
```

## Csound 7 install (all platforms)

**Verify:**
```bash
csound --version   # should show version 7.x
```

### macOS (recommended — user install, no sudo)

1. Download Csound 7 universal pkg from [Csound releases](https://github.com/csound/csound/releases)
2. Extract or install to `~/Applications/Csound/`
3. Symlink: `mkdir -p ~/bin && ln -sf ~/Applications/Csound/csound ~/bin/csound`

### Linux (Ubuntu/Debian)

Build from source or use a Csound 7 package when available for your distro. Workshop docs in `~/Dr.C-URLS` cover full Linux setup.

```bash
sudo apt install build-essential cmake libjack-jackd2-dev
# Follow Csound 7 build instructions at https://github.com/csound/csound
```

## Workshop smoke test

Run on **macOS and Linux** before the session:

```bash
export PATH="$HOME/bin:$HOME/Applications/Csound:$HOME/.local/bin:$PATH"
cd ~/Dr.C-Standalone
npm run test:platform
npm test
```

Quick smoke only (macOS/Linux): `npm run test:smoke`

See also: **`PARTICIPANTS.md`** (app install guide), **`TESTING.md`** (verify your build), **`VERSIONS.md`** (product matrix). Workshop handouts: [Dr.C-Workshop-Demo](https://github.com/csounder/Dr.C-Workshop-Demo).

## Suggested attendee prompt

**Golden model:** `resources/workshop-starters/fm_bell_starter.csd` — shimmering dual-modulator FM bell (Dr. B).

```
make a plain Csound CSD only — no Cabbage. Shimmering FM bell like the workshop golden model: two inharmonic oscili modulators into a carrier, expsegr decay, global reverb bus (instr 99). Score: descending bell melody, harmonic cluster, final low bell (~15 s).
```

Simple FM (beginners):

```
make a plain Csound CSD only — no Cabbage. Simple 2-operator FM synth with foscili, warm and resonant. Score should demo the instrument: scale, arpeggios, ostinato, closing chord (~12 s).
```

**Ping-pong bass model:** `resources/workshop-starters/pluck_bass_starter.csd` — FM pluck + cross-fed `vdelay3` echo.

```
make a plain Csound CSD only — no Cabbage. Ping-pong pluck bass: foscili FM voice, butterlp lowpass, gaEcho global bus, instr 99 with vdelay3 cross-feedback (280 ms / 420 ms). Score: four-note bass riff (~8 s).
```

## Web synths

Converted web apps use `@csound/browser@7.0.0-beta31` from CDN. Reference apps in **Web Apps** gallery are educational demos.

## Cabbage

For live MIDI instruments, convert to Cabbage after the plain CSD works. Most Cabbage patches use `f0 z` and realtime MIDI, not offline `i 1 0 3` scores.

## CsoundQt

For deeper editing and manual lookup, use **Open in CsoundQt** on any plain CSD (artifact panel or Terminal CSD toolbar). Install **CsoundQt v7.x** after Csound 7 — see `INSTALL-STANDALONE.md` §2.5.

## Optional companion tools (recommended)

Attendees may also install **Cabbage**, **Audacity**, and **Reaper** — all optional but recommended for listening to exports, editing WAVs, and DAW/VST workflows. See **[PARTICIPANTS.md](./PARTICIPANTS.md)** § Optional companion tools and `~/Dr.C-URLS/INSTALL-STANDALONE.md` §2.5–2.8.
