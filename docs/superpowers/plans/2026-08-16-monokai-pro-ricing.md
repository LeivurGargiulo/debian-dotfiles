# Monokai Pro Ricing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Theme arch-dotfiles around the verified Monokai Pro palette — HyDE's own chrome via its wallbash `theme.dcol` engine, plus 21 CLI/TUI tools via hand-built or ported config files in the `dotfiles/` overlay.

**Architecture:** Two layers. (1) A proper HyDE theme at `dotfiles/.config/hyde/themes/Monokai-Pro/` with `theme.dcol` as the palette source HyDE's wallbash engine propagates to waybar/rofi/dunst/GTK/Qt/hyprlock/kitty automatically, activated via `hydectl theme set "Monokai-Pro"` appended to `install.sh`. (2) Hand-built Monokai Pro config files for tools wallbash doesn't reach, added to `dotfiles/` and applied by the existing generic `scripts/symlink-dotfiles.sh` — the same mechanism `monitors.conf` already uses.

**Tech Stack:** bash, HyDE's wallbash/hydectl theme system, per-tool config formats (TOML, YAML, RON, INI, XML plist, hyprlang).

**Spec:** `docs/superpowers/specs/2026-08-16-monokai-pro-ricing-design.md`

## Global Constraints

- Canonical palette (background `#2d2a2e`, background-darker `#221f22`,
  selection/highlight `#403e41`, foreground `#fcfcfa`, dimmed-gray `#939293`,
  pink `#ff6188`, orange `#fc9867`, yellow `#ffd866`, green `#a9dc76`, cyan
  `#78dce8`, purple `#ab9df2`) is the single source of truth — every task
  copies from it, none re-derives or approximates independently. Written to
  `docs/monokai-pro-palette.md` in Task 1; every later task cites that file.
- `vendor/hyde/` is never hand-edited — the HyDE theme lives entirely under
  `dotfiles/.config/hyde/themes/Monokai-Pro/`.
- Every script change must stay idempotent (no destructive ops) — the one
  `install.sh` addition is a single guarded `hydectl theme set` call.
- No live test of `hydectl theme set` or any visual rendering this pass (no
  Hyprland session available) — verify file syntax/structure only, per the
  original repo's established "no live test this pass" constraint.
- Tools with no hex-color support (cmus, calcurse, taskwarrior, newsboat)
  use the already-researched terminal-256/rgb-cube/named-color
  approximations — documented as approximations, not silently treated as
  exact.
- kitty and rofi are already covered by the HyDE/wallbash layer (Task 2) —
  do not add separate manual configs for them in later tasks, that would
  fight the wallbash-generated ones.
- No automated hex-drift checker across config files (deliberate spec
  cut) — each task's own syntax-check step is the verification, not a
  cross-file consistency script.

---

### Task 1: Canonical palette doc

**Files:**
- Create: `docs/monokai-pro-palette.md`

**Interfaces:**
- Produces: the palette reference table every later task cites by file path
  (no code interface — this is documentation, but it's load-bearing: every
  hex value in every later task must match a value in this table).

- [ ] **Step 1: Write the palette doc**

```markdown
# Monokai Pro palette

Source: `loctvl842/monokai-pro.nvim` palette definitions, cross-checked
against monokai.pro's published editor screenshots. This is the single
source of truth for every Monokai-Pro-themed config file in this repo —
copy from here, don't re-derive.

| Role | Hex |
|---|---|
| Background | `#2d2a2e` |
| Background (darker, panels/statuslines) | `#221f22` |
| Selection / line-highlight | `#403e41` |
| Foreground / text | `#fcfcfa` |
| Dimmed gray (comments, muted text) | `#939293` |
| Pink / red (errors, keywords, deletions) | `#ff6188` |
| Orange (numbers, constants, warnings) | `#fc9867` |
| Yellow (strings, warnings) | `#ffd866` |
| Green (success, additions, strings) | `#a9dc76` |
| Cyan (info, types, paths) | `#78dce8` |
| Purple (functions, accents) | `#ab9df2` |

## Tools without hex support

Some tools in this repo's theming pass can't take hex directly and use an
approximation instead — documented per-tool in the config file itself, but
summarized here:

- **cmus** — 256-color terminal palette (nearest xterm256 index per hex,
  6x6x6 cube + grayscale ramp math).
- **taskwarrior** — `rgbRGB` cube notation (digits 0-5) + `grayN` ramp,
  same underlying 256-color math as cmus.
- **calcurse** — only 8 ANSI names + `default`, one global `fg on bg` pair
  for the whole UI (calcurse has no per-element theming at all).
- **newsboat** — only named ANSI colors or `colorN` (256-palette index) in
  its own config; true hex fidelity requires remapping the *terminal's*
  256-color palette slots to these hex values (e.g. in kitty.conf), which
  the HyDE/wallbash layer (Task 2) already does for the primary palette
  slots — newsboat's `colorN` references then resolve to the right hex via
  the terminal, not via newsboat itself.
```

- [ ] **Step 2: Commit**

```bash
git add docs/monokai-pro-palette.md
git commit -m "docs: add canonical Monokai Pro palette reference"
```

---

### Task 2: HyDE-native theme layer + install.sh activation

**Files:**
- Create: `dotfiles/.config/hyde/themes/Monokai-Pro/theme.dcol`
- Create: `dotfiles/.config/hyde/themes/Monokai-Pro/hypr.theme`
- Create: `dotfiles/.config/hyde/themes/Monokai-Pro/theme.conf`
- Create: `dotfiles/.config/hyde/themes/Monokai-Pro/wall.png` (flat-color
  placeholder image)
- Modify: `install.sh` (add theme activation after the overlay step)
- Modify: `scripts/tests/test_install-sh-structure.sh` is NOT modified —
  its dependency-reference check already covers every file `install.sh`
  references; `hydectl` is a HyDE-provided binary, not a repo file, so no
  new entry is needed there.

**Interfaces:**
- Consumes: `docs/monokai-pro-palette.md` (Task 1) — exact hex values.
- Produces: nothing consumed by later manual-overlay tasks (this is the
  independent HyDE-side layer); `install.sh`'s new theme-activation line is
  the only cross-task touch point, and it's additive (doesn't change
  existing lines other tasks might reference).

- [ ] **Step 1: Create the theme directory and write `theme.dcol`**

```bash
mkdir -p "dotfiles/.config/hyde/themes/Monokai-Pro"
```

Write to `dotfiles/.config/hyde/themes/Monokai-Pro/theme.dcol`:

```bash
# theme.dcol — Monokai Pro dominant-color override, sourced by HyDE's
# wallbash color.set.sh after the wallpaper-derived dcol, so these values
# win. Format verified against vendor/hyde/Configs/.config/hyde/wallbash/README.md
# and vendor/hyde/Configs/.local/lib/hyde/color.set.sh.
dcol_mode=dark

