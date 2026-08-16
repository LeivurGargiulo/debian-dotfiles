# Monokai Pro ricing — design

**Goal:** theme the whole arch-dotfiles system (Hyprland/HyDE chrome + CLI/TUI
tools) around Monokai Pro, the 2018-rebrand palette (github.com/monokai-pro) —
not the older 2012 "Classic Monokai" everyone half-remembers, and distinct
from the loose/inconsistent HyDE community theme this design found and
rejected as an authoritative color source (see Background).

**Scope:** everything themeable — HyDE's own chrome (Hyprland, waybar, rofi,
dunst, GTK, Qt, hyprlock) plus every CLI/TUI tool in `packages/` that has a
real theme mechanism.

## Background

HyDE ships an official theme system (`hydectl theme`, theme branches under
`HyDE-Project/hyde-themes`) with 12 official themes — none are Monokai. A
community HyDE theme exists (`mahaveergurjar/Theme-Gallery`, `Monokai`
branch) with the right file structure but wrong colors: verified against its
actual `theme.dcol`/`kitty.theme`/`waybar.theme` files, its "accent" colors
are a mashup of Classic Monokai (2012) and Catppuccin Mocha hex values, with
the background disagreeing across files (`#2C2525` / `#2d2a2e` / `#272822`).
Not safe to trust as a color source. Its file *layout* is usable as a
skeleton — HyDE's theme directory format doesn't need to be reverse-engineered
from scratch.

## Verified palette (Monokai Pro / default variant)

Source: `loctvl842/monokai-pro.nvim`'s palette definitions, cross-checked
against monokai.pro's published editor screenshots. This table is the single
source of truth — every config file in this design copies from it, nothing
re-derives or approximates it independently.

| Role | Hex |
|---|---|
| Background | `#2d2a2e` |
| Background (darker) | `#221f22` / `#19181a` |
| Foreground / text | `#fcfcfa` |
| Dimmed gray | `#c1c0c0` → `#403e41` |
| Pink / red (errors, keywords) | `#ff6188` |
| Orange (numbers, constants) | `#fc9867` |
| Yellow (classes, warnings) | `#ffd866` |
| Green (strings, success) | `#a9dc76` |
| Cyan (support, info) | `#78dce8` |
| Purple (functions) | `#ab9df2` |

Written out in full to `docs/monokai-pro-palette.md` during implementation
(includes the dimmed-gray ramp), so every task can cite it without
re-deriving values.

## Architecture

Two layers:

### 1. HyDE-native layer (wallbash-driven)

`dotfiles/.config/hyde/themes/Monokai-Pro/` — a proper HyDE theme, adapted
from `mahaveergurjar/Theme-Gallery`'s file skeleton with every color value
replaced by the verified table above:

```
dotfiles/.config/hyde/themes/Monokai-Pro/
  theme.dcol           # canonical palette source — HyDE's wallbash engine
                        # propagates this to waybar/rofi/dunst/GTK/Qt/
                        # hyprlock/kitty automatically, no per-app file needed
  hypr.theme
  wall.set              -> wallpapers/monokai-pro-solid.png
  wallpapers/
    monokai-pro-solid.png   # flat #2d2a2e placeholder, same spirit as
                             # monitors.conf's placeholder — swap for a real
                             # wallpaper later, not blocking
```

No bundled GTK/icon-theme archive (the source repo's archives are
unverified, same repo whose color files were wrong) — GTK accent colors ride
wallbash's dynamic recolor of the palette; icon theme selection is left for
later, out of scope here.

**Activation:** `install.sh`, after the existing `symlink-dotfiles.sh` step:

```bash
if command -v hydectl >/dev/null 2>&1; then
    hydectl theme set "Monokai-Pro"
fi
```

Confirmed via `hydectl theme set --help` against the vendored binary
(`vendor/hyde/Configs/.local/bin/hydectl`) — `hydectl theme set [theme name]`
is the real, scriptable, non-interactive activation command (the rofi-based
`theme.select.sh` picker was the interactive alternative, not used here).
Idempotent: re-running just re-applies the same theme name.

