#!/usr/bin/env bash
# LAC 2026 Linux VM provision — Ubuntu 22.04 (PARTICIPANTS.md + INSTALL-* guides)
set -euo pipefail

log() { echo "[provision] $*"; }

export DEBIAN_FRONTEND=noninteractive

ARCH="$(uname -m)"

log "apt base packages"
sudo apt-get update -qq
sudo apt-get install -y -qq \
  build-essential cmake git curl ca-certificates \
  libsndfile1-dev libasound2-dev libjack-jackd2-dev \
  bison flex libssl-dev python3 unzip \
  libnss3 libatk-bridge2.0-0 libgtk-3-0 libxss1 libasound2 libgbm1 \
  rsync lsb-release python3-numpy \
  pulseaudio pulseaudio-utils pavucontrol alsa-utils

log "PulseAudio — audio group + user daemon"
sudo usermod -aG audio "$USER" 2>/dev/null || true
if ! pulseaudio --check 2>/dev/null; then
  pulseaudio --start 2>/dev/null || log "pulseaudio --start deferred (no session yet — OK over SSH)"
fi
if pulseaudio --check 2>/dev/null; then
  log "PulseAudio daemon running"
else
  log "PulseAudio not running in this shell — start after login: pulseaudio --start"
fi

log "Web browser (Open in Browser / web app testing)"
DPKG_ARCH="$(dpkg --print-architecture)"
case "$DPKG_ARCH" in
  arm64) CHROME_DEB_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_arm64.deb" ;;
  amd64) CHROME_DEB_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" ;;
  *) CHROME_DEB_URL="" ;;
esac
CHROME_DEB="/tmp/google-chrome-stable_${DPKG_ARCH}.deb"
if [ -n "$CHROME_DEB_URL" ] && curl -fsSL -o "$CHROME_DEB" "$CHROME_DEB_URL" && [ -s "$CHROME_DEB" ]; then
  sudo apt-get install -y -qq "$CHROME_DEB" || { sudo dpkg -i "$CHROME_DEB" && sudo apt-get install -f -y -qq; }
  rm -f "$CHROME_DEB"
  google-chrome-stable --version 2>/dev/null | head -1 || google-chrome --version 2>/dev/null | head -1 || true
else
  rm -f "$CHROME_DEB"
  log "No Google Chrome .deb for ${DPKG_ARCH:-unknown} — installing Chromium (Ubuntu snap via apt)"
  sudo apt-get install -y -qq chromium-browser
  chromium-browser --version 2>/dev/null | head -1 || true
  log "Manual Chrome download: https://www.google.com/chrome/"
fi

log "Node.js 22"
if ! node -v 2>/dev/null | grep -q '^v22\.'; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt-get install -y -qq nodejs
fi
node -v
npm -v

log "Bun (Terminal)"
if ! command -v bun >/dev/null 2>&1; then
  curl -fsSL https://bun.sh/install | bash
fi
export PATH="$HOME/.bun/bin:$HOME/bin:$HOME/Applications/Csound/bin:$HOME/.local/bin:$PATH"
grep -q '.bun/bin' ~/.bashrc 2>/dev/null || echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.bashrc
bun -v

log "Csound 7 user install"
mkdir -p ~/bin ~/Applications/Csound
if ! ~/Applications/Csound/bin/csound --version 2>/dev/null | head -1 | grep -q 'version 7'; then
  if [ ! -d ~/src/csound ]; then
    git clone --depth 1 --branch develop https://github.com/csound/csound.git ~/src/csound
  fi
  # User prefix for binaries/libs; ctcsound.py installs to system site-packages (sudo).
  cmake -S ~/src/csound -B ~/src/csound/build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$HOME/Applications/Csound" \
    -DINSTALL_PYTHON_INTERFACE=ON
  cmake --build ~/src/csound/build -j"$(nproc)"
  cmake --install ~/src/csound/build
  sudo cmake -DCMAKE_INSTALL_PREFIX="$HOME/Applications/Csound" \
    -P ~/src/csound/build/Python/cmake_install.cmake
  ln -sf ~/Applications/Csound/bin/csound ~/bin/csound