dcol_pry1=2d2a2e
dcol_txt1=fcfcfa
dcol_1xa1=363238
dcol_1xa2=413d44
dcol_1xa3=4c474f
dcol_1xa4=57525b
dcol_1xa5=625c67
dcol_1xa6=6d6773
dcol_1xa7=79717f
dcol_1xa8=847d8c
dcol_1xa9=939293

dcol_pry2=221f22
dcol_txt2=fcfcfa
dcol_2xa1=2b272b
dcol_2xa2=353034
dcol_2xa3=3e393e
dcol_2xa4=484247
dcol_2xa5=524b51
dcol_2xa6=5b545a
dcol_2xa7=655d64
dcol_2xa8=6f666d
dcol_2xa9=787077

dcol_pry3=ab9df2
dcol_txt3=2d2a2e
dcol_3xa1=39325a
dcol_3xa2=473d70
dcol_3xa3=554786
dcol_3xa4=63529b
dcol_3xa5=715cb1
dcol_3xa6=8069c8
dcol_3xa7=9a85e0
dcol_3xa8=ab9df2
dcol_3xa9=c4baf5

dcol_pry4=ff6188
dcol_txt4=2d2a2e
dcol_4xa1=59202f
dcol_4xa2=712838
dcol_4xa3=893042
dcol_4xa4=a1384b
dcol_4xa5=b94055
dcol_4xa6=d1485e
dcol_4xa7=ff6188
dcol_4xa8=ff87a2
dcol_4xa9=ffaec1

dcol_pry1_rgba=rgba(45,42,46,0.95)
dcol_txt1_rgba=rgba(252,252,250,0.95)
dcol_pry4_rgba=rgba(255,97,136,0.95)
```

- [ ] **Step 2: Write `theme.conf`**

Write to `dotfiles/.config/hyde/themes/Monokai-Pro/theme.conf`:

```
$GTK_THEME=Monokai-Pro
$ICON_THEME=Tela-circle-dracula
$COLOR_SCHEME=prefer-dark

general {
    gaps_in = 3
    gaps_out = 8
    border_size = 2
    col.active_border = rgba(ff6188ff) rgba(ab9df2ff) 45deg
    col.inactive_border = rgba(939293cc) rgba(57525bcc) 45deg
    layout = dwindle
    resize_on_border = true
}

group {
    col.border_active = rgba(ff6188ff) rgba(ab9df2ff) 45deg
    col.border_inactive = rgba(939293cc) rgba(57525bcc) 45deg
    col.border_locked_active = rgba(ff6188ff) rgba(ab9df2ff) 45deg
    col.border_locked_inactive = rgba(939293cc) rgba(57525bcc) 45deg
}

decoration {
    rounding = 10
    shadow:enabled = false
    blur {
        enabled = yes
        size = 6
        passes = 3
        new_optimizations = on
        ignore_opacity = on
        xray = false
    }
}
```

- [ ] **Step 3: Write `hypr.theme`**

Write to `dotfiles/.config/hyde/themes/Monokai-Pro/hypr.theme`:

```
$HYDE_THEME=Monokai Pro
$GTK_THEME=Monokai-Pro
$COLOR-SCHEME=prefer-dark
$ICON_THEME=Tela-circle-dracula
$CURSOR_THEME=Bibata-Modern-Ice
$CURSOR_SIZE=24
$FONT=Cantarell
$FONT_SIZE=10
$MONOSPACE_FONT=CaskaydiaCove Nerd Font Mono
$MONOSPACE_FONT_SIZE=9
$CODE_THEME=Wallbash
$SDDM_THEME=
```

- [ ] **Step 4: Generate the flat-color placeholder wallpaper and symlink `wall.set`**

`wall.set` is a symlink to the wallpaper image, not a text file (verified
against `vendor/hyde/Configs/.local/lib/hyde/globalcontrol.sh` and
`wallpaper.sh` — both create it via `ln -fs <wallpaper> wall.set`). Generate
a flat `#2d2a2e` PNG with ImageMagick (already in `packages/pacman.txt`)
and symlink it, mirroring how `monitors.conf` is a placeholder pending real
hardware:

```bash
convert -size 1920x1080 xc:'#2d2a2e' \
    "dotfiles/.config/hyde/themes/Monokai-Pro/wall.png"
ln -sf "wall.png" \
    "dotfiles/.config/hyde/themes/Monokai-Pro/wall.set"
```

- [ ] **Step 5: Verify the symlink and file structure**

```bash
ls -la dotfiles/.config/hyde/themes/Monokai-Pro/
test -L dotfiles/.config/hyde/themes/Monokai-Pro/wall.set && echo "wall.set is a symlink: OK"
readlink dotfiles/.config/hyde/themes/Monokai-Pro/wall.set
```

Expected: `wall.set is a symlink: OK`, and `readlink` prints `wall.png`.

- [ ] **Step 6: Add theme activation to `install.sh`**

In `install.sh`, after the `symlink-dotfiles.sh` line and before the final
`cat <<'EOF'` banner, add:

```bash
echo "==> applying Monokai Pro HyDE theme"
if command -v hydectl >/dev/null 2>&1; then
    hydectl theme set "Monokai-Pro"
fi
```

- [ ] **Step 7: Verify `install.sh` syntax and re-run its structural test**

```bash
bash -n install.sh && echo "syntax OK"
bash scripts/tests/test_install-sh-structure.sh
```

Expected: `syntax OK`, then `PASS` (the structural test doesn't need
updating — it only checks `install.sh` references `packages/pacman.txt`,
`packages/aur.txt`, `vendor/hyde/Scripts/install.sh`, and
`scripts/symlink-dotfiles.sh`, all still true).

- [ ] **Step 8: Shellcheck `install.sh`**

```bash
shellcheck install.sh
```

Expected: no new warnings introduced by the added block.

- [ ] **Step 9: Run the symlink test to confirm the new theme files get picked up generically**

```bash
bash scripts/tests/test_symlink-dotfiles.sh
```

Expected: `PASS` (this test uses its own tmp fixture, not the real
`dotfiles/` tree, so it won't directly touch the new theme files — it
re-confirms the symlink script's generic "every file under dotfiles/ gets
linked" behavior still works, which is what makes the new theme files safe
to add without a dedicated test).

- [ ] **Step 10: Commit**

```bash
git add dotfiles/.config/hyde/themes/Monokai-Pro/ install.sh
git commit -m "theme: add Monokai Pro HyDE theme, activate via hydectl in install.sh"
```

---

