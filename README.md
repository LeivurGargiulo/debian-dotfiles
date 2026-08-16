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
  HyDE's own installer already pulls in: the AMD driver stack, the
  CLI/TUI tools ported from a previous (Debian) dotfiles setup, a
  curated set of Rust TUI tools from
  [awesome-ratatui](https://github.com/ratatui/awesome-ratatui), TUI
  replacements for GUI apps that had a genuinely viable one (Discord
  → `endcord`, Telegram/WhatsApp → `nchat`, GNOME Boxes → `vm-curator`),
  `claude-squad` for managing multiple Claude Code sessions, and
  Powerlevel10k (`dotfiles/.p10k.zsh`) as the zsh prompt, replacing
  debian-dotfiles' starship.
- `dotfiles/.config/hyde/themes/Monokai-Pro/` — the HyDE theme (palette
  source for HyDE's wallbash engine, which propagates it to
  waybar/rofi/dunst/GTK/Qt/hyprlock/kitty), activated by `install.sh` via
  `hydectl theme set "Monokai-Pro"`. Every other themed CLI/TUI tool's
  config lives under `dotfiles/.config/<tool>/`, same overlay mechanism as
  everything else — see `docs/monokai-pro-palette.md` for the canonical
  palette every config file was built from.
- `firefox/` — `userChrome.css` + `user.js`, applied to Firefox's default
  profile by `scripts/apply-firefox-theme.sh` (lives at the repo root, not
  under `dotfiles/`, because Firefox profile directory names are
  randomized and can't be a static symlink target).
- `install.sh`, `scripts/` — glue: package install, Node LTS via `nvm`,
  run HyDE's installer, apply the overlay.

`packages/aur.txt`'s `claude-code` entry is a community-maintained AUR
build, not published by Anthropic — review its PKGBUILD before trusting
it if that matters to you.

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

See `docs/SOFTWARE_LIST.md` for what every installed package is actually
for — update it by hand alongside `packages/` changes, same as this
README, it's not generated.

## Not automated yet

These were part of the prior (Debian) setup and aren't wired into
`install.sh` — install manually for now, promote into the automated
flow later if it's worth it:

- Flatpak apps (EasyEffects, PrismLauncher, input-leap, osu! — inherently
  GUI-native, no TUI equivalent worth trusting) — `flatpak`
  itself is in `packages/pacman.txt`; install apps with `flatpak install
  flathub <app-id>` once needed