fi
grep -q 'Applications/Csound/lib' ~/.bashrc 2>/dev/null || \
  echo 'export LD_LIBRARY_PATH="$HOME/Applications/Csound/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"' >> ~/.bashrc
export LD_LIBRARY_PATH="$HOME/Applications/Csound/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PATH="$HOME/bin:$HOME/Applications/Csound/bin:$PATH"
csound --version | head -2
if python3 -c "import ctcsound" 2>/dev/null; then
  log "ctcsound Python module OK"
else
  log "ctcsound import failed (need python3-numpy and LD_LIBRARY_PATH)"
fi

# Optional workshop companion tools — install AFTER Csound 7.
# Docs: PARTICIPANTS.md, INSTALL-STANDALONE.md §2.5–2.8
# Set INSTALL_OPTIONAL_TOOLS=0 to skip.
if [ "${INSTALL_OPTIONAL_TOOLS:-1}" = "1" ]; then
  log "optional companion tools (Audacity, Reaper, CsoundQt, Cabbage)"

  if ! command -v audacity >/dev/null 2>&1; then
    sudo apt-get install -y -qq audacity \
      || log "audacity apt failed — try: flatpak install flathub org.audacityteam.Audacity"
  fi

  REAPER_VER=774
  case "$ARCH" in
    aarch64|arm64) REAPER_TAR="reaper${REAPER_VER}_linux_aarch64.tar.xz" ;;
    x86_64|amd64) REAPER_TAR="reaper${REAPER_VER}_linux_x86_64.tar.xz" ;;
    *) REAPER_TAR="" ;;
  esac
  if [ -n "$REAPER_TAR" ] && [ ! -x "$HOME/Applications/Reaper/REAPER/reaper" ]; then
    mkdir -p ~/Applications/Reaper ~/bin
    if curl -fsSL -A "Mozilla/5.0" -o "/tmp/$REAPER_TAR" "https://www.reaper.fm/files/7.x/$REAPER_TAR"; then
      tar -xf "/tmp/$REAPER_TAR" -C /tmp
      REAPER_DIR="$(find /tmp -maxdepth 1 -type d -name "reaper_linux_*" | head -1)"
      rsync -a "$REAPER_DIR/" ~/Applications/Reaper/
      chmod +x ~/Applications/Reaper/REAPER/reaper
      ln -sf ~/Applications/Reaper/REAPER/reaper ~/bin/reaper
      log "Reaper installed — accept eval license on first GUI launch"
    else
      log "Reaper download failed — manual: https://www.reaper.fm/download.php"
    fi
  fi

  # CsoundQt 7 — https://github.com/CsoundQt/CsoundQt/releases (v7 AppImage is x86_64 only)
  mkdir -p ~/Applications/CsoundQt
  CSQ_APPIMAGE="CsoundQt-7.0.0-beta4-x86_64.AppImage"
  CSQ_URL="https://github.com/CsoundQt/CsoundQt/releases/download/v7.0.0-beta4/${CSQ_APPIMAGE}"
  if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
    if [ ! -x "$HOME/Applications/CsoundQt/$CSQ_APPIMAGE" ]; then
      curl -fsSL -o "$HOME/Applications/CsoundQt/$CSQ_APPIMAGE" "$CSQ_URL"
      chmod +x "$HOME/Applications/CsoundQt/$CSQ_APPIMAGE"
    fi
    ln -sf "$HOME/Applications/CsoundQt/$CSQ_APPIMAGE" ~/bin/csoundqt 2>/dev/null || true
    log "CsoundQt 7 AppImage → ~/bin/csoundqt"
  else
    log "CsoundQt: no aarch64 v7 binary — use macOS CsoundQt or BUILD_CSOUNDQT=1 (source build, slow)"
    if [ "${BUILD_CSOUNDQT:-0}" = "1" ]; then
      log "BUILD_CSOUNDQT=1 — building CsoundQt 7 from csoundqt7 branch (Qt6 + user Csound 7)"
      sudo apt-get install -y -qq qt6-base-dev qt6-tools-dev qt6-tools-dev-tools \
        libqt6svg6-dev libqt6opengl6-dev libjack-jackd2-dev
      if [ ! -d ~/src/CsoundQt ]; then
        git clone --depth 1 --branch csoundqt7 https://github.com/CsoundQt/CsoundQt.git ~/src/CsoundQt
      fi
      cmake -S ~/src/CsoundQt -B ~/src/CsoundQt/build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_PREFIX_PATH="$HOME/Applications/Csound"
      cmake --build ~/src/CsoundQt/build -j"$(nproc)"
      cmake --install ~/src/CsoundQt/build --prefix "$HOME/Applications/CsoundQt"
      ln -sf "$HOME/Applications/CsoundQt/bin/CsoundQt" ~/bin/csoundqt 2>/dev/null || true
    fi
  fi

  # Cabbage — https://github.com/rorywalsh/cabbage/releases (Linux zip is x86_64 only; latest v2.10.0)
  mkdir -p ~/src/cabbage-dl ~/Applications/Cabbage
  CABBAGE_ZIP="CabbageLinux-2.10.0.zip"
  CABBAGE_URL="https://github.com/rorywalsh/cabbage/releases/download/v2.10.0/${CABBAGE_ZIP}"
  if [ ! -f "$HOME/src/cabbage-dl/$CABBAGE_ZIP" ]; then
    curl -fsSL -o "$HOME/src/cabbage-dl/$CABBAGE_ZIP" "$CABBAGE_URL" || log "Cabbage zip download failed"
  fi
  if [ -f "$HOME/src/cabbage-dl/$CABBAGE_ZIP" ]; then
    unzip -qo "$HOME/src/cabbage-dl/$CABBAGE_ZIP" -d "$HOME/src/cabbage-dl" 2>/dev/null || true
  fi
  if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
    if [ ! -f "$HOME/Applications/Cabbage/installCabbage.sh" ]; then
      rsync -a --exclude "$CABBAGE_ZIP" "$HOME/src/cabbage-dl/" "$HOME/Applications/Cabbage/" 2>/dev/null || true
    fi
    if [ -x "$HOME/Applications/Cabbage/installCabbage.sh" ]; then
      (cd "$HOME/Applications/Cabbage" && sudo ./installCabbage.sh) || log "Cabbage installCabbage.sh failed — run manually"
    fi
    if command -v cabbage >/dev/null 2>&1; then
      log "Cabbage → $(command -v cabbage)"
    fi
  else
    log "Cabbage: Linux zip is x86_64 only — no native aarch64 IDE (use macOS Cabbage-2.10.x for workshop GUI)"
    log "Cabbage export smoke still runs on Mac: node scripts/test-cabbage-export.mjs"
    mkdir -p ~/Applications/Cabbage
    echo "aarch64: no native Cabbage binary — use macOS for GUI; zip cached at ~/src/cabbage-dl/" \
      > ~/Applications/Cabbage/AARCH64-BLOCKER.txt
  fi