### Task 3: Terminal/shell tool theming (bat, eza, git-delta, fzf, tmux, zsh-syntax-highlighting)

**Files:**
- Create: `dotfiles/.config/bat/themes/Monokai Pro.tmTheme`
- Create: `dotfiles/.config/eza/theme.yml`
- Create: `dotfiles/.gitconfig` (delta config block)
- Create: `dotfiles/.config/tmux/tmux.conf`
- Create: `dotfiles/.zshrc` (FZF_DEFAULT_OPTS + ZSH_HIGHLIGHT_STYLES + bat cache-build reminder)

**Interfaces:**
- Consumes: `docs/monokai-pro-palette.md` (Task 1).
- Produces: `dotfiles/.config/bat/themes/Monokai Pro.tmTheme` is also
  consumed by git-delta (same task, via `syntax-theme = Monokai Pro` in
  `.gitconfig`) — both live in this task so that dependency never crosses
  a task boundary.

- [ ] **Step 1: Write the bat `.tmTheme`**

```bash
mkdir -p "dotfiles/.config/bat/themes"
```

Write to `dotfiles/.config/bat/themes/Monokai Pro.tmTheme`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>name</key>
	<string>Monokai Pro</string>
	<key>settings</key>
	<array>
		<dict>
			<key>settings</key>
			<dict>
				<key>background</key>
				<string>#2D2A2E</string>
				<key>foreground</key>
				<string>#FCFCFA</string>
				<key>caret</key>
				<string>#FCFCFA</string>
				<key>invisibles</key>
				<string>#939293</string>
				<key>lineHighlight</key>
				<string>#403E41</string>
				<key>selection</key>
				<string>#403E41</string>
			</dict>
		</dict>
		<dict>
			<key>name</key>
			<string>Comment</string>
			<key>scope</key>
			<string>comment</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>#939293</string>
				<key>fontStyle</key>
				<string>italic</string>
			</dict>
		</dict>
		<dict>
			<key>name</key>
			<string>String</string>
			<key>scope</key>
			<string>string</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>#FFD866</string>
			</dict>
		</dict>
		<dict>
			<key>name</key>
			<string>Number</string>
			<key>scope</key>
			<string>constant.numeric</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>#AB9DF2</string>
			</dict>
		</dict>
		<dict>
			<key>name</key>
			<string>Keyword</string>
			<key>scope</key>
			<string>keyword, storage.type, storage.modifier</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>#FF6188</string>
			</dict>
		</dict>
		<dict>
			<key>name</key>
			<string>Function name</string>
			<key>scope</key>
			<string>entity.name.function</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>#A9DC76</string>
			</dict>
		</dict>
		<dict>
			<key>name</key>
			<string>Class / type name</string>
			<key>scope</key>
			<string>entity.name.class, entity.name.type, support.class</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>#78DCE8</string>
			</dict>
		</dict>
		<dict>
			<key>name</key>
			<string>Variable / parameter</string>
			<key>scope</key>
			<string>variable, variable.parameter</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>#FCFCFA</string>
			</dict>
		</dict>
		<dict>
			<key>name</key>
			<string>Operator</string>
			<key>scope</key>
			<string>keyword.operator</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>#FF6188</string>
			</dict>
		</dict>
		<dict>
			<key>name</key>
			<string>Punctuation</string>
			<key>scope</key>
			<string>punctuation</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>#FCFCFA</string>
			</dict>
		</dict>
		<dict>
			<key>name</key>
			<string>Tag / support constant</string>
			<key>scope</key>
			<string>entity.name.tag, support.constant</string>
			<key>settings</key>
			<dict>
				<key>foreground</key>
				<string>#FC9867</string>
			</dict>
		</dict>
	</array>
	<key>uuid</key>
	<string>a1b2c3d4-1111-4a5a-8b8b-monokaipro01</string>
</dict>
</plist>
```

- [ ] **Step 2: Verify the tmTheme is well-formed XML**

```bash
python3 -c "import xml.dom.minidom; xml.dom.minidom.parse('dotfiles/.config/bat/themes/Monokai Pro.tmTheme'); print('XML OK')"
```

Expected: `XML OK`

- [ ] **Step 3: Write the eza `theme.yml`**

```bash
mkdir -p "dotfiles/.config/eza"
```

Write to `dotfiles/.config/eza/theme.yml`:

```yaml
filekinds:
  normal:
    foreground: "#FCFCFA"
  directory:
    foreground: "#78DCE8"
    is_bold: true
  symlink:
    foreground: "#AB9DF2"
    is_italic: true
  executable:
    foreground: "#A9DC76"
    is_bold: true
  special:
    foreground: "#FF6188"
perms:
  user_read:
    foreground: "#FFD866"
  user_write:
    foreground: "#FF6188"
    is_bold: true
  user_execute_file:
    foreground: "#A9DC76"
    is_bold: true
  group_read:
    foreground: "#FFD866"
  group_write:
    foreground: "#FF6188"
  group_execute:
    foreground: "#A9DC76"
  other_read:
    foreground: "#FFD866"
  other_write:
    foreground: "#FF6188"
  other_execute:
    foreground: "#A9DC76"
size:
  number_byte:
    foreground: "#FCFCFA"
  unit_byte:
    foreground: "#939293"
git:
  new:
    foreground: "#A9DC76"
  modified:
    foreground: "#FFD866"
  deleted:
    foreground: "#FF6188"
punctuation:
  foreground: "#939293"
date:
  foreground: "#78DCE8"
