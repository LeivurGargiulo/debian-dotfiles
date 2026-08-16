# Colorice Wallpaper-Driven Theming Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the static `catppuccin`/`orange` theme trees in `ansible/roles/theme/` with [colorice](https://github.com/rattle99/colorice), a wallpaper-to-theme generator, so the whole desktop re-colors from one command instead of two hand-maintained duplicate color trees.

**Architecture:** Two ansible roles. `theme` (trimmed) copies the `catppuccin` tree unconditionally as the static base (layout, keybinds, fallback colors) and installs fonts. New `colorice` role installs colorice via pipx and deploys a `config.toml` + custom template set covering 21 apps. Nine apps use colorice's bundled native templates (kitty, i3, picom, polybar, neovim, dunst, rofi, cava, zellij); twelve use custom templates we write. Applying a wallpaper stays a runtime, user-triggered action (`colorice <img> --apply`) — ansible never runs it.

**Tech Stack:** Ansible, colorice (Python/pipx), pywal-compatible template placeholders (`{color0}`-`{color15}`, `{background}`, `{foreground}`, `{cursor}`, Oklab filters like `.lighten_N`/`.darken_N`/`.saturate_N`/`.desaturate_N`).

**Spec:** `docs/superpowers/specs/2026-08-15-colorice-theming-design.md`

## Global Constraints

- `orange` theme tree and its GTK/Kvantum/qt5ct/cursor assets are deleted entirely — dead weight from a pre-i3 Plasma setup.
- `dotfiles_theme` enum var is retired; `catppuccin` is the only static tree, copied unconditionally.
- tmux and yazi have no reachable base config wiring their catppuccin theme assets in (verified: no `tmux.conf` anywhere in the repo; `yazi.toml` never references the `catppuccin-mocha` flavor) — both are dropped from scope, and their dead theme asset files are deleted rather than carried forward unused.
- `chezmoi/` is out of scope for this plan — it is a separate live-machine mirror, not touched here, except as a one-time source to pull the 2 missing base configs (zellij, aerc) that exist there but not in the `ansible` tree.
- Ansible never runs `colorice --apply` — a freshly-provisioned box shows static Catppuccin Mocha until the user runs colorice once.
- `invoking_home` is the existing ansible var for the target user's home dir (see `ansible/site.yml:31`); all new tasks use it, `become: false`, matching the rest of `theme/tasks/main.yml`.

---

## Extended palette reference (used in Tasks 5, 6, 7, 8, 9)

Colorice only gives 16 ANSI slots + `background`/`foreground`/`cursor`. Several apps use Catppuccin's full ~26 named roles. This repo's current kitty ANSI mapping (`ansible/roles/theme/files/catppuccin/.config/kitty/kitty.conf`) is: `color0`=surface1, `color1`=red, `color2`=green, `color3`=yellow, `color4`=blue, `color5`=pink, `color6`=teal, `color7`=subtext1, `color8`=surface2, `color9`=red, `color10`=green, `color11`=yellow, `color12`=blue, `color13`=pink, `color14`=teal, `color15`=subtext0.

Every custom/native template below that needs an extended role uses this exact derivation (ponytail: approximate via Oklab filters, not a literal 26-color extraction — good enough for chrome/accent colors, not chased further):

| Catppuccin role | Colorice expression |
|---|---|
| rosewater | `{color1.lighten_30.desaturate_20}` |
| flamingo | `{color1.lighten_20.desaturate_15}` |
| pink | `{color5}` |
| mauve | `{color5.saturate_15}` |
| red | `{color1}` |
| maroon | `{color1.darken_10}` |
| peach | `{color3.darken_5.saturate_15}` |
| yellow | `{color3}` |
| green | `{color2}` |
| teal | `{color6}` |
| sky | `{color6.lighten_10}` |
| sapphire | `{color6.darken_5.saturate_10}` |
| blue | `{color4}` |
| lavender | `{color4.lighten_15.desaturate_10}` |
| text | `{foreground}` |
| subtext1 | `{color7}` |
| subtext0 | `{color15}` |
| overlay2 | `{color7.darken_10}` |
| overlay1 | `{color8.lighten_20}` |
| overlay0 | `{color8.lighten_10}` |
| surface2 | `{color8}` |
| surface1 | `{color0}` |
| surface0 | `{background.lighten_5}` |
| base | `{background}` |
| mantle | `{background.darken_5}` |
| crust | `{background.darken_10}` |

---

### Task 1: Delete dead theme cruft, retire `dotfiles_theme`

**Files:**
- Delete: `ansible/roles/theme/files/orange/` (entire tree)
- Delete: `ansible/roles/theme/files/catppuccin/.config/tmux/plugins/catppuccin/themes/catppuccin_mocha_tmux.conf`
- Delete: `ansible/roles/theme/files/catppuccin/.config/yazi/` (entire dir — flavor never referenced)
- Modify: `ansible/roles/theme/defaults/main.yml`
- Modify: `ansible/roles/theme/tasks/main.yml`

**Interfaces:**
- Produces: `theme` role always copies `ansible/roles/theme/files/catppuccin/` to `{{ invoking_home }}/`; no `dotfiles_theme` var exists anymore. Later tasks' `colorice` role assumes this.

- [ ] **Step 1: Delete the orange tree and dead assets**

```bash
git rm -r ansible/roles/theme/files/orange
git rm ansible/roles/theme/files/catppuccin/.config/tmux/plugins/catppuccin/themes/catppuccin_mocha_tmux.conf
git rm -r ansible/roles/theme/files/catppuccin/.config/yazi
```

- [ ] **Step 2: Remove the `dotfiles_theme` default**

`ansible/roles/theme/defaults/main.yml` becomes empty of theme-selection content (delete the file if nothing else uses it):

```bash
git rm ansible/roles/theme/defaults/main.yml
```

- [ ] **Step 3: Trim `ansible/roles/theme/tasks/main.yml`**

