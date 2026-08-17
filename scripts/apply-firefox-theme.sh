#!/usr/bin/env bash
set -euo pipefail

# Installs Monokai Pro's userChrome.css + the enabling user.js pref into
# Firefox's default profile. Profile directories have a randomized name
# (e.g. .../firefox/xxxxxxxx.default-release/), so this can't be a static
# dotfiles/ symlink target — profiles.ini has to be parsed at install time.
#
# Where that profile lives depends on the Firefox build: some still use the
# legacy ~/.mozilla/firefox, but this repo's (153.0.4, CachyOS's package) is
# XDG-compliant and uses ${XDG_CONFIG_HOME:-~/.config}/mozilla/firefox —
# confirmed directly (a -CreateProfile run left ~/.mozilla untouched and
# wrote profiles.ini under the XDG path instead). Checking XDG first with a
# fallback to the legacy path covers both without needing a version check.
#
# Idempotent: re-running just re-copies the same source files (backing up
# a differing destination once as .bak).

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
firefox_dir="${XDG_CONFIG_HOME:-$HOME/.config}/mozilla/firefox"
legacy_firefox_dir="$HOME/.mozilla/firefox"
ini="$firefox_dir/profiles.ini"

if ! command -v firefox >/dev/null 2>&1; then
    echo "error: firefox not found (expected from packages/pacman.txt)" >&2
    exit 1
fi

if [[ ! -f "$ini" && -f "$legacy_firefox_dir/profiles.ini" ]]; then
    firefox_dir="$legacy_firefox_dir"
    ini="$firefox_dir/profiles.ini"
fi

if [[ ! -f "$ini" ]]; then
    echo "==> no Firefox profile yet, creating one"
    # -headless: a fresh install must not flash a browser window during an
    # unattended run. Verified directly against this Firefox build: this
    # exact invocation writes profiles.ini and the profile dir immediately.
    firefox -CreateProfile default-release -no-remote -headless
fi

if [[ ! -f "$ini" ]]; then
    echo "error: profiles.ini still missing after -CreateProfile in both" \
         "$firefox_dir and $legacy_firefox_dir" >&2
    exit 1
fi

rel_path="$(awk -F= '
    /^\[Profile/ { in_profile=1; default_here=0; path=""; next }
    /^\[/        { in_profile=0; next }
    in_profile && /^Default=1/ { default_here=1 }
    in_profile && /^Path=/     { path=$2 }
    default_here && path       { print path; exit }
' "$ini")"

# Fallback: newer Firefox (67+) tracks the default profile per-install via an
# [InstallXXXXXXXXXXXXXXXX] section whose Default= value is the path itself,
# not a Default=1 flag on the [ProfileN] block above — some fresh profiles
# only have this form.
if [[ -z "$rel_path" ]]; then
    rel_path="$(awk -F= '
        /^\[Install/ { in_install=1; next }
        /^\[/        { in_install=0; next }
        in_install && /^Default=/ { print $2; exit }
    ' "$ini")"
fi

if [[ -z "$rel_path" ]]; then
    echo "error: could not find a default profile (neither [ProfileN] Default=1" \
         "nor [InstallXXXX] Default=<path>) in $ini" >&2
    exit 1
fi

profile_dir="$firefox_dir/$rel_path"
chrome_dir="$profile_dir/chrome"
mkdir -p "$chrome_dir"

for pair in "userChrome.css:$chrome_dir/userChrome.css" "user.js:$profile_dir/user.js"; do
    src_name="${pair%%:*}"
    dest="${pair#*:}"
    src="$repo_root/firefox/$src_name"

    if [[ -e "$dest" ]] && ! cmp -s "$src" "$dest"; then
        cp "$dest" "$dest.bak"
    fi
    cp "$src" "$dest"
done

echo "==> Monokai Pro userChrome.css applied to profile: $rel_path"
echo "==> restart Firefox for the theme to take effect"
