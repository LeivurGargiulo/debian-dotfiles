# dotfiles

Debian + i3, Catppuccin Mocha Mauve, TUI-first. Ansible-orchestrated,
chezmoi-linked. See `docs/superpowers/specs/2026-08-14-ansible-dotfiles-rebuild-design.md`
and `docs/superpowers/specs/2026-08-15-i3-ricing-rebuild-design.md` for
the design, `docs/superpowers/plans/2026-08-14-ansible-dotfiles-rebuild.md`
and `docs/superpowers/plans/2026-08-15-i3-ricing-rebuild.md` for the
build-out plans.

## Bootstrap a fresh machine

```sh
sudo apt install ansible git
git clone <repo> ~/debian && cd ~/debian/ansible
ansible-playbook site.yml --ask-become-pass
```