fi

log "sync repos from host mount (if present)"
if [ -d /mnt/Dr.C-Standalone ]; then
  rsync -a --delete \
    --exclude node_modules --exclude out --exclude release --exclude dist \
    /mnt/Dr.C-Standalone/ ~/Dr.C-Standalone/
fi
if [ -d /mnt/Dr.C ]; then
  rsync -a --delete \
    --exclude node_modules --exclude .turbo --exclude dist \
    --exclude 'sdks/vscode/images/icon.png' \
    --exclude 'sdks/vscode/images/button-dark.svg' \
    --exclude 'sdks/vscode/images/button-light.svg' \
    /mnt/Dr.C/ ~/Dr.C/ || true
fi

# 8G VM: default Node heap OOMs on electron-vite production build in npm test.
export NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=4096}"

log "npm install Standalone"
cd ~/Dr.C-Standalone
npm install

log "bun install Terminal"
cd ~/Dr.C/opencode
bun install

log "git identity for bash unit tests"
git config --global user.email "workshop@local" 2>/dev/null || true
git config --global user.name "Workshop" 2>/dev/null || true

log "workshop demo folder"
mkdir -p ~/Dr.C-Workshop-Demo

log "provision complete"
log "verify: csound --version | head -1; pulseaudio --check; which csoundqt cabbage reaper 2>/dev/null"
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
  log "aarch64 notes: CsoundQt/Cabbage GUI → use Mac host; RDP audio needs pulseaudio-module-xrdp (vm-setup-linux-desktop.sh)"
fi
