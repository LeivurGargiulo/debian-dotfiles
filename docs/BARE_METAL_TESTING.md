# Bare-metal testing

Runs after `ansible-playbook site.yml --syntax-check` and
`chezmoi apply --dry-run` both pass clean — see
`docs/superpowers/plans/2026-08-15-i3-ricing-rebuild.md` Task 8 for the
checkpoint this doc turns into a repeatable procedure. This is an i3 +
LightDM stack (previously KDE Plasma + SDDM — see
`docs/superpowers/plans/2026-08-15-i3-ricing-rebuild.md` for that
rebuild). WSL/VM testing structurally can't verify compositor effects,
tray icons, or a real display-manager login, so this stays a required
step even after those pass.

## Prereqs

- Spare machine, or spare disk/partition on a shared machine, dedicated to
  this test. Do not run against a machine you can't afford to wipe.
- Debian netinst USB, freshly written.
- This repo pushed somewhere reachable (or on a USB stick) — bare metal has
  no snapshot/rollback, so don't rely on cloning off a machine you're about
  to overwrite.

## Install

1. Boot the netinst USB, install base Debian (no desktop task selected —
   the `desktop` role installs the i3 stack).
2. First boot, log in, get the repo onto the machine:
   ```sh
   sudo apt install -y ansible git
   git clone <repo-url> ~/debian && cd ~/debian/ansible
   ```
3. Dry run first:
   ```sh
   ansible-playbook site.yml --check --diff --ask-become-pass
   ```
   Expected: no fatal errors. Bad module args or undefined vars surface
   here before anything mutates.
4. Run for real:
   ```sh
   ansible-playbook site.yml --ask-become-pass
   ```
   Expected: `failed=0`. Individual apt package misses are tolerated by
   design (`packages` role installs items one at a time, `ignore_errors:
   true`) — check the "FAILED to install" debug message and fix any real
   typos in `ansible/group_vars/all/packages.yml`, don't just wave off
   every failure.

## Post-install verification

Reboot, then check each of these — this list exists because these are
exactly the things WSL/VM testing structurally can't verify:

- [ ] LightDM shows a session picker and login works; select the i3 session
      explicitly (not a leftover Plasma/other session entry)
- [ ] i3 starts; Polybar bar is visible (`[bar/main]`, launched as
      `polybar main`) with a tray showing icons (not an empty tray —
      upstream's config never exec'd a tray-app agent, this repo's
      `i3/config` adds `nm-applet`/`blueman-applet`/`lxpolkit` execs
      specifically to fill it)
- [ ] `notify-send test` delivers a Dunst notification, themed (not
      default GTK notification styling)
- [ ] Picom is running — shadows and window transparency visible (`picom
      --config ~/.config/picom/i3.conf` should already be running from i3's
      autostart, check with `pgrep picom`)
- [ ] Rofi launcher opens (`mod+d`) and is Catppuccin-themed, not
      unstyled/default rofi (single theme file now: `~/.config/rofi/config.rasi`)
- [ ] Power menu opens (`mod+shift+e`) and its Lock/Logout/Reboot/Shutdown
      choices work (`~/.local/share/rofi/scripts/powermenu.sh`) — confirm
      it's rendered with the rofi theme, not a blank/unstyled prompt
- [ ] kitty renders CaskaydiaCove Nerd Font and full Catppuccin Mocha
      coloring (cursor, tab bar, window borders — not just the 16 base
      colors); `fastfetch` shows the real Catppuccin logo PNG via kitty's
      image protocol (not ASCII-art, not upstream's Arch logo) in the
      boxed Hardware/Software layout with nerd-font icons per row
- [ ] `bat --list-themes | grep -i mocha` finds "Catppuccin Mocha", and
      `bat <anyfile>` actually renders with it (run `bat cache --build`
      first if not — needed once per machine, not part of `chezmoi apply`)
- [ ] `git diff | delta` (in any repo with changes) renders a colored,
      Catppuccin-styled diff, not delta's default colors or a plain diff
      — confirms `~/.gitconfig` (chezmoi-managed now) is being picked up
- [ ] tmux status bar shows Catppuccin modules (host/session/date), not
      oh-my-tmux's own default theme — confirms `~/.tmux.conf.local` is
      sourced and `tmux_conf_theme=disabled` took effect
- [ ] GTK apps (Thunar) and Qt apps (any Kvantum-styled Qt app, or `qt5ct`
      itself) render Catppuccin Mocha Mauve — check widget style is
      Kvantum in `qt5ct`, not the Qt default
- [ ] Papirus-Dark icon theme applied with Catppuccin Mocha Mauve folder
      colors (not Tela — check via `lxappearance` or the file manager's
      icon set)
- [ ] Wallpaper set correctly via nitrogen (`nitrogen --restore` runs from
      i3's autostart — confirm the Catppuccin Mocha wallpaper, not a blank
      desktop)
- [ ] `nvim` opens without plugin/config errors
- [ ] `yazi` opens with the `catppuccin-mocha` flavor active
- [ ] `zsh` is default shell, oh-my-zsh + plugins load, atuin history search
      works (`Ctrl+R`), and `eza`/`ls` output is Catppuccin-colored
- [ ] `btop`, `cava`, `zathura <anypdf>`, `mpv <anyvideo>`, `newsboat`,
      `aerc`, `ncspot`, `lazygit` (in any git repo), `zellij` all launch
      with Catppuccin Mocha coloring, not their tool defaults
- [ ] `flameshot` screenshot tool works — confirm it actually works on
      this hardware; the prior KDE-era repo found flameshot broken under
      Wayland, this i3 stack is X11-only so that failure mode shouldn't
      apply, but verify rather than assume

## Idempotency

Re-run `ansible-playbook site.yml --ask-become-pass` a second time on the
same install (no reinstall). Expected: same result, `changed=0` on tasks
that already converged, no task fails only-on-second-run, no duplicate
resource creation (cursor theme copied twice, a plugin `git clone` erroring
into a now-non-empty dir, etc.).

## Recording results

Fix bugs found in the relevant role file, commit each fix separately with a
message naming the specific bug (matches the VM pass's Task 11 Step 6
convention) — don't batch unrelated fixes into one commit.
