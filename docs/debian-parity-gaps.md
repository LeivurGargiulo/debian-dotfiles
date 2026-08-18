# debian-dotfiles software not in arch-dotfiles

Everything in `debian-dotfiles/docs/SOFTWARE_LIST.md` that has no path into
`packages/pacman.txt` / `packages/aur.txt` here, grouped by why. Most of
the list *was* portable and already got ported — including, as of a later
pass, the last four apps that had been sitting under README's "Not
automated yet" as manual flatpak installs: EasyEffects, PrismLauncher, and
input-leap (superseded by `deskflow`, its actively-maintained successor)
all turned out to have official Arch `extra` packages, and osu! has a real
AUR package (`osu-lazer-bin`) — none needed flatpak after all, so that
section and the `flatpak` package itself were removed entirely. This file
is what's left: things that don't map cleanly.

**A thorough line-by-line re-audit against debian's full `SOFTWARE_LIST.md`
found one real miss, now fixed:** `dotfiles/.config/nvim/` never existed —
neovim (this repo's declared sole editor) had zero configuration despite
every other tool getting careful attention. Ported directly from debian's
own real kickstart.nvim fork (LSP/treesitter/telescope/etc all intact,
copied file-for-file, not reconstructed); colorscheme is now a generated
Lua module following the active HyDE theme, see §2 below. The same audit
also confirmed `flameshot` (debian's screenshot tool) really is
covered by HyDE's own bundled `screenshot.sh` — not a gap, verified
directly against the vendored HyDE source rather than assumed.

## 1. Superseded by Hyprland/HyDE (X11-only, no port needed)

debian-dotfiles targets i3 (X11). HyDE already provides the Wayland/Hyprland
equivalent of each of these, so none were ported — installing them
alongside HyDE would just be redundant with what it already sets up:

xserver-xorg, xinit, i3-wm, i3lock, polybar, lightdm + lightdm-gtk-greeter,
network-manager-gnome, blueman, flameshot, lxpolkit, lxappearance, qt5ct,
thunar + thunar-archive-plugin, nitrogen, dex, light, pulseaudio-utils,
dunst, picom (the `implement-window-animations` fork, built from source in
debian — Hyprland has its own compositor), greenclip (clipboard daemon —
HyDE/Hyprland ships its own), betterlockscreen (screen lock — HyDE ships
`hyprlock` or equivalent).

`rofi` is the one exception worth naming: debian uses it as the i3 app
launcher/power menu, and HyDE typically ships it too (or `wofi`) as part
of its own Hyprland config — so it's already covered, just not via
`packages/pacman.txt` directly.

**Not a gap to fix** — re-verify what HyDE actually installs once
`install.sh` runs on real hardware; only add something here if HyDE
*doesn't* cover it.

## 2. Theming/config layer — dynamic, follows the active HyDE theme

An earlier pass themed everything a single fixed way (Monokai Pro,
hardcoded hex throughout). That's gone — every themeable CLI/TUI tool now
follows whichever HyDE theme is active (`hydectl theme set "<name>"`) via
wallbash templates under `dotfiles/.config/hyde/wallbash/theme/`
(`<wallbash_pryN>`/`<wallbash_NxaM>` placeholders, exactly like HyDE's own
`kitty.dcol`/`waybar.dcol`), with a handful of tools whose color format
can't take hex directly (`taskwarrior`'s rgb-cube notation,
`cmus`/`newsboat`'s 256-color palette index, `fastfetch`'s semicolon-RGB
ANSI escapes) getting a small conversion script under
`dotfiles/.config/hyde/wallbash/scripts/` instead, reading the same
`dcol_*` variables `color.set.sh` exports. See the README's "What's HyDE
vs what's ours" section for the full mechanism and the current tool list.

`nvim` in particular no longer uses a bundled colorscheme plugin
(`monokai-pro.nvim`) — it never could have followed an arbitrary active
theme, since a colorscheme plugin ships its own fixed palette variants.
Replaced with a small generated Lua colorscheme
(`dotfiles/.config/nvim/lua/custom/wallbash-colors.lua`, wallbash-owned)
applied via `dotfiles/.config/nvim/lua/custom/config/wallbash-theme.lua`.

Icon theme, cursor theme, and Firefox theming were dropped entirely (not
converted to dynamic) — the build tooling for a fixed cursor/icon
palette doesn't make sense once the palette itself isn't fixed, and
neither was live-tested on real hardware before removal in any case.
Cursor theme now just follows whatever `$CURSOR_THEME` each HyDE theme's
own `hypr.theme` declares — no separate build step, same as every other
stock theme.

**Deliberately deferred** (not gaps, tracked decisions):
- GRUB boot theme — CachyOS may default to a different bootloader
  (systemd-boot is common on Arch-based installers); verify what's
  actually in use before assuming GRUB applies at all.
- qt5ct/GTK palette — relies on HyDE's wallbash `gtk-css.dcol`/qtct
  templates recoloring from `theme.dcol` automatically; not hand-verified
  against a running system.
- Zen Browser CSS theming (debian: `zen-colors.css`, imported via
  `userChrome.css` in the browser's profile) — Zen Browser has no viable
  TUI replacement (kept as GUI, see the earlier GUI→TUI swap round) and
  its per-profile flatpak-sandbox CSS injection is a different mechanism
  than the CLI/TUI config-file pattern this ricing pass covers — out of
  scope, not attempted.
- `wtf.yml` (a terminal dashboard tool) — `wtf` itself was never added to
  `packages/`, so nothing to theme; not confirmed wanted.

## 3. Dropped on purpose (non-FOSS), not a gap

- **google-chrome-stable** — proprietary; Zen Browser (flatpak, already in
  README's not-automated list) replaces it, same call debian made.
- **VS Code** (`code`) — proprietary build + telemetry; Neovim is the sole
  editor, same call debian made.

## 4. Carried over unresolved from debian itself

debian-dotfiles never installed these either (raised, not confirmed
wanted, or blocked on its own apt mirror) — still open, still nothing
here for them:

- scrcpy — was failing to resolve on debian's apt mirror; untested on Arch/AUR
- openrgb, reaper — no install task in debian either
- LocalSend, HandBrake, ProtonUp-Qt, protontricks, lutris — raised during
  debian's oldpackages review, never confirmed wanted
- ollama — raised, not confirmed wanted
- gurk (Signal), Posting (HTTP client) — surfaced from a TUI-apps search,
  never confirmed wanted

`barrier` is not listed here — debian already replaced it with
`input-leap`, which arch-dotfiles now installs natively as `deskflow`
(see above).
