# Customizing

Task-oriented how-tos for the most common changes. Every change here
follows the same loop: edit the file under `chezmoi/`, run `chezmoi
--source chezmoi apply --dry-run --verbose` to check it, then `chezmoi
apply` for real (or re-run `ansible-playbook site.yml` which calls
chezmoi apply as its last step). Commit once it looks right.

## Add a hotkey

Edit `chezmoi/dot_config/i3/config`. Pattern:

```
bindsym $mod+<key> exec --no-startup-id <command>
```

Check [KEYBINDINGS.md](KEYBINDINGS.md) for which keys are already
taken before picking one. After adding, reload with `mod+shift+c` (no
restart needed) and add the line to
`chezmoi/dot_local/share/rofi/scripts/executable_keybind-help` (it's a
static list, not auto-generated — see below) plus KEYBINDINGS.md.

## Add a description on the launcher (rofi drun)

Two different "launcher description" cases:

**An app already has a `.desktop` file but no description shows** —
rofi pulls the second line from that file's `Comment=` field. Find it
with:

```sh
find /usr/share/applications ~/.local/share/applications -iname '*appname*'
```

Edit the `Comment=` line in that `.desktop` file directly (or, if it's
a system file you don't own, copy it to
`~/.local/share/applications/` first — that copy takes priority and
survives package updates). No repo change needed unless you want the
override vendored — if so, add the copy under
`chezmoi/dot_local/share/applications/`.

**A tool has no `.desktop` file at all** (most TUI tools: rtorrent,
taskwarrior-tui, cmus, etc.) — it will never show in `mod+a` (drun) no
matter what. These belong in the curated TUI menu instead:

Edit `chezmoi/dot_local/share/rofi/scripts/executable_tui-menu`, add a
line to the `tools` associative array:

```bash
["label — one-line description"]="shell command to run"
```

The command runs inside a kitty window
(`kitty -e bash -c "$cmd; read -n1 ..."`), so anything that works in a
terminal works here. `mod+shift+a` opens this menu.

## Add an entry to the audio switcher

`chezmoi/dot_local/share/rofi/scripts/executable_audio-switch` lists
whatever `pactl list short sinks` returns — nothing to hand-maintain,
new audio devices show up automatically once PulseAudio sees them.

## Add a polybar module

Edit `chezmoi/dot_config/polybar/config.ini`:

1. Add a `[module/yourmodule]` block (copy an existing `custom/script`
   or `internal/*` module as a template — see polybar's own docs for
   module types)
2. Add `yourmodule` to `modules-left` / `modules-center` /
   `modules-right` at the top of the `[bar/top]` section
3. Restart polybar to test: `pkill polybar && ~/.config/polybar/launch.sh &`
   (or just `mod+shift+r` to restart i3, which respawns everything)

## Change picom opacity/blur

Edit `chezmoi/dot_config/picom/i3.conf`:

- Per-app opacity: add a line to the `opacity-rule` array —
  `"NN:class_g = 'WindowClass'"` (find the class with `xprop | grep
  WM_CLASS`, click the window)
- Global active/inactive opacity: `active-opacity` / `inactive-opacity`
- Blur strength: `blur-strength` (higher = more blur, more GPU cost)
- Animations: `animation-for-open-window` /
  `animation-for-transient-window` / `animation-for-workspace-switch-in/out`
  — valid values are documented in picom's own `picom.sample.conf` on
  the `implement-window-animations` branch (`squeeze`, `slide-down`,
  `zoom`, `auto`, `none`, etc.)

Toggle with `mod+p` to A/B test changes without restarting i3.

## Change workspace icons

Edit the `set $ws1`.."$ws10"` lines near the top of
`chezmoi/dot_config/i3/config`. Format is `"<number>:<icon>"` — the
number before the colon is what i3 uses for `workspace number`
matching, the rest is just a label. Find Nerd Font glyphs at
[nerdfonts.com/cheat-sheet](https://www.nerdfonts.com/cheat-sheet) (the
installed font is CaskaydiaCove Nerd Font, covers the full set).

## Remap focus/move keys

`i3/config` uses `$left`/`$down`/`$up`/`$right` (currently
`j`/`k`/`l`/`semicolon`) instead of vim's hjkl, because the arrow keys
already work as a fallback and this frees up a row. To change:

```
set $up <key>
set $down <key>
set $left <key>
set $right <key>
```

These variables are reused inside the resize `mode` block too — no
other edits needed.

## Add a Claude Code plugin, hook, or command

See [CLAUDE_CODE_SETUP.md](CLAUDE_CODE_SETUP.md#adding-a-plugin-hook-or-command).

## Add a new installed program

See [SOFTWARE_LIST.md](SOFTWARE_LIST.md) — pick the right section
(apt/pip/npm/github-release/flatpak/cargo/manual-script) and add to
the matching list in `ansible/group_vars/all/packages.yml`, then
update SOFTWARE_LIST.md's table by hand (it's not generated).

## After any change

Run these before committing (same checks CI/the plans in this repo
already use):

```sh
python3 -c "import yaml; yaml.safe_load(open('ansible/group_vars/all/packages.yml'))"
ansible-playbook ansible/site.yml --syntax-check -i ansible/inventory/hosts.ini
chezmoi --source chezmoi apply --dry-run --verbose
```
