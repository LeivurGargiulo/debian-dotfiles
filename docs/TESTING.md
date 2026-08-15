# Testing guide (step by step)

Quick checklist for verifying a fresh install. For the deeper bare-metal
procedure (bug history, why each check exists) see
`docs/BARE_METAL_TESTING.md`. Use this doc when you just want to run
through the steps in order without the extra context.

## 1. Before you touch a real machine

- [ ] `ansible-playbook ansible/site.yml --syntax-check -i ansible/inventory/hosts.ini`
      passes with no errors
- [ ] `chezmoi --source chezmoi apply --dry-run --verbose` passes with no
      errors

Stop here and fix any error before continuing — don't run the real apply
on top of a syntax error.

## 2. Run the install

```sh
cd ansible
ansible-playbook site.yml --ask-become-pass
```

- [ ] Command finishes with `failed=0`
- [ ] Reboot the machine

## 3. Log in

- [ ] LightDM shows a session picker
- [ ] Pick the **i3** session (don't leave it on a default/other entry)
- [ ] Login succeeds, i3 starts

## 4. Look at the desktop

- [ ] Polybar bar is visible at top/bottom of screen
- [ ] Polybar's tray shows icons (network, bluetooth) — not empty
- [ ] Wallpaper is set (Catppuccin Mocha, not a blank/black desktop)
- [ ] Window shadows/transparency visible (picom is running)

## 5. Try the keybindings

- [ ] `$mod+a` opens the Rofi app launcher, themed (not plain/default look)
- [ ] `$mod+Ctrl+Delete` opens the Rofi power menu, themed, and its
      choices (logout/suspend/reboot/shutdown) are clickable
- [ ] Open a terminal, run `notify-send test` — a themed notification
      pops up

## 6. Check the apps

- [ ] Open kitty — font renders as CaskaydiaCove Nerd Font (icons show,
      not empty boxes/"tofu")
- [ ] Run `fastfetch` — shows the custom Debian/Catppuccin logo (not
      Arch's logo), font/icons render correctly
- [ ] Open Thunar (file manager) — Catppuccin Mocha Mauve GTK theme applied
- [ ] Open any Qt app (or `qt5ct`) — Catppuccin Mocha Mauve via Kvantum
      applied
- [ ] Icons throughout are Papirus-Dark with Catppuccin folder colors
      (not Tela, not default Papirus)
- [ ] Run `nvim` — opens with no plugin/config errors
- [ ] Run `yazi` — opens with the Catppuccin Mocha flavor active
- [ ] Open a new shell — it's zsh, oh-my-zsh loads, `Ctrl+R` triggers
      atuin's fuzzy history search
- [ ] Run `flameshot` — screenshot capture works

## 7. Run it twice

Re-run the install on the same machine (no reinstall):

```sh
ansible-playbook site.yml --ask-become-pass
```

- [ ] Second run also finishes with `failed=0`
- [ ] Mostly `changed=0` — nothing that already converged should error or
      duplicate itself on a second pass

## If something fails

Fix it in the relevant role file (`ansible/roles/<role>/tasks/main.yml`
for the packages/config, `chezmoi/dot_config/...` for a dotfile), commit
the fix separately naming the specific bug, then re-verify before calling
it done. Don't batch unrelated fixes into one commit.
