#!/bin/bash
# DukeOS - Batocera "Ports" entry: boot into Bazzite ONCE, then Batocera stays default.
# Install to /userdata/roms/ports/Boot-to-Bazzite.sh (install-batocera.sh does this).
# Over SSH you can also run:  bash /userdata/roms/ports/Boot-to-Bazzite.sh --dry-run | status
LIB=/userdata/system/dukeos/bootnext.sh
CONF=/userdata/system/dukeos-switcher.conf
LOG=/userdata/system/logs/dukeos-switch.log

mkdir -p /userdata/system/logs
exec > >(tee -a "$LOG") 2>&1
echo "---- $(date -Iseconds) Boot-to-Bazzite $*"

[ -f "$LIB" ] || { echo "ERROR: $LIB missing - re-run install-batocera.sh"; exit 1; }
# shellcheck source-path=SCRIPTDIR source=../lib/bootnext.sh
. "$LIB"

# Defaults; override in $CONF
BAZZITE_BOOTNUM=""
BAZZITE_LABEL_REGEX="^(bazzite|fedora)"
BAZZITE_LOADER_REGEX="efi.fedora.shimx64"
DUKEOS_SWITCH_DRY_RUN=0
# shellcheck disable=SC1090
[ -f "$CONF" ] && . "$CONF"

TARGET_NAME="Bazzite"
TARGET_BOOTNUM="$BAZZITE_BOOTNUM"
TARGET_LABEL_REGEX="$BAZZITE_LABEL_REGEX"
TARGET_LOADER_REGEX="$BAZZITE_LOADER_REGEX"
DRY_RUN="$DUKEOS_SWITCH_DRY_RUN"
SUDO=""   # Batocera runs everything as root

case "${1:-}" in
  status)    show_status; exit 0 ;;
  --dry-run) DRY_RUN=1 ;;
  "")        ;;
  *)         echo "Usage: $0 [--dry-run|status]"; exit 2 ;;
esac

# Detach the reboot so EmulationStation gets control back first and can be
# stopped cleanly (saves gamelists) by batocera-es-swissknife. Falls back to a
# plain reboot if ES is not running (e.g. when run over SSH).
do_reboot() {
  setsid sh -c 'sleep 2; batocera-es-swissknife --reboot; sleep 8; shutdown -r now' >/dev/null 2>&1 < /dev/null &
}

# TARGET_* / DRY_RUN / SUDO are read by functions in the sourced library.
export TARGET_NAME TARGET_BOOTNUM TARGET_LABEL_REGEX TARGET_LOADER_REGEX DRY_RUN SUDO
set_bootnext_and_reboot do_reboot
