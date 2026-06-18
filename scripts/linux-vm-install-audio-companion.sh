#!/usr/bin/env bash
# One-shot: PulseAudio + CsoundQt/Cabbage companion tools on lac-2026-linux (existing VM).
# Run inside VM: bash ~/Dr.C-Standalone/scripts/linux-vm-install-audio-companion.sh
# Or from Mac host:
#   multipass transfer ~/Dr.C-Standalone/scripts/linux-vm-install-audio-companion.sh lac-2026-linux:/tmp/
#   multipass exec lac-2026-linux -- bash /tmp/linux-vm-install-audio-companion.sh
set -euo pipefail

log() { echo "[audio-companion] $*"; }

export DEBIAN_FRONTEND=noninteractive
ARCH="$(uname -m)"

log "PulseAudio packages"
sudo apt-get update -qq
sudo apt-get install -y -qq pulseaudio pulseaudio-utils pavucontrol alsa-utils
sudo usermod -aG audio "$USER" 2>/dev/null || true
pulseaudio --start 2>/dev/null || true
if pulseaudio --check 2>/dev/null; then
  log "PulseAudio: OK"
else
  log "PulseAudio: not running in this shell (start after GUI login)"
fi

log "xrdp PulseAudio module"
if ! dpkg -l pulseaudio-module-xrdp 2>/dev/null | grep -q '^ii'; then
  if apt-cache show pulseaudio-module-xrdp >/dev/null 2>&1; then
    sudo apt-get install -y -qq pulseaudio-module-xrdp
  else
    build_pulseaudio_module_xrdp() {
      if find /usr/lib -name module-xrdp-sink.so 2>/dev/null | grep -q .; then
        log "pulseaudio-module-xrdp: already installed"
        return 0
      fi
      log "Building pulseaudio-module-xrdp from neutrinolabs…"
      sudo apt-get install -y -qq libpulse-dev autoconf automake libtool pkg-config git meson ninja-build
      local PA_SRC=/tmp/pulseaudio-upstream PA_BUILD=/tmp/pa-meson-build BUILD_DIR=/tmp/pulseaudio-module-xrdp-build
      rm -rf "$PA_SRC" "$PA_BUILD" "$BUILD_DIR"
      git clone --depth 1 --branch v15.99.1 https://gitlab.freedesktop.org/pulseaudio/pulseaudio.git "$PA_SRC"
      meson setup "$PA_BUILD" "$PA_SRC" --prefix=/usr -Ddaemon=false -Dtests=false -Dman=false -Ddoxygen=false
      git clone --depth 1 https://github.com/neutrinolabs/pulseaudio-module-xrdp.git "$BUILD_DIR"
      (cd "$BUILD_DIR" && ./bootstrap && ./configure PULSE_DIR="$PA_SRC" PULSE_CONFIG_DIR="$PA_BUILD" && make -j"$(nproc)" && sudo make install)
      sudo ldconfig
    }
    build_pulseaudio_module_xrdp
  fi
fi
ls /etc/xrdp/pulseaudio*.so 2>/dev/null || ls /usr/lib*/pulse-*/modules/module-xrdp-sink.so 2>/dev/null || true

log "CsoundQt 7 (arch-aware)"
mkdir -p ~/Applications/CsoundQt ~/bin
CSQ_APPIMAGE="CsoundQt-7.0.0-beta4-x86_64.AppImage"
if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
  if [ ! -x "$HOME/Applications/CsoundQt/$CSQ_APPIMAGE" ]; then
    curl -fsSL -o "$HOME/Applications/CsoundQt/$CSQ_APPIMAGE" \
      "https://github.com/CsoundQt/CsoundQt/releases/download/v7.0.0-beta4/$CSQ_APPIMAGE"
  fi
  chmod +x "$HOME/Applications/CsoundQt/$CSQ_APPIMAGE"
  ln -sf "$HOME/Applications/CsoundQt/$CSQ_APPIMAGE" ~/bin/csoundqt
  log "CsoundQt: ~/bin/csoundqt"
else
  log "CsoundQt: BLOCKED on $ARCH — no aarch64 v7 AppImage; use macOS CsoundQt"
fi

log "Cabbage 2.10 (arch-aware)"
mkdir -p ~/src/cabbage-dl ~/Applications/Cabbage
CABBAGE_ZIP="CabbageLinux-2.10.0.zip"
if [ ! -f "$HOME/src/cabbage-dl/$CABBAGE_ZIP" ]; then
  curl -fsSL -o "$HOME/src/cabbage-dl/$CABBAGE_ZIP" \
    "https://github.com/rorywalsh/cabbage/releases/download/v2.10.0/$CABBAGE_ZIP"
fi
if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
  unzip -qo "$HOME/src/cabbage-dl/$CABBAGE_ZIP" -d "$HOME/src/cabbage-dl" 2>/dev/null || true
  rsync -a --exclude "$CABBAGE_ZIP" "$HOME/src/cabbage-dl/" "$HOME/Applications/Cabbage/" 2>/dev/null || true
  if [ -x "$HOME/Applications/Cabbage/installCabbage.sh" ]; then
    (cd "$HOME/Applications/Cabbage" && sudo ./installCabbage.sh) || log "installCabbage.sh failed"
  fi
else
  log "Cabbage: BLOCKED on $ARCH — Linux zip is x86_64; use macOS Cabbage-2.10.x"
fi

log "=== verification ==="
export PATH="$HOME/bin:$HOME/Applications/Csound/bin:$PATH"
csound --version 2>/dev/null | head -1 || echo "csound: NOT FOUND"
pulseaudio --check 2>/dev/null && echo "pulseaudio: OK" || echo "pulseaudio: NOT RUNNING"
if which csoundqt >/dev/null 2>&1; then file "$(which csoundqt)"; else echo "csoundqt: not installed"; fi
if which cabbage >/dev/null 2>&1; then cabbage --version 2>/dev/null || file "$(which cabbage)"; else echo "cabbage: not installed"; fi
aplay -l 2>/dev/null | head -5 || true
log "RDP audio: Windows App → edit PC → Display & Audio → Play sound on: This computer"