Read the file first, then:
- Replace `src: "{{ dotfiles_theme }}/"` with `src: "catppuccin/"` in the "Copy theme files into place" task, and drop `{{ dotfiles_theme }}` from its `name:` line (hardcode "Copy catppuccin theme files into place").
- Delete every task gated `when: dotfiles_theme == 'orange'` (Kvantum dir/fetch, qt5ct dir/fetch, GTK theme fetch/unarchive, orange nitrogen wallpaper, orange cursor theme — cross-reference against the file listing from Task 1's `git rm` above; any task path referencing `files/orange` is orange-only and goes).
- Keep the `when: dotfiles_theme == 'catppuccin'` tasks (cursor theme, nitrogen seed) but drop the `when:` clause entirely — they now always run.

- [ ] **Step 4: Syntax-check**

Run: `ansible-playbook ansible/site.yml --syntax-check`
Expected: no errors, no reference to `dotfiles_theme` anywhere (`grep -rn dotfiles_theme ansible/` returns nothing).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "Drop orange theme and dead tmux/yazi assets, retire dotfiles_theme"
```

---

### Task 2: Pull missing base configs (zellij, aerc) from chezmoi

**Files:**
- Create: `ansible/roles/theme/files/catppuccin/.config/zellij/config.kdl` (copy of `chezmoi/dot_config/zellij/config.kdl`)
- Create: `ansible/roles/theme/files/catppuccin/.config/aerc/aerc.conf` (copy of `chezmoi/dot_config/aerc/aerc.conf`)

**Interfaces:**
- Consumes: nothing new.
- Produces: `~/.config/zellij/config.kdl` with `theme "catppuccin-mocha"` and `~/.config/aerc/aerc.conf` with `styleset-name=catppuccin-mocha`, both now present in the ansible tree for Task 6/9 to edit.

- [ ] **Step 1: Copy the two files**

```bash
cp chezmoi/dot_config/zellij/config.kdl ansible/roles/theme/files/catppuccin/.config/zellij/config.kdl
cp chezmoi/dot_config/aerc/aerc.conf ansible/roles/theme/files/catppuccin/.config/aerc/aerc.conf
```

- [ ] **Step 2: Verify content is intact**

```bash
grep -n 'theme "catppuccin-mocha"' ansible/roles/theme/files/catppuccin/.config/zellij/config.kdl
grep -n 'styleset-name=catppuccin-mocha' ansible/roles/theme/files/catppuccin/.config/aerc/aerc.conf
```

Expected: both greps match one line each.

- [ ] **Step 3: Commit**

```bash
git add ansible/roles/theme/files/catppuccin/.config/zellij/config.kdl ansible/roles/theme/files/catppuccin/.config/aerc/aerc.conf
git commit -m "Bring zellij/aerc base configs into the ansible theme tree"
```

---

### Task 3: Scaffold the `colorice` ansible role

**Files:**
- Create: `ansible/roles/colorice/tasks/main.yml`
- Modify: `ansible/site.yml` (add the role to the play)

**Interfaces:**
- Produces: after this task, `colorice --version` succeeds on the target and `~/.config/colorice/templates/` exists with the 22 bundled templates. Tasks 4-9 add files this role deploys via `ansible.builtin.copy`/`ansible.builtin.template` from `ansible/roles/colorice/files/`.

- [ ] **Step 1: Find where `theme` role is included in the play**

Run: `grep -n "role: theme\|roles/theme\|- theme" ansible/site.yml`

- [ ] **Step 2: Write the role task file**

`ansible/roles/colorice/tasks/main.yml`:

```yaml
---
- name: Ensure pipx is available
  ansible.builtin.apt:
    name: pipx
    state: present

- name: Install colorice via pipx
  ansible.builtin.command: pipx install colorice
  register: colorice_install
  changed_when: "'installed package' in colorice_install.stdout"
  failed_when: colorice_install.rc != 0 and 'already seems to be installed' not in colorice_install.stderr
  become: false

- name: Check if colorice templates are already initialized
  ansible.builtin.stat:
    path: "{{ invoking_home }}/.config/colorice/config.toml"
  register: colorice_config
  become: false

- name: Run colorice --init to drop bundled templates and starter config
  ansible.builtin.command: colorice --init
  become: false
  when: not colorice_config.stat.exists
```

- [ ] **Step 3: Add the role to the play**

In `ansible/site.yml`, add `colorice` immediately after `theme` in the `roles:` list (same indentation/style as the existing entries found in Step 1).

- [ ] **Step 4: Syntax-check**

Run: `ansible-playbook ansible/site.yml --syntax-check`
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add ansible/roles/colorice/tasks/main.yml ansible/site.yml
git commit -m "Scaffold colorice ansible role"
```

---

### Task 4: `config.toml` enabling all 21 apps

**Files:**
- Create: `ansible/roles/colorice/files/config.toml`
- Modify: `ansible/roles/colorice/tasks/main.yml`

**Interfaces:**
- Consumes: role scaffold from Task 3.
- Produces: `~/.config/colorice/config.toml` with all 21 `[[templates]]` entries colorice's engine reads on `--apply`. Tasks 5-9 reference these exact `name`/`input`/`output` values — do not rename them there.

- [ ] **Step 1: Write the config file**

`ansible/roles/colorice/files/config.toml`:

```toml
# Deployed by the colorice ansible role — do not edit on-machine, edit
# ansible/roles/colorice/files/config.toml and re-provision.

[[templates]]
name = "kitty"
input = "kitty.conf"
output = "~/.config/kitty/colorice-colors.conf"
hook = "killall -USR1 kitty"

[[templates]]
name = "i3"
input = "i3-colors.conf"
output = "~/.config/i3/colorice-colors.conf"
hook = "i3-msg reload"

[[templates]]
name = "i3-extended"
input = "i3-extended.conf"
output = "~/.config/i3/colorice-extended.conf"
hook = "i3-msg reload"

[[templates]]
name = "picom"
input = "picom.conf"
output = "~/.config/picom/i3.conf"
hook = "sleep 0.5 && systemctl --user restart picom"

[[templates]]
name = "polybar"
input = "polybar-colors.ini"
output = "~/.config/polybar/colorice-colors.ini"
hook = "polybar-msg cmd restart"

[[templates]]
name = "polybar-extended"
input = "polybar-extended.ini"
output = "~/.config/polybar/colorice-extended.ini"
hook = "polybar-msg cmd restart"

[[templates]]
name = "neovim"
input = "neovim-colors.lua"
output = "~/.config/nvim/lua/colorice-colors.lua"

[[templates]]
name = "dunst"
input = "dunst.conf"
output = "~/.config/dunst/dunstrc"
hook = "systemctl --user restart dunst"

[[templates]]
name = "rofi"
input = "rofi-colors.rasi"
output = "~/.config/rofi/colorice-colors.rasi"

[[templates]]
name = "cava"
input = "cava.conf"
output = "~/.config/cava/config"

[[templates]]
name = "zellij"
input = "zellij-theme.kdl"
output = "~/.config/zellij/themes/colorice.kdl"

[[templates]]
name = "fastfetch"
input = "fastfetch.jsonc"
output = "~/.config/fastfetch/config.jsonc"

[[templates]]
name = "atuin"
input = "atuin.toml"
output = "~/.config/atuin/config.toml"

[[templates]]
name = "bat"
input = "bat.tmTheme"
output = "~/.config/bat/themes/Colorice.tmTheme"
hook = "bat cache --build"

[[templates]]
name = "btop"
input = "btop.theme"
output = "~/.config/btop/themes/colorice.theme"

[[templates]]
name = "eza"
input = "eza.yml"
output = "~/.config/eza/theme.yml"

[[templates]]
name = "lazygit"
input = "lazygit.yml"
output = "~/.config/lazygit/config.yml"

[[templates]]
name = "mpv"
input = "mpv.conf"
output = "~/.config/mpv/mpv.conf"

[[templates]]
name = "ncspot"
input = "ncspot.toml"
output = "~/.config/ncspot/config.toml"

[[templates]]
name = "starship"
input = "starship.toml"
output = "~/.config/starship.toml"

[[templates]]
name = "aerc"
input = "aerc-styleset"
output = "~/.config/aerc/stylesets/colorice"

[[templates]]
name = "betterlockscreen"
input = "betterlockscreen-colors"
output = "~/.config/betterlockscreen/colorice-colors.sh"

[[templates]]
name = "delta"
input = "delta.gitconfig"
output = "~/.config/delta/colorice-colors.gitconfig"
```

- [ ] **Step 2: Deploy it from the role**

Add to `ansible/roles/colorice/tasks/main.yml` (after the `--init` task):

```yaml
- name: Deploy colorice config.toml
  ansible.builtin.copy:
    src: config.toml
    dest: "{{ invoking_home }}/.config/colorice/config.toml"
    mode: "0644"
  become: false
```

- [ ] **Step 3: Verify TOML is well-formed**

Run: `python3 -c "import tomllib; tomllib.load(open('ansible/roles/colorice/files/config.toml','rb'))"`
Expected: no exception.

- [ ] **Step 4: Commit**

```bash
git add ansible/roles/colorice/files/config.toml ansible/roles/colorice/tasks/main.yml
git commit -m "Add colorice config.toml enabling all 21 themed apps"
```

---

### Task 5: Wire WM/terminal core — kitty, i3, picom, polybar

**Files:**
- Create: `ansible/roles/colorice/files/templates/i3-extended.conf`
- Create: `ansible/roles/colorice/files/templates/polybar-extended.ini`
- Modify: `ansible/roles/theme/files/catppuccin/.config/kitty/kitty.conf`
- Modify: `ansible/roles/theme/files/catppuccin/.config/i3/config`
- Modify: `ansible/roles/theme/files/catppuccin/.config/polybar/config.ini`
- Modify: `ansible/roles/colorice/tasks/main.yml`

**Interfaces:**
- Consumes: `config.toml` entries `kitty`/`i3`/`i3-extended`/`picom`/`polybar`/`polybar-extended` from Task 4 (exact `output` paths below must match).
- Produces: base configs that pick up colorice output once the user runs `colorice --apply`; extended-palette templates other tasks can pattern-match against.

- [ ] **Step 1: Add the include line to kitty.conf**

Append to `ansible/roles/theme/files/catppuccin/.config/kitty/kitty.conf`:

```
# colorice — generated colors override the block above once you run
# `colorice <wallpaper> --apply`
include colorice-colors.conf
```

- [ ] **Step 2: Add the include lines to i3 config**

Append near the top of `ansible/roles/theme/files/catppuccin/.config/i3/config` (after the existing `set $mod` / color `set` lines, before they're consumed by `client.*`):

```
# colorice — overrides the $variables above and adds extended roles,
# once you run `colorice <wallpaper> --apply`
include ~/.config/i3/colorice-colors.conf
include ~/.config/i3/colorice-extended.conf
```

Note: i3 `include` directives only take effect from i3 >= 4.20 and only override variables defined *before* them in file order — this repo's `set $mauve`, etc. block must stay above these two lines (it already is, since we're appending near the top but after the existing `set $` block).

- [ ] **Step 3: picom — no base-file edit needed**

`config.toml`'s `picom` entry already points `output` directly at `ansible/roles/theme/files/catppuccin/.config/picom/i3.conf`'s deployed path (`~/.config/picom/i3.conf`) — colorice fully owns/rewrites that file on apply (rewrite mechanism). No change to the picom base file itself; it stays as today's static fallback until the user applies.

- [ ] **Step 4: Add the include line to polybar config.ini**

Prepend inside the existing `[colors]` section of `ansible/roles/theme/files/catppuccin/.config/polybar/config.ini` (as the first lines of that section, so later static lines act as fallback until override):

```ini
[colors]
; colorice — once you run `colorice <wallpaper> --apply`, these two
; includes override the static values below
include-file = ~/.config/polybar/colorice-colors.ini
include-file = ~/.config/polybar/colorice-extended.ini
```

- [ ] **Step 5: Write the i3 extended-palette template**

`ansible/roles/colorice/files/templates/i3-extended.conf`:

```
# colorice extended palette — generated from {wallpaper}
# Included by ~/.config/i3/config after colorice-colors.conf
set $rosewater {color1.lighten_30.desaturate_20}
set $flamingo  {color1.lighten_20.desaturate_15}
set $mauve     {color5.saturate_15}
set $maroon    {color1.darken_10}
set $peach     {color3.darken_5.saturate_15}
set $sky       {color6.lighten_10}
set $sapphire  {color6.darken_5.saturate_10}
set $lavender  {color4.lighten_15.desaturate_10}
set $subtext0  {color15}
set $overlay2  {color7.darken_10}
set $overlay1  {color8.lighten_20}
set $overlay0  {color8.lighten_10}
set $surface2  {color8}
set $surface1  {color0}
set $surface0  {background.lighten_5}
set $mantle    {background.darken_5}
set $crust     {background.darken_10}
```

- [ ] **Step 6: Write the polybar extended-palette template**

`ansible/roles/colorice/files/templates/polybar-extended.ini`:

```ini
; colorice extended palette — generated from {wallpaper}
; Included by polybar config.ini after colorice-colors.ini
[colors]
rosewater = {color1.lighten_30.desaturate_20}
flamingo  = {color1.lighten_20.desaturate_15}
mauve     = {color5.saturate_15}
maroon    = {color1.darken_10}
peach     = {color3.darken_5.saturate_15}
sky       = {color6.lighten_10}
sapphire  = {color6.darken_5.saturate_10}
lavender  = {color4.lighten_15.desaturate_10}
subtext0  = {color15}
overlay2  = {color7.darken_10}
overlay1  = {color8.lighten_20}
overlay0  = {color8.lighten_10}
surface2  = {color8}
surface1  = {color0}
surface0  = {background.lighten_5}
mantle    = {background.darken_5}
crust     = {background.darken_10}
```

- [ ] **Step 7: Deploy the two new template files from the role**

Add to `ansible/roles/colorice/tasks/main.yml`:

```yaml
- name: Deploy colorice custom templates
  ansible.builtin.copy:
    src: "templates/{{ item }}"
    dest: "{{ invoking_home }}/.config/colorice/templates/{{ item }}"
    mode: "0644"
  become: false
  loop:
    - i3-extended.conf
    - polybar-extended.ini
```

(Later tasks append more filenames to this same `loop:` list rather than adding new tasks.)

- [ ] **Step 8: Verify placeholder syntax**

Run: `grep -c '{color\|{background\|{foreground' ansible/roles/colorice/files/templates/i3-extended.conf ansible/roles/colorice/files/templates/polybar-extended.ini`
Expected: both files report a nonzero count.

- [ ] **Step 9: Commit**

```bash
git add ansible/roles/colorice/files/templates/i3-extended.conf ansible/roles/colorice/files/templates/polybar-extended.ini \
  ansible/roles/theme/files/catppuccin/.config/kitty/kitty.conf \
  ansible/roles/theme/files/catppuccin/.config/i3/config \
  ansible/roles/theme/files/catppuccin/.config/polybar/config.ini \
  ansible/roles/colorice/tasks/main.yml
git commit -m "Wire colorice into kitty, i3, picom, polybar"
```

---

### Task 6: Wire remaining native-template apps — neovim, dunst, rofi, cava, zellij

**Files:**
- Modify: `ansible/roles/theme/files/catppuccin/.config/nvim/lua/custom/plugins/init.lua`
- Modify: `ansible/roles/theme/files/catppuccin/.config/rofi/config.rasi`
- Modify: `ansible/roles/theme/files/catppuccin/.config/zellij/config.kdl` (from Task 2)
- No change needed: `dunst.conf`, `cava/config` (pure rewrite mechanism, same as picom in Task 5 Step 3)

**Interfaces:**
- Consumes: `config.toml` entries `neovim`/`dunst`/`rofi`/`cava`/`zellij` from Task 4.

- [ ] **Step 1: neovim — add a require for the generated module**

At the top of `ansible/roles/theme/files/catppuccin/.config/nvim/lua/custom/plugins/init.lua`, before the `return {` line, add:

```lua
-- colorice — once you run `colorice <wallpaper> --apply`, this module
-- exists and can be required by a colorscheme-setting plugin spec below
pcall(require, "colorice-colors")
```

- [ ] **Step 2: dunst, cava — no base-file edit needed**

Same as picom: `config.toml`'s `dunst`/`cava` entries point directly at the deployed catppuccin `dunstrc`/`cava/config` paths. Colorice fully rewrites them on apply (rewrite mechanism). No base-file change.

- [ ] **Step 3: rofi — add the import line**

At the very top of `ansible/roles/theme/files/catppuccin/.config/rofi/config.rasi` (rasi requires `@import` before any block), add:

```
@import "colorice-colors.rasi"
```

- [ ] **Step 4: zellij — point config.kdl at the colorice theme**

In `ansible/roles/theme/files/catppuccin/.config/zellij/config.kdl` (added in Task 2), change:

```
theme "catppuccin-mocha"
```

to:

```
theme "colorice"
```

This makes zellij load `~/.config/zellij/themes/colorice.kdl` (Task 4's `zellij` template output) once it exists; zellij falls back to its own built-in default if the file is absent, which is an acceptable pre-apply state (matches the "static fallback" bar set for other rewrite-mechanism apps, since the original `catppuccin-mocha` theme file is still on disk for reference but no longer loaded by name — note this trade-off explicitly, it's the one native app where the pre-apply fallback isn't the exact original catppuccin look).

- [ ] **Step 5: Syntax-check the touched files**

```bash
lua -e "loadfile('ansible/roles/theme/files/catppuccin/.config/nvim/lua/custom/plugins/init.lua')" 2>&1 | head -5
```
Expected: no syntax error reported (a `nil` return from a missing require target is fine — `pcall` swallows it).

- [ ] **Step 6: Commit**

```bash
git add ansible/roles/theme/files/catppuccin/.config/nvim/lua/custom/plugins/init.lua \
  ansible/roles/theme/files/catppuccin/.config/rofi/config.rasi \
  ansible/roles/theme/files/catppuccin/.config/zellij/config.kdl
git commit -m "Wire colorice into neovim, dunst, rofi, cava, zellij"
```

---

### Task 7: Custom rewrite templates — fastfetch, atuin, bat, btop

**Files:**
- Create: `ansible/roles/colorice/files/templates/fastfetch.jsonc`
- Create: `ansible/roles/colorice/files/templates/atuin.toml`
- Create: `ansible/roles/colorice/files/templates/bat.tmTheme`
- Create: `ansible/roles/colorice/files/templates/btop.theme`
- Modify: `ansible/roles/colorice/tasks/main.yml`

**Interfaces:**
- Consumes: `config.toml` entries `fastfetch`/`atuin`/`bat`/`btop` from Task 4.

- [ ] **Step 1: fastfetch template**

`ansible/roles/colorice/files/templates/fastfetch.jsonc` — same layout as the current catppuccin config, with the two hardcoded catppuccin hexes (`#f2cdcd` flamingo-ish divider, `#cba6f7` mauve title) and the `keyColor` RGB triplet swapped for placeholders:

```jsonc
// colorice — generated from {wallpaper}

{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "source": "debian",
    "color": { "1": "white" },
    "padding": { "top": 2, "left": 2, "right": 2 }
  },
  "display": {
    "separator": " [38;2;{color4.red};{color4.green};{color4.blue}m[0m ",
    "constants": [
      "[38;2;{color1.red};{color1.green};{color1.blue}m─────────────────[0m"
    ],
    "key": { "type": "icon", "paddingLeft": 2 }
  },
  "modules": [
    { "type": "custom", "format": "[38;2;{color1.red};{color1.green};{color1.blue}m┌[0m{$1} [38;2;{color4.red};{color4.green};{color4.blue}mHardware Information[0m {$1}[38;2;{color1.red};{color1.green};{color1.blue}m┐[0m" },
    { "type": "host", "keyColor": "{color5.red};{color5.green};{color5.blue}" },
    { "type": "cpu", "keyColor": "{color5.red};{color5.green};{color5.blue}" },
    { "type": "gpu", "keyColor": "{color5.red};{color5.green};{color5.blue}" },
    { "type": "disk", "keyColor": "{color5.red};{color5.green};{color5.blue}" },
    { "type": "memory", "keyColor": "{color5.red};{color5.green};{color5.blue}" },
    { "type": "display", "keyColor": "{color5.red};{color5.green};{color5.blue}" },
    { "type": "custom", "format": "[38;2;{color1.red};{color1.green};{color1.blue}m└[0m{$1}[38;2;{color1.red};{color1.green};{color1.blue}m──────────────────────[0m{$1}[38;2;{color1.red};{color1.green};{color1.blue}m┘[0m" },
    { "type": "custom", "format": "" },
    { "type": "custom", "format": "[38;2;{color1.red};{color1.green};{color1.blue}m┌[0m{$1} [38;2;{color4.red};{color4.green};{color4.blue}mSoftware Information[0m {$1}[38;2;{color1.red};{color1.green};{color1.blue}m┐[0m" },
    { "type": "os", "keyColor": "{color5.red};{color5.green};{color5.blue}" },
    { "type": "kernel", "keyColor": "{color5.red};{color5.green};{color5.blue}" },
    { "type": "lm", "keyColor": "{color5.red};{color5.green};{color5.blue}" },
    { "type": "wm", "keyColor": "{color5.red};{color5.green};{color5.blue}" },
    { "type": "shell", "keyColor": "{color5.red};{color5.green};{color5.blue}" },
    { "type": "terminal", "keyColor": "{color5.red};{color5.green};{color5.blue}" },
    { "type": "font", "keyColor": "{color5.red};{color5.green};{color5.blue}" },
    { "type": "icons", "keyColor": "{color5.red};{color5.green};{color5.blue}" },
    { "type": "packages", "keyColor": "{color5.red};{color5.green};{color5.blue}" },
    { "type": "uptime", "keyColor": "{color5.red};{color5.green};{color5.blue}" },
    { "type": "locale", "keyColor": "{color5.red};{color5.green};{color5.blue}" },
    { "type": "custom", "format": "[38;2;{color1.red};{color1.green};{color1.blue}m└[0m{$1}[38;2;{color1.red};{color1.green};{color1.blue}m──────────────────────[0m{$1}[38;2;{color1.red};{color1.green};{color1.blue}m┘[0m" },
    { "type": "colors", "symbol": "circle", "paddingLeft": 21 }
  ]
}
```

- [ ] **Step 2: atuin template**

`ansible/roles/colorice/files/templates/atuin.toml`:

```toml
# colorice — generated from {wallpaper}
[theme]
name = "colorice"
```

Note: atuin also ships a themes directory (`~/.config/atuin/themes/*.toml`) referenced by `name` above — that file isn't wallpaper-reactive in this plan (ponytail: atuin's history-search TUI colors are low-value to chase; `[theme] name` alone still picks up atuin's own bundled fallback correctly).

- [ ] **Step 3: bat template**

`ansible/roles/colorice/files/templates/bat.tmTheme` — a minimal valid tmTheme with just background/foreground/selection/caret (ponytail ceiling: no per-token syntax-highlight coloring, only chrome; add per-scope rules later if wanted):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- colorice — generated from {wallpaper} -->
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>name</key>
	<string>Colorice</string>
	<key>settings</key>
	<array>
		<dict>
			<key>settings</key>
			<dict>
				<key>background</key>
				<string>{background}</string>
				<key>foreground</key>
				<string>{foreground}</string>
				<key>caret</key>
				<string>{cursor}</string>
				<key>selection</key>
				<string>{color0}</string>
			</dict>
		</dict>
	</array>
	<key>uuid</key>
	<string>c010ec1c-1111-4c1c-9c1c-c0101ce00000</string>
</dict>
</plist>
```

- [ ] **Step 4: btop template**

`ansible/roles/colorice/files/templates/btop.theme` — using the extended-palette table for the roles the original file names in comments (Mauve, Green, Maroon, Blue, Sapphire, Lavender, Peach, Sky, Teal):

```
# colorice — generated from {wallpaper}
theme[main_bg]="{background}"
theme[main_fg]="{foreground}"
theme[title]="{foreground}"
theme[hi_fg]="{color4}"
theme[selected_bg]="{color0}"
theme[selected_fg]="{color4}"
theme[inactive_fg]="{color8.lighten_10}"
theme[graph_text]="{color1.lighten_30.desaturate_20}"
theme[meter_bg]="{color0}"
theme[proc_misc]="{color1.lighten_30.desaturate_20}"
theme[cpu_box]="{color5.saturate_15}"
theme[mem_box]="{color2}"
theme[net_box]="{color1.darken_10}"
theme[proc_box]="{color4}"
theme[div_line]="{color8}"
theme[temp_start]="{color2}"
theme[temp_mid]="{color3}"
theme[temp_end]="{color1}"
theme[cpu_start]="{color6}"
theme[cpu_mid]="{color6.darken_5.saturate_10}"
theme[cpu_end]="{color4.lighten_15.desaturate_10}"
theme[free_start]="{color5.saturate_15}"
theme[free_mid]="{color4.lighten_15.desaturate_10}"
theme[free_end]="{color4}"
theme[cached_start]="{color6.darken_5.saturate_10}"
theme[cached_mid]="{color4}"
theme[cached_end]="{color4.lighten_15.desaturate_10}"
theme[available_start]="{color3.darken_5.saturate_15}"
theme[available_mid]="{color1.darken_10}"
theme[available_end]="{color1}"
theme[used_start]="{color2}"
theme[used_mid]="{color6}"
theme[used_end]="{color6.lighten_10}"
theme[download_start]="{color3.darken_5.saturate_15}"
theme[download_mid]="{color1.darken_10}"
theme[download_end]="{color1}"
theme[upload_start]="{color2}"
theme[upload_mid]="{color6}"
theme[upload_end]="{color6.lighten_10}"
theme[process_start]="{color6.darken_5.saturate_10}"
theme[process_mid]="{color4.lighten_15.desaturate_10}"
theme[process_end]="{color5.saturate_15}"
```

- [ ] **Step 5: Deploy the four new templates**

In `ansible/roles/colorice/tasks/main.yml`, extend the `loop:` list from Task 5 Step 7 with:

```yaml
    - fastfetch.jsonc
    - atuin.toml
    - bat.tmTheme
    - btop.theme
```

- [ ] **Step 6: Verify JSON/TOML/XML are well-formed after stripping placeholders**

Placeholders make these files invalid JSON/XML as-is, so verify structurally instead:

```bash
python3 -c "import re; s=open('ansible/roles/colorice/files/templates/fastfetch.jsonc').read(); assert s.count('{')==s.count('}')"
python3 -c "import tomllib,re; s=open('ansible/roles/colorice/files/templates/atuin.toml').read(); tomllib.loads(re.sub(r'\{[^}]*\}','x',s))"
python3 -c "import xml.dom.minidom as m,re; s=open('ansible/roles/colorice/files/templates/bat.tmTheme').read(); m.parseString(re.sub(r'\{[^}]*\}','X',s))"
```
Expected: no exceptions.

- [ ] **Step 7: Commit**

```bash
git add ansible/roles/colorice/files/templates/fastfetch.jsonc ansible/roles/colorice/files/templates/atuin.toml \
  ansible/roles/colorice/files/templates/bat.tmTheme ansible/roles/colorice/files/templates/btop.theme \
  ansible/roles/colorice/tasks/main.yml
git commit -m "Add colorice custom templates: fastfetch, atuin, bat, btop"
```

---

### Task 8: Custom rewrite templates — eza, lazygit, mpv, ncspot, starship

**Files:**
- Create: `ansible/roles/colorice/files/templates/eza.yml`
- Create: `ansible/roles/colorice/files/templates/lazygit.yml`
- Create: `ansible/roles/colorice/files/templates/mpv.conf`
- Create: `ansible/roles/colorice/files/templates/ncspot.toml`
- Create: `ansible/roles/colorice/files/templates/starship.toml`
- Modify: `ansible/roles/colorice/tasks/main.yml`

**Interfaces:**
- Consumes: `config.toml` entries `eza`/`lazygit`/`mpv`/`ncspot`/`starship` from Task 4.

- [ ] **Step 1: eza template** (role-to-expression mapping from the current `theme.yml`, using the extended-palette table)

`ansible/roles/colorice/files/templates/eza.yml`:

```yaml
# colorice — generated from {wallpaper}
colourful: true

filekinds:
  normal: {foreground: "{foreground}"}
  directory: {foreground: "{color5.saturate_15}"}
  symlink: {foreground: "{color4}"}
  pipe: {foreground: "{color7}"}
  block_device: {foreground: "{color1.darken_10}"}
  char_device: {foreground: "{color1.darken_10}"}
  socket: {foreground: "{color7}"}
  special: {foreground: "{color5.saturate_15}"}
  executable: {foreground: "{color2}"}
  mount_point: {foreground: "{color6}"}

perms:
  user_read: {foreground: "{color1}", is_bold: true}
  user_write: {foreground: "{color3}", is_bold: true}
  user_execute_file: {foreground: "{color2}", is_bold: true}
  user_execute_other: {foreground: "{color2}", is_bold: true}
  group_read: {foreground: "{color1}"}
  group_write: {foreground: "{color3}"}
  group_execute: {foreground: "{color2}"}
  other_read: {foreground: "{color1}"}
  other_write: {foreground: "{color3}"}
  other_execute: {foreground: "{color2}"}
  special_user_file: {foreground: "{color5.saturate_15}"}
  special_other: {foreground: "{color8.lighten_20}"}
  attribute: {foreground: "{color7.darken_10}"}

size:
  major: {foreground: "{color15}"}
  minor: {foreground: "{color6.lighten_10}"}
  number_byte: {foreground: "{color7}"}
  number_kilo: {foreground: "{color15}"}
  number_mega: {foreground: "{color4}"}
  number_giga: {foreground: "{color5.saturate_15}"}
  number_huge: {foreground: "{color5.saturate_15}"}
  unit_byte: {foreground: "{color15}"}
  unit_kilo: {foreground: "{color6.lighten_10}"}
  unit_mega: {foreground: "{color5.saturate_15}"}
  unit_giga: {foreground: "{color5.saturate_15}"}
  unit_huge: {foreground: "{color6}"}

users:
  user_you: {foreground: "{foreground}"}
  user_root: {foreground: "{color1}"}
  user_other: {foreground: "{color1.darken_10}"}
  group_yours: {foreground: "{color15}"}
  group_other: {foreground: "{color7.darken_10}"}
  group_root: {foreground: "{color1}"}

links:
  normal: {foreground: "{color4}"}
  multi_link_file: {foreground: "{color4}"}

git:
  new: {foreground: "{color2}"}
  modified: {foreground: "{color3}"}
  deleted: {foreground: "{color1.darken_10}"}
  renamed: {foreground: "{color6}"}
  typechange: {foreground: "{color5}"}
  ignored: {foreground: "{color8.lighten_20}"}
  conflicted: {foreground: "{color3.darken_5.saturate_15}"}

git_repo:
  branch_main: {foreground: "{color15}"}
  branch_other: {foreground: "{color5.saturate_15}"}
  git_clean: {foreground: "{color2}"}
  git_dirty: {foreground: "{color1.darken_10}"}

security_context:
  colon: {foreground: "{color8}"}
  user: {foreground: "{color8.lighten_20}"}
  role: {foreground: "{color5.saturate_15}"}
  typ: {foreground: "{color8}"}
  range: {foreground: "{color5.saturate_15}"}

file_type:
  image: {foreground: "{color3}"}
  video: {foreground: "{color1}"}
  music: {foreground: "{color2}"}
  lossless: {foreground: "{color6}"}
  crypto: {foreground: "{color8.lighten_20}"}
  document: {foreground: "{foreground}"}
  compressed: {foreground: "{color5}"}
  temp: {foreground: "{color1.darken_10}"}
  compiled: {foreground: "{color6.darken_5.saturate_10}"}
  source: {foreground: "{color4}"}

punctuation: {foreground: "{color8}"}
date: {foreground: "{color3}"}
inode: {foreground: "{color15}"}
blocks: {foreground: "{color8}"}
header: {foreground: "{foreground}"}
octal: {foreground: "{color6}"}
flags: {foreground: "{color5.saturate_15}"}

symlink_path: {foreground: "{color6.lighten_10}"}
control_char: {foreground: "{color6.darken_5.saturate_10}"}
broken_symlink: {foreground: "{color1}"}
broken_path_overlay: {foreground: "{color8}"}
```

- [ ] **Step 2: lazygit template**

`ansible/roles/colorice/files/templates/lazygit.yml`:

```yaml
# colorice — generated from {wallpaper}
gui:
  theme:
    activeBorderColor:
      - "{color5.saturate_15}"
      - bold
    inactiveBorderColor:
      - "{color15}"
    searchingActiveBorderColor:
      - "{color3}"
    optionsTextColor:
      - "{color4}"
    selectedLineBgColor:
      - "{color0}"
    inactiveViewSelectedLineBgColor:
      - "{color8}"
    cherryPickedCommitFgColor:
      - "{color5.saturate_15}"
    cherryPickedCommitBgColor:
      - "{color0}"
    markedBaseCommitFgColor:
      - "{color4}"
    markedBaseCommitBgColor:
      - "{color3}"
    unstagedChangesColor:
      - "{color1}"
    defaultFgColor:
      - "{foreground}"

  authorColors:
    "*": "{color4.lighten_15.desaturate_10}"
```

- [ ] **Step 3: mpv template**

`ansible/roles/colorice/files/templates/mpv.conf` (only the color-bearing subset of the current file — the surrounding script-opts comments/plumbing stay static since they're not colors; note this template is a full-file rewrite, so anything not listed here won't survive `--apply`. If mpv.conf grows non-color options later, move those into a separate static file mpv `include`s):

```
# colorice — generated from {wallpaper}
background-color='{background}'
osd-back-color='{background.darken_10}'
osd-border-color='{background.darken_10}'
osd-color='{foreground}'
osd-shadow-color='{background}'

script-opts-append=stats-border_color={color1.strip}
script-opts-append=stats-font_color={color1.lighten_20.desaturate_10.strip}
script-opts-append=stats-plot_bg_border_color={color5.strip}
script-opts-append=stats-plot_bg_color={color1.strip}
script-opts-append=stats-plot_color={color5.strip}

script-opts-append=uosc-color=foreground={color5.saturate_15.strip},foreground_text={color0.strip},background={background.strip},background_text={foreground.strip},curtain={background.darken_10.strip},success={color2.strip},error={color1.strip}
```

- [ ] **Step 4: ncspot template**

`ansible/roles/colorice/files/templates/ncspot.toml`:

```toml
# colorice — generated from {wallpaper}
[theme]
background = "{background}"
primary = "{foreground}"
secondary = "{color6}"
title = "{color5.saturate_15}"
playing = "{color2}"
playing_bg = "{background}"
highlight = "{foreground}"
highlight_bg = "{color5.saturate_15.darken_10}"
playing_selected = "{color2}"
error = "{background}"
error_bg = "{color1}"
statusbar = "{color5.saturate_15}"
statusbar_bg = "{color0}"
statusbar_progress = "{color5.saturate_15}"
cmdline = "{color5.saturate_15}"
cmdline_bg = "{background.darken_5}"
```

- [ ] **Step 5: starship template**

`ansible/roles/colorice/files/templates/starship.toml` — full-file rewrite using starship's native `[palettes.<name>]` mechanism, only defining what the current config needs:

```toml
# colorice — generated from {wallpaper}
palette = "colorice"

[palettes.colorice]
rosewater = "{color1.lighten_30.desaturate_20}"
flamingo = "{color1.lighten_20.desaturate_15}"
pink = "{color5}"
mauve = "{color5.saturate_15}"
red = "{color1}"
maroon = "{color1.darken_10}"
peach = "{color3.darken_5.saturate_15}"
yellow = "{color3}"
green = "{color2}"
teal = "{color6}"
sky = "{color6.lighten_10}"
sapphire = "{color6.darken_5.saturate_10}"
blue = "{color4}"
lavender = "{color4.lighten_15.desaturate_10}"
text = "{foreground}"
base = "{background}"
```

Note: this only sets up the palette table. The rest of `starship.toml`'s module formatting (not present in the `ansible` tree today — see Task constraints, out of scope) is a separate, pre-existing gap; this task only ensures whichever starship config exists picks up `palette = "colorice"` and its color roles.

- [ ] **Step 6: Deploy the five new templates**

In `ansible/roles/colorice/tasks/main.yml`, extend the `loop:` list with:

```yaml
    - eza.yml
    - lazygit.yml
    - mpv.conf
    - ncspot.toml
    - starship.toml
```

- [ ] **Step 7: Verify YAML/TOML are well-formed after stripping placeholders**

```bash
python3 -c "import yaml,re; s=open('ansible/roles/colorice/files/templates/eza.yml').read(); yaml.safe_load(re.sub(r'\{[^}]*\}','x',s))"
python3 -c "import yaml,re; s=open('ansible/roles/colorice/files/templates/lazygit.yml').read(); yaml.safe_load(re.sub(r'\{[^}]*\}','x',s))"
python3 -c "import tomllib,re; s=open('ansible/roles/colorice/files/templates/ncspot.toml').read(); tomllib.loads(re.sub(r'\{[^}]*\}','x',s))"
python3 -c "import tomllib,re; s=open('ansible/roles/colorice/files/templates/starship.toml').read(); tomllib.loads(re.sub(r'\{[^}]*\}','x',s))"
```
Expected: no exceptions.

- [ ] **Step 8: Commit**

```bash
git add ansible/roles/colorice/files/templates/eza.yml ansible/roles/colorice/files/templates/lazygit.yml \
  ansible/roles/colorice/files/templates/mpv.conf ansible/roles/colorice/files/templates/ncspot.toml \
  ansible/roles/colorice/files/templates/starship.toml ansible/roles/colorice/tasks/main.yml
git commit -m "Add colorice custom templates: eza, lazygit, mpv, ncspot, starship"
```

---

### Task 9: Custom include templates — aerc, betterlockscreen, delta

**Files:**
- Create: `ansible/roles/colorice/files/templates/aerc-styleset`
- Create: `ansible/roles/colorice/files/templates/betterlockscreen-colors`
- Create: `ansible/roles/colorice/files/templates/delta.gitconfig`
- Modify: `ansible/roles/theme/files/catppuccin/.config/aerc/aerc.conf` (from Task 2)
- Modify: `ansible/roles/theme/files/catppuccin/.config/betterlockscreen/betterlockscreenrc`
- Modify: `ansible/roles/colorice/tasks/main.yml`

**Interfaces:**
- Consumes: `config.toml` entries `aerc`/`betterlockscreen`/`delta` from Task 4.

- [ ] **Step 1: aerc styleset template**

`ansible/roles/colorice/files/templates/aerc-styleset`:

```
*.default=true
*.normal=true

default.fg={foreground}

error.fg={color1}
warning.fg={color3.darken_5.saturate_15}
success.fg={color2}

tab.fg={color8}
tab.bg={background.darken_5}
tab.selected.fg={foreground}
tab.selected.bg={background}
tab.selected.bold=true

border.fg={background.darken_10}
border.bold=true

msglist_unread.bold=true
msglist_flagged.fg={color3}
```

- [ ] **Step 2: point aerc.conf at it**

In `ansible/roles/theme/files/catppuccin/.config/aerc/aerc.conf`, change:

```
styleset-name=catppuccin-mocha
```

to:

```
styleset-name=colorice
```

Same pre-apply trade-off as zellij (Task 6 Step 4): the file exists once colorice runs `--apply`; before that, aerc falls back to its own built-in default rather than the old catppuccin styleset, since the styleset name no longer matches. Acceptable — matches the zellij precedent already accepted for this plan.

- [ ] **Step 3: betterlockscreen — split colors into a sourced file**

`ansible/roles/colorice/files/templates/betterlockscreen-colors` (betterlockscreenrc is bash-sourced, so this is a plain shell key=value fragment — colorice's `.strip` filter gives the bare hex without `#`, matching betterlockscreenrc's `RRGGBBAA` no-hash convention):

```bash
# colorice — generated from {wallpaper}
loginbox={background.strip}66
loginshadow=00000000
bgcolor={background.strip}ff
timecolor={foreground.strip}ff
greetercolor={foreground.strip}ff
layoutcolor={foreground.strip}ff
insidewrongcolor={color1.strip}ff
ringwrongcolor={color1.strip}ff
insidevercolor={color5.saturate_15.strip}ff
ringvercolor={color5.saturate_15.strip}ff
insidecolor={background.strip}00
ringcolor={color8.strip}ff
```

- [ ] **Step 4: source it from the base betterlockscreenrc**

Remove the now-duplicated color lines from `ansible/roles/theme/files/catppuccin/.config/betterlockscreen/betterlockscreenrc` (everything from `loginbox=` through `ringcolor=`) and replace with:

```bash
# colorice — once you run `colorice <wallpaper> --apply`, this file exists
[ -f ~/.config/betterlockscreen/colorice-colors.sh ] && source ~/.config/betterlockscreen/colorice-colors.sh
```

Keep the non-color lines (`display_on`, `span_image`, `lock_timeout`, `fx_list`, `dim_level`, `wallpaper_cmd`, `quiet`, `locktext`, `font`, `time_format`) as-is — they're not colors and betterlockscreenrc has no per-key override precedence issue since `source` just runs the sourced lines in place.

- [ ] **Step 5: delta template**

`ansible/roles/colorice/files/templates/delta.gitconfig` — a single unnamed `[delta]` section (delta's default, used when `delta.features` doesn't select a named variant):

```gitconfig
# colorice — generated from {wallpaper}
[delta]
	syntax-theme = Colorice
	minus-style = syntax "{color1}"
	plus-style = syntax "{color2}"
	line-numbers-minus-style = bold "{color1}"
	line-numbers-plus-style = bold "{color2}"
	file-style = "{foreground}"
	hunk-header-decoration-style = "{color8}" box ul
	commit-decoration-style = "{color8}" bold box ul
```

Note: this repo has no tracked `.gitconfig` (git identity/config isn't ansible-managed here — verified, no `.gitconfig`/`gitconfig` file exists anywhere in the repo). This task only produces the renderable file; wiring it in is a one-time **manual** step, not an ansible task: add `[include]\n\tpath = ~/.config/delta/colorice-colors.gitconfig` to your real `~/.gitconfig` once, and reference `delta` (unnamed) rather than a named `catppuccin-*` variant in `delta.features`/`core.pager`.

- [ ] **Step 6: Deploy the three new templates**

In `ansible/roles/colorice/tasks/main.yml`, extend the `loop:` list with:

```yaml
    - aerc-styleset
    - betterlockscreen-colors
    - delta.gitconfig
```

- [ ] **Step 7: Verify the shell fragment parses**

```bash
bash -n <(sed 's/{[^}]*}/x/g' ansible/roles/colorice/files/templates/betterlockscreen-colors)
```
Expected: no syntax error (exit 0).

- [ ] **Step 8: Commit**

```bash
git add ansible/roles/colorice/files/templates/aerc-styleset ansible/roles/colorice/files/templates/betterlockscreen-colors \
  ansible/roles/colorice/files/templates/delta.gitconfig \
  ansible/roles/theme/files/catppuccin/.config/aerc/aerc.conf \
  ansible/roles/theme/files/catppuccin/.config/betterlockscreen/betterlockscreenrc \
  ansible/roles/colorice/tasks/main.yml
git commit -m "Add colorice custom templates: aerc, betterlockscreen, delta"
```

---

### Task 10: Rice-refresh keybind and end-to-end verification

**Files:**
- Create: `ansible/roles/colorice/files/rice-refresh`
- Modify: `ansible/roles/colorice/tasks/main.yml`
- Modify: `ansible/roles/theme/files/catppuccin/.config/i3/config`

**Interfaces:**
- Consumes: everything from Tasks 1-9.
- Produces: `~/.local/bin/rice-refresh`, executable, bound to `$mod+shift+w`.

- [ ] **Step 1: Write the refresh script**

`ansible/roles/colorice/files/rice-refresh`:

```bash
#!/usr/bin/env bash
WALLPAPER=$(find ~/Pictures/Wallpapers -type f | shuf -n 1)
nitrogen --set-zoom-fill "$WALLPAPER"
colorice "$WALLPAPER" --apply --no-preview -q
notify-send "Theme refreshed" "$(basename "$WALLPAPER")"
```

- [ ] **Step 2: Deploy it, executable**

Add to `ansible/roles/colorice/tasks/main.yml`:

```yaml
- name: Deploy rice-refresh script
  ansible.builtin.copy:
    src: rice-refresh
    dest: "{{ invoking_home }}/.local/bin/rice-refresh"
    mode: "0755"
  become: false
```

- [ ] **Step 3: Bind it in i3**

In `ansible/roles/theme/files/catppuccin/.config/i3/config`, near the existing `bindsym $mod+w layout tabbed` line (found in Task-independent grep at line 156), add:

```
bindsym $mod+shift+w exec --no-startup-id ~/.local/bin/rice-refresh
```

- [ ] **Step 4: Full syntax-check**

```bash
ansible-playbook ansible/site.yml --syntax-check
grep -rn "dotfiles_theme" ansible/ || echo "clean: no dotfiles_theme references remain"
grep -c '\[\[templates\]\]' ansible/roles/colorice/files/config.toml
```
Expected: syntax-check passes; "clean" message prints; template count is 23 (21 apps + the `i3-extended`/`polybar-extended` helper entries).

- [ ] **Step 5: Dry-run against a disposable target**

Run (adjust inventory target to whatever disposable VM/container this repo's CI/dev flow uses — check `ansible/site.yml` and any `ansible/inventory*` file for the pattern first):

```bash
ansible-playbook ansible/site.yml --check --diff -l <disposable-target>
```
Expected: no fatal errors; diff shows the new colorice role tasks and the trimmed theme role tasks as pending changes.

- [ ] **Step 6: Provision for real, verify colorice installed and initialized**

On the disposable target:

```bash
colorice --version
ls ~/.config/colorice/templates/ | wc -l
```
Expected: colorice reports a version; template count is 22 (bundled by `--init`) + 14 (our custom files: 12 app templates + `i3-extended.conf` + `polybar-extended.ini`) = 36 files (some bundled templates we don't use, like `mako.conf`/`sway-colors.conf`, are present but simply not referenced by `config.toml` — harmless).

- [ ] **Step 7: Apply and spot-check**

```bash
colorice ~/Pictures/Wallpapers/<any-image> --apply --no-preview -q
kitty +kitten themes # or just relaunch kitty, confirm background changed
i3-msg reload
polybar-msg cmd restart
cat ~/.config/starship.toml | head -3   # confirm palette = "colorice"
```
Expected: kitty/i3/polybar visibly re-color; starship.toml shows the new palette line.

- [ ] **Step 8: Confirm the fallback path**

On a second fresh provision where `colorice --apply` is never run manually, confirm the desktop still looks like intact static Catppuccin Mocha (kitty colors, i3 borders, polybar all show the original hardcoded hex values, since colorice's `include`/rewrite outputs don't exist yet).

- [ ] **Step 9: Commit**

```bash
git add ansible/roles/colorice/files/rice-refresh ansible/roles/colorice/tasks/main.yml \
  ansible/roles/theme/files/catppuccin/.config/i3/config
git commit -m "Add rice-refresh keybind, complete colorice theming rollout"
```
