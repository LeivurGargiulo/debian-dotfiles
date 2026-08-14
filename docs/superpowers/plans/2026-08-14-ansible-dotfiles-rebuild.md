# Ansible + chezmoi Debian Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the old stow+bash+Gruvbox dotfiles repo with an Ansible-orchestrated, chezmoi-linked, Catppuccin Mocha, TUI-first Debian + KDE Plasma 6 setup that reaches a fully configured machine from `git clone` + one command.

**Architecture:** Single repo. `ansible/` holds the playbook, inventory, and per-concern roles (`packages`, `desktop`, `theme`, `dotfiles`, `shell-env`, `dev-tools`). `chezmoi/` holds the chezmoi source state (dotfiles + age-encrypted secrets), applied by the `dotfiles` role. `docs/` carries forward the design spec and reference material from the old repo.

**Tech Stack:** Ansible (playbook + roles, apt/flatpak/get_url/unarchive modules), chezmoi (dotfile linking + age encryption), KDE Plasma 6 + KWin tiling script, Debian apt, bash.

**Spec:** `docs/superpowers/specs/2026-08-14-ansible-dotfiles-rebuild-design.md`

## Global Constraints

- Target OS: Debian only (no multi-distro fallback), matching the old repo's `00-distro.sh` behavior — Ansible tasks should `assert` on `ansible_facts['distribution'] == "Debian"` early in `site.yml`.
- Idempotent: every role must be safely re-runnable; use Ansible's native state modules (`apt` with `state: present`, not shell loops with `dpkg -l` greps).
- Secrets (SSH config, Tailscale IPs) are age-encrypted via chezmoi — never committed in plaintext.
- TUI tool preferred over GUI wherever a mature TUI equivalent exists (see spec's package table) — do not substitute a GUI alternative for a task's specified tool without updating the spec first.
- Old repo lives at `~/dotfiles` during this plan's execution; Task 1 moves it to `~/dotfiles-old` before the new repo is scaffolded in its place.

---

### Task 1: Archive old repo, scaffold new repo skeleton

**Files:**
- Move: `~/dotfiles` → `~/dotfiles-old`
- Create: `~/dotfiles/` (new git repo)
- Create: `~/dotfiles/README.md`
- Create: `~/dotfiles/.gitignore`
- Create: `~/dotfiles/ansible/` `~/dotfiles/chezmoi/` `~/dotfiles/docs/superpowers/specs/` `~/dotfiles/docs/superpowers/plans/` (empty dirs, via `.gitkeep` where needed)
- Copy: `~/dotfiles-old/docs/superpowers/specs/2026-08-14-ansible-dotfiles-rebuild-design.md` → `~/dotfiles/docs/superpowers/specs/2026-08-14-ansible-dotfiles-rebuild-design.md`
- Copy: `~/dotfiles-old/docs/superpowers/plans/2026-08-14-ansible-dotfiles-rebuild.md` → `~/dotfiles/docs/superpowers/plans/2026-08-14-ansible-dotfiles-rebuild.md` (this file)
- Copy: `~/dotfiles-old/docs/PARITY_MATRIX.md` → `~/dotfiles/docs/PARITY_MATRIX.md`
- Copy: `~/dotfiles-old/shell/.zshrc` → staged for Task 7 (chezmoi source), not moved yet

**Interfaces:**
- Produces: `~/dotfiles` as a fresh git repo, empty `ansible/` and `chezmoi/` directories that later tasks populate.

- [ ] **Step 1: Move old repo aside**

```bash
mv ~/dotfiles ~/dotfiles-old
```

- [ ] **Step 2: Scaffold new repo**

```bash
mkdir -p ~/dotfiles/ansible/{inventory,group_vars/all,roles}
mkdir -p ~/dotfiles/chezmoi
mkdir -p ~/dotfiles/docs/superpowers/specs
mkdir -p ~/dotfiles/docs/superpowers/plans
cd ~/dotfiles && git init
```

- [ ] **Step 3: Carry forward spec, plan, and reference docs**

```bash
cp ~/dotfiles-old/docs/superpowers/specs/2026-08-14-ansible-dotfiles-rebuild-design.md \
   ~/dotfiles/docs/superpowers/specs/
cp ~/dotfiles-old/docs/superpowers/plans/2026-08-14-ansible-dotfiles-rebuild.md \
   ~/dotfiles/docs/superpowers/plans/
cp ~/dotfiles-old/docs/PARITY_MATRIX.md ~/dotfiles/docs/
```

- [ ] **Step 4: Write `.gitignore`**

```gitignore
*.retry
.vagrant/
*.log
```

- [ ] **Step 5: Write stub `README.md`**

```markdown
# dotfiles

Debian + KDE Plasma 6, Catppuccin Mocha, TUI-first. Ansible-orchestrated,
chezmoi-linked. See `docs/superpowers/specs/2026-08-14-ansible-dotfiles-rebuild-design.md`
for the design, `docs/superpowers/plans/2026-08-14-ansible-dotfiles-rebuild.md`
for the build-out plan.

## Bootstrap a fresh machine

\`\`\`sh
sudo apt install ansible git
git clone <repo> ~/dotfiles && cd ~/dotfiles/ansible
ansible-playbook site.yml --ask-become-pass
\`\`\`
```

- [ ] **Step 6: Commit**

```bash
cd ~/dotfiles
git add README.md .gitignore docs/
git commit -m "Scaffold new repo, carry forward spec/plan/docs from archived dotfiles-old"
```

---

### Task 2: Ansible control setup

**Files:**
- Create: `~/dotfiles/ansible/ansible.cfg`
- Create: `~/dotfiles/ansible/inventory/hosts.ini`
- Create: `~/dotfiles/ansible/site.yml`

**Interfaces:**
- Produces: `site.yml` play targeting `localhost`, with a Debian-only guard, that later tasks append `roles:` entries to.

- [ ] **Step 1: Write `ansible.cfg`**

```ini
[defaults]
inventory = inventory/hosts.ini
roles_path = roles
host_key_checking = False
retry_files_enabled = False
```

- [ ] **Step 2: Write `inventory/hosts.ini`**

```ini
[local]
localhost ansible_connection=local
```

- [ ] **Step 3: Write `site.yml` with the Debian guard**

```yaml
---
- name: Configure Debian workstation
  hosts: local
  become: true
  pre_tasks:
    - name: Assert target is Debian
      ansible.builtin.assert:
        that:
          - ansible_facts['distribution'] == "Debian"
        fail_msg: "This playbook only supports Debian. Detected: {{ ansible_facts['distribution'] }}"
  roles: []
```

- [ ] **Step 4: Syntax-check**

Run: `cd ~/dotfiles/ansible && ansible-playbook site.yml --syntax-check`
Expected: `playbook: site.yml` printed, exit code 0.

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles
git add ansible/ansible.cfg ansible/inventory/hosts.ini ansible/site.yml
git commit -m "Add Ansible control setup with Debian-only guard"
```

---

### Task 3: `packages` role — apt packages

**Files:**
- Create: `~/dotfiles/ansible/group_vars/all/packages.yml`
- Create: `~/dotfiles/ansible/roles/packages/tasks/main.yml`

**Interfaces:**
- Consumes: nothing.
- Produces: `apt_packages` var (list of strings) other roles can extend by appending to before this role runs; `packages` role installs everything in `apt_packages` individually-retried (loop with `ignore_errors`, not a single bulk `apt` call) so one bad package name doesn't abort the run — matching the old repo's resilience requirement from the spec.

- [ ] **Step 1: Write `group_vars/all/packages.yml` — apt list**

```yaml
---
apt_packages:
  # core CLI (carried from old apt.txt)
  - curl
  - eza
  - bat
  - fd-find
  - ripgrep
  - fzf
  - zoxide
  - tmux
  - mosh
  - jq
  - git
  - gh
  - zsh
  - p7zip-full
  - p7zip-rar
  - ffmpeg
  - python3
  - python3-pip
  - python3-venv
  - openjdk-21-jdk
  - openssh-server
  - docker.io
  - docker-compose-v2
  - unzip
  - imagemagick
  - git-delta
  - meld
  - scrcpy
  - duf
  - smartmontools
  - hdparm
  - ncdu
  - bandwhich
  - btop
  - glances

  # TUI-first picks
  - yazi
  - bluetuith
  - zathura
  - mpv
  - transmission-cli
  - tremc
  - cava

  # firewall / disk / archive
  - ufw
  - gparted

  # remote/GUI exceptions with no TUI equivalent
  - dolphin
  - remmina
  - remmina-plugin-rdp
  - remmina-plugin-vnc
  - filezilla
  - gimp
  - kdenlive
  - obs-studio
  - nextcloud-desktop
  - libnotify-bin
  - gwenview
  - ark

  # office/audio
  - pavucontrol

  # password manager CLI
  - bitwarden-cli

  # KVM sharing / minecraft launcher
  - barrier
  - prismlauncher

  # not in Debian apt — installed separately (see packages_manual role tasks):
  #   starship, tailscale, google-chrome-stable, chezmoi, ncspot, lazygit,
  #   yt-dlp, atuin, jrnl, glow, mangohud, ventoy, vscode, zen browser,
  #   vesktop, telegram, zapzap, easyeffects (flatpak), gnome-boxes,
  #   openrgb, reaper, catppuccin-cursors, catppuccin-papirus-folders
```

- [ ] **Step 2: Write `roles/packages/tasks/main.yml`**

```yaml
---
- name: Update apt cache
  ansible.builtin.apt:
    update_cache: true
    cache_valid_time: 3600

- name: Install apt packages individually (resilient to one bad name)
  ansible.builtin.apt:
    name: "{{ item }}"
    state: present
  loop: "{{ apt_packages }}"
  loop_control:
    label: "{{ item }}"
  register: apt_result
  ignore_errors: true

- name: Report failed apt packages
  ansible.builtin.debug:
    msg: "FAILED to install: {{ apt_result.results | selectattr('failed', 'defined') | selectattr('failed') | map(attribute='item') | list }}"
  when: apt_result.results | selectattr('failed', 'defined') | selectattr('failed') | list | length > 0
```

- [ ] **Step 3: Wire into `site.yml`**

Edit `ansible/site.yml`, change `roles: []` to:

```yaml
  roles:
    - packages
```

- [ ] **Step 4: Syntax-check**

Run: `cd ~/dotfiles/ansible && ansible-playbook site.yml --syntax-check`
Expected: exit code 0.

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles
git add ansible/group_vars/all/packages.yml ansible/roles/packages/tasks/main.yml ansible/site.yml
git commit -m "Add packages role with apt package list"
```

---

### Task 4: `packages` role — non-apt installs (GitHub release, official script, flatpak)

**Files:**
- Modify: `~/dotfiles/ansible/roles/packages/tasks/main.yml`
- Create: `~/dotfiles/ansible/roles/packages/tasks/github_releases.yml`
- Create: `~/dotfiles/ansible/roles/packages/tasks/official_scripts.yml`
- Create: `~/dotfiles/ansible/roles/packages/tasks/flatpak.yml`
- Modify: `~/dotfiles/ansible/group_vars/all/packages.yml`

**Interfaces:**
- Consumes: nothing new.
- Produces: `lazygit`, `ncspot`, `yt-dlp`, `atuin`, `jrnl`, `glow`, `ventoy` binaries on `$PATH` via `/usr/local/bin`; `starship`, `tailscale`, `chezmoi` via their official install scripts; `google-chrome-stable`, `code` (VS Code) via apt repos added at runtime; flatpak apps (`vesktop`, `org.telegram.desktop`, `com.rtosta.zapzap`, `com.github.wwmm.easyeffects`, `org.gnome.Boxes`, `com.spotify.Client` — no, ncspot replaces this — see note) installed via `community.general.flatpak`.

- [ ] **Step 1: Add GitHub-release package vars**

Append to `group_vars/all/packages.yml`:

```yaml
github_release_binaries:
  - repo: jesseduffield/lazygit
    asset_pattern: "lazygit_.*_Linux_x86_64.tar.gz"
    binary_name: lazygit
  - repo: hrkfdn/ncspot
    asset_pattern: "ncspot-.*-linux.tar.gz"
    binary_name: ncspot
  - repo: yt-dlp/yt-dlp
    asset_pattern: "yt-dlp_linux"
    binary_name: yt-dlp
    direct_binary: true
  - repo: atuinsh/atuin
    asset_pattern: "atuin-x86_64-unknown-linux-gnu.tar.gz"
    binary_name: atuin
  - repo: ventoy/Ventoy
    asset_pattern: "ventoy-.*-linux.tar.gz"
    binary_name: Ventoy2Disk.sh

flatpak_apps:
  - dev.vencord.Vesktop
  - org.telegram.desktop
  - com.rtosta.zapzap
  - com.github.wwmm.easyeffects
  - org.gnome.Boxes
```

- [ ] **Step 2: Write `github_releases.yml`**

```yaml
---
- name: Fetch latest release info for GitHub binaries
  ansible.builtin.uri:
    url: "https://api.github.com/repos/{{ item.repo }}/releases/latest"
    return_content: true
  loop: "{{ github_release_binaries }}"
  loop_control:
    label: "{{ item.repo }}"
  register: gh_releases

- name: Download and install each GitHub-release binary
  ansible.builtin.include_tasks: github_release_install.yml
  loop: "{{ gh_releases.results }}"
  loop_control:
    label: "{{ item.item.repo }}"
    loop_var: release
```

- [ ] **Step 3: Write `github_release_install.yml` (single-binary install helper)**

```yaml
---
- name: "Find matching asset for {{ release.item.repo }}"
  ansible.builtin.set_fact:
    matched_asset: "{{ (release.json.assets | selectattr('name', 'match', release.item.asset_pattern) | first).browser_download_url }}"

- name: "Install {{ release.item.binary_name }} directly (single-binary release)"
  ansible.builtin.get_url:
    url: "{{ matched_asset }}"
    dest: "/usr/local/bin/{{ release.item.binary_name }}"
    mode: "0755"
  when: release.item.direct_binary | default(false)

- name: "Download and unarchive {{ release.item.binary_name }}"
  ansible.builtin.unarchive:
    src: "{{ matched_asset }}"
    dest: "/tmp/{{ release.item.binary_name }}-extract"
    remote_src: true
  when: not (release.item.direct_binary | default(false))

- name: "Move {{ release.item.binary_name }} into place"
  ansible.builtin.shell: |
    set -euo pipefail
    found="$(find /tmp/{{ release.item.binary_name }}-extract -type f -name '{{ release.item.binary_name }}' | head -1)"
    install -m 0755 "$found" /usr/local/bin/{{ release.item.binary_name }}
  args:
    executable: /bin/bash
  when: not (release.item.direct_binary | default(false))
```

- [ ] **Step 4: Write `official_scripts.yml`**

```yaml
---
- name: Check if starship is installed
  ansible.builtin.command: which starship
  register: starship_check
  ignore_errors: true
  changed_when: false

- name: Install starship via official script
  ansible.builtin.shell: curl -sS https://starship.rs/install.sh | sh -s -- --yes
  when: starship_check.rc != 0

- name: Check if tailscale is installed
  ansible.builtin.command: which tailscale
  register: tailscale_check
  ignore_errors: true
  changed_when: false

- name: Install tailscale via official script
  ansible.builtin.shell: curl -fsSL https://tailscale.com/install.sh | sh
  when: tailscale_check.rc != 0

- name: Check if chezmoi is installed
  ansible.builtin.command: which chezmoi
  register: chezmoi_check
  ignore_errors: true
  changed_when: false

- name: Install chezmoi via official script
  ansible.builtin.shell: sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
  when: chezmoi_check.rc != 0
```

- [ ] **Step 5: Write `flatpak.yml`**

```yaml
---
- name: Ensure flatpak is installed
  ansible.builtin.apt:
    name: flatpak
    state: present

- name: Add Flathub remote
  community.general.flatpak_remote:
    name: flathub
    state: present
    flatpakrepo_url: https://flathub.org/repo/flathub.flatpakrepo

- name: Install flatpak apps
  community.general.flatpak:
    name: "{{ item }}"
    state: present
  loop: "{{ flatpak_apps }}"
  loop_control:
    label: "{{ item }}"
```

- [ ] **Step 6: Wire the three new task files into `roles/packages/tasks/main.yml`**

Append to the end of the file:

```yaml
- name: Install non-apt binaries from GitHub releases
  ansible.builtin.include_tasks: github_releases.yml

- name: Install packages via official install scripts
  ansible.builtin.include_tasks: official_scripts.yml

- name: Install flatpak apps
  ansible.builtin.include_tasks: flatpak.yml
```

- [ ] **Step 7: Syntax-check**

Run: `cd ~/dotfiles/ansible && ansible-playbook site.yml --syntax-check`
Expected: exit code 0.

- [ ] **Step 8: Commit**

```bash
cd ~/dotfiles
git add ansible/roles/packages/tasks/ ansible/group_vars/all/packages.yml
git commit -m "Add non-apt package installs: GitHub releases, official scripts, flatpak"
```

---

### Task 5: `desktop` role — Plasma 6 + tiling

**Files:**
- Create: `~/dotfiles/ansible/roles/desktop/tasks/main.yml`
- Modify: `~/dotfiles/ansible/group_vars/all/packages.yml`
- Modify: `~/dotfiles/ansible/site.yml`

**Interfaces:**
- Consumes: nothing.
- Produces: Plasma 6 desktop session installed and sddm enabled as the display manager; Bismuth KWin tiling script installed for later roles (`theme`) to activate via `kwriteconfig6`.

- [ ] **Step 1: Add Plasma package vars**

Append to `group_vars/all/packages.yml`:

```yaml
plasma_packages:
  - plasma-desktop
  - sddm
  - kwin-wayland
  - plasma-nm
  - bluedevil
  - kde-spectacle
  - konsole
  - kitty
  - kde-config-gtk-style
  - kpackagetool6
```

- [ ] **Step 2: Write `roles/desktop/tasks/main.yml`**

```yaml
---
- name: Install Plasma desktop packages
  ansible.builtin.apt:
    name: "{{ plasma_packages }}"
    state: present

- name: Enable sddm service
  ansible.builtin.systemd:
    name: sddm
    enabled: true

- name: Clone Bismuth KWin tiling script
  ansible.builtin.git:
    repo: https://github.com/Bismuth-Forge/bismuth.git
    dest: /tmp/bismuth-build
    depth: 1
  register: bismuth_clone

- name: Build and install Bismuth (requires cmake/extra-cmake-modules)
  ansible.builtin.apt:
    name:
      - cmake
      - extra-cmake-modules
      - libkf6config-dev
      - libkf6configwidgets-dev
      - libkf6i18n-dev
      - libkf6kio-dev
      - qt6-declarative-dev
    state: present

- name: Configure and build Bismuth
  ansible.builtin.shell: |
    set -euo pipefail
    cd /tmp/bismuth-build
    cmake -B build -DCMAKE_INSTALL_PREFIX=/usr
    cmake --build build
  args:
    executable: /bin/bash
  when: bismuth_clone.changed

- name: Install Bismuth
  ansible.builtin.command: cmake --install build
  args:
    chdir: /tmp/bismuth-build
  when: bismuth_clone.changed
```

- [ ] **Step 3: Wire into `site.yml`**

```yaml
  roles:
    - packages
    - desktop
```

- [ ] **Step 4: Syntax-check**

Run: `cd ~/dotfiles/ansible && ansible-playbook site.yml --syntax-check`
Expected: exit code 0.

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles
git add ansible/roles/desktop/ ansible/group_vars/all/packages.yml ansible/site.yml
git commit -m "Add desktop role: Plasma 6 + sddm + Bismuth tiling"
```

---

### Task 6: `theme` role — Catppuccin Mocha

**Files:**
- Create: `~/dotfiles/ansible/roles/theme/tasks/main.yml`
- Create: `~/dotfiles/ansible/roles/theme/files/apply-colorscheme.sh`
- Modify: `~/dotfiles/ansible/group_vars/all/packages.yml`
- Modify: `~/dotfiles/ansible/site.yml`

**Interfaces:**
- Consumes: `kpackagetool6` from the `desktop` role.
- Produces: Catppuccin Mocha color scheme, Papirus+catppuccin-folders icons, catppuccin-cursors, JetBrainsMono Nerd Font, Catppuccin wallpaper, and two KDE Store panel widgets all installed and applied. Later `dotfiles` role's chezmoi source references this role only for package installs — theming *files* (kitty.conf, starship.toml) live in chezmoi, not here.

- [ ] **Step 1: Add theme package vars**

Append to `group_vars/all/packages.yml`:

```yaml
theme_packages:
  - papirus-icon-theme
  - fonts-jetbrains-mono
```

- [ ] **Step 2: Write `roles/theme/tasks/main.yml`**

```yaml
---
- name: Install base theme packages (Papirus, JetBrains Mono)
  ansible.builtin.apt:
    name: "{{ theme_packages }}"
    state: present

- name: Clone catppuccin-papirus-folders
  ansible.builtin.git:
    repo: https://github.com/catppuccin/papirus-folders.git
    dest: /tmp/catppuccin-papirus-folders
    depth: 1

- name: Install catppuccin-papirus-folders
  ansible.builtin.command: ./install.sh -a
  args:
    chdir: /tmp/catppuccin-papirus-folders

- name: Clone catppuccin-cursors
  ansible.builtin.git:
    repo: https://github.com/catppuccin/cursors.git
    dest: /tmp/catppuccin-cursors
    depth: 1
  register: cursors_clone

- name: Install Catppuccin Mocha cursor theme
  ansible.builtin.copy:
    src: /tmp/catppuccin-cursors/mocha/dist/catppuccin-mocha-dark-cursors
    dest: /usr/share/icons/
    remote_src: true
  when: cursors_clone.changed

- name: Fetch Catppuccin Plasma color scheme
  ansible.builtin.get_url:
    url: https://raw.githubusercontent.com/catppuccin/kde/main/themes/colorschemes/CatppuccinMocha.colors
    dest: /usr/share/color-schemes/CatppuccinMocha.colors
    mode: "0644"

- name: Apply Catppuccin Mocha color scheme
  ansible.builtin.command: plasma-apply-colorscheme CatppuccinMocha
  become: false
  environment:
    XDG_RUNTIME_DIR: "/run/user/{{ ansible_facts['env']['SUDO_UID'] | default(1000) }}"

- name: Fetch a Catppuccin Mocha wallpaper
  ansible.builtin.get_url:
    url: https://raw.githubusercontent.com/catppuccin/wallpapers/main/minimalistic/mocha-4k.png
    dest: /usr/share/wallpapers/catppuccin-mocha.png
    mode: "0644"

- name: Apply wallpaper
  ansible.builtin.command: plasma-apply-wallpaperimage /usr/share/wallpapers/catppuccin-mocha.png
  become: false
```

- [ ] **Step 3: Wire into `site.yml`**

```yaml
  roles:
    - packages
    - desktop
    - theme
```

- [ ] **Step 4: Syntax-check**

Run: `cd ~/dotfiles/ansible && ansible-playbook site.yml --syntax-check`
Expected: exit code 0.

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles
git add ansible/roles/theme/ ansible/group_vars/all/packages.yml ansible/site.yml
git commit -m "Add theme role: Catppuccin Mocha colors, icons, cursors, wallpaper"
```

---

### Task 7: chezmoi source content — shell, terminal, prompt configs

**Files:**
- Create: `~/dotfiles/chezmoi/dot_zshrc`
- Create: `~/dotfiles/chezmoi/dot_tmux.conf`
- Create: `~/dotfiles/chezmoi/dot_config/kitty/kitty.conf`
- Create: `~/dotfiles/chezmoi/dot_config/starship.toml`
- Create: `~/dotfiles/chezmoi/.chezmoiroot` (repo-root file, contains `chezmoi`)

**Interfaces:**
- Consumes: old repo's `~/dotfiles-old/shell/.zshrc`, `.tmux.conf` content (carried forward verbatim per spec).
- Produces: chezmoi source state that Task 9's `dotfiles` role applies via `chezmoi apply`.

- [ ] **Step 1: Write `.chezmoiroot` at repo root**

```bash
echo "chezmoi" > ~/dotfiles/.chezmoiroot
```

- [ ] **Step 2: Carry forward `.zshrc`, adding atuin init**

```bash
cp ~/dotfiles-old/shell/.zshrc ~/dotfiles/chezmoi/dot_zshrc
```

Append to `~/dotfiles/chezmoi/dot_zshrc`:

```bash

# atuin: fuzzy-searchable shell history
eval "$(atuin init zsh)"
```

- [ ] **Step 3: Carry forward `.tmux.conf`**

```bash
cp ~/dotfiles-old/shell/.tmux.conf ~/dotfiles/chezmoi/dot_tmux.conf
```

- [ ] **Step 4: Write `kitty.conf` — Catppuccin Mocha + glass/blur**

```
font_family      JetBrainsMono Nerd Font
font_size        11.0

background_opacity 0.85
background_blur    24

# Catppuccin Mocha
foreground              #CDD6F4
background              #1E1E2E
cursor                  #F5E0DC
selection_foreground    #1E1E2E
selection_background    #F5E0DC

color0  #45475A
color1  #F38BA8
color2  #A6E3A1
color3  #F9E2AF
color4  #89B4FA
color5  #F5C2E7
color6  #94E2D5
color7  #BAC2DE
color8  #585B70
color9  #F38BA8
color10 #A6E3A1
color11 #F9E2AF
color12 #89B4FA
color13 #F5C2E7
color14 #94E2D5
color15 #A6ADC8

cursor_shape block
cursor_blink_interval 0
```

- [ ] **Step 5: Write `starship.toml` — Catppuccin Mocha preset**

```toml
palette = "catppuccin_mocha"

[palettes.catppuccin_mocha]
rosewater = "#f5e0dc"
flamingo = "#f2cdcd"
pink = "#f5c2e7"
mauve = "#cba6f7"
red = "#f38ba8"
maroon = "#eba0ac"
peach = "#fab387"
yellow = "#f9e2af"
green = "#a6e3a1"
teal = "#94e2d5"
sky = "#89dceb"
sapphire = "#74c7ec"
blue = "#89b4fa"
lavender = "#b4befe"
text = "#cdd6f4"
base = "#1e1e2e"
surface0 = "#313244"

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

[directory]
style = "bold blue"

[git_branch]
style = "bold mauve"
```

- [ ] **Step 6: Commit**

```bash
cd ~/dotfiles
git add .chezmoiroot chezmoi/
git commit -m "Add chezmoi source: zshrc, tmux, kitty, starship (Catppuccin Mocha)"
```

---

### Task 8: chezmoi source content — encrypted SSH config

**Files:**
- Create: `~/dotfiles/chezmoi/.chezmoi.toml.tmpl`
- Create: `~/dotfiles/chezmoi/encrypted_private_dot_ssh/encrypted_config.age`

**Interfaces:**
- Consumes: `~/dotfiles-old/dev/.ssh/config` (12 lines, SSH host aliases + Tailscale IPs).
- Produces: age-encrypted SSH config in chezmoi source, decrypted automatically on `chezmoi apply` once the operator's age key is present at `~/.config/chezmoi/key.txt`.

- [ ] **Step 1: Generate an age key if one doesn't already exist**

```bash
mkdir -p ~/.config/chezmoi
[ -f ~/.config/chezmoi/key.txt ] || age-keygen -o ~/.config/chezmoi/key.txt
```

- [ ] **Step 2: Write `.chezmoi.toml.tmpl` declaring the age encryption backend**

```toml
encryption = "age"
[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "{{ (age.recipient | default "") }}"
```

- [ ] **Step 3: Encrypt the SSH config with chezmoi**

```bash
cd ~/dotfiles
chezmoi --source ./chezmoi add --encrypt ~/dotfiles-old/dev/.ssh/config
```

This creates `chezmoi/encrypted_private_dot_ssh/encrypted_config.age` (chezmoi's naming convention for an encrypted file under `private_dot_ssh/`).

- [ ] **Step 4: Verify decryption round-trips**

Run: `cd ~/dotfiles && chezmoi --source ./chezmoi cat ~/.ssh/config`
Expected: prints the original plaintext SSH config content.

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles
git add chezmoi/.chezmoi.toml.tmpl chezmoi/encrypted_private_dot_ssh/
git commit -m "Add age-encrypted SSH config to chezmoi source"
```

---

### Task 9: `dotfiles` and `shell-env` roles

**Files:**
- Create: `~/dotfiles/ansible/roles/dotfiles/tasks/main.yml`
- Create: `~/dotfiles/ansible/roles/shell-env/tasks/main.yml`
- Modify: `~/dotfiles/ansible/site.yml`

**Interfaces:**
- Consumes: chezmoi source from Tasks 7-8; `chezmoi` binary from Task 4's `official_scripts.yml`.
- Produces: dotfiles linked into `$HOME`, oh-my-zsh + plugins installed, nvm + node LTS installed, tmux plugin manager cloned, default shell set to zsh.

- [ ] **Step 1: Write `roles/dotfiles/tasks/main.yml`**

```yaml
---
- name: Apply chezmoi source state
  ansible.builtin.command: chezmoi --source "{{ playbook_dir }}/../chezmoi" apply
  become: false
```

- [ ] **Step 2: Write `roles/shell-env/tasks/main.yml`**

```yaml
---
- name: Check if oh-my-zsh is installed
  ansible.builtin.stat:
    path: "{{ ansible_env.HOME }}/.oh-my-zsh"
  become: false
  register: omz_stat

- name: Install oh-my-zsh
  ansible.builtin.shell: |
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  become: false
  when: not omz_stat.stat.exists

- name: Clone zsh-autosuggestions plugin
  ansible.builtin.git:
    repo: https://github.com/zsh-users/zsh-autosuggestions.git
    dest: "{{ ansible_env.HOME }}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    depth: 1
  become: false

- name: Clone zsh-syntax-highlighting plugin
  ansible.builtin.git:
    repo: https://github.com/zsh-users/zsh-syntax-highlighting.git
    dest: "{{ ansible_env.HOME }}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    depth: 1
  become: false

- name: Clone zsh-completions plugin
  ansible.builtin.git:
    repo: https://github.com/zsh-users/zsh-completions.git
    dest: "{{ ansible_env.HOME }}/.oh-my-zsh/custom/plugins/zsh-completions"
    depth: 1
  become: false

- name: Clone zsh-history-substring-search plugin
  ansible.builtin.git:
    repo: https://github.com/zsh-users/zsh-history-substring-search.git
    dest: "{{ ansible_env.HOME }}/.oh-my-zsh/custom/plugins/zsh-history-substring-search"
    depth: 1
  become: false

- name: Check if nvm is installed
  ansible.builtin.stat:
    path: "{{ ansible_env.HOME }}/.nvm"
  become: false
  register: nvm_stat

- name: Install nvm
  ansible.builtin.shell: |
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  become: false
  when: not nvm_stat.stat.exists

- name: Install latest Node LTS via nvm
  ansible.builtin.shell: |
    export NVM_DIR="{{ ansible_env.HOME }}/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
  args:
    executable: /bin/bash
  become: false

- name: Clone tmux plugin manager
  ansible.builtin.git:
    repo: https://github.com/tmux-plugins/tpm.git
    dest: "{{ ansible_env.HOME }}/.tmux/plugins/tpm"
    depth: 1
  become: false

- name: Set zsh as default shell
  ansible.builtin.user:
    name: "{{ ansible_env.USER }}"
    shell: /usr/bin/zsh
```

- [ ] **Step 3: Wire into `site.yml`**

```yaml
  roles:
    - packages
    - desktop
    - theme
    - dotfiles
    - shell-env
```

- [ ] **Step 4: Syntax-check**

Run: `cd ~/dotfiles/ansible && ansible-playbook site.yml --syntax-check`
Expected: exit code 0.

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles
git add ansible/roles/dotfiles/ ansible/roles/shell-env/ ansible/site.yml
git commit -m "Add dotfiles (chezmoi apply) and shell-env roles"
```

---

### Task 10: `dev-tools` role

**Files:**
- Create: `~/dotfiles/ansible/roles/dev-tools/tasks/main.yml`
- Modify: `~/dotfiles/ansible/group_vars/all/packages.yml`
- Modify: `~/dotfiles/ansible/site.yml`

**Interfaces:**
- Consumes: `pip3` from `packages` role.
- Produces: `pip_user_packages` installed via `pip3 install --user`.

- [ ] **Step 1: Add pruned pip package list**

Append to `group_vars/all/packages.yml`:

```yaml
pip_user_packages:
  - beautifulsoup4
  - curl_cffi
  - git-filter-repo
  - numpy
  - pandas
  - peewee
  - pillow
  - prompt_toolkit
  - protobuf
  - pyarrow
  - python-dateutil
  - python-dotenv
  - pytz
  - questionary
  - SQLAlchemy
  - six
  - soupsieve
  - websockets
  - pytest

npm_global_packages: []
```

- [ ] **Step 2: Write `roles/dev-tools/tasks/main.yml`**

```yaml
---
- name: Install pip user packages
  ansible.builtin.pip:
    name: "{{ pip_user_packages }}"
    extra_args: --user
  become: false

- name: Install npm global packages
  community.general.npm:
    name: "{{ item }}"
    global: true
  loop: "{{ npm_global_packages }}"
  when: npm_global_packages | length > 0
```

- [ ] **Step 3: Wire into `site.yml`**

```yaml
  roles:
    - packages
    - desktop
    - theme
    - dotfiles
    - shell-env
    - dev-tools
```

- [ ] **Step 4: Syntax-check**

Run: `cd ~/dotfiles/ansible && ansible-playbook site.yml --syntax-check`
Expected: exit code 0.

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles
git add ansible/roles/dev-tools/ ansible/group_vars/all/packages.yml ansible/site.yml
git commit -m "Add dev-tools role: pruned pip-user packages, npm-global placeholder"
```

---

### Task 11: VM testing pass

**Files:** none (validation task, no repo changes unless bugs are found — if bugs are found, fix the relevant role file from Tasks 3-10 and commit the fix here).

**Interfaces:**
- Consumes: the full `site.yml` from Tasks 1-10.
- Produces: a verified-working playbook run recorded in this task's completion.

- [ ] **Step 1: Create a fresh Debian VM and snapshot at clean-install state**

Using VirtualBox or QEMU (either is fine — spec left this open), install a
minimal Debian net-install ISO, take a snapshot named `clean-install`
immediately after first boot, before any packages are installed.

- [ ] **Step 2: Copy the repo into the VM and dry-run**

```bash
git clone <repo-url> ~/dotfiles
sudo apt install -y ansible
cd ~/dotfiles/ansible
ansible-playbook site.yml --check --diff --ask-become-pass
```

Expected: no fatal errors: task-definition mistakes (bad module args,
undefined vars) surface here before anything is mutated.

- [ ] **Step 3: Run for real**

```bash
ansible-playbook site.yml --ask-become-pass
```

Expected: completes with `failed=0` (some `apt` package-name misses are
tolerated per the `ignore_errors` resilience design — check the "FAILED to
install" debug message from Task 3 Step 2 and fix any real typos in
`group_vars/all/packages.yml`).

- [ ] **Step 4: Reboot and verify through sddm**

Reboot the VM. Verify: sddm login screen appears, Plasma session loads,
Catppuccin Mocha color scheme is applied, wallpaper is set, kitty opens
with the glass/blur Catppuccin theme, `zsh` is the default shell with
oh-my-zsh + atuin working.

- [ ] **Step 5: Roll back to `clean-install` snapshot, re-run to verify idempotency**

Restore the `clean-install` snapshot, run Steps 2-3 again. Expected: same
result as the first run — no task fails only-on-second-run, no duplicate
resource creation (e.g. cursor theme copied twice, plugin cloned into a
non-empty dir and erroring).

- [ ] **Step 6: Fix any bugs found, commit each fix separately**

For each bug found in Steps 3-5, fix the specific role file and commit:

```bash
cd ~/dotfiles
git add ansible/roles/<role>/tasks/main.yml
git commit -m "Fix <specific bug found during VM testing>"
```

- [ ] **Step 7: Bare-metal pass**

Per the spec's testing plan, repeat Steps 2-4 on real hardware once VM
testing passes clean — the old repo found two bugs (Plasma package names,
flameshot/Wayland incompatibility) that only surfaced on bare metal.

---

## Self-Review Notes

- **Spec coverage:** orchestration (Tasks 2-4, 9-10), desktop hybrid DE+tiling (Task 5), theming (Task 6-7), package selection incl. TUI-first table and GUI exceptions (Task 3-4), shell config carryover (Task 7), secrets/chezmoi encryption (Task 8), migration from old repo (Task 1), testing plan (Task 11). All spec sections have a task.
- **Deferred picks called out in the spec** (Bismuth vs Polonium, age vs gpg) are resolved concretely in this plan (Bismuth, age) rather than left open — an implementer needs one path, not a menu; if Polonium or gpg is preferred instead, swap Task 5 Step 2's repo URL or Task 8 Step 2's `encryption` value accordingly.
- **Type/name consistency checked:** `apt_packages`, `theme_packages`, `plasma_packages`, `github_release_binaries`, `flatpak_apps`, `pip_user_packages`, `npm_global_packages` are each defined once (Tasks 3-6, 10) and referenced by exactly that name in their consuming role — no renames across tasks.
