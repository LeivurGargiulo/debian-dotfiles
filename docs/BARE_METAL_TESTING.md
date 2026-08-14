# Bare-metal testing

Runs after the VM pass (`docs/superpowers/plans/2026-08-14-ansible-dotfiles-rebuild.md`,
Task 11) passes clean. The old repo found two bugs only on real hardware
(Plasma package names, flameshot/Wayland incompatibility) that the VM pass
missed — this stays a required step even after VM success.

## Prereqs

- Spare machine, or spare disk/partition on a shared machine, dedicated to
  this test. Do not run against a machine you can't afford to wipe.
- Debian netinst USB, freshly written.
- This repo pushed somewhere reachable (or on a USB stick) — bare metal has
  no snapshot/rollback, so don't rely on cloning off a machine you're about
  to overwrite.

## Install

1. Boot the netinst USB, install base Debian (no desktop task selected —
   the `desktop` role installs Plasma).
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

- [ ] sddm login screen appears, Plasma session loads
- [ ] Catppuccin Mocha color scheme applied (check System Settings → Colors)
- [ ] Wallpaper set correctly
- [ ] Bismuth tiling active (open two windows, confirm auto-tile)
- [ ] kitty opens with glass/blur effect — this is the one the old repo's
      README flagged as compositor-specific (was SwayFX before, is KWin's
      native blur-behind now). If blur doesn't render: check
      `kwriteconfig6 --file kwinrc --group Compositing --key Enabled` is
      true and the machine's GPU driver actually supports OpenGL
      compositing (a cheap/headless server board may not).
- [ ] `zsh` is default shell, oh-my-zsh + plugins load, atuin history search
      works (`Ctrl+R`)
- [ ] flameshot or `kde-spectacle` screenshot tool actually works under
      Wayland — the old repo's bare-metal pass found flameshot broken on
      Wayland; this repo uses `kde-spectacle` instead specifically to avoid
      that, confirm it still works on this hardware

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
