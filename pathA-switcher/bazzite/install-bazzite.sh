#!/usr/bin/env bash
# Install the Bazzite half of the DukeOS boot switcher for the current user.
# Usage: ./install-bazzite.sh [--dry-run] [--nopasswd] [--mount-share] [--share-acl] [--add-to-steam]
#   --nopasswd     allow 'efibootmgr' via sudo without a password (needed for one-click from
#                  Steam Game Mode; same rule as Bazzite's 'ujust setup-boot-windows-steam')
#   --mount-share  mount Batocera's SHARE partition at /var/mnt/batocera on every boot
#   --share-acl    give your user read/write (ACL) on SHARE's roms/bios/saves (ext4 only)
#   --add-to-steam add 'boot-to-batocera' as a non-Steam game (like Bazzite does for Windows)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DRY=0 NOPASSWD=0 MOUNT=0 ACL=0 STEAM=0
for a in "$@"; do case "$a" in
  --dry-run) DRY=1;; --nopasswd) NOPASSWD=1;; --mount-share) MOUNT=1;;
  --share-acl) ACL=1;; --add-to-steam) STEAM=1;;
  *) echo "Unknown option $a"; exit 2;; esac; done
run() { if [ $DRY = 1 ]; then echo "[dry-run] $*"; else "$@"; fi; }
[ "$(id -u)" -ne 0 ] || { echo "Run as your normal user (it will sudo when needed)."; exit 1; }

BIN="$HOME/.local/bin"; SHAREDIR="$HOME/.local/share/dukeos"; CFG="${XDG_CONFIG_HOME:-$HOME/.config}/dukeos"
run mkdir -p "$BIN" "$SHAREDIR" "$CFG" "$HOME/.local/share/applications"
run install -m 0644 "$HERE/../lib/bootnext.sh" "$SHAREDIR/bootnext.sh"
run install -m 0755 "$HERE/boot-to-batocera" "$BIN/boot-to-batocera"
run install -m 0644 "$HERE/boot-to-batocera.desktop" "$HOME/.local/share/applications/boot-to-batocera.desktop"
[ -e "$CFG/switcher.conf" ] || run install -m 0644 "$HERE/switcher.conf" "$CFG/switcher.conf"
if [ -d "$HOME/Desktop" ]; then
  run install -m 0755 "$HERE/boot-to-batocera.desktop" "$HOME/Desktop/boot-to-batocera.desktop"
fi

if [ $NOPASSWD = 1 ]; then
  EFI="$(command -v efibootmgr)"
  RULE="%wheel ALL=(root) NOPASSWD: $EFI"
  TMP=$(mktemp); echo "$RULE" > "$TMP"
  if sudo visudo -cf "$TMP" >/dev/null; then
    run sudo install -m 0440 "$TMP" /etc/sudoers.d/dukeos-efibootmgr
  else echo "ERROR: generated sudoers rule failed validation; not installed."; fi
  rm -f "$TMP"
fi

if [ $MOUNT = 1 ]; then
  DEV=/dev/disk/by-label/SHARE
  [ -e "$DEV" ] || { echo "ERROR: no partition labelled SHARE found (lsblk -f to check)."; exit 1; }
  N=$(lsblk -rno LABEL | grep -cx SHARE || true)
  [ "$N" -eq 1 ] || { echo "ERROR: $N partitions are labelled SHARE - edit the mount unit by UUID instead."; exit 1; }
  FSTYPE=$(lsblk -no FSTYPE "$DEV")
  echo "Batocera SHARE: $(readlink -f "$DEV") ($FSTYPE)"
  UNIT=$(mktemp); sed "s/@FSTYPE@/$FSTYPE/" "$HERE/batocera-share.mount" > "$UNIT"
  run sudo mkdir -p /var/mnt/batocera
  run sudo install -m 0644 "$UNIT" /etc/systemd/system/var-mnt-batocera.mount
  rm -f "$UNIT"
  run sudo systemctl daemon-reload
  run sudo systemctl enable --now var-mnt-batocera.mount
fi

if [ $ACL = 1 ]; then
  [ "$DRY" = 1 ] || mountpoint -q /var/mnt/batocera || { echo "ERROR: /var/mnt/batocera not mounted (use --mount-share)."; exit 1; }
  for d in roms bios saves; do
    [ -d "/var/mnt/batocera/$d" ] || continue
    run sudo setfacl -R -m "u:$USER:rwX" "/var/mnt/batocera/$d"
    run sudo setfacl -R -d -m "u:$USER:rwX" "/var/mnt/batocera/$d"
  done
fi

if [ $STEAM = 1 ]; then
  run steam "steam://addnonsteamgame/$(printf '%s' "$BIN/boot-to-batocera" | sed 's#/#%2F#g')"
fi

echo "Installed. Test safely first:  boot-to-batocera status  &&  boot-to-batocera --dry-run"
