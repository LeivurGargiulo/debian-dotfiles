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

Full walkthrough, including what to pick during the Debian installer,
first keybinds to know, and troubleshooting a first boot:
[docs/GETTING_STARTED.md](docs/GETTING_STARTED.md).

## Documentation

- [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md) — tutorial: blank machine to working desktop, start to finish
- [docs/KEYBINDINGS.md](docs/KEYBINDINGS.md) — every i3 hotkey
- [docs/DESKTOP_GUIDE.md](docs/DESKTOP_GUIDE.md) — what runs on login, what each rofi menu does
- [docs/CUSTOMIZING.md](docs/CUSTOMIZING.md) — how-tos: add a hotkey, a launcher description, a polybar module, Catppuccin-theme a new tool, a Claude Code plugin, etc.
- [docs/SOFTWARE_LIST.md](docs/SOFTWARE_LIST.md) — every installed package/tool and what it's for, including every Catppuccin-themed CLI/TUI tool
- [docs/CLAUDE_CODE_SETUP.md](docs/CLAUDE_CODE_SETUP.md) — what's vendored from `~/.claude/`, what's excluded and why
- [docs/PARITY_MATRIX.md](docs/PARITY_MATRIX.md), [docs/TESTING.md](docs/TESTING.md), [docs/BARE_METAL_TESTING.md](docs/BARE_METAL_TESTING.md) — verification docs (BARE_METAL_TESTING is GETTING_STARTED's install steps reframed as a QA checklist)
