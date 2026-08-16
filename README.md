# arch-dotfiles

CachyOS + Hyprland dotfiles, AMD GPU, forked from
[HyDE](https://github.com/HyDE-Project/HyDE) as the rice base. No
Ansible, no chezmoi — a symlink overlay plus `pacman -S --needed` /
`yay -S --needed` package lists, which gives idempotency without an
extra tooling layer. Goal: reformat = clone this repo, run
`install.sh`.

## What's HyDE vs what's ours

- `vendor/hyde/` — HyDE, vendored as a git subtree from
  [LeivurGargiulo/HyDE](https://github.com/LeivurGargiulo/HyDE) (a
  fork of `HyDE-Project/HyDE`). **Never hand-edited.** Provides
  Hyprland, Waybar, rofi, a lock screen, a notification daemon, GTK/Qt
  theming, and its own package/install logic.
- `dotfiles/` — our overlay, mirrors `$HOME` layout exactly (e.g.
  `dotfiles/.config/hypr/monitors.conf` → `~/.config/hypr/monitors.conf`).
  Applied last, after HyDE's installer, so it always wins.
- `packages/pacman.txt` / `packages/aur.txt` — everything beyond what
  HyDE's own installer already pulls in: the AMD driver stack and the
  CLI/TUI tools ported from a previous (Debian) dotfiles setup.
- `install.sh`, `scripts/` — glue: package install, run HyDE's
  installer, apply the overlay.

## CachyOS vs vanilla Arch

CachyOS is Arch-based with its own performance-tuned repos/kernel;
HyDE's installer targets "Arch or Arch-based" and works as-is. No
CachyOS-specific package renames are known yet — if `install.sh` hits
one (a package under a different name in CachyOS's repos), fix it in
`packages/pacman.txt`/`packages/aur.txt` directly and note it here.

## Fresh install

```sh
git clone <this-repo-url> ~/arch-dotfiles
cd ~/arch-dotfiles
./install.sh
```

Safe to re-run end to end — every step uses `--needed`/`-sfn`-style
idempotent operations.

**3-monitor setup:** `dotfiles/.config/hypr/monitors.conf` ships as a
placeholder. After first install, run `hyprctl monitors`, fill in the
real output names/positions, then re-run `scripts/symlink-dotfiles.sh`
(or all of `install.sh`).

## Updating HyDE

```sh
git subtree pull --prefix vendor/hyde git@github.com:LeivurGargiulo/HyDE.git master --squash
```

If the fork itself is behind `HyDE-Project/HyDE`, sync it first (GitHub
web UI "Sync fork," or `gh repo sync LeivurGargiulo/HyDE`), then run
the `subtree pull` above.

## Regenerating package lists

After installing anything new by hand:

```sh
./scripts/regenerate-packages.sh
git diff packages/
git add packages/ && git commit -m "packages: regenerate from live system"
```

This overwrites both files from the live system's `pacman -Qqe`/`-Qqm`
— it drops the hand-written `#` category comments from the original
curated lists. Re-add comments by hand if you want them back, or just
let the plain list stand.

## Not automated yet

These were part of the prior (Debian) setup and aren't wired into
`install.sh` — install manually for now, promote into the automated
flow later if it's worth it:

- pip user packages (`beautifulsoup4`, `pandas`, `pytest`, etc. — see
  `../debian-dotfiles/docs/SOFTWARE_LIST.md` for the full list)
- npm globals (`@anthropic-ai/claude-code`, `@bitwarden/cli`)
- `oh-my-zsh` + its custom plugins, `nvm`-installed Node LTS, `tmux`
  plugin manager (tpm) — shell-environment setup scripts, not packages
- Cargo-only tools (e.g. Raijin weather TUI, no pre-built binary)
- Flatpak apps (Zen Browser, RustDesk, Vesktop, Telegram, ZapZap,
  EasyEffects, GNOME Boxes, PrismLauncher, input-leap) — `flatpak` itself
  is in `packages/pacman.txt`; install apps with `flatpak install
  flathub <app-id>` once needed
