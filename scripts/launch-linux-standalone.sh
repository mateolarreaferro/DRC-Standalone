#!/usr/bin/env bash
# macOS host — run Dr.C Standalone inside lac-2026-linux (Multipass).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=linux-vm-host.sh
source "${SCRIPT_DIR}/linux-vm-host.sh"

DO_SHELL=0
for arg in "$@"; do
  case "$arg" in
    --shell) DO_SHELL=1 ;;
    -h|--help)
      cat <<USAGE
Usage: $(basename "$0") [--shell]

  Default: preflight in VM, warn about GUI, then multipass exec launch-drc.sh
           (Electron needs a display inside the VM — fails headless).

  --shell   Skip launch attempt; open interactive multipass shell instead.

VM: ${VM_NAME} (override with DRC_LINUX_VM)
USAGE
      exit 0
      ;;
  esac
done

drc_ensure_vm_running

drc_vm_sync_from_mount

echo ""
echo "━━━ Dr.C Linux Standalone (${VM_NAME}) ━━━"
echo "  IPv4: $(drc_vm_ip || echo '?')"
echo ""
echo "GUI note: Electron needs an X11/Wayland session inside the VM."
echo "Multipass from macOS cannot show the Linux desktop window on your Mac."
echo "For on-stage GUI demos use Dr.C Mac Standalone on the host."
echo ""

echo "Preflight (DRC_DRY_RUN=1)…"
drc_vm_bash_lc "${DRC_VM_PATH_EXPORT}; ${DRC_VM_LD_EXPORT}; cd ~/Dr.C-Standalone && DRC_DRY_RUN=1 ./scripts/launch-drc.sh"
echo ""

if [[ "${DRC_DRY_RUN:-}" == "1" ]]; then
  exit 0
fi

if [[ "${DO_SHELL}" -eq 1 ]]; then
  echo "Entering VM shell — run: cd ~/Dr.C-Standalone && ./scripts/launch-drc.sh"
  echo ""
  exec multipass shell "${VM_NAME}"
fi

echo "Launching Standalone inside VM (requires DISPLAY in VM)…"
echo ""
exec multipass exec "${VM_NAME}" -- bash -lc "${DRC_VM_PATH_EXPORT}; ${DRC_VM_LD_EXPORT}; cd ~/Dr.C-Standalone && exec ./scripts/launch-drc.sh"
