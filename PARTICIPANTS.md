# LAC 2026 — Workshop Participant Guide

**Platform handouts (Mac / Linux / QR):** [csounder/Dr.C-Workshop-Demo](https://github.com/csounder/Dr.C-Workshop-Demo)

**Dr.C Standalone** (GUI) + optional **Dr.C Terminal** (CLI).  
Branch: **`lac-2026-csound7`** · Version **1.3.1**

> **LAC 2026 supports macOS and Linux only.** Windows builds and launchers are not part of this session.

---

## Choose your path

| I want… | Use |
|---------|-----|
| Visual app, Player keyboard, Web Apps | **Dr.C Standalone** (this guide) |
| Terminal / shell workflow | [Dr.C Terminal](#dr-c-terminal-optional) |
| No install, browser only | CsoundLive Web (separate repo) |

**No API key required** for offline demos (FM bell, Player workshop demo, Web Apps tab).

---

## 1. Install Csound 7 (macOS & Linux)

Verify after install:

```bash
csound --version
```

You should see **version 7.x**.

### macOS

1. Download Csound 7 from [Csound releases](https://github.com/csound/csound/releases) (universal `.pkg` or `.dmg`).
2. Install to **`~/Applications/Csound/`** (user install — no admin needed).
3. Symlink CLI:
   ```bash
   mkdir -p ~/bin
   ln -sf ~/Applications/Csound/csound ~/bin/csound
   ```
4. If Homebrew Csound 6 shadows CS7: `brew unlink csound`

**Also need:** [Node.js 22](https://nodejs.org/) (`node -v` → v22.x recommended)

### Linux (Ubuntu / Debian)

> **Important:** On **Ubuntu 22.04 (Jammy)**, `sudo apt install csound` installs **Csound 6.17**, not 7.  
> `npm run test:platform` and `npm run test:workshop` require **7.x**. Use **Option B** (build from source) or install Csound 7 binaries from [GitHub releases](https://github.com/csound/csound/releases).  
> `npm run test:smoke` may still pass on 6.x for many compile checks — do not treat that as a full workshop gate.

```bash
# Build tools if compiling from source
sudo apt update
sudo apt install -y build-essential cmake git libjack-jackd2-dev

# Option A — distro package ONLY if csound --version shows 7.x (not on 22.04 Jammy)
sudo apt install -y csound
csound --version   # must show version 7.x for workshop gate

# Option B — build Csound 7 from source (recommended on 22.04)
# https://github.com/csound/csound/blob/develop/BUILD.md

# Node.js 22 (Node 20 may work for smoke tests; 22 recommended)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
```

User-local install path (optional): `~/Applications/Csound/csound` on `PATH` via `~/bin`.

**Headless Linux (SSH, no desktop):** GUI launchers need a display (`DISPLAY` or Wayland). Use `npm run test:platform` and `npm test` in the repo; run the Electron app on a machine with a desktop session.

---

## 2. Get Dr.C Standalone

```bash
git clone -b lac-2026-csound7 https://github.com/csounder/DRC-Standalone.git ~/Dr.C-Standalone
cd ~/Dr.C-Standalone
npm install
cp .env.example .env    # optional — or use Settings UI
```

Pre-built installers may be added later; for LAC 2026 use **git clone** on `lac-2026-csound7`.

---

## 3. Launch Dr.C

### macOS

**Double-click** (after `chmod +x` if needed):

| Role | Launcher |
|------|----------|
| Attendee (free tier) | `launchers/Dr.C-Workshop-Attendee.command` |
| Instructor (Pro+) | `launchers/Dr.C-Standalone.command` |

**First launch (Gatekeeper):** Right-click the `.command` file → **Open** → **Open**. If macOS blocks it or says “damaged”:

```bash
xattr -cr ~/Dr.C-Standalone/launchers/*.command
xattr -cr ~/Dr.C-Workshop-Demo/*.command
chmod +x ~/Dr.C-Standalone/launchers/*.command
```

Packaged app: `xattr -cr /Applications/DrC.app`

Or in Terminal:

```bash
cd Dr.C-Standalone
./scripts/launch-workshop-attendee.sh   # attendees
./scripts/launch-drc.sh                 # instructor
```

### Linux

```bash
cd Dr.C-Standalone
chmod +x launchers/*.sh scripts/*.sh
./launchers/Dr.C-Workshop-Attendee.sh     # attendees
./launchers/Dr.C-Standalone.sh            # instructor
```

---

## 4. Agent / LLM (optional)

Dr.C needs a language model for the **Agent** tab. Pick what fits your workshop.

| Option | Type | Works in Standalone today? | Notes |
|--------|------|----------------------------|-------|
| **Ollama** | Local | Yes | **Recommended free path** — no signup, no rate limits |
| **Anthropic (Claude)** | Cloud paid | Yes | **Instructor typical** — best Agent quality for teaching |
| **OpenAI** | Cloud paid | Yes | **Instructor typical** — strong alternative to Claude |
| OpenRouter | Cloud | Yes | One key, many models (incl. free slugs); paid defaults route to Claude Sonnet |
| Groq | Cloud free | Yes | `llama-3.3-70b-versatile` · ~30 req/min · backup |
| Gemini | Cloud free or paid | Yes | `gemini-2.5-flash` · same [AI Studio](https://aistudio.google.com/apikey) key; enable billing for paid quotas |
| Cursor API | Cloud | **No** | [Cursor SDK](https://cursor.com/docs/sdk/typescript) — agent automation for IDE/CI, **not** a drop-in key for Standalone Agent |
| OpenCode Zen | Cloud | **Terminal only** | Free rotating models at [opencode.ai/docs/zen](https://opencode.ai/docs/zen/) via `/connect` — **not** in Standalone GUI |

### Best quality: your own API key (recommended for instructors)

**Instructor typical (paid):** **[Anthropic](https://console.anthropic.com/settings/keys)** (Claude) or **[OpenAI](https://platform.openai.com/api-keys)** — paste in **Settings → API Keys** → **Test**, or set `ANTHROPIC_API_KEY=` / `OPENAI_API_KEY=` in `.env` (dev / git clone). **Attendees:** Ollama, Groq, or Gemini (free).

**Alternative — one key, many models:** **[OpenRouter](https://openrouter.ai/keys)** routes to Claude, GPT, Gemini, and more. Add credits at [openrouter.ai/credits](https://openrouter.ai/credits). Paste in **Settings → OpenRouter** → **Test**. Free model slugs: [openrouter.ai/models?max_price=0](https://openrouter.ai/models?max_price=0) (Dr.C defaults to paid Claude Sonnet when credits are available).

| Provider | Cost | Get a key | Env var (optional) |
|----------|------|-----------|-------------------|
| **Anthropic (Claude)** | Pay per use | [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys) | `ANTHROPIC_API_KEY` |
| **OpenAI** | Pay per use | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) | `OPENAI_API_KEY` |
| **OpenRouter** (one key, many models) | Pay per use | [openrouter.ai/keys](https://openrouter.ai/keys) | `OPENROUTER_API_KEY` |

Paste keys in **Settings → API Keys** → **Test** (packaged builds) or copy `.env.example` → `.env` for dev.

### Free cloud (backup — rate limits apply)

| Provider | Cost | Get a key | Model Dr.C uses |
|----------|------|-----------|-----------------|
| Groq | Free tier | [console.groq.com/keys](https://console.groq.com/keys) | `llama-3.3-70b-versatile` |
| Google Gemini | Free tier or paid | [aistudio.google.com/apikey](https://aistudio.google.com/apikey) | `gemini-2.5-flash` |

Free tiers are weak for Csound sound design and hit rate limits (~20–30 requests/minute). Dr.C shows a **countdown timer** when throttled and switches between Groq and Gemini if both keys are saved. **Your own paid key works much better.**

**Gemini paid:** Dr.C uses the same `GEMINI_API_KEY` / Settings field — there is no separate “paid key.” Create a key at [Google AI Studio](https://aistudio.google.com/apikey), paste it in Settings, and enable billing in AI Studio when you need higher quotas or paid-tier models. Free vs paid is billing on Google’s side, not a different Dr.C provider.

**Cursor API:** Cursor offers a `CURSOR_API_KEY` for the [Cursor SDK](https://cursor.com/docs/sdk/typescript) (programmatic Cursor agents in scripts, CI, and automations). It is **not** an OpenAI-compatible chat endpoint and is **not wired into Dr.C Standalone** today. For Agent in the GUI, use Anthropic, OpenAI, OpenRouter, Ollama, Groq, or Gemini instead.

**OpenRouter free models:** OpenRouter also hosts zero-cost model slugs ([browse free models](https://openrouter.ai/models?max_price=0)). Dr.C Standalone does **not** preset those today — it routes OpenRouter keys to paid models (`anthropic/claude-sonnet-4`). Use Ollama or Groq/Gemini for free Standalone Agent use.

### Best free option: local model (Ollama)

No API key, no rate limits, runs on your Mac or Linux machine.

| Step | Action |
|------|--------|
| 1 | Install [Ollama](https://ollama.com/download) |
| 2 | Terminal: `ollama pull qwen2.5-coder:7b` |
| 3 | Dr.C **Settings** → **Local LLM server** → **Use local LLM for Agent** → On → **Test** |

**Full guide with model choices and troubleshooting:** **[LOCAL-LLM.md](./LOCAL-LLM.md)**

Smaller laptops: `ollama pull qwen2.5-coder:3b` or `ollama pull llama3.2:3b`

### No model at all

- **Web Apps** tab — no key
- **Player → Workshop demo** — no key
- **Agent** → **Load workshop FM bell (no key)**

**Attendee launchers:** `launch-workshop-attendee.sh` (macOS/Linux).

---

## 5. First steps in the app

### Without any API key

1. **Agent** → **Load workshop FM bell (no key)** (or use golden starters via prompt)
2. **Player** → **Demos** dropdown (FM-Bell, Trapped in Convert, 60+ MIDI models) → keyboard / QWERTY
3. **Web Apps** tab — preview in app; **Open in Browser** after converting an artifact (needs network for WASM CDN)

### Player demo menu groups

| Group | Examples |
|-------|----------|
| Csound Models | FM-Bell |
| Trapped in Convert | Blue, Black, Sand |
| MIDI Synths | Moog, Henon, FM Pan, … |
| Bass / Chinese / HandPan / FM / Pads / … | From Dr. B model collection |

Refresh bundled demos from source folders: `node scripts/ingest-player-model-demos.mjs`

### With API key — try these prompts

**Shimmer FM bell:**
```
make a plain Csound CSD only — no Cabbage. Shimmering FM bell: two inharmonic oscili modulators into a carrier, expsegr decay, global reverb bus (instr 99). Score: descending bell melody (~15 s).
```

**Ping-pong bass:**
```
make a plain Csound CSD only — no Cabbage. Ping-pong pluck bass: foscili FM voice, butterlp, gaEcho + vdelay3 cross-feedback. Score: four-note bass riff (~8 s).
```

Golden reference CSDs: `resources/workshop-starters/`

---

## 6. Verify your install

### macOS / Linux

```bash
export PATH="$HOME/bin:$HOME/Applications/Csound:$HOME/.local/bin:$PATH"
cd Dr.C-Standalone
npm test
```

Expected: platform checks + **126 passed, 0 failed** (smoke) + build

---

## Dr.C Terminal (optional)

For shell-native users — full guide: **`Dr.C/opencode/GET-STARTED.md`**

**OpenCode Zen (Terminal only):** Sign in with `/connect` or `/auth login`, then `/models` to pick a model. [OpenCode Zen](https://opencode.ai/docs/zen/) offers rotating free models (e.g. Big Pickle, DeepSeek V4 Flash Free) plus `opencode/gpt-5-nano`. Paid Zen models need a balance. This path is **not** available in Dr.C Standalone — use Ollama or Groq/Gemini there instead.

| OS | Launcher |
|----|----------|
| macOS | `Dr.C/opencode/launchers/Dr.C-Terminal.command` |
| Linux | `Dr.C/opencode/launchers/Dr.C-Terminal.sh` |

```bash
git clone https://github.com/csounder/DRC-Standalone
cd Dr.C/opencode
bun install
chmod +x scripts/*.sh launchers/*.sh   # macOS/Linux
./scripts/launch-drc-terminal.sh
```

Workshop knowledge bundles are **included in the repo** (no extra sync step).

See also `Dr.C/opencode/WORKSHOP.md`.

---

## Companion tools

**Required:** **CsoundQt 7** and **Cabbage** — install after Csound 7 (§1). Dr.C uses them for **Open in CsoundQt** and **Convert → Cabbage**.

**Optional (recommended):** **Audacity** (listen/edit WAV exports) and **Reaper** (lightweight DAW / VST host).

Full steps: `~/Dr.C-URLS/INSTALL-STANDALONE.md` §2.5–2.8.

**Linux workshop VM (aarch64):** Google Chrome has no official arm64 `.deb`; `scripts/linux-vm-provision.sh` installs **Chromium** (`/usr/bin/chromium-browser`) for **Open in Browser**. Desktop Chrome: [google.com/chrome](https://www.google.com/chrome/).

### CsoundQt 7 — Csound IDE (required)

**Releases:** [github.com/CsoundQt/CsoundQt/releases](https://github.com/CsoundQt/CsoundQt/releases) (v7 AppImage / beta)

| OS | Install |
|----|---------|
| macOS | Download `CsoundQt-*-MacOS.dmg` from the v7 release → **Applications**. Dr.C: **Settings → CsoundQt**. |
| Linux | v7 **AppImage** from GitHub (recommended), or `sudo apt install csoundqt` if your distro ships 7.x. **ARM64:** official v7 AppImage is **x86_64 only** — use macOS or build CsoundQt from source. |

### Cabbage — live plugin UI (required)

**Downloads:** [cabbageaudio.com/download](https://cabbageaudio.com/download/) · [GitHub releases](https://github.com/cabbageaudio/Cabbage/releases)

| OS | Install |
|----|---------|
| macOS | DMG → drag **Cabbage** to **Applications**. Dr.C: **Settings → Cabbage**. |
| Linux | [rorywalsh/cabbage](https://github.com/rorywalsh/cabbage/releases) `CabbageLinux-*.zip` (VST3 + rack). **ARM64:** Linux zip is **x86_64**; full **Cabbage** GUI is on **macOS** for this workshop. |

### Audacity — listen and edit exports (optional)

| OS | Install |
|----|---------|
| macOS | `brew install --cask audacity` or [audacityteam.org/download](https://www.audacityteam.org/download/) |
| Linux | `sudo apt install audacity` (Ubuntu 22.04) or [Flatpak](https://flathub.org/apps/org.audacityteam.Audacity) |

### Reaper — lightweight DAW host (optional)

| OS | Install |
|----|---------|
| macOS | [reaper.fm/download.php](https://www.reaper.fm/download.php) (ARM64) or `brew install --cask reaper` |
| Linux | [reaper.fm/download.php](https://www.reaper.fm/download.php) — eval license; **aarch64** and **x86_64** builds available |

---

## Reference links

| Resource | URL |
|----------|-----|
| **One-slide handout (PDF)** | `resources/workshop/LAC-2026-one-slide.pdf` — or **Settings → Copy workshop links** / **Open one-slide PDF** in the app |
| Dr.C Standalone repo | https://github.com/csounder/DRC-Standalone |
| Dr.C Terminal repo | https://github.com/csounder/DRC-Standalone |
| Csound 7 releases | https://github.com/csound/csound/releases |
| Csound download | https://csound.com/download.html |
| FLOSS Manual | https://flossmanual.csound.com/ |
| Opcode index | https://csound.com/manual/opcodesIndex/ |
| CsoundQt 7 | https://github.com/CsoundQt/CsoundQt/releases |
| Cabbage | https://cabbageaudio.com/download/ |
| Audacity | https://www.audacityteam.org/download/ |
| Reaper | https://www.reaper.fm/download.php |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `csound not found` | Re-run OS install steps; restart terminal; use workshop launcher (sets PATH) |
| Blank screen after Send | Close app; launcher kills stale port 5173 |
| Agent empty / weak Csound | Enable Ollama, or add Anthropic/OpenAI; use offline demos |
| macOS `.command` blocked / “damaged” | Right-click → **Open** → **Open**; `xattr -cr ~/Dr.C-Standalone/launchers/*.command` · `chmod +x launchers/*.command` (see §3) |
| macOS DrC.app “damaged” | Right-click → **Open** → **Open**; or `xattr -cr /Applications/DrC.app` |
| Linux `npm install` fails | Use Node 22; `npx electron-builder install-app-deps` |
| Linux apt `csound` is 6.x | Ubuntu 22.04 ships 6.17 — build Csound 7 from source (see Linux section above) |
| `test:platform` fails Csound 7 | Same — workshop gate needs 7.x even if `test:smoke` passes on 6.x |
| Web app silent in browser | Press **Start Audio**; need internet for Csound WASM CDN; re-convert if console shows `cpsmidinn` errors |
| MIDI demos very quiet | Update to latest `lac-2026-csound7` (velocity 0–1 fix in Player wrap) |
| Settings → **Web Browser** | Choose Chrome/Safari/Firefox for **Open in Browser** on web app artifacts |

More in this repo: [WORKSHOP.md](./WORKSHOP.md) (branch notes), [TESTING.md](./TESTING.md), [VERSIONS.md](./VERSIONS.md)
