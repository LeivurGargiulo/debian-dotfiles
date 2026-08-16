# Grub / Kernel Cmdline Customization Plan

> **For agentic workers:** Small system-config change, no code/tests involved — execute inline, no subagent dispatch needed.

**Goal:** Tune `/etc/default/grub` for quieter boot and small latency win, without touching CPU mitigation security posture.

**Architecture:** Direct edit of `/etc/default/grub` (Debian trixie, BIOS boot, i7-2600, Intel iGPU, plymouth already installed) followed by `update-grub` to regenerate `/boot/grub/grub.cfg`.

**Tech Stack:** grub2, plymouth (already present), sed.

**Spec:** none — decisions captured inline below (system-config task, not a feature spec).

## Global Constraints

- No `mitigations=off` — user explicitly declined the perf/security tradeoff (2026-08-16 decision).
- No new packages/themes — plymouth already installed, reuse as-is.
- Machine is BIOS-boot (not UEFI) — no `efibootmgr`/ESP steps needed.

---

## Decisions made (2026-08-16)

- `GRUB_TIMEOUT`: 5 → 3 (still visible/interruptible, not hidden)
- `GRUB_CMDLINE_LINUX_DEFAULT`: `"quiet"` → `"quiet splash nowatchdog"`
  - `splash`: plymouth already installed, safe to enable
  - `nowatchdog`: latency win, zero security cost
  - `mitigations=off` rejected by user — leave kernel mitigations at default (on)

### Task 1: Apply grub config edit and regenerate grub.cfg

**Files:**
- Modify: `/etc/default/grub` (system file, root-owned, needs sudo)

**Interfaces:**
- Consumes: nothing
- Produces: updated `/boot/grub/grub.cfg` via `update-grub`

- [ ] **Step 1: Edit `/etc/default/grub`**

```bash
sudo sed -i \
  -e 's/^GRUB_TIMEOUT=5/GRUB_TIMEOUT=3/' \
  -e 's/^GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nowatchdog"/' \
  /etc/default/grub
```

- [ ] **Step 2: Verify the edit landed**

```bash
grep -E '^GRUB_TIMEOUT=|^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub
```

Expected:
```
GRUB_TIMEOUT=3
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nowatchdog"
```

- [ ] **Step 3: Regenerate grub.cfg**

```bash
sudo update-grub
```

Expected: output ends with `done` and lists the found kernel(s), e.g. `Found linux image: /boot/vmlinuz-6.12.101+deb13-amd64`.

- [ ] **Step 4: Reboot and verify live cmdline**

```bash
sudo reboot
# after reboot:
cat /proc/cmdline
```

Expected: contains `quiet splash nowatchdog`, no `mitigations=off`.

- [ ] **Step 5: Commit doc state**

No repo files changed by this task (system file only, not chezmoi-managed yet). If later brought under chezmoi management, that's a separate task — see "Follow-up" below.

---

## Follow-up (not in scope here)

- `/etc/default/grub` is currently **not** tracked by chezmoi (`chezmoi/` dir has no grub source). If the user wants this reproducible across machines, add `chezmoi/dot_etc_default_grub` or a chezmoi script — separate task, ask first since it touches boot config on every managed host.
