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
  starship (`dotfiles/.config/starship.toml`) as the zsh prompt —
  Monokai Pro, two-line layout.
- `dotfiles/.config/hyde/themes/Monokai-Pro/` — the HyDE theme (palette
  source for HyDE's wallbash engine, which propagates it to
  waybar/rofi/dunst/GTK/Qt/hyprlock/kitty), activated by `install.sh` via
  `hydectl theme set "Monokai-Pro"`. Every other themed CLI/TUI tool's
  config lives under `dotfiles/.config/<tool>/`, same overlay mechanism as
  everything else — see `docs/monokai-pro-palette.md` for the canonical
  palette every config file was built from.
- `dotfiles/.config/nvim/` — a real kickstart.nvim config (ported directly
  from the prior Debian setup's own fork, LSP/treesitter/telescope/etc all
  intact), with the colorscheme swapped from Catppuccin to
  [monokai-pro.nvim](https://github.com/loctvl842/monokai-pro.nvim) —
  neovim had zero config until this was caught in a parity re-audit.
- `firefox/` — `userChrome.css` + `user.js`, applied to Firefox's default
  profile by `scripts/apply-firefox-theme.sh` (lives at the repo root, not
  under `dotfiles/`, because Firefox profile directory names are
  randomized and can't be a static symlink target). The profile itself
  lives at `${XDG_CONFIG_HOME:-~/.config}/mozilla/firefox` on this repo's
  Firefox (153.0.4, CachyOS's package) — confirmed directly, since it's
  XDG-compliant rather than the legacy `~/.mozilla/firefox` most
  documentation still assumes. The script checks XDG first and falls back
  to the legacy path, so either Firefox build works. On a genuinely fresh
  install with no profile yet, it runs `firefox -CreateProfile
  default-release -no-remote -headless`, confirmed to create one instantly
  with no window flash.
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
All 57 of HyDE's core pacman dependencies resolve in CachyOS's repos;
only `hyprquery` is AUR-only, and yay covers it.

**Chaotic-AUR is deliberately declined.** CachyOS ships its own tuned
repos and layering Chaotic-AUR over them causes conflicting rebuilds.
HyDE's `install_pre.sh` offers it on a 120-second timer that *defaults
to installing it*, so `install.sh` writes a `[chaotic-aur]` comment
into `/etc/pacman.conf` — HyDE skips the prompt when it greps that
string, and a comment satisfies the grep without enabling the repo.
That comment is load-bearing; don't tidy it away.

### rustup needs a default toolchain

`packages/pacman.txt` installs `rustup`, whose `rustc`/`cargo` shims
take PATH precedence over the system ones and **refuse to run until a
default toolchain is selected**:

```
error: rustup could not choose a version of rustc to run, because one
       wasn't specified explicitly, and no default is configured
```

Every AUR package that builds with cargo fails on this. `install.sh`
now runs `rustup default stable` before the AUR step. This was a real
install-killer (`journalview`, exit status 4) and is very likely what
the earlier "rust-lld breaks the ring crate" / "mirro-rs-git won't
link" commits were actually diagnosing — with the default toolchain
set, those builds need no linker overrides at all.

## Fresh install

```sh
git clone <this-repo-url> ~/arch-dotfiles
cd ~/arch-dotfiles
./install.sh
```

Safe to re-run end to end — every step uses `--needed`/`-sfn`-style
idempotent operations.

The run is fully unattended: HyDE's installer asks four questions (its
pacman `-Syyu`, Chaotic-AUR, the login shell, the sddm theme) plus a
closing "reboot now?", and `install.sh` pre-answers all of them. The
AUR step and HyDE's installer are both non-fatal — a single unbuildable
AUR package must never again abort the run before the desktop is
installed. Anything that failed is listed at the end and sets a
non-zero exit.

HyDE's installer is fed stdin from an endless stream of blank lines
(`< <(yes '')`), not `/dev/null`. Closing stdin entirely used to be how
its own prompts were answered, but that also starves a prompt one layer
deeper: HyDE's dependency installer (`deez`) shells out to plain `sudo
pacman -S <pkg>` with no `--noconfirm` for anything it finds missing —
its own package-manager table has no `--noconfirm` entry for pacman at
all. On EOF that "Proceed with installation? [Y/n]" prompt fails
outright, and `deez` only logs it as a warning rather than treating it
as fatal, which is exactly how a real run silently ended up without
`sddm` installed at all while still reporting success. A blank line
resolves every prompt in this chain to its safe default — `[Y/n]`
proceeds, `[y/N]` declines, HyDE's sddm-theme picker falls through to
Corners — without special-casing any of them, and it is deliberately
never a literal `y`: the closing prompt is `[y/N]` for "reboot now?",
and an unattended run must never talk itself into a surprise reboot.

A background `sudo -v` keeps the cached credential alive for the whole
HyDE step: the cursor theme build alone takes several minutes, and
combined with AUR builds a run can outlast the default 15-minute sudo
ticket right as `deez`'s un-`noconfirm`ed pacman calls need it.

**Login shell, set before HyDE's installer runs, not by it:**
`vendor/hyde/Scripts/restore_shl.sh` changes the shell with a bare
`chsh -s <path>` — no sudo, so it authenticates via the account's own
*login* password, which is a different credential from sudo's and
nothing in this script has it. Worse, every HyDE script sources
`global_fn.sh`, which sets `set -e`, so that failure isn't contained to
restore_shl.sh: it cascades all the way up through `install_pst.sh` and
aborts HyDE's top-level `install.sh` before it ever reaches the
services step (`NetworkManager`, `bluetooth`) or migrations — confirmed
live, a real run's log showed `chsh: Authentication failure` immediately
followed by control returning to this script, with no services/migration
output anywhere in between. `install.sh` now runs `sudo chsh` itself
first — root can change an account's shell without that account's own
password — comparing against a plain basename exactly like HyDE's own
`login_shell()`/`resolve_shell()` do, so HyDE sees the shell as already
correct and never calls `chsh` at all.

**pipewire-jack vs jack2:** `packages/pacman.txt` pulls in `ffmpeg`,
`mpv`, `cava` and others that need *a* JACK implementation; left to
`--needed --noconfirm`, pacman resolves that to `jack2`. HyDE's core
deps require `pipewire-jack` instead, which outright conflicts with
`jack2` (`pacman -Si`: both provide the same `jack`/`libjack.so`, and
`pipewire-jack` lists `jack2` under `Conflicts With`). That conflict
aborts HyDE's entire core-deps transaction as one unit — a real run
reported `sddm`, `hyprland`, `waybar`, `rofi` and `dunst` all "missing"
simultaneously from this single unresolved conflict, since pacman
treats a dependency batch as all-or-nothing. Neither `--noconfirm` nor
the blank-line stdin above changes the conflict prompt's own `[y/N]`
default, so `install.sh` installs `pipewire-jack` explicitly before
`packages/pacman.txt` ever runs, answering just that one prompt with a
scoped `yes |` (not the run-wide blank-line stream) — `pipewire-jack`
provides the same `jack`/`libjack.so`, so every `jack2` dependent stays
satisfied by the swap.

**Cleanup:** the run tidies up after itself. A single scratch root holds
every step's working space and is removed by an `EXIT` trap however the
script ends, and a final step drops the build byproducts of the AUR
step — yay's source checkouts and build trees, plus the Rust and Go
compiler caches — then trims the pacman cache with `paccache -rk1` /
`-ruk0`, which keeps one previous version of each installed package so
a downgrade stays possible. On a fresh install that reclaims several
GB. Two deliberate exceptions: `install.log` is never touched, and the
cache cleanup is skipped entirely when an AUR build failed, since those
cached sources are what make the retry fast.

**Display manager:** HyDE installs `sddm`, and `install.sh` forces it
to own `display-manager.service`, disabling any other enabled DM
(lightdm/gdm/lxdm) so the two can't race for the seat. A second desktop
such as LXDE can stay installed — it remains selectable as a session in
sddm and makes a useful fallback.

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

