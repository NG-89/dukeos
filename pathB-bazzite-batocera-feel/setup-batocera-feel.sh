#!/usr/bin/env bash
# DukeOS Path B - make Bazzite (KDE desktop image) feel like Batocera:
# power on -> auto-login -> RetroDECK (ES-DE) full screen; Quit in ES-DE -> KDE desktop.
#
# Usage: ./setup-batocera-feel.sh [--dry-run] <step>...
#   install      install RetroDECK from Flathub (net.retrodeck.retrodeck)
#   theme        download the Carbon theme for ES-DE (lilbud/carbon-es-de) into RetroDECK's themes folder
#   share        let RetroDECK read Batocera's SHARE mount (/var/mnt/batocera, from Path A --mount-share)
#   autostart    start RetroDECK automatically when KDE logs in ("game menu first")
#   no-autostart remove that autostart (back to normal KDE)
#   autologin    make SDDM log you straight into Plasma (needs sudo)
#   shortcuts    add "Game Mode (RetroDECK)" and "Desktop: stay in KDE next login" launchers
#   all          install theme autostart shortcuts   (autologin/share are opt-in)
set -euo pipefail
APP=net.retrodeck.retrodeck
THEME_REPO=https://github.com/lilbud/carbon-es-de.git
RD_CONF="$HOME/.var/app/$APP/config/retrodeck/retrodeck.json"
AUTOSTART="$HOME/.config/autostart/dukeos-retrodeck.desktop"
HERE="$(cd "$(dirname "$0")" && pwd)"
DRY=0

run() { if [ $DRY = 1 ]; then echo "[dry-run] $*"; else "$@"; fi; }
die() { echo "ERROR: $*" >&2; exit 1; }
[ "$(id -u)" -ne 0 ] || die "Run as your normal user."

rd_path() { # rd_path <key> <default>
  if [ -f "$RD_CONF" ] && command -v jq >/dev/null; then
    local v; v=$(jq -r ".paths.$1 // empty" "$RD_CONF"); [ -n "$v" ] && { echo "$v"; return; }
  fi
  echo "$2"
}

step_install() {
  command -v flatpak >/dev/null || die "flatpak missing (it ships with Bazzite)."
  if flatpak info "$APP" >/dev/null 2>&1; then echo "RetroDECK already installed."; return; fi
  run flatpak install -y --noninteractive flathub "$APP"
  echo ">> Now launch RetroDECK once from the app menu and finish its first-run wizard"
  echo "   (pick where the retrodeck/ folder goes). Then run: $0 theme autostart shortcuts"
}

step_theme() {
  local themes; themes=$(rd_path themes_path "$HOME/retrodeck/ES-DE/themes")
  [ $DRY = 1 ] || [ -d "$(dirname "$themes")" ] || die "RetroDECK not set up yet ($themes). Run RetroDECK's first-run wizard first."
  run mkdir -p "$themes"
  if [ -d "$themes/carbon-es-de/.git" ]; then run git -C "$themes/carbon-es-de" pull --ff-only
  else run git clone --depth 1 "$THEME_REPO" "$themes/carbon-es-de"; fi
  echo ">> In RetroDECK/ES-DE: Start > UI Settings > Theme > Carbon."
}

step_share() {
  [ $DRY = 1 ] || mountpoint -q /var/mnt/batocera || die "/var/mnt/batocera not mounted - use Path A: install-bazzite.sh --mount-share"
  run flatpak override --user --filesystem=/var/mnt/batocera "$APP"
  echo ">> Batocera ROMs are at /var/mnt/batocera/roms. Point RetroDECK at them via"
  echo "   RetroDECK Configurator > Tools/Move, or ES-DE Other Settings > Game media / ROM directory."
  echo "   Most folder names match (snes, megadrive, psx, n64, ...) but some differ - see README."
}

step_autostart() {
  run mkdir -p "$(dirname "$AUTOSTART")" "$HOME/.local/bin"
  run install -m 0755 "$HERE/dukeos-gamemode" "$HOME/.local/bin/dukeos-gamemode"
  if [ $DRY = 1 ]; then echo "[dry-run] write $AUTOSTART"; return; fi
  cat > "$AUTOSTART" <<DESK
[Desktop Entry]
Type=Application
Name=DukeOS Game Mode (RetroDECK)
Exec=$HOME/.local/bin/dukeos-gamemode --autostart
X-KDE-autostart-phase=2
X-KDE-AutostartDelay=2
DESK
  echo "Autostart enabled. Quit ES-DE (Start > Quit) to drop to the KDE desktop."
}

step_no_autostart() { run rm -f "$AUTOSTART"; echo "Autostart removed."; }

step_autologin() {
  local f=/etc/sddm.conf.d/zz-dukeos-autologin.conf
  for o in /etc/sddm.conf.d/zz-bazzite-autologin.conf /etc/sddm.conf.d/zz-holo-autologin.conf; do
    [ -e "$o" ] && echo "NOTE: Bazzite already has $o - check it does not conflict."
  done
  local tmp; tmp=$(mktemp)
  printf '[Autologin]\nUser=%s\nSession=plasma\nRelogin=false\n' "$USER" > "$tmp"
  run sudo mkdir -p /etc/sddm.conf.d
  run sudo install -m 0644 "$tmp" "$f"; rm -f "$tmp"
  echo "SDDM autologin -> $USER (Plasma Wayland). Undo: sudo rm $f"
}

step_shortcuts() {
  local apps="$HOME/.local/share/applications"
  run mkdir -p "$apps" "$HOME/.local/bin"
  run install -m 0755 "$HERE/dukeos-gamemode" "$HOME/.local/bin/dukeos-gamemode"
  run install -m 0644 "$HERE/dukeos-gamemode.desktop" "$apps/dukeos-gamemode.desktop"
  run install -m 0644 "$HERE/dukeos-desktop-next.desktop" "$apps/dukeos-desktop-next.desktop"
  if [ -d "$HOME/Desktop" ]; then
    run install -m 0755 "$HERE/dukeos-gamemode.desktop" "$HOME/Desktop/dukeos-gamemode.desktop"
  fi
}

[ $# -gt 0 ] || { sed -n '2,15p' "$0"; exit 0; }
STEPS=()
for a in "$@"; do case "$a" in
  --dry-run) DRY=1;;
  all) STEPS+=(install theme autostart shortcuts);;
  install|theme|share|autostart|no-autostart|autologin|shortcuts) STEPS+=("$a");;
  *) die "unknown step '$a'";; esac; done
for s in "${STEPS[@]}"; do echo "== $s"; "step_${s//-/_}"; done
