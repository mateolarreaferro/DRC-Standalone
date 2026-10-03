# Workshop launchers (macOS & Linux — LAC 2026)

Presenter Desktop shortcuts (symlink to these files):

| Desktop name | Repo launcher |
|--------------|---------------|
| **Dr.C Mac Standalone.command** | `Dr.C Mac Standalone.command` |
| **Dr.C Mac Terminal.command** | `../Dr.C/opencode/launchers/Dr.C Mac Terminal.command` |
| **Dr.C Linux VM Shell.command** | `Dr.C Linux VM Shell.command` |
| **Dr.C Linux Standalone.command** | `Dr.C Linux Standalone.command` |
| **Dr.C Linux Terminal.command** | `Dr.C Linux Terminal.command` |
| **Dr.C Linux Standalone Launch.command** | `Dr.C Linux Standalone Launch.command` (RDP — auto DISPLAY) |
| **Dr.C Linux Terminal Launch.command** | `Dr.C Linux Terminal Launch.command` (RDP — xfce4-terminal) |

```bash
ln -sf "$HOME/Dr.C-Standalone/launchers/Dr.C Mac Standalone.command" ~/Desktop/
ln -sf "$HOME/Dr.C/opencode/launchers/Dr.C Mac Terminal.command" ~/Desktop/
ln -sf "$HOME/Dr.C-Standalone/launchers/Dr.C Linux VM Shell.command" ~/Desktop/
ln -sf "$HOME/Dr.C-Standalone/launchers/Dr.C Linux Standalone.command" ~/Desktop/
ln -sf "$HOME/Dr.C-Standalone/launchers/Dr.C Linux Terminal.command" ~/Desktop/
ln -sf "$HOME/Dr.C-Standalone/launchers/Dr.C Linux Standalone Launch.command" ~/Desktop/
ln -sf "$HOME/Dr.C-Standalone/launchers/Dr.C Linux Terminal Launch.command" ~/Desktop/
```

| OS | Instructor (Pro+) | Attendee (free tier) |
|----|-----------------|----------------------|
| **macOS** | `Dr.C Mac Standalone.command` or `Dr.C-Standalone.command` | `Dr.C-Workshop-Attendee.command` |
| **macOS → Linux VM** | `Dr.C Linux VM Shell.command`, `Dr.C Linux Standalone.command`, `Dr.C Linux Terminal.command` | — |
| **Linux** | `chmod +x Dr.C-Standalone.sh && ./Dr.C-Standalone.sh` | `chmod +x Dr.C-Workshop-Attendee.sh && ./Dr.C-Workshop-Attendee.sh` |

From repo root:

```bash
./scripts/launch-drc.sh                 # Mac / Linux host Standalone
./scripts/launch-linux-vm.sh            # Multipass shell (lac-2026-linux)
./scripts/launch-linux-standalone.sh    # Standalone inside VM (needs DISPLAY in VM)
./scripts/launch-linux-terminal.sh      # Terminal TUI inside VM
./scripts/launch-linux-standalone-rdp.sh  # Standalone on RDP display (:10+ auto-detect)
./scripts/launch-linux-terminal-rdp.sh    # Terminal in xfce4-terminal on RDP desktop
./scripts/launch-workshop-attendee.sh   # attendees
```

**Linux GUI in Multipass:** Electron cannot display on the Mac host. Use **Dr.C Linux Standalone Launch.command** (or `launch-linux-standalone-rdp.sh`) after connecting **Windows App** RDP — it auto-detects `DISPLAY` (`:10` for xrdp) and opens the app in the RDP session. For on-stage sound demos, prefer **Dr.C Mac Standalone** on the host.

Full install steps: **[PARTICIPANTS.md](../PARTICIPANTS.md)**

> Windows `.bat` / `.ps1` launchers remain in the repo for future use but are **not** part of LAC 2026.
