#!/usr/bin/env bash
# LAC workshop — from USB or any clone location (macOS + Linux)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export DRC_STANDALONE_ROOT="${DRC_STANDALONE_ROOT:-${SCRIPT_DIR}}"

if [[ -x "${DRC_STANDALONE_ROOT}/scripts/launch-workshop-attendee.sh" ]]; then
  exec "${DRC_STANDALONE_ROOT}/scripts/launch-workshop-attendee.sh"
fi

echo "Run from Dr.C-Standalone repo root, or set DRC_STANDALONE_ROOT"
exit 1
