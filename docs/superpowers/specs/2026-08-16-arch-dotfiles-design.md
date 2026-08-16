# arch-dotfiles design

## Goal

Git-tracked dotfiles repo for a CachyOS + Hyprland desktop, so a
reformat/reinstall is "clone repo, run script" instead of losing config.
Fork HyDE (github.com/HyDE-Project/HyDE) as the rice base instead of
hand-rolling Hyprland/Waybar/rofi/etc config. No Ansible, no chezmoi —
plain package lists + a symlink script, `--needed` gives idempotency
without an extra tooling layer. This repo replaces a failed prior attempt
(Debian + Ansible + chezmoi + Sway, see `../debian-dotfiles/`) that died
from scope creep and package-availability fights; stay close to HyDE's
own installer, adapt rather than rewrite.

## Environment

- Distro: CachyOS (Arch-based, performance-tuned), installed via
  CachyOS's own installer
- WM: Hyprland (via HyDE)
- GPU: AMD, Wayland-native drivers, no NVIDIA workarounds
- Display: single desktop PC, target 3x 1080p monitors — real hardware
  not available yet this pass, monitor config is a placeholder
- This repo is authored on WSL (no CachyOS/Hyprland present) — nothing
  in the install path is exercised live during this pass; correctness
  rests on reading HyDE's own README/installer and porting the
  debian-dotfiles package list by name, not on a live test run

## Repo layout

```
arch-dotfiles/
  install.sh                    # top-level idempotent entrypoint
  vendor/hyde/                  # git subtree, fork of HyDE-Project/HyDE
  dotfiles/                     # overlay, mirrors $HOME layout
  packages/pacman.txt           # official-repo packages, one per line
  packages/aur.txt              # AUR packages, one per line
  scripts/regenerate-packages.sh
  scripts/symlink-dotfiles.sh
  README.md
```

## HyDE vendoring

1. `gh repo fork HyDE-Project/HyDE --clone=false` → creates
   `LeivurGargiulo/HyDE` on GitHub (gh already authenticated as that
   account, confirmed this session).
2. `git subtree add --prefix vendor/hyde <fork-ssh-url> master --squash`
   from the arch-dotfiles repo root.
3. Upstream updates later: `git subtree pull --prefix vendor/hyde
   <fork-ssh-url> master --squash` (after syncing the fork from
   HyDE-Project/HyDE upstream on GitHub's side, or adding upstream as a
   second git remote to the fork — document whichever is simpler in
   README's update section).
4. `vendor/hyde/` is never hand-edited. All customization lives in
   `dotfiles/` and is layered on top after HyDE's installer runs.

## Dotfile application

Plain overlay, no chezmoi/stow dependency. `dotfiles/` mirrors `$HOME`
exactly (e.g. `dotfiles/.config/hypr/monitors.conf` →
`~/.config/hypr/monitors.conf`). `scripts/symlink-dotfiles.sh` walks the
tree and `ln -sfn`s every file into place — safe to re-run, always wins
over whatever HyDE's installer put there, since it runs after HyDE's
installer in `install.sh`.

This pass, `dotfiles/` contains at minimum:
- `.config/hypr/monitors.conf` — placeholder (see below)
- anything else HyDE's `Configs/` doesn't already cover and the user
  wants customized (kept minimal for v1 — extend after real use)

## install.sh flow

Idempotent, safe to re-run end to end, no destructive operations:

1. Sanity checks: running on an Arch-based distro, not root, `git` and
   `base-devel` present (install via pacman if missing).
2. Bootstrap `yay` if absent (build from AUR via `base-devel` +
   `git`).
3. `pacman -S --needed -` < `packages/pacman.txt`
4. `yay -S --needed -` < `packages/aur.txt`
5. Run `vendor/hyde/Scripts/install.sh` unmodified — HyDE's own
   installer handles its package set, GPU driver branching (AMD needs
   no special case; HyDE only branches for NVIDIA), and laying down
   `Configs/` into `$HOME`.
6. Run `scripts/symlink-dotfiles.sh` to lay the overlay on top.
7. Print a reminder to fill in `dotfiles/.config/hypr/monitors.conf`
   with real output names/positions once on actual hardware, then
   re-run step 6 (or the whole script — idempotent either way).

## Monitor config placeholder

`dotfiles/.config/hypr/monitors.conf`, sourced from HyDE's main Hyprland
config (HyDE's default config already splits monitor config into its
own file under `~/.config/hypr/` — this overlay file replaces it via
the symlink step). Content is a clearly marked TODO block with commented
example syntax for a 3-monitor layout, no invented output names
(`DP-1`/`DP-2`/`HDMI-1` are examples only, real names come from
`hyprctl monitors` on actual hardware).

## Package lists (this pass — hand-curated, not yet machine-generated)

`packages/pacman.txt` / `packages/aur.txt` are **not** regenerated from
a live `pacman -Qqe` this pass (no CachyOS install exists yet). They're
hand-curated by porting `../debian-dotfiles/docs/SOFTWARE_LIST.md`
to Arch/AUR package names, plus the AMD Wayland driver stack, minus:

- Everything HyDE's own installer already provides (Hyprland itself,
  Waybar, rofi, a notification daemon, SDDM, a lock screen, a clipboard
  manager, GTK/Qt theming) — not duplicated in our lists to avoid
  version/config conflicts with HyDE's choices.
- X11-only packages with no meaning under Wayland/Hyprland (i3-wm,
  xserver-xorg, xinit, polybar, lightdm, nitrogen, dex, picom-from-source,
  betterlockscreen, greenclip, GRUB colorice theming, qt5ct/lxappearance
  build steps) — dropped, HyDE's stack replaces their job.
- pip/npm/cargo/rustup-installed tooling and manual GitHub-release
  binaries with no AUR package — listed in README as a documented
  "extras, not automated this pass" section instead of forced into
  pacman/AUR lists that can't actually hold them.

Marked in README as best-effort until `scripts/regenerate-packages.sh`
is run on real hardware once the user has actually installed everything
they use day to day.

## scripts/regenerate-packages.sh

```sh
pacman -Qqe | comm -23 - <(pacman -Qqm | sort) > packages/pacman.txt
pacman -Qqm > packages/aur.txt
```
(exact flags to be finalized during implementation — intent: explicit
native packages minus AUR-owned ones go to pacman.txt, AUR-owned go to
aur.txt). Run after installing anything new, then commit the diff.

## README contents

- What's HyDE upstream (`vendor/hyde/`) vs this repo's customization
  (`dotfiles/`, `packages/`, `install.sh`)
- CachyOS vs vanilla Arch deltas relevant here (repo/mirror differences,
  any CachyOS-specific package naming encountered)
- Fresh install: clone, run `install.sh`
- Update flow: `git subtree pull` for HyDE, re-run `install.sh`
  (idempotent)
- Regenerating package lists after installing something new
- Extras not automated this pass (pip/npm/cargo packages, manual
  GitHub-release binaries with no AUR package) — listed for reference,
  install manually until/unless promoted into the automated flow later

## Out of scope this pass

- Real 3-monitor Hyprland output config (needs real hardware)
- Catppuccin/colorice-style live theming pipeline from debian-dotfiles
  (HyDE ships its own theme system; revisit only if HyDE's doesn't
  cover something the user needs)
- Automating pip/npm/cargo package installation
- Testing `install.sh` end to end (no CachyOS machine available this
  session) — implementation should be reviewed for correctness against
  HyDE's documented install flow, not run live
