# Path B — Bazzite that feels like Batocera

One OS (Bazzite KDE desktop image). Power on → auto-login → **RetroDECK**
(ES-DE game menu, full screen). Quit ES-DE → you're on the KDE desktop. A
"Game Mode (RetroDECK)" icon brings the menu back.

Honest caveat: RetroDECK's frontend is **ES-DE**, not Batocera's EmulationStation.
There is no way to run Batocera's ES fork on Bazzite in a supported way. The
Carbon theme gets the look close; menus/behaviour will still be ES-DE's.

## Steps (`setup-batocera-feel.sh [--dry-run] <steps>`)
| Step | Does |
|---|---|
| `install` | `flatpak install flathub net.retrodeck.retrodeck` |
| (you) | launch RetroDECK once from the app menu and finish its first-run wizard |
| `theme` | clones **lilbud/carbon-es-de** (ES-DE port of the RetroPie Carbon theme that Batocera's default Carbon descends from) into RetroDECK's `themes_path` (read from `~/.var/app/net.retrodeck.retrodeck/config/retrodeck/retrodeck.json`, default `~/retrodeck/ES-DE/themes`). Then pick it in ES-DE: Main Menu → UI Settings → Theme |
| `autostart` | `~/.config/autostart/dukeos-retrodeck.desktop` → runs RetroDECK at KDE login |
| `shortcuts` | app-menu/desktop launchers: "Game Mode (RetroDECK)", "Stay on Desktop next login" |
| `autologin` | `/etc/sddm.conf.d/zz-dukeos-autologin.conf` (`User=you`, `Session=plasma`) — opt-in, needs sudo |
| `share` | `flatpak override --user --filesystem=/var/mnt/batocera` so RetroDECK can use Batocera's ROMs (mount from Path A `--mount-share`) |
| `no-autostart` | undo autostart |
| `all` | install + theme + autostart + shortcuts |

Typical run:
```bash
./setup-batocera-feel.sh --dry-run all
./setup-batocera-feel.sh install         # then open RetroDECK once, finish wizard
./setup-batocera-feel.sh theme autostart shortcuts
./setup-batocera-feel.sh autologin       # optional: boot straight in with no login screen
```
Getting to the desktop: ES-DE Main Menu → Quit (or Alt+F4 / keyboard). To skip the
game menu at the next login, use "Stay on Desktop next login".

## Alternative B2 (not scripted): Steam Game Mode
Bazzite's `-deck` images boot into Steam Gaming Mode with "Switch to Desktop" in
the power menu. Rebase (from the KDE desktop image) with
`rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/bazzite-deck:stable`
(use the `-nvidia` variant if you have NVIDIA; check docs.bazzite.gg first), then
let RetroDECK's wizard add itself to Steam. You get the Steam UI first, with
RetroDECK one click away — not quite Batocera-first, but very controller-friendly.
Roll back with `rpm-ostree rollback`.

## Batocera ROM folders
Many folder names match ES-DE (snes, megadrive, psx, n64, nes, gba, dreamcast, ps2),
but some differ (e.g. Batocera `gamecube` vs ES-DE `gc`, `3ds` vs `n3ds` — verify in
ES-DE's `es_systems.xml`). Pointing RetroDECK at `/var/mnt/batocera/roms` works for
matching folders; mismatched ones need symlinks or a custom systems file.
