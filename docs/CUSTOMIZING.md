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
restart needed) and add the row to KEYBINDINGS.md by hand — there's no
in-rofi cheat-sheet or generator, KEYBINDINGS.md is the only place this
lives now.

## Add a description on the launcher (rofi drun)

An app already has a `.desktop` file but no description shows — rofi
pulls the second line from that file's `Comment=` field. Find it with:

```sh
find /usr/share/applications ~/.local/share/applications -iname '*appname*'
```

Edit the `Comment=` line in that `.desktop` file directly (or, if it's
a system file you don't own, copy it to
`~/.local/share/applications/` first — that copy takes priority and
survives package updates). No repo change needed unless you want the
override vendored — if so, add the copy under
`chezmoi/dot_local/share/applications/`.

A tool with **no** `.desktop` file at all (most TUI tools) will never
show in `mod+d` (drun), full stop — there's no curated TUI menu
fallback in this repo anymore (dropped in the i3/polybar/rofi
re-vendor, see [KEYBINDINGS.md](KEYBINDINGS.md#not-bound-deliberately)).
Launch those from a terminal, or write a `.desktop` file for it under
`chezmoi/dot_local/share/applications/` if you want it in the launcher.

## Add a polybar module

Edit `chezmoi/dot_config/polybar/config.ini`:

1. Add a `[module/yourmodule]` block (copy an existing `custom/script`
   or `internal/*` module as a template — see polybar's own docs for
   module types)
2. Add `yourmodule` to `modules-left` / `modules-center` /
   `modules-right` at the top of the `[bar/main]` section
3. Restart polybar to test: `pkill polybar && ~/.config/polybar/launch.sh &`
   (or just `mod+shift+r` to restart i3, which respawns everything)

`launch.sh` runs `polybar main &` — the bar name (`main`) must match
the `[bar/main]` section name if you ever rename it, or polybar fails
to find the bar (this bit a real bug earlier in this repo's history —
see git history "Re-vendor i3/polybar/rofi").

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

## Change workspace names

Edit the `set $ws1`.."$ws10"` lines near the top of
`chezmoi/dot_config/i3/config` (currently plain `"1"`.."10"`). To add
icons, use `"<number>:<icon>"` — the number before the colon is what i3
uses for `workspace number` matching, the rest is just a label. Find
Nerd Font glyphs at
[nerdfonts.com/cheat-sheet](https://www.nerdfonts.com/cheat-sheet) (the
installed font is CaskaydiaCove Nerd Font, covers the full set). Update
the same strings anywhere they're referenced (`workspace number $ws1`
lines further down) — i3 matches on the number prefix so this is safe.

## Remap focus/move keys

`i3/config`'s focus/move binds use `j`/`k`/`l`/`semicolon` directly
(Colemak-ish left/down/up/right) instead of vim's hjkl or i3's default
arrow-only binds — arrow keys work too as a fallback. To change,
find-and-replace `bindsym $mod+j` / `k` / `l` / `semicolon` (and the
matching `$mod+Shift+...` move binds, and the `resize` mode block's
`j`/`k`/`l`/`semicolon` lines) with your preferred keys — there's no
indirection variable for this anymore (the earlier `$left`/`$down`/
`$up`/`$right` `set` layer was dropped in the i3/polybar/rofi
re-vendor), so it's a direct edit in a few places.

## Add Catppuccin theming to a newly installed tool

This repo tries to theme every installed tool that has an official
[catppuccin org repo](https://github.com/orgs/catppuccin/repositories)
(Mocha flavor, matching everything else). When adding a new tool:

1. Check if `https://github.com/catppuccin/<toolname>` exists.
2. `gh api repos/catppuccin/<toolname>/git/trees/HEAD?recursive=true`
   to find the actual theme/config file path — names and formats vary
   a lot per tool (a full config file, a color-only snippet to
   `include`, a plugin script, inline TOML/YAML keys...).
3. Vendor it under `chezmoi/dot_config/<toolname>/...` (or
   `chezmoi/dot_gitconfig`-style dotfile if the tool has no XDG config
   dir) — check whether the tool auto-discovers a theme file by name,
   or needs an explicit "enable this theme" key added to its main
   config (most do).
4. Never add account/credential/server config while doing this — theme
   only. (`aerc`, `atuin`, `ncspot` all needed this discipline.)
5. Verify against the real binary, not just `chezmoi apply --dry-run`
   — most tools have a `--version`/`--help` that at least proves the
   binary starts, and several (bat, tmux, git+delta) have a real way to
   confirm the theme actually loaded (`bat --list-themes`, a real tmux
   session, `git diff | delta`).

See git history "Catppuccin Mocha for bat, delta, eza, fzf, tmux,
btop, cava, zathura, mpv, newsboat, aerc, atuin, ncspot, lazygit,
zellij, qt5ct" for 15 worked examples, including the two non-obvious
mechanisms: `qt5ct` is ansible-managed (`ansible/roles/theme/tasks/main.yml`),
not chezmoi, and `tmux` themes go in `chezmoi/dot_tmux.conf.local`
(never edit `dot_tmux.conf` itself — it's vendored oh-my-tmux, see its
own "DO NOT MODIFY" header).

## Add a Claude Code plugin, hook, or command

See [CLAUDE_CODE_SETUP.md](CLAUDE_CODE_SETUP.md#adding-a-plugin-hook-or-command).

## Add a new installed program

See [SOFTWARE_LIST.md](SOFTWARE_LIST.md) — pick the right section
(apt/pip/npm/github-release/flatpak/cargo/manual-script) and add to
the matching list in `ansible/group_vars/all/packages.yml`, then
update SOFTWARE_LIST.md's table by hand (it's not generated). If it has
an official Catppuccin theme, see "Add Catppuccin theming to a newly
installed tool" above.

## After any change

Run these before committing (same checks CI/the plans in this repo
already use):

```sh
python3 -c "import yaml; yaml.safe_load(open('ansible/group_vars/all/packages.yml'))"
ansible-playbook ansible/site.yml --syntax-check -i ansible/inventory/hosts.ini
chezmoi --source chezmoi apply --dry-run --verbose
```
