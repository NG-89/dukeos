# DukeOS

Pinned name. This is **our** Batocera customization layer.

EmulationStation first. Official Batocera underneath. Desktop / Steam helpers on `SHARE`. Not a compiled ISO, not Bazzite, not HippOS — those stay as optional other paths.

```
DukeOS  =  official Batocera image  +  this overlay
```

## Apply

Copy `overlay/userdata/` onto `\\BATOCERA\share`:

- `share/system/dukeos.conf`
- `share/system/services/DukeOS_boot`
- `share/system/services/DukeOS_steamhint`

```bash
batocera-services enable DukeOS_boot
batocera-services enable DukeOS_steamhint
batocera-services start DukeOS_boot
```

```bash
sudo ./scripts/apply-share.sh /mnt/BATOCERA_SHARE
```

GitHub: https://github.com/NG-89/dukeos

Scripts MIT. Batocera is a separate project.
