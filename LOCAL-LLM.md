# Local LLM setup for Dr.C (LAC 2026 — macOS & Linux)

Run a language model **on your own machine** — no API key, no rate limits, no data sent to the cloud.

Dr.C connects to any **OpenAI-compatible local server** (Ollama, LM Studio, llama.cpp server, …).

> **LAC 2026:** macOS and Linux only. Windows is out of scope for this session.

Full participant guide: **[PARTICIPANTS.md](./PARTICIPANTS.md)**

---

## Settings in Dr.C

| | |
|---|---|
| **Section** | Settings → **Local LLM server** |
| **Server URL** | Ollama default `http://127.0.0.1:11434` · LM Studio `http://127.0.0.1:1234` |
| **Toggle** | **Use local LLM for Agent** → **Refresh** → **Test** |

Dr.C discovers models via **`/v1/models`** (OpenAI-compatible). Ollama’s native `/api/tags` is used as a fallback.

---

## Recommended: Ollama

| | |
|---|---|
| **Download** | [ollama.com/download](https://ollama.com/download) |
| **Platforms** | macOS, Linux (LAC 2026) |
| **Cost** | Free and open source |
| **Dr.C setup** | Settings → **Local LLM server** → set URL if needed → **Use local LLM for Agent** → **Test** |

### Step by step

1. Install Ollama from [ollama.com/download](https://ollama.com/download) and open the app (menu-bar icon on Mac).
2. In Terminal, pull a coding model (pick one row below).
3. In Dr.C → **Settings** → **Local LLM server**:
   - Confirm **Server URL** (blank = Ollama default `http://127.0.0.1:11434`)
   - Turn **Use local LLM for Agent** **On**
   - Choose the model → **Refresh** → **Test**
4. Optional: turn **Prefer local over cloud keys** **On** if you also saved Groq/Gemini/OpenRouter keys but want local first.

### Models that work well with Dr.C

| Model | Command | RAM (approx.) | Notes |
|-------|---------|---------------|--------|
| **Qwen 2.5 Coder 7B** (default) | `ollama pull qwen2.5-coder:7b` | ~8 GB | Best balance for Csound / code on a typical laptop |
| Qwen 2.5 Coder 3B | `ollama pull qwen2.5-coder:3b` | ~4 GB | Lighter machines |
| Llama 3.2 3B | `ollama pull llama3.2:3b` | ~4 GB | Fast, general purpose |
| DeepSeek Coder V2 Lite | `ollama pull deepseek-coder-v2:16b-lite-instruct-q4_0` | ~10 GB | Strong coder if you have RAM |
| Code Llama 7B | `ollama pull codellama:7b` | ~8 GB | Older but solid for code |

Browse more: [ollama.com/library](https://ollama.com/library)

### Apple Silicon (M1/M2/M3/M4)

Ollama uses Metal automatically — no extra setup. The 7B models run well on 16 GB RAM MacBooks.

### Linux

Same install flow. If Dr.C cannot find Ollama, ensure the service is running: `ollama serve` (or use the systemd user service from the Ollama install docs).

---

## LM Studio & llama.cpp server

| Tool | Server URL in Settings | Notes |
|------|------------------------|--------|
| **LM Studio** | `http://127.0.0.1:1234` | Load a coder model → **Local Server** tab → Start server |
| **llama.cpp** (`llama-server`) | e.g. `http://127.0.0.1:8080` | Start with OpenAI-compatible API enabled |

Use **Refresh** after the server is running so Dr.C lists models from `/v1/models`.

---

## Other desktop apps (chat only)

| Tool | Link | Notes |
|------|------|--------|
| **GPT4All** | [gpt4all.io](https://gpt4all.io/) | Not wired into Dr.C Agent |
| **Jan** | [jan.ai](https://jan.ai/) | Not wired into Dr.C Agent |

---

## Compare: local vs free cloud vs your own API key

| Option | Cost | Rate limits | Sound-design quality | Setup | Standalone? |
|--------|------|-------------|----------------------|--------|-------------|
| **Ollama (local)** | Free | None | Good — better than free Gemini/Groq for many users | Install + server URL + model | Yes |
| Groq (free tier) | Free | Yes (~30 req/min) | Variable; often weak for Csound | Paste key in Settings | Yes |
| Gemini (free or paid) | Free tier; paid via AI Studio billing | Yes on free tier (~20 req/min) | Variable on free; better with billing | Same key at [aistudio.google.com/apikey](https://aistudio.google.com/apikey) — enable billing for paid quotas | Yes |
| **Anthropic (Claude)** | Pay per use | Account limits only | **Best** — instructor typical | Settings → **Anthropic (Claude)** or `ANTHROPIC_API_KEY` in `.env` | Yes |
| **OpenAI** | Pay per use | Account limits only | **Best** — instructor typical | Settings → **OpenAI** or `OPENAI_API_KEY` in `.env` | Yes |
| **OpenRouter (paid defaults)** | Pay per use | Account limits only | **Best** — one key, routes to Claude, GPT, Gemini | Settings or `OPENROUTER_API_KEY` | Yes |
| OpenRouter `:free` slugs | Free | Yes (50/day without credits) | Variable | [Browse free models](https://openrouter.ai/models?max_price=0) — **not preset in Dr.C Standalone today** | No (future) |
| **OpenCode Zen** | Free + paid models | Varies by model | Good for Terminal workflow | `/connect` in Dr.C Terminal | **Terminal only** |
| No model | Free | — | Use offline demos only | Web Apps, Player workshop demo | Yes |

**Workshop advice:** Offer **Ollama** as the best free path with no signup. **Instructor typical:** **Anthropic** or **OpenAI** (paid) — paste in **Settings → API Keys** or set `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` in `.env`. **OpenRouter** is a good one-key alternative. **Attendees:** Groq/Gemini as optional free backups (rate-limit timers apply). **Gemini paid:** same `GEMINI_API_KEY` — enable billing in [Google AI Studio](https://aistudio.google.com/apikey).

**Not in Standalone:** **Cursor API** ([Cursor SDK](https://cursor.com/docs/sdk/typescript)) — agent automation for IDE/CI, not a drop-in chat key for Dr.C Agent.

**Cloud keys (not local):** [PARTICIPANTS.md §4](./PARTICIPANTS.md#4-agent--llm-optional) · [Anthropic](https://console.anthropic.com/settings/keys) · [OpenAI](https://platform.openai.com/api-keys) · [Gemini](https://aistudio.google.com/apikey)

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| “Ollama not detected” / server unreachable | Check **Server URL**; start Ollama, LM Studio local server, or llama.cpp |
| “Model not found” | Run the `ollama pull …` command for that model |
| Slow first reply | Normal — model loads into RAM on first use |
| Out of memory | Use a smaller model (`qwen2.5-coder:3b` or `llama3.2:3b`) |
| Agent still uses cloud | Turn on **Prefer local over cloud keys**, or remove cloud keys temporarily |

---

## Dr.C Terminal (CLI)

Same Ollama install. In the TUI: `/settings` → enable **use Ollama** → **test**.

**OpenCode Zen (Terminal only — not Standalone):** `/connect` or `/auth login`, then `/models`. Free rotating models and `opencode/gpt-5-nano` are listed at [opencode.ai/docs/zen](https://opencode.ai/docs/zen/). Paid Zen models need a balance.

Guide: [Dr.C/opencode/GET-STARTED.md](https://github.com/mateolarreaferro/Dr.C/blob/main/opencode/GET-STARTED.md)
