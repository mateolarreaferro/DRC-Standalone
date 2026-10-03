#!/usr/bin/env bash
# LAC workshop attendees — free tier, Groq-first, one LLM call per Agent turn.
set -euo pipefail
export DRC_PRO_PLUS=0
export DRC_WORKSHOP_LITE=1
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "${ROOT}/scripts/launch-drc.sh"
