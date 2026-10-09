# Path A — Real Batocera, one-click switching

> **Status:** tested working on real hardware on 9 Oct 2026, both directions
> (Boot0001 Batocera, Boot0002 Bazzite — labels auto-detected, no config changes needed).
>
> **After cloning:** GitHub web/API pushes don't keep the executable bit. Either run
> `chmod +x batocera/Boot-to-Bazzite.sh batocera/install-batocera.sh bazzite/boot-to-batocera bazzite/install-bazzite.sh`
> or call the installers with bash explicitly: `bash bazzite/install-bazzite.sh`, `bash batocera/install-batocera.sh /userdata`.
> The installers copy every script with mode 0755, so the installed copies are executable.

Batocera stays the **default** boot. Each side gets a button that reboots **once**
into the other OS using UEFI `BootNext` (`efibootmgr --bootnext`). BootOrder is
never touched, so the next normal power-on always goes back to your firmware
default (set Batocera first in the BIOS boot order).

| Where | Button | What it does |
|---|---|---|
| Batocera | **Ports → Boot-to-Bazzite** | finds Bazzite's UEFI entry, sets BootNext, stops ES cleanly (`batocera-es-swissknife --reboot`), reboots |
| Bazzite (KDE) | **Boot to Batocera** app / desktop icon (optionally a non-Steam game) | finds Batocera's UEFI entry, sets BootNext, `systemctl reboot` |

Why `efibootmgr` and not `grub2-reboot`: Batocera has its own EFI loader
(`\EFI\batocera\shimx64.efi`, entry label "Batocera") and is not in Bazzite's
GRUB menu, and Batocera can't edit Bazzite's GRUB environment. Firmware BootNext
works from both sides. Bazzite already uses exactly this for Windows
(`/usr/bin/boot-windows` → `efibootmgr -n <num> && reboot`).

## Files
```
lib/bootnext.sh                 shared logic: find entry by label (fallback: loader path), dry-run, verify, reboot
batocera/Boot-to-Bazzite.sh     Ports entry  -> /userdata/roms/ports/
batocera/dukeos-switcher.conf   config       -> /userdata/system/ (ships with DRY_RUN=1)
batocera/install-batocera.sh    copies the above onto SHARE
bazzite/boot-to-batocera        command      -> ~/.local/bin/
bazzite/boot-to-batocera.desktop launcher    -> app menu + ~/Desktop
bazzite/switcher.conf           config       -> ~/.config/dukeos/
bazzite/batocera-share.mount    optional: mount Batocera SHARE at /var/mnt/batocera
bazzite/install-bazzite.sh      installer (--dry-run --nopasswd --mount-share --share-acl --add-to-steam)
```

## Install & test
**Bazzite side** (in Konsole, from this folder):
```bash
./bazzite/install-bazzite.sh --dry-run          # see what it would do
./bazzite/install-bazzite.sh                    # install for your user
boot-to-batocera status                         # lists UEFI entries – check "Batocera" is there
boot-to-batocera --dry-run                      # shows which BootNNNN it would use
boot-to-batocera                                # real switch (asks for password via polkit)
# optional extras:
./bazzite/install-bazzite.sh --nopasswd         # no password prompt (needed from Steam Game Mode)
./bazzite/install-bazzite.sh --add-to-steam
./bazzite/install-bazzite.sh --mount-share --share-acl   # shared ROMs, see below
```
**Batocera side** — either from Bazzite once SHARE is mounted:
`sudo ./batocera/install-batocera.sh /var/mnt/batocera`
or on Batocera over SSH (`root`/`linux` by default) after copying this folder:
`./batocera/install-batocera.sh /userdata`.
Then in Batocera: *Main menu → Game settings → Update gamelists*, open **Ports → Boot-to-Bazzite**.
The first run is a dry run: check `/userdata/system/logs/dukeos-switch.log`, then set
`DUKEOS_SWITCH_DRY_RUN=0` in `/userdata/system/dukeos-switcher.conf`.

If auto-detect picks the wrong entry or finds several, run `status` and pin
`BAZZITE_BOOTNUM=000X` / `BATOCERA_BOOTNUM=000X` in the config file.

## Shared ROMs
Batocera keeps ROMs/BIOS/saves on its **SHARE** partition (ext4, label `SHARE`).
`--mount-share` mounts it in Bazzite at `/var/mnt/batocera` (systemd mount unit,
`nofail`, refuses if 0 or >1 partitions are labelled SHARE). Files there are
owned by root (Batocera runs as root); `--share-acl` adds an ACL so your user can
write to `roms/`, `bios/`, `saves/` without changing ownership. Path B can point
RetroDECK at the same folder. Do not have both OSes write the same save files
"at the same time" — they never run together here, so that's fine.

## Safety
- One-time BootNext only; firmware default untouched. Worst case: a normal boot.
- Entry found by label, fallback by loader path; aborts on 0 or >1 matches.
- BootNext is read back and verified before rebooting.
- Dry-run everywhere; Batocera side ships in dry-run mode.
- Nothing is changed on Windows.
