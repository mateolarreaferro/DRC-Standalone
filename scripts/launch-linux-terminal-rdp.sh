#!/usr/bin/env bash
# macOS host — open Dr.C Terminal TUI in xfce4-terminal on the Linux RDP desktop.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=linux-vm-host.sh
source "${SCRIPT_DIR}/linux-vm-host.sh"

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      cat <<USAGE
Usage: $(basename "$0")

  Starts VM if needed, syncs repos, detects DISPLAY (xrdp :10+), opens
  xfce4-terminal in the RDP session running Dr.C Terminal TUI.

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
echo "━━━ Dr.C Linux Terminal (RDP) — ${VM_NAME} ━━━"
echo "  IPv4: ${IP}"
echo "  DISPLAY: ${DISPLAY:-<none — connect RDP first>}"
echo ""

drc_vm_xrdp_reminder

if [[ -z "${DISPLAY}" ]]; then
  echo "Cannot open terminal without an X display in the VM."
  read -r -p "Press Enter to close…" _
  exit 1
fi

echo "Preflight…"
drc_vm_ensure_terminal_deps
drc_vm_bash_lc "export DISPLAY=${DISPLAY}; ${DRC_VM_PATH_EXPORT}; cd ~/Dr.C/opencode && DRC_DRY_RUN=1 ./scripts/launch-drc-terminal.sh"
echo ""

if [[ "${DRC_DRY_RUN:-}" == "1" ]]; then
  exit 0
fi

echo "Opening Dr.C Terminal in xfce4-terminal on DISPLAY=${DISPLAY}…"
echo ""

DRC_TERM_INNER='export PATH="$HOME/bin:$HOME/Applications/Csound/bin:$HOME/.bun/bin:$PATH"; cd "$HOME/Dr.C/opencode" && exec ./scripts/launch-drc-terminal.sh'

if ! drc_vm_bash_lc "export DISPLAY=${DISPLAY}; xfce4-terminal --hold -e bash -lc $(printf '%q' "${DRC_TERM_INNER}")"; then
  echo ""
  echo "xfce4-terminal failed. Is RDP connected? Try from VM shell:"
  echo "  export DISPLAY=${DISPLAY}"
  echo "  ${DRC_TERM_INNER}"
  read -r -p "Press Enter to close…" _
  exit 1
fi

echo "Dr.C Terminal should appear in your Windows App RDP window."
read -r -p "Press Enter to close…" _
