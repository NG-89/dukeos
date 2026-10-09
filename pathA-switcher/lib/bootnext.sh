#!/usr/bin/env bash
# DukeOS boot switcher - shared helpers (sourced, not executed).
# Sets a ONE-TIME UEFI BootNext entry with efibootmgr. BootOrder is never
# changed, so if anything goes wrong the firmware falls back to its default.
#
# Inputs (env or config):
#   TARGET_NAME         human name used in messages (e.g. "Bazzite")
#   TARGET_BOOTNUM      optional explicit 4-hex-digit entry (e.g. 0003) - wins over detection
#   TARGET_LABEL_REGEX  extended regex matched against the entry LABEL
#   TARGET_LOADER_REGEX extended regex matched against the loader path (fallback)
#   SUDO=sudo           prefix for the write call when not root
#   DRY_RUN=1           print what would happen, change nothing

# shellcheck disable=SC2034
BOOTNEXT_LIB_VERSION="0.1.0"

die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo "==> $*"; }

need_efi() {
  [ -d /sys/firmware/efi ] || die "This system was not booted in UEFI mode; BootNext cannot be used."
  command -v efibootmgr >/dev/null 2>&1 || die "efibootmgr not found in PATH."
}

# Print "NNNN<TAB>label<TAB>rest-of-line" for every BootNNNN entry.
list_entries() {
  efibootmgr -v 2>/dev/null | sed -n -E 's/^Boot([0-9A-Fa-f]{4})\*?[[:space:]]+(.*)$/\1\t\2/p' |
  while IFS=$'\t' read -r num rest; do
    # label is everything before the first tab-or-device-path token
    label=${rest%%$'\t'*}
    printf '%s\t%s\t%s\n' "$num" "$label" "$rest"
  done
}

# Resolve the boot number for the target; prints it or dies with a clear reason.
resolve_target() {
  if [ -n "${TARGET_BOOTNUM:-}" ]; then
    printf '%s' "$TARGET_BOOTNUM" | grep -Eq '^[0-9A-Fa-f]{4}$' || die "TARGET_BOOTNUM='$TARGET_BOOTNUM' is not 4 hex digits."
    list_entries | cut -f1 | grep -iqx "$TARGET_BOOTNUM" || die "Boot$TARGET_BOOTNUM does not exist. Run with 'status' to list entries."
    printf '%s\n' "$TARGET_BOOTNUM"; return 0
  fi
  local matches
  matches=$(list_entries | awk -F'\t' -v re="${TARGET_LABEL_REGEX:-^$}" 'tolower($2) ~ tolower(re) {print $1}')
  if [ -z "$matches" ] && [ -n "${TARGET_LOADER_REGEX:-}" ]; then
    matches=$(list_entries | awk -F'\t' -v re="$TARGET_LOADER_REGEX" 'tolower($0) ~ tolower(re) {print $1}')
  fi
  local count
  count=$(printf '%s' "$matches" | grep -c . || true)
  if [ "$count" -eq 0 ]; then
    die "No UEFI boot entry for ${TARGET_NAME:-target} (label /${TARGET_LABEL_REGEX:-}/, loader /${TARGET_LOADER_REGEX:-}/). Run 'status' and set TARGET_BOOTNUM in the config."
  elif [ "$count" -gt 1 ]; then
    die "Several entries match ${TARGET_NAME:-target}: $(echo "$matches" | tr '\n' ' ')- set TARGET_BOOTNUM in the config to pick one."
  fi
  printf '%s\n' "$matches"
}

show_status() {
  need_efi
  echo "Current boot : $(efibootmgr | sed -n 's/^BootCurrent: //p')"
  echo "Boot next    : $(efibootmgr | sed -n 's/^BootNext: //p')"
  echo "Boot order   : $(efibootmgr | sed -n 's/^BootOrder: //p')"
  echo "Entries:"
  list_entries | awk -F'\t' '{printf "  Boot%s  %s\n", $1, $2}'
}

# set_bootnext_and_reboot <reboot-command...>
set_bootnext_and_reboot() {
  need_efi
  local num
  num=$(resolve_target) || exit 1
  info "${TARGET_NAME:-target} is Boot$num"
  if [ "${DRY_RUN:-0}" = "1" ]; then
    info "[dry-run] would run: efibootmgr --bootnext $num"
    info "[dry-run] would run: $*"
    return 0
  fi
  # SUDO is empty on Batocera (already root) and "sudo" on Bazzite.
  ${SUDO:-} efibootmgr --bootnext "$num" >/dev/null || die "efibootmgr --bootnext $num failed (permissions? read-only efivars?)."
  local got
  got=$(efibootmgr | sed -n 's/^BootNext: //p')
  [ "${got^^}" = "${num^^}" ] || die "BootNext reads back as '$got', expected '$num'. Not rebooting."
  info "BootNext=$num set. Rebooting..."
  "$@"
}
