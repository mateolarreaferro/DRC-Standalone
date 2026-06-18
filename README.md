# DrC — Standalone

AI-powered Csound creative tool. Electron app.

**LAC 2026 workshop:** platform handouts and QR sheet → [csounder/Dr.C-Workshop-Demo](https://github.com/csounder/Dr.C-Workshop-Demo). App install and launch → **[PARTICIPANTS.md](./PARTICIPANTS.md)**. Local LLM → **[LOCAL-LLM.md](./LOCAL-LLM.md)**.

## Install (LAC 2026 workshop)

```bash
git clone -b lac-2026-csound7 https://github.com/csounder/DRC-Standalone.git
cd DRC-Standalone
npm install
```

Pre-built installers may be added later; for LAC 2026 use **git clone** on `lac-2026-csound7`.

1. Install **Csound 7** once (the app calls the `csound` CLI):
   - macOS: install from [csound/csound releases](https://github.com/csound/csound/releases) to `~/Applications/Csound/` (not Homebrew 6.x)
   - Linux: install Csound 7 from [GitHub releases](https://github.com/csound/csound/releases) or build from source (Ubuntu 22.04 apt ships 6.x)
   - Windows: installer at [csound.com/download](https://csound.com/download.html)
2. Launch with workshop launcher (see [PARTICIPANTS.md](./PARTICIPANTS.md)), open **Settings**, paste an AI Studio Gemini key
   (free — [aistudio.google.com/apikey](https://aistudio.google.com/apikey)),
   hit **Test** — or use offline demos with no key.

> **macOS first launch (packaged builds only):** unsigned apps may show Gatekeeper warnings. Either right-click the app → **Open** →
> **Open**, or run once:
> ```bash
> xattr -cr /Applications/DrC.app
> ```

## Build from source

### Prerequisites

- **Node.js ≥ 20** and npm
- **Git**
- **Csound** on your `PATH` — the app shells out to the Csound CLI for
  compile/render/play
  - macOS: `brew install csound`
  - Linux (Debian/Ubuntu): `sudo apt install csound`
  - Windows: download from [csound.com/download](https://csound.com/download.html)

### Clone and install

```bash
git clone -b lac-2026-csound7 https://github.com/csounder/DRC-Standalone.git
cd DRC-Standalone
npm install
```

Add an API key (either works):

1. Settings page → paste a Gemini key and hit **Test**. Use an **AI Studio** key
   (Gemini Developer API, free) from https://aistudio.google.com/apikey —
   Vertex AI credentials won't work.
2. Copy `.env.example` to `.env` at the repo root and fill in the key(s):
   ```
   GEMINI_API_KEY=...
   # optional fallbacks:
   ANTHROPIC_API_KEY=...
   OPENAI_API_KEY=...
   ```

The app pins the Gemini endpoint to `generativelanguage.googleapis.com/v1beta`,
which is what free AI Studio keys authenticate against.

### Run

```bash
npm run dev        # dev with hot reload (opens the Electron window)
npm run build      # bundle main + preload + renderer → out/
npm run typecheck  # tsc, both node + web projects
```

`npm run dev` is the usual day-to-day entry point — it bundles, launches
Electron, and hot-reloads on file changes.

After `npm run build`, you can relaunch the bundled output without the dev
server:

```bash
npx electron out/main/index.js
```

### Package an installer

```bash
npm run dist:mac     # → release/DrC-<version>-arm64.dmg + x64
npm run dist:win     # → release/DrC Setup <version>.exe
npm run dist:linux   # → release/DrC-<version>.AppImage
npm run dist         # current platform, defaults
```

Artifacts land in `release/`. Builds are **unsigned** — distributing a signed
mac build requires an Apple Developer ID and `CSC_LINK`/`CSC_KEY_PASSWORD` env
vars; see [electron-builder's code signing guide](https://www.electron.build/code-signing).

## Architecture

See [SYSTEM.md](./SYSTEM.md) for full system documentation.

Short version:
- **Main** (`src/main/`): LLM provider (Google/Anthropic/OpenAI), Csound CLI, RAG engine, IPC handlers.
- **Preload** (`src/preload/`): typed `window.api` bridge.
- **Renderer** (`src/renderer/`): React 19 UI with artifact panel (CSD / Web App / VST).
- **Resources** (`resources/knowledge/`): 197 opcode cards, 1,952 CSD examples, Csound Book full text.

## Artifacts

Three artifact types are auto-detected from LLM output:

| Type | Trigger | Files |
|------|---------|-------|
| CSD | `<CsoundSynthesizer>...</CsoundSynthesizer>` | `main.csd` |
| Web App | `<!DOCTYPE html>...</html>` | `index.html` + derived `app.js`, `style.css`, `main.csd` |
| VST | `<Cabbage>` + `<CsoundSynthesizer>` | `main.csd` + derived `widgets.cabbage` |

Edit the primary file (e.g. `main.csd`, `index.html`) in the artifact panel — derived files are read-only views that re-compute after each edit.
