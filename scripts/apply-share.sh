#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${1:-}"
[ -n "$DEST" ] && [ -d "$DEST" ] || { echo "Usage: $0 /path/to/SHARE"; exit 1; }
mkdir -p "$DEST/system/services" "$DEST/system/logs"
install -m 0644 "$ROOT/overlay/userdata/system/dukeos.conf" "$DEST/system/dukeos.conf"
install -m 0755 "$ROOT/overlay/userdata/system/services/DukeOS_boot" "$DEST/system/services/DukeOS_boot"
install -m 0755 "$ROOT/overlay/userdata/system/services/DukeOS_steamhint" "$DEST/system/services/DukeOS_steamhint"
echo "Installed DukeOS onto $DEST"
