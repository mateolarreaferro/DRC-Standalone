#!/usr/bin/env bash
# macOS host — launch Dr.C Standalone inside lac-2026-linux on the active RDP display.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=linux-vm-host.sh
source "${SCRIPT_DIR}/linux-vm-host.sh"

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      cat <<USAGE
Usage: $(basename "$0")

  Starts VM if needed, syncs repos, detects DISPLAY (xrdp :10+), launches
  Dr.C Standalone Electron inside the Windows App RDP session.

  Connect RDP first: ~/Dr.C-Standalone/scripts/open-linux-desktop.sh

VM: ${VM_NAME} (override with DRC_LINUX_VM)
USAGE
      exit 0
      ;;
  esac
done

drc_ensure_vm_running
drc_vm_sync_from_mount

DISPLAY="$(drc_vm_detect_display || true)"
IP="$(drc_vm_ip || echo '?')"

echo ""
echo "━━━ Dr.C Linux Standalone (RDP) — ${VM_NAME} ━━━"
echo "  IPv4: ${IP}"
echo "  DISPLAY: ${DISPLAY:-<none — connect RDP first>}"
echo ""

drc_vm_xrdp_reminder

if [[ -z "${DISPLAY}" ]]; then
  echo "Cannot launch GUI without an X display in the VM."
  read -r -p "Press Enter to close…" _
  exit 1
fi

echo "Preflight (DRC_DRY_RUN=1)…"
drc_vm_bash_lc "export DISPLAY=${DISPLAY}; ${DRC_VM_PATH_EXPORT}; ${DRC_VM_LD_EXPORT}; cd ~/Dr.C-Standalone && DRC_DRY_RUN=1 ./scripts/launch-drc.sh"
echo ""

if [[ "${DRC_DRY_RUN:-}" == "1" ]]; then
  exit 0
fi

echo "Launching Dr.C Standalone on DISPLAY=${DISPLAY} (window appears in RDP)…"
echo ""

drc_vm_bash_lc "export DISPLAY=${DISPLAY}; ${DRC_VM_PATH_EXPORT}; ${DRC_VM_LD_EXPORT}; cd ~/Dr.C-Standalone && ./scripts/launch-drc.sh" &
LAUNCH_PID=$!

sleep 2
if kill -0 "${LAUNCH_PID}" 2>/dev/null; then
  echo "Dr.C is starting in the Linux VM — switch to your Windows App RDP window."
  echo "(This Terminal window can stay open; Ctrl+C does not stop Dr.C in the VM.)"
  read -r -p "Press Enter to close…" _
else
  wait "${LAUNCH_PID}" || true
  read -r -p "Press Enter to close…" _
fi
