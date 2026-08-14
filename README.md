# dotfiles

Debian + KDE Plasma 6, Catppuccin Mocha, TUI-first. Ansible-orchestrated,
chezmoi-linked. See `docs/superpowers/specs/2026-08-14-ansible-dotfiles-rebuild-design.md`
for the design, `docs/superpowers/plans/2026-08-14-ansible-dotfiles-rebuild.md`
for the build-out plan.

## Bootstrap a fresh machine

```sh
sudo apt install ansible git
git clone <repo> ~/debian/ansible
ansible-playbook site.yml --ask-become-pass
```
