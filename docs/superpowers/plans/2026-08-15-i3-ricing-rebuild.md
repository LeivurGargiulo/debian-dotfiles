# i3 Ricing Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the KDE Plasma 6 desktop layer with an i3 window-manager
stack modeled on vaelixd/i3-dotfiles, keeping the existing ansible +
chezmoi orchestration.

**Architecture:** `ansible/roles/desktop` installs the i3 stack + LightDM
instead of Plasma + SDDM. `ansible/roles/theme` keeps Papirus/cursor/GTK/
Kvantum theming, drops all Plasma/KDE-specific tasks, adds a font fetch
and a nitrogen wallpaper seed. The i3/polybar/rofi/picom/dunst/nvim/yazi/
fastfetch configs are vendored once (this plan) from vaelixd/i3-dotfiles
at pinned commit `533fa46ba36cd4cfce894a9c56655b82b0412e44` directly into
`chezmoi/dot_config/` as committed, editable dotfiles — consistent with
how `kitty.conf`/`starship.toml` already live in this repo, rather than
re-fetched by ansible on every apply.

**Tech Stack:** Ansible (Debian target), chezmoi, i3, Polybar, Rofi,
Picom, Dunst, LightDM, Neovim, Yazi, Fastfetch.

**Spec:** `docs/superpowers/specs/2026-08-15-i3-ricing-rebuild-design.md`

## Global Constraints

- Font is CaskaydiaCove Nerd Font everywhere. No JetBrains Mono
  reference may remain anywhere in the repo after this plan.
- Icon theme stays Papirus (+ Catppuccin folder colors), not upstream's
  Tela Circle Dracula — any vendored config referencing Tela must be
  edited to Papirus-Dark.
- Cursor theme, GTK theme, Kvantum theme tasks in `theme` role are
  otherwise unchanged.
- This is an infra/config repo with no application test suite. "Tests"
  in this plan are `ansible-playbook --syntax-check`, `ansible-lint`
  (if available), and `chezmoi diff`/`chezmoi apply --dry-run` — run
  these instead of unit tests at the end of every task.
- Do not run a real (non-dry-run) `ansible-playbook site.yml` apply
  against the live machine as part of any task in this plan — that is
  an explicit, separate checkpoint with the user after all tasks are
  done (see Task 8).

---

### Task 1: Swap package lists — remove Plasma, add i3 stack

**Files:**
- Modify: `ansible/group_vars/all/packages.yml`

