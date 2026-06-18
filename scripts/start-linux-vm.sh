#!/usr/bin/env bash
# LAC 2026 — start Multipass Linux VM only (no shell); macOS host
set -euo pipefail

VM_NAME="${DRC_LINUX_VM:-lac-2026-linux}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROVISION_SCRIPT="${SCRIPT_DIR}/linux-vm-provision.sh"

if ! command -v multipass >/dev/null 2>&1; then
  echo "multipass is not installed."
  echo ""
  echo "Install Multipass for macOS:"
  echo "  brew install --cask multipass"
  echo "  — or — https://multipass.run/install"
  echo ""
  echo "Then create the workshop VM (Ubuntu 22.04 aarch64) and run provision once."
  exit 1
fi

if ! multipass info "${VM_NAME}" >/dev/null 2>&1; then
  echo "Multipass VM '${VM_NAME}' not found."
  echo ""
  echo "Create and provision the LAC 2026 Linux VM, then re-run this launcher."
  echo "Provision script: ${PROVISION_SCRIPT}"
  exit 1
fi

STATE="$(multipass info "${VM_NAME}" 2>/dev/null | awk -F': ' '/^State:/ {print $2}')"
if [[ "${STATE}" != "Running" ]]; then
  echo "Starting ${VM_NAME}…"
  multipass start "${VM_NAME}"
else
  echo "${VM_NAME} is already running."
fi

echo ""
echo "━━━ ${VM_NAME} ━━━"
multipass info "${VM_NAME}" | awk -F': ' '/^State:|^Release:|^IPv4:/ {printf "  %-8s %s\n", $1, $2}'
echo ""
echo "Double-click Dr.C Linux VM Shell to enter."
echo ""

if [[ -d /Applications/Multipass.app ]] || [[ -d "${HOME}/Applications/Multipass.app" ]]; then
  open -a Multipass 2>/dev/null || true
fi