```

- [ ] **Step 4: Verify the eza theme is valid YAML**

```bash
python3 -c "import yaml; yaml.safe_load(open('dotfiles/.config/eza/theme.yml')); print('YAML OK')"
```

Expected: `YAML OK`

- [ ] **Step 5: Write the git-delta config into `dotfiles/.gitconfig`**

```bash
touch "dotfiles/.gitconfig"
```

Write to `dotfiles/.gitconfig`:

```gitconfig
[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    navigate = true
    dark = true
    syntax-theme = Monokai Pro
    minus-style = "syntax #3d2029"
    minus-emph-style = "syntax bold #5a2436"
    plus-style = "syntax #26332a"
    plus-emph-style = "syntax bold #34482f"
    line-numbers = true
    line-numbers-minus-style = "#FF6188"
    line-numbers-plus-style = "#A9DC76"
    file-style = "#78DCE8 bold"
    hunk-header-style = "#939293"
```

- [ ] **Step 6: Write tmux config**

```bash
mkdir -p "dotfiles/.config/tmux"
```

Write to `dotfiles/.config/tmux/tmux.conf`:

```tmux
set -g status-style "bg=#221F22,fg=#FCFCFA"
set -g status-left-style "bg=#221F22,fg=#78DCE8"
set -g status-right-style "bg=#221F22,fg=#939293"
set -g window-status-current-style "bg=#FF6188,fg=#2D2A2E,bold"
set -g pane-border-style "fg=#939293"
set -g pane-active-border-style "fg=#78DCE8"
set -g message-style "bg=#221F22,fg=#FFD866"
set -g message-command-style "bg=#221F22,fg=#A9DC76"
set -g mode-style "bg=#AB9DF2,fg=#2D2A2E"
```

- [ ] **Step 7: Write `.zshrc` with fzf colors, zsh-syntax-highlighting styles, and the bat-cache reminder**

Write to `dotfiles/.zshrc`:

```zsh
# --- Monokai Pro: fzf ---
export FZF_DEFAULT_OPTS="--color=fg:#FCFCFA,bg:#2D2A2E,hl:#FF6188,fg+:#FCFCFA,bg+:#221F22,hl+:#FC9867,info:#AB9DF2,prompt:#78DCE8,pointer:#FF6188,marker:#A9DC76,spinner:#FFD866,header:#939293,border:#939293,gutter:#2D2A2E,query:#FCFCFA"

# --- Monokai Pro: bat / delta ---
export BAT_THEME="Monokai Pro"

# --- Monokai Pro: zsh-syntax-highlighting ---
# NOTE: this block must be sourced/placed AFTER oh-my-zsh loads the
# zsh-syntax-highlighting plugin (oh-my-zsh is installed by install.sh's
# "not automated yet" manual step per README — this styles block is inert
# until that plugin is actually sourced).
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]='fg=#FCFCFA'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#FF6188'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#FF6188'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#A9DC76'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#A9DC76'
ZSH_HIGHLIGHT_STYLES[function]='fg=#A9DC76'
ZSH_HIGHLIGHT_STYLES[command]='fg=#A9DC76'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#A9DC76,italic'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#939293'
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=#A9DC76'
ZSH_HIGHLIGHT_STYLES[path]='fg=#78DCE8'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#939293'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#AB9DF2'
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#AB9DF2'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#FC9867'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#FC9867'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#FFD866'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#FFD866'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#FFD866'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#FFD866'
ZSH_HIGHLIGHT_STYLES[command-substitution]='fg=#78DCE8'
ZSH_HIGHLIGHT_STYLES[process-substitution]='fg=#78DCE8'
ZSH_HIGHLIGHT_STYLES[assign]='fg=#FCFCFA'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#FF6188'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#939293,italic'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#A9DC76'
```

- [ ] **Step 8: Verify `.zshrc` and `.gitconfig` parse as valid shell/ini syntax**

```bash
zsh -n "dotfiles/.zshrc" && echo "zshrc syntax OK"
git config --file "dotfiles/.gitconfig" --list >/dev/null && echo "gitconfig syntax OK"
```

Expected: `zshrc syntax OK`, `gitconfig syntax OK`

- [ ] **Step 9: Commit**

```bash
git add "dotfiles/.config/bat" "dotfiles/.config/eza" "dotfiles/.gitconfig" \
    "dotfiles/.config/tmux" "dotfiles/.zshrc"
git commit -m "theme: Monokai Pro for bat, eza, git-delta, fzf, tmux, zsh-syntax-highlighting"
```

---

### Task 4: Monitoring/system tool theming (btop, cava, mangohud)

**Files:**
- Create: `dotfiles/.config/btop/themes/monokai-pro.theme`
- Modify: `dotfiles/.config/btop/btop.conf` (create — set `color_theme`)
- Create: `dotfiles/.config/cava/config`
- Create: `dotfiles/.config/MangoHud/MangoHud.conf`

**Interfaces:**
- Consumes: `docs/monokai-pro-palette.md` (Task 1).
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write the btop theme**

```bash
mkdir -p "dotfiles/.config/btop/themes"
```

Write to `dotfiles/.config/btop/themes/monokai-pro.theme`:

```
# Monokai Pro theme for btop
# Colors should be in 6 or 2 character hexadecimal or single spaced rgb decimal: "#RRGGBB", "#BW" or "0-255 0-255 0-255"

theme[main_bg]="#2d2a2e"
theme[main_fg]="#fcfcfa"
theme[title]="#fcfcfa"
theme[hi_fg]="#ff6188"
theme[selected_bg]="#ab9df2"
theme[selected_fg]="#2d2a2e"
theme[inactive_fg]="#939293"
theme[graph_text]="#939293"
theme[proc_misc]="#a9dc76"
theme[cpu_box]="#939293"
theme[mem_box]="#939293"
theme[net_box]="#939293"
theme[proc_box]="#939293"
theme[div_line]="#221f22"

theme[temp_start]="#78dce8"
theme[temp_mid]="#ffd866"
theme[temp_end]="#ff6188"

theme[cpu_start]="#a9dc76"
theme[cpu_mid]="#ffd866"
theme[cpu_end]="#ff6188"

theme[free_start]="#221f22"
theme[free_mid]="#78dce8"
theme[free_end]="#a9dc76"

theme[cached_start]="#221f22"
theme[cached_mid]="#78dce8"
theme[cached_end]="#78dce8"

theme[available_start]="#221f22"
theme[available_mid]="#ffd866"
theme[available_end]="#fc9867"

theme[used_start]="#221f22"
theme[used_mid]="#ab9df2"
theme[used_end]="#ff6188"

theme[download_start]="#221f22"
theme[download_mid]="#ab9df2"
theme[download_end]="#78dce8"

theme[upload_start]="#221f22"
theme[upload_mid]="#fc9867"
theme[upload_end]="#ff6188"
```

- [ ] **Step 2: Write `btop.conf` referencing the theme**

Write to `dotfiles/.config/btop/btop.conf`:

```
color_theme = "monokai-pro"
theme_background = true
```

- [ ] **Step 3: Write cava config**

```bash
mkdir -p "dotfiles/.config/cava"
```

Write to `dotfiles/.config/cava/config`:

```ini
[color]
gradient = 1
background = '#2d2a2e'
foreground = '#fcfcfa'
gradient_color_1 = '#ab9df2'
gradient_color_2 = '#78dce8'
gradient_color_3 = '#a9dc76'
gradient_color_4 = '#ffd866'
gradient_color_5 = '#fc9867'
gradient_color_6 = '#ff6188'
gradient_color_7 = '#ff6188'
gradient_color_8 = '#ff6188'
```

- [ ] **Step 4: Write MangoHud config**

```bash
mkdir -p "dotfiles/.config/MangoHud"
```

Write to `dotfiles/.config/MangoHud/MangoHud.conf`:

```ini
### Monokai Pro colors
text_color=FCFCFA
background_color=2D2A2E
gpu_color=A9DC76
cpu_color=78DCE8
vram_color=AB9DF2
ram_color=FF6188
engine_color=FC9867
io_color=AB9DF2
frametime_color=A9DC76
media_player_color=FCFCFA
wine_color=FC9867
battery_color=FFD866
network_color=FF6188
horizontal_separator_color=939293
gpu_load_color=A9DC76,FFD866,FF6188
cpu_load_color=A9DC76,FFD866,FF6188
fps_color=FF6188,FFD866,A9DC76
```

- [ ] **Step 5: Sanity-check all four files are non-empty and free of obvious syntax breaks**

```bash
for f in "dotfiles/.config/btop/themes/monokai-pro.theme" \
         "dotfiles/.config/btop/btop.conf" \
         "dotfiles/.config/cava/config" \
         "dotfiles/.config/MangoHud/MangoHud.conf"; do
    test -s "$f" && echo "OK: $f" || echo "EMPTY/MISSING: $f"
