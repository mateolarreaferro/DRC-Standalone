#!/usr/bin/env bash
# One-time setup: XFCE + xrdp on Ubuntu 22.04 (Multipass lac-2026-linux).
# Run on the VM: sudo bash vm-setup-linux-desktop.sh
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

VM_USER="${VM_USER:-ubuntu}"
VM_HOME="/home/${VM_USER}"

install_drc_desktop_shortcuts() {
  local DESK="${VM_HOME}/Desktop"
  local BIN="${VM_HOME}/bin"
  mkdir -p "$DESK" "$BIN"
  chown "${VM_USER}:${VM_USER}" "$DESK" "$BIN"

  # Fallback GUI launcher (Run from terminal or assign to a custom shortcut).
  cat > "${BIN}/drc-standalone-gui.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/bin:${HOME}/Applications/Csound/bin:${HOME}/.bun/bin:${PATH:-}"
ROOT="${HOME}/Dr.C-Standalone"
if [[ ! -d "$ROOT" ]]; then
  echo "Missing ${ROOT}. Sync Dr.C-Standalone from the host (see WORKSHOP.md)."
  read -r -p "Press Enter to close…" _
  exit 1
fi
cd "$ROOT"
if [[ ! -x ./scripts/launch-drc.sh ]]; then
  echo "Missing ./scripts/launch-drc.sh in ${ROOT}"
  read -r -p "Press Enter to close…" _
  exit 1
fi
if ! ./scripts/launch-drc.sh; then
  ec=$?
  echo ""
  echo "Dr.C Standalone exited with status ${ec}."
  read -r -p "Press Enter to close…" _
  exit "$ec"
fi
EOF
  chmod +x "${BIN}/drc-standalone-gui.sh"
  chown "${VM_USER}:${VM_USER}" "${BIN}/drc-standalone-gui.sh"

  # XFCE ignores or prompts on untrusted .desktop files; use a visible terminal for errors.
  local DRC_PATH='export PATH="$HOME/bin:$HOME/Applications/Csound/bin:$HOME/.bun/bin:$PATH"'

  cat > "${DESK}/Dr.C-Standalone.desktop" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Dr.C Standalone
Comment=Launch Dr.C Electron in Linux VM
Path=${VM_HOME}/Dr.C-Standalone
Exec=xfce4-terminal --hold -e bash -lc '${DRC_PATH}; exec "\$HOME/Dr.C-Standalone/scripts/launch-drc.sh"'
Icon=applications-multimedia
Terminal=false
Categories=Audio;
EOF

  cat > "${DESK}/Dr.C-Terminal.desktop" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Dr.C Terminal
Comment=Dr.C TUI
Path=${VM_HOME}/Dr.C/opencode
Exec=xfce4-terminal --hold -e bash -lc '${DRC_PATH}; exec "\$HOME/Dr.C/opencode/scripts/launch-drc-terminal.sh"'
Icon=utilities-terminal
Terminal=false
Categories=Development;
EOF

  cat > "${DESK}/Terminal-Dr.C-Standalone.desktop" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Terminal (Dr.C folder)
Comment=Open shell in Dr.C-Standalone
Exec=xfce4-terminal --working-directory=${VM_HOME}/Dr.C-Standalone
Icon=utilities-terminal
Terminal=false
Categories=System;
EOF

  chown "${VM_USER}:${VM_USER}" "${DESK}"/*.desktop
  chmod +x "${DESK}"/*.desktop

  echo "[vm-setup] desktop shortcuts installed in ${DESK}"
}

# XFCE 4.16+: desktop launchers need trusted metadata or clicks do nothing.
enable_xfce_desktop_launchers() {
  local desktop="${VM_HOME}/Desktop"
  local apps="${VM_HOME}/.local/share/applications"
  mkdir -p "$apps"
  chown "${VM_USER}:${VM_USER}" "$apps"
  for f in "${desktop}"/*.desktop; do
    [ -f "$f" ] || continue
    chmod +x "$f"
    chown "${VM_USER}:${VM_USER}" "$f"
    if command -v gio >/dev/null 2>&1; then
      runuser -u "${VM_USER}" -- gio set "$f" metadata::trusted true 2>/dev/null || true
    fi
    cp -f "$f" "${apps}/$(basename "$f")"
    chown "${VM_USER}:${VM_USER}" "${apps}/$(basename "$f")"
    chmod +x "${apps}/$(basename "$f")"
    if command -v gio >/dev/null 2>&1; then
      runuser -u "${VM_USER}" -- gio set "${apps}/$(basename "$f")" metadata::trusted true 2>/dev/null || true
    fi
  done
  runuser -u "${VM_USER}" -- xfconf-query -c xfce4-desktop -p /desktop-icons/style -s 0 --create -t int 2>/dev/null || true
  runuser -u "${VM_USER}" -- xfconf-query -c xfce4-desktop -p /desktop-icons/show-executables -s true --create -t bool 2>/dev/null || true
  # F5 may not refresh desktop over RDP; use right-click Desktop → Refresh
  # or: multipass exec lac-2026-linux -- bash -lc "DISPLAY=:0 xfdesktop --reload"
  echo "[vm-setup] XFCE desktop launchers enabled (trusted + xfconf)"
}

if [[ "${DRC_DESKTOP_ONLY:-}" == "1" ]]; then
  install_drc_desktop_shortcuts
  enable_xfce_desktop_launchers
  exit 0
fi


build_pulseaudio_module_xrdp() {
  if find /usr/lib -name 'module-xrdp-sink.so' 2>/dev/null | grep -q .; then
    echo "[vm-setup] module-xrdp-sink already installed — skip build"
    return 0
  fi
  echo "[vm-setup] Building pulseaudio-module-xrdp from neutrinolabs (one-time)"
  apt-get install -y -qq libpulse-dev autoconf automake libtool pkg-config git meson ninja-build
  PA_SRC=/tmp/pulseaudio-upstream
  PA_BUILD=/tmp/pa-meson-build
  BUILD_DIR="/tmp/pulseaudio-module-xrdp-build"
  rm -rf "$PA_SRC" "$PA_BUILD" "$BUILD_DIR"
  git clone --depth 1 --branch v15.99.1 https://gitlab.freedesktop.org/pulseaudio/pulseaudio.git "$PA_SRC"
  meson setup "$PA_BUILD" "$PA_SRC" --prefix=/usr -Ddaemon=false -Dtests=false -Dman=false -Ddoxygen=false
  git clone --depth 1 https://github.com/neutrinolabs/pulseaudio-module-xrdp.git "$BUILD_DIR"
  (cd "$BUILD_DIR" && ./bootstrap && ./configure PULSE_DIR="$PA_SRC" PULSE_CONFIG_DIR="$PA_BUILD" && make -j"$(nproc)" && make install)
  ldconfig
}

echo "[vm-setup] apt update + XFCE + xrdp + PulseAudio"
apt-get update -qq
apt-get install -y -qq xfce4 xfce4-goodies xrdp dbus-x11 \
  pulseaudio pulseaudio-utils pavucontrol alsa-utils

# RDP audio redirection (neutrinolabs pulseaudio-module-xrdp)
if ! dpkg -l pulseaudio-module-xrdp 2>/dev/null | grep -q '^ii'; then
  if apt-cache show pulseaudio-module-xrdp >/dev/null 2>&1; then
    apt-get install -y -qq pulseaudio-module-xrdp
  else
    build_pulseaudio_module_xrdp
  fi
fi

adduser "${VM_USER}" audio 2>/dev/null || usermod -aG audio "${VM_USER}"

if ! passwd -S "${VM_USER}" 2>/dev/null | grep -q P; then
  echo "${VM_USER}:ubuntu" | chpasswd
  echo "[vm-setup] set password for user ${VM_USER} (RDP login)"
fi

# xrdp must read TLS key (snakeoil in ssl-cert group)
adduser xrdp ssl-cert 2>/dev/null || usermod -aG ssl-cert xrdp

cat > "${VM_HOME}/.xsession" <<'XSESS'
#!/bin/sh
unset DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_DESKTOP=xfce
export XDG_CURRENT_DESKTOP=XFCE
export XDG_DATA_DIRS=/usr/share/xfce4:/usr/local/share:/usr/share:/var/lib/snapd/desktop
export LIBGL_ALWAYS_SOFTWARE=1
export MESA_GL_VERSION_OVERRIDE=3.3
# Start PulseAudio for ALSA apps and xrdp sound redirection
if ! pulseaudio --check 2>/dev/null; then
  pulseaudio --start --log-target=syslog 2>/dev/null || true
fi
exec dbus-launch --exit-with-session xfce4-session
XSESS
chown "${VM_USER}:${VM_USER}" "${VM_HOME}/.xsession"
chmod +x "${VM_HOME}/.xsession"

mkdir -p "${VM_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml"
cat > "${VM_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" <<'XFWM'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
    <property name="sync_to_vblank" type="bool" value="false"/>
  </property>
</channel>
XFWM
chown -R "${VM_USER}:${VM_USER}" "${VM_HOME}/.config"

systemctl enable xrdp
systemctl restart xrdp

install_drc_desktop_shortcuts
enable_xfce_desktop_launchers

echo "[vm-setup] done — xrdp: $(systemctl is-active xrdp)"
echo "[vm-setup] RDP: <VM-IP>:3389  user ${VM_USER}  password ubuntu"
echo "[vm-setup] RDP audio (Mac Windows App): edit PC → Display & Audio → Play sound on: This computer"
echo "[vm-setup] VM sound test (after RDP login): speaker-test -t sine -f 440 -l 1 -c 2"
echo "[vm-setup] PulseAudio check: pulseaudio --check && echo OK"
