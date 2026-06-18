#!/usr/bin/env bash
# Reset local Windows App (Microsoft RDC) sandbox state when the app crashes on launch.
# WARNING: Removes saved PCs/workspaces in the Mac client — you must re-add lac-2026-linux (ubuntu/ubuntu).
set -euo pipefail

EXECUTE=0
if [[ "${1:-}" == "--execute" ]]; then
  EXECUTE=1
fi

echo "Windows App / Microsoft RDC — reset local state (Mac)"
echo ""
echo "This removes sandbox data only (not the VM). You will need to re-add:"
echo "  PC: lac-2026-linux IP on port 3389, user ubuntu / password ubuntu"
echo ""
echo "Paths targeted:"
echo "  ~/Library/Containers/com.microsoft.rdc.macos"
echo "  ~/Library/Containers/com.microsoft.rdc.macos.qlx"
echo "  ~/Library/Group Containers/UBF8T346G9.com.microsoft.rdc"
echo "  ~/Library/Group Containers/UBF8T346G9.group.com.microsoft.shared (optional — may sign you out of other MS apps)"
echo ""
echo "Quit Windows App first (Activity Monitor → Windows App → Quit)."
echo ""

if [[ "$EXECUTE" -ne 1 ]]; then
  echo "Dry run only. To delete the folders above, run:"
  echo "  $0 --execute"
  exit 0
fi

read -r -p "Type YES to delete RDC container data: " confirm
if [[ "$confirm" != "YES" ]]; then
  echo "Aborted."
  exit 1
fi

osascript -e 'quit app "Windows App"' 2>/dev/null || true
sleep 1

for path in \
  "$HOME/Library/Containers/com.microsoft.rdc.macos" \
  "$HOME/Library/Containers/com.microsoft.rdc.macos.qlx" \
  "$HOME/Library/Group Containers/UBF8T346G9.com.microsoft.rdc"
do
  if [[ -e "$path" ]]; then
    echo "Removing $path"
    rm -rf "$path"
  fi
done

echo ""
echo "Done. Reinstall or open Windows App from Applications, then Add PC again."
echo "Guide: ~/Dr.C-Workshop-Demo/LINUX-DESKTOP.md"
