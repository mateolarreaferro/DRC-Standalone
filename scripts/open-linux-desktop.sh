#!/usr/bin/env bash
# Start lac-2026-linux and open RDP to the Linux XFCE desktop (Dr.C icons live there).
set -euo pipefail

VM="lac-2026-linux"

if ! command -v multipass >/dev/null 2>&1; then
  echo "Multipass not found. Install from https://multipass.run"
  exit 1
fi

multipass start "$VM" 2>/dev/null || true

IP="$(multipass info "$VM" --format csv 2>/dev/null | tail -1 | cut -d, -f3 || true)"
if [ -z "$IP" ]; then
  IP="$(multipass info "$VM" 2>/dev/null | awk '/IPv4/{print $2; exit}')"
fi

XRDP_STATUS="$(multipass exec "$VM" -- systemctl is-active xrdp 2>/dev/null || echo inactive)"

XRDP_KEY_OK="$(multipass exec "$VM" -- sudo -u xrdp test -r /etc/xrdp/key.pem 2>/dev/null && echo yes || echo no)"
WM_CRASH="$(multipass exec "$VM" -- bash -c 'grep -q "exit code 139" /var/log/xrdp-sesman.log 2>/dev/null && echo yes || echo no' 2>/dev/null || echo no)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Dr.C Linux Desktop (XFCE inside $VM)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1. Open Windows App (Mac App Store; was Microsoft Remote Desktop)"
echo "  2. Add PC:  ${IP}:3389"
echo "  3. User:     ubuntu"
echo "  4. Password: ubuntu"
echo ""
echo "  xrdp status: $XRDP_STATUS"
if [ "$XRDP_STATUS" != "active" ]; then
  echo ""
  echo "  xrdp is not active. Install the desktop once:"
  echo "    multipass transfer ~/Dr.C-Standalone/scripts/vm-setup-linux-desktop.sh $VM:/tmp/"
  echo "    multipass exec $VM -- sudo bash /tmp/vm-setup-linux-desktop.sh"
elif [ "$XRDP_KEY_OK" != "yes" ]; then
  echo ""
  echo "  xrdp TLS key not readable (connections may fail). On the VM:"
  echo "    sudo adduser xrdp ssl-cert && sudo systemctl restart xrdp"
fi
if [ "$WM_CRASH" = "yes" ]; then
  echo ""
  echo "  Note: Recent RDP log shows XFCE window-manager crash (exit 139)."
  echo "  Re-run vm-setup-linux-desktop.sh on the VM, then reconnect."
  echo "  Workshop fallback (no RDP): multipass shell $VM"
fi
echo ""
echo "  Guide: ~/Dr.C-Workshop-Demo/LINUX-DESKTOP.md"
echo ""

RDP_APP=""
RDP_LEGACY="/Applications/Microsoft Remote Desktop.app"
RDP_WINAPP="/Applications/Windows App.app"
RDP_RESET_HINT="If Windows App crashes on launch, run: ~/Dr.C-Standalone/scripts/reset-windows-app-rdp-state.sh --execute"

open_rdp_client() {
  local opened=false
  if [ -d "$RDP_LEGACY" ] && [ -d "$RDP_WINAPP" ]; then
    if open -a "Microsoft Remote Desktop" 2>/dev/null; then
      RDP_APP="Microsoft Remote Desktop"
      opened=true
    elif open -a "Windows App" 2>/dev/null; then
      RDP_APP="Windows App"
      opened=true
    fi
  elif [ -d "$RDP_LEGACY" ]; then
    if open -a "Microsoft Remote Desktop" 2>/dev/null; then
      RDP_APP="Microsoft Remote Desktop"
      opened=true
    fi
  elif [ -d "$RDP_WINAPP" ]; then
    if open -a "Windows App" 2>/dev/null; then
      RDP_APP="Windows App"
      opened=true
    elif [ -d "$RDP_LEGACY" ] && open -a "Microsoft Remote Desktop" 2>/dev/null; then
      RDP_APP="Microsoft Remote Desktop"
      opened=true
    fi
  fi
  if [ "$opened" = false ]; then
    echo "  $RDP_RESET_HINT"
    return 1
  fi
  return 0
}

if [ -d "$RDP_LEGACY" ] || [ -d "$RDP_WINAPP" ]; then
  echo "  Opening RDP client…"
  open_rdp_client || true
  echo "  In the app: Add PC → ${IP} → user ubuntu / password ubuntu"
  echo "  If the app quits when you connect, use: multipass shell $VM"
  if [ -n "$RDP_APP" ]; then
    echo "  Using: ${RDP_APP}"
  fi
else
  echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  No RDP app found. Install one (free) from the Mac App Store:"
  echo ""
  echo "    Search:  Windows App"
  echo "    (or legacy name: Microsoft Remote Desktop)"
  echo ""
  echo "    https://apps.apple.com/app/windows-app/id1295203466"
  echo ""
  echo "  After install: Add PC → ${IP}:3389 → ubuntu / ubuntu"
  echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  open "https://apps.apple.com/app/windows-app/id1295203466" 2>/dev/null || true
fi

read -r -p "Press Enter to close…" _