**Interfaces:**
- Produces: `i3_packages` var (consumed by Task 2's desktop role
  rewrite), `theme_packages` with `fonts-jetbrains-mono` removed
  (consumed by Task 3's theme role rewrite).

- [ ] **Step 1: Remove `plasma_packages`, add `i3_packages`**

Replace the `plasma_packages:` block (lines 111-121) with:

```yaml
i3_packages:
  - xserver-xorg
  - xinit
  - i3-wm
  - i3lock
  - polybar
  - rofi
  - picom
  - dunst
  - lightdm
  - lightdm-gtk-greeter
  - network-manager-gnome
  - blueman
  - flameshot
  - policykit-1-gnome
  - lxappearance
  - qt5ct
  - thunar
  - thunar-archive-plugin
  - nitrogen
  - dex
  - light
  - pulseaudio-utils
  - neovim
  - fastfetch
```

- [ ] **Step 2: Drop the JetBrains Mono font from `theme_packages`**

Change:

```yaml
theme_packages:
  - papirus-icon-theme
  - fonts-jetbrains-mono
  - qt-style-kvantum
```

to:

```yaml
theme_packages:
  - papirus-icon-theme
  - qt-style-kvantum
```

- [ ] **Step 3: Verify YAML is well-formed**

Run: `python3 -c "import yaml; yaml.safe_load(open('ansible/group_vars/all/packages.yml'))"`
Expected: no output, exit code 0.

- [ ] **Step 4: Commit**

```bash
git add ansible/group_vars/all/packages.yml
git commit -m "Swap Plasma packages for i3 stack in group_vars"
```

---

### Task 2: Rewrite `desktop` role for i3 + LightDM

**Files:**
- Modify: `ansible/roles/desktop/tasks/main.yml` (full rewrite)

**Interfaces:**
- Consumes: `i3_packages` (from Task 1).

- [ ] **Step 1: Replace the file contents**

```yaml
---
- name: Install i3 desktop stack packages
  ansible.builtin.apt:
    name: "{{ i3_packages }}"
    state: present

- name: Enable lightdm service
  ansible.builtin.systemd:
    name: lightdm
    enabled: true

- name: Set default systemd target to graphical
  ansible.builtin.file:
    src: /usr/lib/systemd/system/graphical.target
    dest: /etc/systemd/system/default.target
    state: link
```

This drops the SDDM enable task, the KWin build-deps install, the
Polonium clone/build tasks (no KWin, no Bismuth/Polonium tiling script
needed — i3 tiles natively), and swaps the enabled service to `lightdm`.

- [ ] **Step 2: Syntax-check the role**

Run: `ansible-playbook ansible/site.yml --syntax-check -i ansible/inventory/hosts.ini`
Expected: `playbook: ansible/site.yml` with no errors.

- [ ] **Step 3: Commit**

```bash
git add ansible/roles/desktop/tasks/main.yml
git commit -m "Replace Plasma/KWin/Polonium desktop role with i3 + LightDM"
```

---

### Task 3: Rewrite `theme` role — drop KDE-specific tasks, add font + wallpaper seed

**Files:**
- Modify: `ansible/roles/theme/tasks/main.yml` (full rewrite)

**Interfaces:**
- Consumes: `theme_packages` (from Task 1).
- Produces: `~/.local/share/fonts/CaskaydiaCoveNerdFont*` (consumed by
  nothing in ansible — chezmoi-vendored configs in Task 4/5 assume this
  font is installed), `~/.config/nitrogen/bg-saved.cfg` (read by
  `nitrogen --restore`, which the vendored i3 config execs on startup —
  Task 4).

- [ ] **Step 1: Replace the file contents**

```yaml
---
- name: Install base theme packages (Papirus, Kvantum)
  ansible.builtin.apt:
    name: "{{ theme_packages }}"
    state: present

- name: Clone catppuccin-papirus-folders
  ansible.builtin.git:
    repo: https://github.com/catppuccin/papirus-folders.git
    dest: /tmp/catppuccin-papirus-folders
    depth: 1

- name: Install Catppuccin Papirus folder color assets
  ansible.builtin.copy:
    src: /tmp/catppuccin-papirus-folders/src/
    dest: /usr/share/icons/Papirus/
    remote_src: true

- name: Fetch papirus-folders script
  ansible.builtin.get_url:
    url: https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders
    dest: /usr/local/bin/papirus-folders
    mode: "0755"

- name: Set Catppuccin Mocha Mauve Papirus folder color
  ansible.builtin.command: papirus-folders -C cat-mocha-mauve --theme Papirus-Dark

- name: Fetch Catppuccin Mocha Mauve cursor theme
  ansible.builtin.get_url:
    url: https://github.com/catppuccin/cursors/releases/download/v2.0.0/catppuccin-mocha-mauve-cursors.zip
    dest: /tmp/catppuccin-mocha-mauve-cursors.zip
    mode: "0644"

- name: Install Catppuccin Mocha Mauve cursor theme
  ansible.builtin.unarchive:
    src: /tmp/catppuccin-mocha-mauve-cursors.zip
    dest: /usr/share/icons/
    remote_src: true
    creates: /usr/share/icons/catppuccin-mocha-mauve-cursors

- name: Create fonts directory
  ansible.builtin.file:
    path: "{{ ansible_user_dir }}/.local/share/fonts"
    state: directory
    mode: "0755"
  become: false

- name: Fetch CaskaydiaCove Nerd Font
  ansible.builtin.get_url:
    url: https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip
    dest: /tmp/CascadiaCode-nerd-font.zip
    mode: "0644"

- name: Install CaskaydiaCove Nerd Font
  ansible.builtin.unarchive:
    src: /tmp/CascadiaCode-nerd-font.zip
    dest: "{{ ansible_user_dir }}/.local/share/fonts"
    remote_src: true
    creates: "{{ ansible_user_dir }}/.local/share/fonts/CaskaydiaCoveNerdFont-Regular.ttf"
  become: false

- name: Refresh font cache
  ansible.builtin.command: fc-cache -f
  become: false

- name: Fetch a Catppuccin Mocha wallpaper
  ansible.builtin.get_url:
    url: https://raw.githubusercontent.com/catppuccin/wallpapers/main/minimalistic/mocha-4k.png
    dest: /usr/share/wallpapers/catppuccin-mocha.png
    mode: "0644"

- name: Create nitrogen config directory
  ansible.builtin.file:
    path: "{{ ansible_user_dir }}/.config/nitrogen"
    state: directory
    mode: "0755"
  become: false

- name: Seed nitrogen's saved background to the Catppuccin wallpaper
  ansible.builtin.copy:
    dest: "{{ ansible_user_dir }}/.config/nitrogen/bg-saved.cfg"
    content: |
      [xin_-1]
      file=/usr/share/wallpapers/catppuccin-mocha.png
      mode=5
      bgcolor=#1E1E2E
    mode: "0644"
  become: false

- name: Create Kvantum theme directory
  ansible.builtin.file:
    path: "{{ ansible_user_dir }}/.config/Kvantum/catppuccin-mocha-mauve"
    state: directory
    mode: "0755"
  become: false

- name: Fetch Catppuccin Kvantum theme files
  ansible.builtin.get_url:
    url: "https://raw.githubusercontent.com/catppuccin/kvantum/main/themes/catppuccin-mocha-mauve/{{ item }}"
    dest: "{{ ansible_user_dir }}/.config/Kvantum/catppuccin-mocha-mauve/{{ item }}"
    mode: "0644"
  become: false
  loop:
    - catppuccin-mocha-mauve.kvconfig
    - catppuccin-mocha-mauve.svg

- name: Select Catppuccin theme in Kvantum
  community.general.ini_file:
    path: "{{ ansible_user_dir }}/.config/Kvantum/kvantum.kvconfig"
    section: General
    option: theme
    value: catppuccin-mocha-mauve
    mode: "0644"
  become: false

- name: Create qt5ct config directory
  ansible.builtin.file:
    path: "{{ ansible_user_dir }}/.config/qt5ct"
    state: directory
    mode: "0755"
  become: false

- name: Set Kvantum as the qt5ct widget style
  community.general.ini_file:
    path: "{{ ansible_user_dir }}/.config/qt5ct/qt5ct.conf"
    section: Appearance
    option: style
    value: kvantum
    mode: "0644"
  become: false

- name: Create GTK theme directory
  ansible.builtin.file:
    path: "{{ ansible_user_dir }}/.local/share/themes"
    state: directory
    mode: "0755"
  become: false

- name: Fetch Catppuccin GTK theme
  ansible.builtin.get_url:
    url: "https://github.com/catppuccin/gtk/releases/download/v1.0.3/catppuccin-mocha-mauve-standard+default.zip"
    dest: /tmp/catppuccin-mocha-mauve-gtk.zip
    mode: "0644"

- name: Extract Catppuccin GTK theme
  ansible.builtin.unarchive:
    src: /tmp/catppuccin-mocha-mauve-gtk.zip
    dest: "{{ ansible_user_dir }}/.local/share/themes/"
    remote_src: true
    creates: "{{ ansible_user_dir }}/.local/share/themes/catppuccin-mocha-mauve-standard+default"
  become: false

- name: Create GTK settings directories
  ansible.builtin.file:
    path: "{{ ansible_user_dir }}/.config/{{ item }}"
    state: directory
    mode: "0755"
  become: false
  loop:
    - gtk-3.0
    - gtk-4.0

- name: Apply Catppuccin GTK theme to GTK3 apps
  community.general.ini_file:
    path: "{{ ansible_user_dir }}/.config/gtk-3.0/settings.ini"
    section: Settings
    option: gtk-theme-name
    value: catppuccin-mocha-mauve-standard+default
    mode: "0644"
  become: false

- name: Apply Catppuccin GTK theme to GTK4 apps
  community.general.ini_file:
    path: "{{ ansible_user_dir }}/.config/gtk-4.0/settings.ini"
    section: Settings
    option: gtk-theme-name
    value: catppuccin-mocha-mauve-standard+default
    mode: "0644"
  become: false
```

This drops (relative to the pre-rewrite file): the Plasma color-scheme
apply, `plasma-apply-wallpaperimage` (replaced by the nitrogen seed
above), the catppuccin-kde Global Theme install, the `kwriteconfig6`
Kvantum widget-style task (replaced by qt5ct's ini file), the SDDM
Catppuccin theme fetch/install, and the Konsole colorscheme/profile
tasks. It adds the font fetch and the nitrogen wallpaper seed.

- [ ] **Step 2: Syntax-check the role**

Run: `ansible-playbook ansible/site.yml --syntax-check -i ansible/inventory/hosts.ini`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add ansible/roles/theme/tasks/main.yml
git commit -m "Rewrite theme role for i3: drop KDE tasks, add font + wallpaper seed"
```

---

### Task 4: Vendor i3/polybar/rofi/picom/dunst/fastfetch configs into chezmoi

**Files:**
- Create: `chezmoi/dot_config/i3/config`
- Create: `chezmoi/dot_config/polybar/config.ini`
- Create: `chezmoi/dot_config/polybar/executable_launch.sh`
- Create: `chezmoi/dot_config/rofi/config/i3.rasi`
- Create: `chezmoi/dot_config/rofi/config/power.rasi`
- Create: `chezmoi/dot_config/rofi/local/themes/catppuccin-mocha.rasi`
- Create: `chezmoi/dot_config/rofi/local/themes/catppuccin-mocha-powermenu.rasi`
- Create: `chezmoi/dot_local/share/rofi/scripts/executable_rofi-power-menu`
- Create: `chezmoi/dot_config/picom/i3.conf`
- Create: `chezmoi/dot_config/dunst/dunstrc`
- Create: `chezmoi/dot_config/fastfetch/config.jsonc`
- Create: `chezmoi/dot_config/fastfetch/debian-catppuccin.txt`
- Modify: `chezmoi/dot_config/kitty/kitty.conf`

**Interfaces:**
- Produces: the full set of dotfiles `chezmoi apply` (existing
  `ansible/roles/dotfiles` task, unchanged) will symlink/copy into
  `~/.config` and `~/.local/share/rofi` on the target machine.

- [ ] **Step 1: Clone upstream at the pinned commit into a scratch dir**

```bash
git clone --no-checkout https://github.com/vaelixd/i3-dotfiles /tmp/i3-dotfiles-src
git -C /tmp/i3-dotfiles-src checkout 533fa46ba36cd4cfce894a9c56655b82b0412e44
```

- [ ] **Step 2: Copy the small, already-correctly-themed configs as-is**

These already use CaskaydiaCove Nerd Font and Papirus icons (verified
against upstream source — no Tela/JetBrains references in any of
these files), so copy verbatim:

```bash
mkdir -p chezmoi/dot_config/i3 chezmoi/dot_config/polybar \
         chezmoi/dot_config/rofi/config chezmoi/dot_config/rofi/local/themes \
         chezmoi/dot_config/picom chezmoi/dot_local/share/rofi/scripts \
         chezmoi/dot_config/dunst chezmoi/dot_config/fastfetch

cp /tmp/i3-dotfiles-src/i3/config                                    chezmoi/dot_config/i3/config
cp /tmp/i3-dotfiles-src/polybar/config.ini                           chezmoi/dot_config/polybar/config.ini
cp /tmp/i3-dotfiles-src/polybar/launch.sh                            chezmoi/dot_config/polybar/executable_launch.sh
cp /tmp/i3-dotfiles-src/rofi/config/i3.rasi                          chezmoi/dot_config/rofi/config/i3.rasi
cp /tmp/i3-dotfiles-src/rofi/config/power.rasi                       chezmoi/dot_config/rofi/config/power.rasi
cp /tmp/i3-dotfiles-src/rofi/local/themes/catppuccin-mocha.rasi      chezmoi/dot_config/rofi/local/themes/catppuccin-mocha.rasi
cp /tmp/i3-dotfiles-src/rofi/local/themes/catppuccin-mocha-powermenu.rasi chezmoi/dot_config/rofi/local/themes/catppuccin-mocha-powermenu.rasi
cp /tmp/i3-dotfiles-src/rofi/local/scripts/rofi-power-menu            chezmoi/dot_local/share/rofi/scripts/executable_rofi-power-menu
cp /tmp/i3-dotfiles-src/picom/i3.conf                                 chezmoi/dot_config/picom/i3.conf
cp /tmp/i3-dotfiles-src/dunst/dunstrc                                 chezmoi/dot_config/dunst/dunstrc
cp /tmp/i3-dotfiles-src/fastfetch/config.jsonc                        chezmoi/dot_config/fastfetch/config.jsonc

chmod +x chezmoi/dot_config/polybar/executable_launch.sh chezmoi/dot_local/share/rofi/scripts/executable_rofi-power-menu
```

- [ ] **Step 3: Add tray-app autostart lines to `i3/config` — upstream never execs nm-applet/blueman/a polkit agent, so Polybar's tray module would sit empty and GUI polkit prompts would never appear**

Edit `chezmoi/dot_config/i3/config`, changing the exec block from:

```
exec --no-startup-id dex --autostart --environment i3

exec --no-startup-id setxkbmap -layout us,gb -option grp:alt_shift_toggle &
exec --no-startup-id dunst &
exec --no-startup-id ~/.config/polybar/launch.sh &
exec --no-startup-id nitrogen --restore &
exec --no-startup-id picom --config ~/.config/picom/i3.conf &
exec --no-startup-id flameshot &
```
to:
```
exec --no-startup-id dex --autostart --environment i3

exec --no-startup-id setxkbmap -layout us,gb -option grp:alt_shift_toggle &
exec --no-startup-id dunst &
exec --no-startup-id ~/.config/polybar/launch.sh &
exec --no-startup-id nitrogen --restore &
exec --no-startup-id picom --config ~/.config/picom/i3.conf &
exec --no-startup-id flameshot &
exec --no-startup-id nm-applet &
exec --no-startup-id blueman-applet &
exec --no-startup-id /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &
```

- [ ] **Step 4: Retexture `dunstrc` — Tela icons to Papirus-Dark**

Edit `chezmoi/dot_config/dunst/dunstrc`, changing:

```
icon_theme = "Tela-circle-dracula"
```
to:
```
icon_theme = "Papirus-Dark"
```

and changing the `icon_path` line from:

```
icon_path = /home/dds/.icons/Tela-circle-dracula/16/actions:/home/dds/.icons/Tela-circle-dracula/16/apps:/home/dds/.icons/Tela-circle-dracula/16/devices:/home/dds/.icons/Tela-circle-dracula/16/mimetypes:/home/dds/.icons/Tela-circle-dracula/16/panel:/home/dds/.icons/Tela-circle-dracula/16/places:/home/dds/.icons/Tela-circle-dracula/16/status
```
to:
```
icon_path = /usr/share/icons/Papirus-Dark/16x16/actions:/usr/share/icons/Papirus-Dark/16x16/apps:/usr/share/icons/Papirus-Dark/16x16/devices:/usr/share/icons/Papirus-Dark/16x16/mimetypes:/usr/share/icons/Papirus-Dark/16x16/panel:/usr/share/icons/Papirus-Dark/16x16/places:/usr/share/icons/Papirus-Dark/16x16/status
```

- [ ] **Step 5: Give fastfetch a custom Catppuccin/Debian logo instead of upstream's Arch ASCII**

Create `chezmoi/dot_config/fastfetch/debian-catppuccin.txt`:

```
${c1}    _,met$$$$$gg.
${c1} ,g$$$$$$$$$$$$$$$P.
${c1}$$$$P(     )$4$$$$$$
${c1}'$$$$U         `$$$$b
${c1}$$$$'   ${c2}mauve${c1}    `$$$$
${c1}$$$P    ${c2}mocha${c1}     $$$$
${c1}.$$$'                `$$$$$$
${c1}:$$$'    ${c2}i3${c1}         `$$$$.
${c1}::$$    ${c2}rocks${c1}         `$$$;
${c1}:$$    ${c2}debian${c1}          `$$$;
${c1};$$:                  :$$;
${c1}:$$;                 ;$$;
${c1} $$$    ${c2}o o o${c1}      $$$
${c1} `$$b           d$'
${c1}  `$$$$agg_______gg$$$$'
${c1}   `<$$$$$$$$$$$$$P'
```

Edit `chezmoi/dot_config/fastfetch/config.jsonc`, changing the `logo`
block from:

```jsonc
  "logo": {
    "source": "~/.config/fastfetch/arch.txt",
    "type": "file",
    "color": {
      "1": "blue",
    },
  },
```
to:
```jsonc
  "logo": {
    "source": "~/.config/fastfetch/debian-catppuccin.txt",
    "type": "file",
    "color": {
      "1": "magenta",
      "2": "cyan",
    },
  },
```

- [ ] **Step 6: Update kitty's font to match (remove last JetBrains reference)**

Edit `chezmoi/dot_config/kitty/kitty.conf`, changing:

```
font_family      JetBrainsMono Nerd Font
```
to:
```
font_family      CaskaydiaCove Nerd Font
```

- [ ] **Step 7: Confirm no JetBrains/Tela references remain in vendored files**

Run: `grep -ril "jetbrains\|tela" chezmoi/`
Expected: no output (empty match set).

- [ ] **Step 8: Dry-run chezmoi to confirm the source state is valid**

Run: `chezmoi --source chezmoi execute-template < /dev/null` (validates
templating doesn't choke on the new files) and
`chezmoi --source chezmoi apply --dry-run --verbose`
Expected: no errors; dry-run output lists the new files it would create.

- [ ] **Step 9: Commit**

```bash
git add chezmoi/dot_config/i3 chezmoi/dot_config/polybar chezmoi/dot_config/rofi \
        chezmoi/dot_local chezmoi/dot_config/picom chezmoi/dot_config/dunst \
        chezmoi/dot_config/fastfetch chezmoi/dot_config/kitty/kitty.conf
git commit -m "Vendor i3/polybar/rofi/picom/dunst/fastfetch configs from i3-dotfiles@533fa46"
```

---

### Task 5: Vendor Neovim and Yazi configs into chezmoi

**Files:**
- Create: `chezmoi/dot_config/nvim/` (full tree from upstream)
- Create: `chezmoi/dot_config/yazi/` (full tree from upstream, including
  the `catppuccin-mocha.yazi` flavor)

**Interfaces:**
- Consumes: `/tmp/i3-dotfiles-src` cloned in Task 4 Step 1 (re-clone
  here if working in a fresh session/subagent).
- Produces: nothing else depends on these — Neovim and Yazi are
  self-contained editor/file-manager configs, no theme-role coupling.

Both trees are upstream-authored application configs (kickstart.nvim
fork, Yazi with its own flavor system) with no JetBrains/Tela
references — Yazi's `theme.toml` already selects `catppuccin-mocha`
(verified against upstream source), so this is a straight copy, not a
retexture.

- [ ] **Step 1: Re-clone if needed**

```bash
test -d /tmp/i3-dotfiles-src || {
  git clone --no-checkout https://github.com/vaelixd/i3-dotfiles /tmp/i3-dotfiles-src
  git -C /tmp/i3-dotfiles-src checkout 533fa46ba36cd4cfce894a9c56655b82b0412e44
}
```

- [ ] **Step 2: Copy the trees**

```bash
mkdir -p chezmoi/dot_config/nvim chezmoi/dot_config/yazi
cp -r /tmp/i3-dotfiles-src/nvim/.  chezmoi/dot_config/nvim/
cp -r /tmp/i3-dotfiles-src/yazi/.  chezmoi/dot_config/yazi/
rm -rf chezmoi/dot_config/nvim/assets chezmoi/dot_config/nvim/README.md
```

(Drop the nvim README/screenshot assets — they're upstream marketing
material, not config; keeping them adds binary PNGs to this dotfiles
repo for no reason.)

- [ ] **Step 3: Confirm no JetBrains/Tela references leaked in**

Run: `grep -ril "jetbrains\|tela-circle" chezmoi/dot_config/nvim chezmoi/dot_config/yazi`
Expected: no output.

- [ ] **Step 4: Dry-run chezmoi again with the full new tree**

Run: `chezmoi --source chezmoi apply --dry-run --verbose`
Expected: no errors; lists nvim/yazi files it would create.

- [ ] **Step 5: Commit**

```bash
git add chezmoi/dot_config/nvim chezmoi/dot_config/yazi
git commit -m "Vendor Neovim and Yazi configs from i3-dotfiles@533fa46"
```

---

### Task 6: Clean up stale references (README, packages.yml comments, chrome/vscode/apt_repos if KDE-coupled)

**Files:**
- Modify: `README.md`
- Modify: `ansible/group_vars/all/packages.yml` (comment cleanup only)

**Interfaces:** none — documentation/comment-only task.

- [ ] **Step 1: Update `README.md`'s stack description**

Change:

```
Debian + KDE Plasma 6, Catppuccin Mocha, TUI-first. Ansible-orchestrated,
chezmoi-linked. See `docs/superpowers/specs/2026-08-14-ansible-dotfiles-rebuild-design.md`
for the design, `docs/superpowers/plans/2026-08-14-ansible-dotfiles-rebuild.md`
for the build-out plan.
```
to:
```
Debian + i3, Catppuccin Mocha Mauve, TUI-first. Ansible-orchestrated,
chezmoi-linked. See `docs/superpowers/specs/2026-08-14-ansible-dotfiles-rebuild-design.md`
and `docs/superpowers/specs/2026-08-15-i3-ricing-rebuild-design.md` for
the design, `docs/superpowers/plans/2026-08-14-ansible-dotfiles-rebuild.md`
and `docs/superpowers/plans/2026-08-15-i3-ricing-rebuild.md` for the
build-out plans.
```

- [ ] **Step 2: Check `github_release_binaries` manual-install comment block for stale KDE mentions**

Run: `grep -n "catppuccin-cursors\|catppuccin-papirus-folders" ansible/group_vars/all/packages.yml`

These two are still accurate (cursor/Papirus theming is unchanged by
this plan) — leave as-is. If the grep surfaces any other Plasma-only
tool left over, remove that line; otherwise no change needed here.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "Update README for i3 desktop stack"
```

---

### Task 7: Repo-wide sanity sweep

**Files:** none created/modified unless the sweep finds something.

**Interfaces:** none.

- [ ] **Step 1: Confirm no leftover Plasma/KDE/SDDM/Konsole/KWin references outside of the two design-spec history docs**

```bash
grep -rIl "plasma\|kwin\|sddm\|konsole\|kde-config\|kpackagetool\|kwriteconfig\|bismuth\|polonium" \
  --exclude-dir=.git --exclude-dir=docs .
```

Expected: no output. (`docs/superpowers/specs/` and `plans/` are
excluded implicitly — they're historical design records, not live
config, and should keep the old KDE-era file for context; if the grep
command above still matches inside `docs/`, that's fine and expected —
only investigate matches outside `docs/`.)

- [ ] **Step 2: Confirm no leftover JetBrains/Tela references anywhere live**

```bash
grep -rIl "jetbrains\|tela-circle\|tela circle" --exclude-dir=.git --exclude-dir=docs .
```

Expected: no output.

- [ ] **Step 3: Full ansible syntax + chezmoi dry-run pass**

```bash
ansible-playbook ansible/site.yml --syntax-check -i ansible/inventory/hosts.ini
chezmoi --source chezmoi apply --dry-run --verbose
```

Expected: both succeed with no errors.

- [ ] **Step 4: Fix anything the sweep surfaces, then commit if changes were needed**

```bash
git add -A
git commit -m "Sweep: remove residual KDE/JetBrains references"
```

(Skip this commit if Steps 1-3 found nothing to fix.)

---

### Task 8: Live verification checkpoint (user-in-the-loop, not automatable)

**Files:** none.

**Interfaces:** none.

This task cannot be done by an agent alone — it requires an actual
reboot/login on the target machine. Per `verification-before-completion`,
do not claim this plan complete until this checkpoint has actually run.

- [ ] **Step 1: Ask the user to run the real apply**

Tell the user: run `cd ansible && ansible-playbook site.yml
--ask-become-pass` on the target machine (or a VM/snapshot first, if
they'd rather not risk the live session), then log out and select the
i3 session from LightDM's session picker.

- [ ] **Step 2: Ask the user to confirm, one at a time:**

- LightDM shows a session and login works
- i3 starts; Polybar bar is visible with a tray, Dunst delivers a test
  notification (`notify-send test`), Picom's shadows/transparency are
  active
- Rofi launcher (`$mod+a`) and power menu (`$mod` + whatever `$logout`
  is bound to) both open
- kitty and fastfetch show CaskaydiaCove Nerd Font; fastfetch shows the
  custom Debian/Catppuccin logo, not Arch's
  - GTK and Qt apps (e.g. Thunar and a Kvantum-styled Qt app) render
    Catppuccin Mocha Mauve
- `nvim` opens without plugin/config errors
- nm-applet and blueman tray icons appear in the Polybar tray

- [ ] **Step 3: If anything fails, fix it in a follow-up commit (not an amend) and re-verify before calling the branch done.**
