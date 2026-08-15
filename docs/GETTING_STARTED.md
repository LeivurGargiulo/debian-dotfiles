# Getting started

A walkthrough for turning a blank machine into this desktop, start to
finish. If you're testing changes to this repo itself (not setting up
a machine you'll actually use), see
[BARE_METAL_TESTING.md](BARE_METAL_TESTING.md) instead — same install
steps, but framed as a QA checklist with a disposable test machine in
mind.

## What you end up with

Debian + i3 (tiling window manager), Catppuccin Mocha everywhere —
terminal, launcher, bar, notifications, editor, and every CLI/TUI tool
that has an official [Catppuccin theme](https://github.com/orgs/catppuccin/repositories).
TUI-first: most "apps" here are terminal tools, not GUI programs. See
[SOFTWARE_LIST.md](SOFTWARE_LIST.md) for the full inventory,
[DESKTOP_GUIDE.md](DESKTOP_GUIDE.md) for what runs and why.

## 1. Install base Debian

Boot a [Debian netinst](https://www.debian.org/distrib/netinst) USB.
During install:

- **Don't** select the "Desktop environment" task in tasksel — the
  `desktop` Ansible role installs the i3 stack itself, a pre-installed
  DE just means more to remove later.
- **Do** select "SSH server" if you want to drive the rest of this
  setup from another machine instead of the console.
- Everything else is normal Debian install defaults (partitioning,
  user account, etc.) — nothing here is install-time-order-sensitive.

Reboot into your new base Debian system and log in (console or SSH).

## 2. Get the repo and bootstrap tools

```sh
sudo apt update && sudo apt install -y ansible git
git clone <this-repo-url> ~/debian
cd ~/debian/ansible
```

## 3. Dry run, then apply

Always dry-run first — this repo's roles are safe to `--check` and it
catches undefined-variable/typo bugs before anything actually installs:

```sh
ansible-playbook site.yml --check --diff --ask-become-pass
```

If that comes back clean (no fatal errors — individual package-not-found
warnings are tolerated by design, see below), run it for real:

```sh
ansible-playbook site.yml --ask-become-pass
```

This is a full run: it installs every package in
[SOFTWARE_LIST.md](SOFTWARE_LIST.md), builds picom from source, fetches
fonts/cursors/GTK/Kvantum themes, symlinks every dotfile via chezmoi,
sets up your shell (zsh + oh-my-zsh + plugins), and installs the Claude
Code CLI + plugin set. Expect it to take a while — several packages,
one thing built from source, several GitHub release downloads.

**Individual apt package failures don't stop the run** — the
`packages` role installs them one at a time with `ignore_errors: true`
by design, so one missing/renamed package (mirror drift, Debian version
skew) doesn't block everything else. Check the "FAILED to install"
messages at the end; a real typo in `packages.yml` is a bug worth
fixing, a single stale package name on an old mirror usually isn't
worth chasing.

## 4. Reboot into i3

```sh
sudo reboot
```

LightDM should show a session picker — pick the **i3** session (there's
usually only one, but if this machine ever had another DE, don't pick
a leftover entry). Log in.

## 5. First few minutes in i3

i3 is a tiling window manager: windows split the screen instead of
overlapping. No taskbar to click — everything is a keybind. The
essentials to get moving:

| Bind | What |
|---|---|
| `mod+Return` | open a terminal (kitty) |
| `mod+d` | app launcher — type to search, Enter to launch |
| `mod+j/k/l/;` (or arrow keys) | move focus between windows |
| `mod+shift+q` | close focused window |
| `mod+1`..`mod+0` | switch workspace 1-10 |
| `mod+shift+r` | restart i3 (use after editing its config) |

`mod` is the Windows/Super key. Full list:
[KEYBINDINGS.md](KEYBINDINGS.md). What each rofi menu does, what
starts automatically, how the compositor/polybar/lock screen work:
[DESKTOP_GUIDE.md](DESKTOP_GUIDE.md).

Open a terminal (`mod+Return`) and run `fastfetch` — if you see a
Catppuccin-colored system-info panel with a real logo image (not
ASCII art, not tofu boxes where icons should be), fonts and the
terminal image protocol are both working correctly.

## 6. Make it yours

Everything is chezmoi-managed source in `chezmoi/` and Ansible-managed
config in `ansible/` — nothing lives only on the machine. Common first
edits:

- Add/remove installed software: [SOFTWARE_LIST.md](SOFTWARE_LIST.md) →
  `ansible/group_vars/all/packages.yml`
- Add a hotkey, change workspace names, add a polybar module:
  [CUSTOMIZING.md](CUSTOMIZING.md)
- Theme a newly-added tool with Catppuccin:
  [CUSTOMIZING.md](CUSTOMIZING.md#add-catppuccin-theming-to-a-newly-installed-tool)

After any edit: `cd ~/debian/ansible && ansible-playbook site.yml
--ask-become-pass` re-applies everything idempotently (safe to re-run —
already-converged tasks report `changed=0`), or if you only touched a
chezmoi-managed dotfile, `chezmoi --source ~/debian/chezmoi apply` is
faster.

## Troubleshooting a fresh install

- **Blank/empty tray** — `nm-applet`/`blueman-applet`/`lxpolkit` need a
  few seconds after login; if still empty after that, check
  `pgrep -a nm-applet` etc. actually started (see
  [DESKTOP_GUIDE.md](DESKTOP_GUIDE.md#what-starts-on-login))
- **No icons/glyphs, tofu boxes everywhere** — CaskaydiaCove Nerd Font
  failed to install or the font cache is stale; `fc-list | grep -i
  caskaydia` should list it, `fc-cache -f` if not showing up
- **Rofi/polybar look unstyled** — chezmoi didn't apply cleanly; run
  `chezmoi --source ~/debian/chezmoi apply --dry-run --verbose` and
  look for errors, or check `chezmoi --source ~/debian/chezmoi diff`
  for anything that failed to land
- **Picom not running, no shadows/blur** — it's built from source, not
  apt; confirm the build actually succeeded (`which picom` should say
  `/usr/local/bin/picom`) rather than assuming a silent apt fallback
- Full bare-metal verification checklist (every themed tool, every
  visual detail): [BARE_METAL_TESTING.md](BARE_METAL_TESTING.md)
