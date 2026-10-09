#!/usr/bin/env bash
# Copy the Batocera half of the switcher onto Batocera's SHARE partition.
# Usage: sudo ./install-batocera.sh /path/to/mounted/SHARE [--dry-run]
#   - From Windows/Bazzite: mount the SHARE partition (or \\BATOCERA\share) and pass its path.
#   - On Batocera itself over SSH: ./install-batocera.sh /userdata
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="${1:-}"; DRY="${2:-}"
[ -n "$DEST" ] && [ -d "$DEST" ] || { echo "Usage: $0 /path/to/SHARE [--dry-run]"; exit 1; }
[ -d "$DEST/system" ] || { echo "ERROR: $DEST/system not found - is this really Batocera's SHARE/userdata?"; exit 1; }
run() { if [ "$DRY" = "--dry-run" ]; then echo "[dry-run] $*"; else "$@"; fi; }

run mkdir -p "$DEST/system/dukeos" "$DEST/system/logs" "$DEST/roms/ports"
run install -m 0644 "$HERE/../lib/bootnext.sh"      "$DEST/system/dukeos/bootnext.sh"
run install -m 0755 "$HERE/Boot-to-Bazzite.sh"      "$DEST/roms/ports/Boot-to-Bazzite.sh"
if [ -e "$DEST/system/dukeos-switcher.conf" ]; then
  echo "Keeping existing $DEST/system/dukeos-switcher.conf"
else
  run install -m 0644 "$HERE/dukeos-switcher.conf" "$DEST/system/dukeos-switcher.conf"
fi
echo "Done. In Batocera: Main menu > Game settings > Update gamelists, then look in Ports for 'Boot-to-Bazzite'."
echo "The config ships with DUKEOS_SWITCH_DRY_RUN=1 - check /userdata/system/logs/dukeos-switch.log, then set it to 0."
