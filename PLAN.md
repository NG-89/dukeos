# DukeOS plan: Batocera experience + Bazzite KDE desktop

Machine: Windows 11 + Bazzite (KDE) + Batocera, UEFI. HippOS rejected (too buggy).
Goal: Batocera's EmulationStation feel *and* a KDE desktop, easy to swap between.

| | Path A: real Batocera + switching | Path B: Bazzite that feels like Batocera |
|---|---|---|
| Game menu | Batocera's own ES (what you prefer) | ES-DE via RetroDECK + Carbon theme |
| Desktop | Bazzite KDE after a reboot (~30-60 s) | KDE instantly (quit ES-DE) |
| Effort/risk | low; one-shot BootNext only | low; user-level files + optional SDDM autologin |
| ROMs | one copy on Batocera SHARE, mounted in Bazzite | same mount, or RetroDECK's own folder |

Recommended order:
1. Path A first (`pathA-switcher/`): install on Bazzite, `status`, `--dry-run`, then real switch.
   Then Batocera side in dry-run → live.
2. Mount SHARE in Bazzite (`--mount-share --share-acl`) so both use one ROM library.
3. Try Path B on Bazzite (`pathB-bazzite-batocera-feel/`) with autostart; remove with `no-autostart` if not liked.
   A and B coexist: Batocera stays default boot; Bazzite then opens to RetroDECK.
4. Keep whichever feels better.

## Status
- **Path A tested working on real hardware on 9 Oct 2026**, both directions
  (Boot0001 Batocera, Boot0002 Bazzite; labels auto-detected, no config changes needed).
- Path B is still a draft, not yet tested.

## After cloning: executable bits
GitHub web/API pushes don't keep the executable bit. After `git clone`, run:
```bash
chmod +x pathA-switcher/batocera/Boot-to-Bazzite.sh pathA-switcher/batocera/install-batocera.sh \
         pathA-switcher/bazzite/boot-to-batocera pathA-switcher/bazzite/install-bazzite.sh \
         pathB-bazzite-batocera-feel/setup-batocera-feel.sh pathB-bazzite-batocera-feel/dukeos-gamemode
```
or run the installers with bash explicitly (e.g. `bash pathA-switcher/bazzite/install-bazzite.sh`).
The installers themselves install every script with mode 0755, so installed copies are executable.