### 2. Manual overlay layer (dotfiles/ config files)

For CLI/TUI tools wallbash doesn't touch, hand-built (or ported from an
existing verified community Monokai Pro config where the research found a
trustworthy one) config files added to `dotfiles/`, applied by the existing
`symlink-dotfiles.sh` — no new mechanism, same as `monitors.conf`.

**Covered (21 tools):** bat, eza, git-delta, fzf, tmux, btop, cava, zathura,
mpv, newsboat, aerc, atuin, ncspot, lazygit, yazi, zsh-syntax-highlighting,
mangohud, gitui, cmus, calcurse, taskwarrior.

**Explicitly not covered:**
- kitty, rofi — already themed via the HyDE/wallbash layer above; a second
  manual config would fight the wallbash-generated one.
- The ratatui-picks batch with no user-facing palette config (gping, trippy,
  bottom, dua-cli, diskonaut, systemctl-tui, serie, igrep, journalview,
  hwatch, tabiew, rucola, mirro-rs, parui) — these inherit terminal ANSI
  colors from the themed terminal; hand-configuring each individually isn't
  worth it for tools with no dedicated theme file.

Per-tool exact config syntax (bat's `.tmTheme` build step, eza's
`theme.yml`, tmux's color directives, etc.) is implementation-plan detail,
not fixed here — the design's commitment is the tool list and the rule
"verified community port first, hand-build from the palette table
otherwise," not each file's contents.

## File layout (full)

```
dotfiles/
  .config/
    hyde/themes/Monokai-Pro/
      theme.dcol
      hypr.theme
      wall.set
      wallpapers/monokai-pro-solid.png
    bat/
    eza/theme.yml
    tmux/tmux.conf             # XDG path (tmux >=3.1 supports it), consistent
                                # with this repo's XDG-first convention
    btop/themes/monokai-pro.theme
    cava/config
    zathura/zathurarc
    mpv/mpv.conf
    newsboat/config
    aerc/
    atuin/
    ncspot/config.toml
    lazygit/config.yml
    yazi/theme.toml
    gitui/theme.ron
    mangohud/MangoHud.conf
  .zshrc                       # zsh-syntax-highlighting, git-delta, fzf env —
                                # plain $HOME path, matches oh-my-zsh's own
                                # convention (this repo already installs
                                # oh-my-zsh, which expects ~/.zshrc directly)
docs/
  monokai-pro-palette.md        # canonical hex table
```

`install.sh`:
```bash
echo "==> applying dotfiles overlay (scripts/symlink-dotfiles.sh)"
"$repo_root/scripts/symlink-dotfiles.sh"

echo "==> applying Monokai Pro HyDE theme"
if command -v hydectl >/dev/null 2>&1; then
    hydectl theme set "Monokai-Pro"
fi
```

## Testing / verification

- No new scripts, so no new shellcheck surface beyond the `install.sh`
  addition (covered by the existing `shellcheck install.sh` step).
- `test_symlink-dotfiles.sh` already generically verifies every file under
  `dotfiles/` becomes a symlink — no new test needed for the theme files
  themselves, they're just more files under the same tree.
- No automated hex-drift checker across the ~20 config files — deliberately
  cut as unnecessary machinery for a personal dotfiles repo. Verify each
  file against `docs/monokai-pro-palette.md` by hand during implementation
  review.
- Whether `hydectl theme set` actually applies cleanly is untestable in this
  sandbox (needs a running Hyprland session) — same "no live test this pass"
  constraint the rest of `install.sh` already operates under. A real-hardware
  failure there gets fixed on the real install, not guessed at now.

## Explicitly out of scope

- A real (non-solid-color) wallpaper — placeholder only, same pattern as
  `monitors.conf`.
- Icon theme selection.
- GTK/Qt bundled theme archives (rely on wallbash's dynamic recolor instead).
- Any tool not in the 21-tool "covered" list above.