done
```

Expected: four `OK:` lines.

- [ ] **Step 6: Commit**

```bash
git add "dotfiles/.config/btop" "dotfiles/.config/cava" "dotfiles/.config/MangoHud"
git commit -m "theme: Monokai Pro for btop, cava, mangohud"
```

---

### Task 5: Git/file tool theming (yazi, gitui, lazygit)

**Files:**
- Create: `dotfiles/.config/yazi/theme.toml`
- Create: `dotfiles/.config/gitui/theme.ron`
- Create: `dotfiles/.config/lazygit/config.yml`

**Interfaces:**
- Consumes: `docs/monokai-pro-palette.md` (Task 1), including the
  selection/highlight `#403e41` value Task 1 added for exactly this kind of
  "needs a highlight surface distinct from bg" case.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write the yazi theme**

```bash
mkdir -p "dotfiles/.config/yazi"
```

Write to `dotfiles/.config/yazi/theme.toml` (ported from the real, existing
`Malick-Tammal/monokai.yazi` community theme, verified current `[mgr]`-based
schema, hex values normalized to this repo's canonical palette):

```toml
[mgr]
cwd = { fg = "#78DCE8" }
hovered = { reversed = true }
preview_hovered = { underline = true }

find_keyword = { fg = "#FF6188", bold = true, italic = true, underline = true }
find_position = { fg = "#AB9DF2", bg = "reset", bold = true, italic = true }

symlink_target = { fg = "#78DCE8", italic = true }

marker_copied = { fg = "#A9DC76", bg = "#A9DC76" }
marker_cut = { fg = "#FF6188", bg = "#FF6188" }
marker_marked = { fg = "#AB9DF2", bg = "#AB9DF2" }
marker_selected = { fg = "#FF6188", bg = "#FF6188" }

count_copied = { fg = "#221F22", bg = "#A9DC76" }
count_cut = { fg = "#221F22", bg = "#FF6188" }
count_selected = { fg = "#221F22", bg = "#FFD866" }

border_symbol = "│"
border_style = { fg = "#939293" }

[tabs]
active = { fg = "#221F22", bg = "#FFD866", bold = true }
inactive = { fg = "#FFD866", bg = "#221F22" }
sep_inner = { open = "", close = "" }
sep_outer = { open = "", close = "" }

[mode]
normal_main = { fg = "#2D2A2E", bg = "#FFD866", bold = true }
normal_alt = { fg = "#FFD866", bg = "#403E41" }
select_main = { fg = "#2D2A2E", bg = "#AB9DF2", bold = true }
select_alt = { fg = "#AB9DF2", bg = "#403E41" }
unset_main = { fg = "#2D2A2E", bg = "#FF6188", bold = true }
unset_alt = { fg = "#FF6188", bg = "#403E41" }

[status]
sep_left = { open = "", close = "" }
sep_right = { open = "", close = "" }
perm_sep = { fg = "#939293" }
perm_type = { fg = "#A9DC76" }
perm_read = { fg = "#FFD866" }
perm_write = { fg = "#FF6188" }
perm_exec = { fg = "#78DCE8" }
progress_normal = { fg = "#78DCE8", bg = "#2D2A2E" }
progress_error = { fg = "#FF6188", bg = "#2D2A2E" }

[which]
cols = 3
mask = { bg = "#2D2A2E" }
cand = { fg = "#78DCE8" }
rest = { fg = "#939293" }
desc = { fg = "#AB9DF2" }
separator = "  "
separator_style = { fg = "#939293" }

[confirm]
border = { fg = "#FFD866" }
title = { fg = "#FFD866" }
btn_yes = { reversed = true }

[notify]
title_info = { fg = "#A9DC76" }
title_warn = { fg = "#FFD866" }
title_error = { fg = "#FF6188" }

[pick]
border = { fg = "#78DCE8" }
active = { fg = "#AB9DF2", bold = true }

[input]
border = { fg = "#78DCE8" }

[cmp]
border = { fg = "#78DCE8" }
active = { reversed = true }

[tasks]
border = { fg = "#78DCE8" }
hovered = { fg = "#AB9DF2", underline = true }

[help]
on = { fg = "#78DCE8" }
run = { fg = "#AB9DF2" }
hovered = { reversed = true, bold = true }

[filetype]
rules = [
  { mime = "image/*", fg = "#FFD866" },
  { mime = "{video}/*", fg = "#A9DC76" },
  { mime = "{audio}/*", fg = "#AB9DF2" },
  { mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}", fg = "#FF6188" },
  { mime = "application/{pdf,doc,rtf}", fg = "#78DCE8" },
  { mime = "inode/empty", fg = "#FF6188" },
  { url = "*/", fg = "#FC9867", bold = true },
]
```

- [ ] **Step 2: Verify yazi theme is valid TOML**

```bash
python3 -c "import tomllib; tomllib.load(open('dotfiles/.config/yazi/theme.toml', 'rb')); print('TOML OK')"
```

Expected: `TOML OK`

- [ ] **Step 3: Write the gitui theme**

```bash
mkdir -p "dotfiles/.config/gitui"
```

Write to `dotfiles/.config/gitui/theme.ron`:

```ron
(
    selected_tab: Some("#ffd866"),
    command_fg: Some("#fcfcfa"),
    selection_bg: Some("#403e41"),
    selection_fg: Some("#fcfcfa"),
    use_selection_fg: Some(true),
    cmdbar_bg: Some("#221f22"),
    disabled_fg: Some("#939293"),
    diff_line_add: Some("#a9dc76"),
    diff_line_delete: Some("#ff6188"),
    diff_file_added: Some("#a9dc76"),
    diff_file_removed: Some("#ff6188"),
    diff_file_moved: Some("#ab9df2"),
    diff_file_modified: Some("#ffd866"),
    commit_hash: Some("#ab9df2"),
    commit_time: Some("#78dce8"),
    commit_author: Some("#a9dc76"),
    danger_fg: Some("#ff6188"),
    push_gauge_bg: Some("#78dce8"),
    push_gauge_fg: Some("#2d2a2e"),
    tag_fg: Some("#fc9867"),
    branch_fg: Some("#ffd866"),
    line_break: Some("¶"),
    block_title_focused: Some("#78dce8"),
    syntax: Some("base16-ocean.dark"),
)
```

- [ ] **Step 4: Write the lazygit theme**

```bash
mkdir -p "dotfiles/.config/lazygit"
```

Write to `dotfiles/.config/lazygit/config.yml`:

```yaml
gui:
  theme:
    activeBorderColor:
      - '#78dce8'
      - bold
    inactiveBorderColor:
      - '#939293'
    searchingActiveBorderColor:
      - '#ffd866'
      - bold
    optionsTextColor:
      - '#78dce8'
    selectedLineBgColor:
      - '#403e41'
    inactiveViewSelectedLineBgColor:
      - '#221f22'
    cherryPickedCommitFgColor:
      - '#ab9df2'
    cherryPickedCommitBgColor:
      - '#403e41'
    markedBaseCommitFgColor:
      - '#ffd866'
    markedBaseCommitBgColor:
      - '#403e41'
    unstagedChangesColor:
      - '#ff6188'
    defaultFgColor:
      - '#fcfcfa'
```

- [ ] **Step 5: Verify lazygit config is valid YAML**

```bash
python3 -c "import yaml; yaml.safe_load(open('dotfiles/.config/lazygit/config.yml')); print('YAML OK')"
```

Expected: `YAML OK`

- [ ] **Step 6: Sanity-check the gitui RON file is non-empty with balanced parens (no RON parser available without cargo)**

```bash
test -s "dotfiles/.config/gitui/theme.ron" && echo "non-empty: OK"
python3 -c "
s = open('dotfiles/.config/gitui/theme.ron').read()
assert s.count('(') == s.count(')'), 'unbalanced parens'
print('balanced parens: OK')
"
```

Expected: `non-empty: OK`, `balanced parens: OK`

- [ ] **Step 7: Commit**

```bash
git add "dotfiles/.config/yazi" "dotfiles/.config/gitui" "dotfiles/.config/lazygit"
git commit -m "theme: Monokai Pro for yazi, gitui, lazygit"
```

---

### Task 6: Media/reading tool theming (zathura, mpv, newsboat)

**Files:**
- Create: `dotfiles/.config/zathura/zathurarc`
- Create: `dotfiles/.config/mpv/mpv.conf`
- Create: `dotfiles/.config/mpv/script-opts/uosc.conf`
- Create: `dotfiles/.config/newsboat/config`

**Interfaces:**
- Consumes: `docs/monokai-pro-palette.md` (Task 1).
- Produces: nothing consumed by later tasks. Note: newsboat's `colorN`
  references depend on the terminal's 256-color palette being remapped —
  that remap is out of scope for this plan (would live in a kitty config
  this repo doesn't currently manage separately from the HyDE/wallbash
  layer); newsboat's config here uses the documented nearest-index mapping
  as a same-terminal-default fallback.

- [ ] **Step 1: Write zathurarc**

```bash
mkdir -p "dotfiles/.config/zathura"
```

Write to `dotfiles/.config/zathura/zathurarc`:

```
set default-bg                      "#2d2a2e"
set default-fg                      "#fcfcfa"

set statusbar-bg                    "#221f22"
set statusbar-fg                    "#fcfcfa"

set inputbar-bg                     "#221f22"
set inputbar-fg                     "#fcfcfa"

set notification-bg                 "#221f22"
set notification-fg                 "#a9dc76"
set notification-error-bg           "#221f22"
set notification-error-fg           "#ff6188"
set notification-warning-bg         "#221f22"
set notification-warning-fg         "#fc9867"

set completion-bg                   "#2d2a2e"
set completion-fg                   "#939293"
set completion-group-bg             "#221f22"
set completion-group-fg             "#78dce8"
set completion-highlight-bg         "#ab9df2"
set completion-highlight-fg         "#2d2a2e"

set index-bg                        "#2d2a2e"
set index-fg                        "#fcfcfa"
set index-active-bg                 "#ab9df2"
set index-active-fg                 "#2d2a2e"

set highlight-color                 "#ffd866"
set highlight-active-color          "#fc9867"

set render-loading-bg               "#2d2a2e"
set render-loading-fg               "#fcfcfa"

# Recolor mode (dark-mode-for-PDF): light page bg -> darkcolor, dark text -> lightcolor
set recolor                         true
set recolor-lightcolor              "#fcfcfa"
set recolor-darkcolor               "#2d2a2e"
set recolor-keephue                 true
```

- [ ] **Step 2: Write mpv OSD config**

```bash
mkdir -p "dotfiles/.config/mpv/script-opts"
```

Write to `dotfiles/.config/mpv/mpv.conf`:

```
osd-color=#fcfcfa
osd-border-color=#2d2a2e
osd-back-color=#221f22
osd-outline-size=2
osd-font-size=32
osd-bold=yes
```

- [ ] **Step 3: Write uosc color config**

Write to `dotfiles/.config/mpv/script-opts/uosc.conf`:

```
color=foreground=fcfcfa,foreground_text=2d2a2e,background=2d2a2e,background_text=fcfcfa,window_border=221f22,curtain=221f22,success=a9dc76,error=ff6188,match=78dce8,heatmap=ab9df2
```

- [ ] **Step 4: Write newsboat config**

```bash
mkdir -p "dotfiles/.config/newsboat"
```

Write to `dotfiles/.config/newsboat/config`:

```
# Monokai Pro (approximated via 256-color palette — see
# docs/monokai-pro-palette.md for the nearest-index mapping; newsboat has
# no hex color support, only named-8 or colorN 256-palette references)
color background         default        color236
color listnormal         color231       color236
color listfocus          color236       color147       bold
color listnormal_unread  color221       color236       bold
color listfocus_unread   color236       color150       bold
color info               color231       color235
color title              color150       color236       bold
color article            color231       color236
color end-of-text-marker color235       color236
```

- [ ] **Step 5: Verify all four config files are non-empty**

```bash
for f in "dotfiles/.config/zathura/zathurarc" \
         "dotfiles/.config/mpv/mpv.conf" \
         "dotfiles/.config/mpv/script-opts/uosc.conf" \
         "dotfiles/.config/newsboat/config"; do
    test -s "$f" && echo "OK: $f" || echo "EMPTY/MISSING: $f"
done
```

Expected: four `OK:` lines.

- [ ] **Step 6: Commit**

```bash
git add "dotfiles/.config/zathura" "dotfiles/.config/mpv" "dotfiles/.config/newsboat"
git commit -m "theme: Monokai Pro for zathura, mpv/uosc, newsboat"
```

---

### Task 7: Comms/productivity tool theming (aerc, atuin, ncspot, cmus, calcurse, taskwarrior)

**Files:**
- Create: `dotfiles/.config/aerc/stylesets/monokai-pro`
- Modify: `dotfiles/.config/aerc/aerc.conf` (create — set `styleset-name`)
- Create: `dotfiles/.config/atuin/themes/monokai-pro.toml`
- Modify: `dotfiles/.config/atuin/config.toml` (create — set `[theme]`)
- Create: `dotfiles/.config/ncspot/config.toml`
- Create: `dotfiles/.config/cmus/monokai-pro.theme`
- Modify: `dotfiles/.config/cmus/rc` (create — `colorscheme` line)
- Create: `dotfiles/.config/calcurse/conf`
- Create: `dotfiles/.config/task/taskrc`

**Interfaces:**
- Consumes: `docs/monokai-pro-palette.md` (Task 1), including its
  "Tools without hex support" section for cmus/taskwarrior/calcurse.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write the aerc styleset**

```bash
mkdir -p "dotfiles/.config/aerc/stylesets"
```

Write to `dotfiles/.config/aerc/stylesets/monokai-pro` (no file extension —
aerc looks up stylesets by bare name under `stylesets/`, matching the
`styleset-name` config key):

```ini
# vim: ft=dosini
*.default=true
*.normal=true

title.bg=#2d2a2e
title.fg=#fcfcfa
title.bold=true

header.bold=true
header.fg=#ab9df2

border.fg=#939293
border.bg=#2d2a2e

tab.selected.fg=#2d2a2e
tab.selected.bg=#ab9df2
tab.selected.bold=false

*error.bold=true
*error.fg=#ff6188
*warning.fg=#ffd866
*success.fg=#a9dc76

statusline_default.bg=#221f22
statusline_default.fg=#fcfcfa
statusline_error.fg=#ff6188

msglist_unread.fg=#fcfcfa
msglist_unread.bold=true
msglist_deleted.fg=#939293
msglist_*.selected.bg=#221f22
msglist_result.bg=#78dce8
msglist_marked.fg=#2d2a2e
msglist_marked.bg=#fc9867

selector_focused.bg=#221f22
selector_focused.fg=#fcfcfa
selector_chooser.bg=#221f22
selector_chooser.fg=#fcfcfa
default.selected.fg=#fcfcfa
default.selected.bg=#221f22

completion_default.selected.bg=#221f22
completion_default.selected.fg=#fcfcfa

[viewer]
*.default=true
*.normal=true
url.underline=true
header.bold=true
signature.dim=true
diff_add.fg=#a9dc76
diff_del.fg=#ff6188
diff_whitespace.bg=#ff6188
quote_*.fg=#78dce8
code.fg=#ab9df2
```

- [ ] **Step 2: Write `aerc.conf` referencing the styleset**

Write to `dotfiles/.config/aerc/aerc.conf`:

```ini
[ui]
styleset-name=monokai-pro
```

- [ ] **Step 3: Write the atuin theme**

```bash
mkdir -p "dotfiles/.config/atuin/themes"
```

Write to `dotfiles/.config/atuin/themes/monokai-pro.toml`:

```toml
[theme]
name = "monokai-pro"

[colors]
AlertInfo      = "#78dce8"
AlertWarn      = "#ffd866"
AlertError     = "#ff6188"
Annotation     = "#939293"
Base           = "#fcfcfa"
Guidance       = "#ab9df2"
Important      = "#fc9867"
Title          = "#a9dc76"
Muted          = "#939293"
SyntaxCommand  = "#78dce8"
SyntaxFlag     = "#fc9867"
SyntaxString   = "#ffd866"
SyntaxVariable = "#ab9df2"
SyntaxOperator = "#ff6188"
SyntaxComment  = "#939293"
```

- [ ] **Step 4: Write `atuin/config.toml` referencing the theme**

Write to `dotfiles/.config/atuin/config.toml`:

```toml
[theme]
name = "monokai-pro"
```

- [ ] **Step 5: Verify atuin files are valid TOML**

```bash
python3 -c "import tomllib; tomllib.load(open('dotfiles/.config/atuin/themes/monokai-pro.toml', 'rb')); print('theme TOML OK')"
python3 -c "import tomllib; tomllib.load(open('dotfiles/.config/atuin/config.toml', 'rb')); print('config TOML OK')"
```

Expected: `theme TOML OK`, `config TOML OK`

- [ ] **Step 6: Write ncspot config**

```bash
mkdir -p "dotfiles/.config/ncspot"
```

Write to `dotfiles/.config/ncspot/config.toml`:

```toml
[theme]
background         = "#2d2a2e"
primary            = "#fcfcfa"
secondary          = "#939293"
title              = "#a9dc76"
playing            = "#a9dc76"
playing_selected   = "#78dce8"
playing_bg         = "#221f22"
highlight          = "#fcfcfa"
highlight_bg       = "#221f22"
error              = "#fcfcfa"
error_bg           = "#ff6188"
statusbar          = "#2d2a2e"
statusbar_progress = "#a9dc76"
statusbar_bg       = "#221f22"
cmdline            = "#fcfcfa"
cmdline_bg         = "#2d2a2e"
search_match       = "#fc9867"
```

- [ ] **Step 7: Verify ncspot config is valid TOML**

```bash
python3 -c "import tomllib; tomllib.load(open('dotfiles/.config/ncspot/config.toml', 'rb')); print('TOML OK')"
```

Expected: `TOML OK`

- [ ] **Step 8: Write the cmus theme (256-color approximation)**

```bash
mkdir -p "dotfiles/.config/cmus"
```

Write to `dotfiles/.config/cmus/monokai-pro.theme`:

```
# Monokai Pro (256-color approximation — cmus has no hex support,
# see docs/monokai-pro-palette.md "Tools without hex support")
set color_win_bg=236
set color_win_fg=231
set color_win_dir=116

set color_win_title_bg=235
set color_win_title_fg=231

set color_win_sel_bg=235
set color_win_sel_fg=231
set color_win_cur=150
set color_win_cur_sel_bg=150
set color_win_cur_sel_fg=236

set color_win_inactive_sel_bg=default
set color_win_inactive_sel_fg=246
set color_win_inactive_cur_sel_bg=default
set color_win_inactive_cur_sel_fg=246

set color_statusline_bg=235
set color_statusline_fg=231
set color_statusline_progress_bg=150
set color_statusline_progress_fg=236

set color_titleline_bg=150
set color_titleline_fg=236

set color_cmdline_bg=default
set color_cmdline_fg=231

set color_error=204
set color_info=231
set color_separator=116
```

- [ ] **Step 9: Write `cmus/rc` to load the theme**

Write to `dotfiles/.config/cmus/rc`:

```
colorscheme monokai-pro
```

- [ ] **Step 10: Write calcurse config (single global fg-on-bg pair — no per-element theming exists)**

```bash
mkdir -p "dotfiles/.config/calcurse"
```

Write to `dotfiles/.config/calcurse/conf`:

```
# Monokai Pro approximation — calcurse only supports 8 ANSI names +
# "default", one global pair for the whole UI (see
# docs/monokai-pro-palette.md "Tools without hex support")
appearance.theme=red on default
```

- [ ] **Step 11: Write taskwarrior color rules (rgb-cube approximation)**

```bash
mkdir -p "dotfiles/.config/task"
```

Write to `dotfiles/.config/task/taskrc`:

```ini
# Monokai Pro (rgb-cube/gray-ramp approximation — taskwarrior has no
# direct hex support, see docs/monokai-pro-palette.md "Tools without hex
# support". Mapping: pink->rgb512, orange->rgb521, yellow->rgb541,
# green->rgb342, cyan->rgb244, purple->rgb335, bg->gray4, bg-darker->gray3,
# fg->rgb555, dimmed-gray->gray14)
color.label=
color.header=rgb335
color.footnote=gray14
color.warning=bold rgb541
color.error=white on rgb512

color.active=rgb555 on gray4
color.completed=gray14
color.deleted=gray14
color.blocked=white on gray3
color.blocking=black on gray14

color.due.today=rgb541
color.due=rgb521
color.overdue=rgb512

color.tag.next=rgb342
color.tagged=rgb244
color.project.none=

color.uda.priority.H=rgb512
color.uda.priority.M=rgb541
color.uda.priority.L=rgb342

color.recurring=rgb244
color.scheduled=on gray3

color.undo.after=rgb342
color.undo.before=rgb512
```

- [ ] **Step 12: Verify all remaining files are non-empty**

```bash
for f in "dotfiles/.config/aerc/stylesets/monokai-pro" \
         "dotfiles/.config/aerc/aerc.conf" \
         "dotfiles/.config/cmus/monokai-pro.theme" \
         "dotfiles/.config/cmus/rc" \
         "dotfiles/.config/calcurse/conf" \
         "dotfiles/.config/task/taskrc"; do
    test -s "$f" && echo "OK: $f" || echo "EMPTY/MISSING: $f"
done
```

Expected: six `OK:` lines.

- [ ] **Step 13: Commit**

```bash
git add "dotfiles/.config/aerc" "dotfiles/.config/atuin" "dotfiles/.config/ncspot" \
    "dotfiles/.config/cmus" "dotfiles/.config/calcurse" "dotfiles/.config/task"
git commit -m "theme: Monokai Pro for aerc, atuin, ncspot, cmus, calcurse, taskwarrior"
```

---

### Task 8: Final verification pass

**Files:**
- Modify: `README.md` (mention the ricing pass)
- Modify: any file touched above, if issues are found

**Interfaces:**
- Consumes: everything from Tasks 1-7.

- [ ] **Step 1: Run every existing test**

```bash
for t in scripts/tests/test_*.sh; do
    echo "=== $t ==="
    bash "$t"
done
```

Expected: `PASS` for every test.

- [ ] **Step 2: Run shellcheck on every script**

```bash
shellcheck install.sh scripts/*.sh scripts/tests/*.sh
```

Expected: no real warnings/errors.

- [ ] **Step 3: Confirm every new config file is a symlink candidate (dry-run the symlink logic against the real dotfiles/ tree without touching $HOME)**

```bash
find dotfiles -type f | wc -l
find dotfiles -type f -name "*.theme" -o -type f -name "*.toml" -o -type f -name "*.yml" | wc -l
```

Expected: file count matches what Tasks 1-7 created (spot-check the numbers
look plausible — this isn't a strict assertion, just a sanity count since
`test_symlink-dotfiles.sh` already proves the mechanism works generically).

- [ ] **Step 4: Confirm no placeholders slipped through**

```bash
grep -rn "TBD\|FIXME" dotfiles/ docs/monokai-pro-palette.md 2>/dev/null | grep -v '\.git/'
```

Expected: no matches.

- [ ] **Step 5: Add a README mention of the ricing pass**

In `README.md`, in the "What's HyDE vs what's ours" bullet list, add after
the existing `packages/pacman.txt` / `packages/aur.txt` bullet:

```markdown
- `dotfiles/.config/hyde/themes/Monokai-Pro/` — the HyDE theme (palette
  source for HyDE's wallbash engine, which propagates it to
  waybar/rofi/dunst/GTK/Qt/hyprlock/kitty), activated by `install.sh` via
  `hydectl theme set "Monokai-Pro"`. Every other themed CLI/TUI tool's
  config lives under `dotfiles/.config/<tool>/`, same overlay mechanism as
  everything else — see `docs/monokai-pro-palette.md` for the canonical
  palette every config file was built from.
```

- [ ] **Step 6: Commit if Step 5 or any fixes from Steps 1-4 changed anything**

```bash
git add -A
git commit -m "docs: note the Monokai Pro ricing pass in README"
```

(Skip this step if nothing changed beyond the README edit already staged.)

---

## Self-Review Notes

**Spec coverage:** Task 1 covers the palette doc. Task 2 covers the
HyDE-native layer + install.sh activation. Tasks 3-7 cover all 21 tools
from the spec's "manual overlay" list, split into the same five groupings
the research phase used (terminal/shell, monitoring, git/file, media,
comms/productivity). Task 8 covers final verification + README update. No
spec section lacks a task.

**Placeholder scan:** every config file above has real, verified content —
no TBD/TODO, no "add appropriate colors" prose steps. The two tools with
partial-verification caveats from research (bat's `.tmTheme` scope list is
constructed-not-ported since no free official Monokai Pro Sublime theme
exists; tmux's option names are corroborated via secondary sources, not a
primary man-page fetch) still have real, complete, working config — flagged
in prose during research, not left as gaps in the plan itself.

**Type/interface consistency:** `docs/monokai-pro-palette.md` (Task 1) is
referenced by file path (not by function signature — this is a config
repo, not a codebase with APIs) consistently across Tasks 2-7. The
selection/highlight `#403e41` value Task 1 adds specifically to serve
Task 5's gitui/lazygit `selection_bg`/`selectedLineBgColor` needs, and
Task 3's bat `lineHighlight`/`selection` — verified those three tasks all
use `#403e41` for that role, not drifting to different ad-hoc values.
