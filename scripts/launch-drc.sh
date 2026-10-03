#!/usr/bin/env bash
# Launch Dr.C Standalone with Csound 7 first on PATH (macOS + Linux workshop build)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=workshop-path.sh
source "${SCRIPT_DIR}/workshop-path.sh"

export DRC_PRO_PLUS="${DRC_PRO_PLUS:-1}"
export DRC_WORKSHOP_LITE="${DRC_WORKSHOP_LITE:-0}"

ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$ROOT"

if ! command -v csound >/dev/null 2>&1; then
  echo "Csound not found. Install Csound 7 and ensure it is on PATH."
  echo "See PARTICIPANTS.md (macOS or Linux section)."
  exit 1
fi

echo "Dr.C Standalone (Csound 7) — tier: ${DRC_PRO_PLUS} Pro+ | OS: $(uname -s)"
echo "Csound: $(csound --version 2>&1 | head -1)"
echo ""


if [[ "$(uname -s)" == "Linux" ]]; then
  case "$ROOT" in
    /mnt/*)
      echo "Do not run Dr.C from a Multipass mount ($ROOT)."
      echo "Work in ~/Dr.C-Standalone (sync from /mnt without node_modules, then npm install on the VM)."
      echo "See ~/Dr.C-Workshop-Demo/LINUX-DESKTOP.md"
      exit 1
      ;;
  esac
  rollup_native=""
  case "$(uname -m)" in
    aarch64|arm64) rollup_native="node_modules/@rollup/rollup-linux-arm64-gnu" ;;
    x86_64|amd64) rollup_native="node_modules/@rollup/rollup-linux-x64-gnu" ;;
  esac
  if [[ -n "$rollup_native" && ! -d "$rollup_native" ]]; then
    echo "Linux-native npm dependencies are missing ($rollup_native)."
    if [[ -d node_modules/@rollup/rollup-darwin-arm64 ]] || [[ -d node_modules/@rollup/rollup-darwin-x64 ]]; then
      echo "node_modules appears to be from macOS (Multipass mount or copied Mac install)."
    fi
    echo "On this VM: cd ~/Dr.C-Standalone && rm -rf node_modules && npm install"
    echo "See ~/Dr.C-Workshop-Demo/LINUX-DESKTOP.md"
    exit 1
  fi
fi

if [[ ! -d node_modules ]]; then
  echo "Run: npm install"
  exit 1
fi

if command -v lsof >/dev/null 2>&1 && lsof -ti:5173 >/dev/null 2>&1; then
  echo "Closing previous Dr.C session on port 5173…"
  lsof -ti:5173 | xargs kill 2>/dev/null || true
  sleep 1
fi

if ! npm run check-memory --silent 2>/dev/null; then
  echo ""
  echo "Memory is OFF — rebuilding better-sqlite3 for Electron…"
  npx electron-builder install-app-deps
fi

if [[ "${DRC_DRY_RUN:-}" == "1" ]]; then
  echo "DRC_DRY_RUN=1 — preflight OK (skipping npm run dev)"
  exit 0
fi

# Start Ollama when installed but not already serving (local LLM for Agent).
if command -v ollama >/dev/null 2>&1; then
  if ! curl -sf --max-time 2 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
    echo "Starting Ollama (local LLM)…"
    nohup ollama serve >/tmp/ollama-drc.log 2>&1 &
    for _ in {1..24}; do
      curl -sf --max-time 2 http://127.0.0.1:11434/api/tags >/dev/null 2>&1 && break
      sleep 0.5
    done
  fi
fi

exec npm run dev
