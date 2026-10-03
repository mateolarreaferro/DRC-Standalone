#!/usr/bin/env bash
# macOS host — run Dr.C Terminal TUI inside lac-2026-linux (Multipass).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=linux-vm-host.sh
source "${SCRIPT_DIR}/linux-vm-host.sh"

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      cat <<USAGE
Usage: $(basename "$0")

  Starts VM if needed, preflight, then runs Dr.C Terminal in the VM.
  Double-click the Desktop .command so Terminal.app provides a TTY for the TUI.

VM: ${VM_NAME} (override with DRC_LINUX_VM)
USAGE
      exit 0
      ;;
  esac
done

drc_ensure_vm_running
drc_vm_sync_from_mount

echo ""
echo "━━━ Dr.C Linux Terminal (${VM_NAME}) ━━━"
echo "  IPv4: $(drc_vm_ip || echo '?')"
echo ""

if [[ "${DRC_DRY_RUN:-}" == "1" ]]; then
  drc_vm_ensure_terminal_deps
  drc_vm_bash_lc "${DRC_VM_PATH_EXPORT}; cd ~/Dr.C/opencode && DRC_DRY_RUN=1 ./scripts/launch-drc-terminal.sh"
  exit 0
fi

echo "Preflight…"
drc_vm_ensure_terminal_deps
drc_vm_bash_lc "${DRC_VM_PATH_EXPORT}; cd ~/Dr.C/opencode && DRC_DRY_RUN=1 ./scripts/launch-drc-terminal.sh"
echo ""
echo "Starting Dr.C Terminal in VM (Ctrl+C to stop)…"
echo ""

exec multipass exec "${VM_NAME}" -- bash -lc "${DRC_VM_PATH_EXPORT}; cd ~/Dr.C/opencode && exec ./scripts/launch-drc-terminal.sh"
