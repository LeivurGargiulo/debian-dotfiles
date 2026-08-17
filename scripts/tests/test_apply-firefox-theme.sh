#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Fake repo layout
mkdir -p "$tmp/repo/scripts" "$tmp/repo/firefox"
script_under_test="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/apply-firefox-theme.sh"
cp "$script_under_test" "$tmp/repo/scripts/apply-firefox-theme.sh"
chmod +x "$tmp/repo/scripts/apply-firefox-theme.sh"
echo "/* fake userChrome.css */" > "$tmp/repo/firefox/userChrome.css"
echo 'user_pref("fake", true);' > "$tmp/repo/firefox/user.js"

# Fake firefox on PATH (no-op — only used for the cold-start branch)
mkdir -p "$tmp/bin"
cat > "$tmp/bin/firefox" <<'FAKE'
#!/usr/bin/env bash
exit 0
FAKE
chmod +x "$tmp/bin/firefox"

# Every scenario below sets HOME *and* XDG_CONFIG_HOME/XDG_CACHE_HOME
# explicitly. The script resolves the profile directory from
# ${XDG_CONFIG_HOME:-$HOME/.config} — leaving XDG_CONFIG_HOME unset in a test
# lets it leak in from the real environment instead of defaulting off the
# fake $HOME, which is exactly the bug that let an early manual test of this
# fix read and write a real profile under the actual account.
run() {
    local home="$1"
    HOME="$home" XDG_CONFIG_HOME="$home/.config" XDG_CACHE_HOME="$home/.cache" \
        PATH="$tmp/bin:$PATH" "$tmp/repo/scripts/apply-firefox-theme.sh"
}

# --- Scenario 1: modern XDG layout (this repo's real Firefox, 153.0.4) ----
# Confirmed directly against the real binary: -CreateProfile writes
# profiles.ini under ${XDG_CONFIG_HOME:-~/.config}/mozilla/firefox, not the
# legacy ~/.mozilla/firefox — a run that only ever checked the legacy path
# reported "no Firefox profile yet" forever on a fresh install and failed.
fake_home="$tmp/home"
mkdir -p "$fake_home/.config/mozilla/firefox/wxyz5678.default"
cat > "$fake_home/.config/mozilla/firefox/profiles.ini" <<'EOF'
[Profile1]
Name=default-release
IsRelative=1
Path=abcd1234.default-release

[Profile0]
Name=default
IsRelative=1
Path=wxyz5678.default
Default=1
EOF

run "$fake_home"

chrome_css="$fake_home/.config/mozilla/firefox/wxyz5678.default/chrome/userChrome.css"
user_js="$fake_home/.config/mozilla/firefox/wxyz5678.default/user.js"

if [[ ! -f "$chrome_css" ]]; then
    echo "FAIL: $chrome_css was not created (XDG profile path)" >&2
    exit 1
fi
if [[ ! -f "$user_js" ]]; then
    echo "FAIL: $user_js was not created (XDG profile path)" >&2
    exit 1
fi

# Re-run to confirm idempotency (no error, files still present)
run "$fake_home"
[[ -f "$chrome_css" ]] || { echo "FAIL: not idempotent"; exit 1; }

# --- Scenario 2: [InstallXXXX] Default=<path> fallback, still under XDG ---
fake_home2="$tmp/home2"
mkdir -p "$fake_home2/.config/mozilla/firefox/install-default.default-release"
cat > "$fake_home2/.config/mozilla/firefox/profiles.ini" <<'EOF'
[Profile0]
Name=default-release
IsRelative=1
Path=install-default.default-release

[Install4696BAC38E282B08]
Default=install-default.default-release
Locked=1
EOF

run "$fake_home2"

chrome_css2="$fake_home2/.config/mozilla/firefox/install-default.default-release/chrome/userChrome.css"
if [[ ! -f "$chrome_css2" ]]; then
    echo "FAIL: $chrome_css2 was not created (Install-section fallback, XDG path)" >&2
    exit 1
fi

# --- Scenario 3: legacy ~/.mozilla/firefox (older/non-XDG Firefox builds) -
# No ~/.config/mozilla/firefox/profiles.ini at all — only the pre-XDG path.
fake_home3="$tmp/home3"
mkdir -p "$fake_home3/.mozilla/firefox/legacy1234.default-release"
cat > "$fake_home3/.mozilla/firefox/profiles.ini" <<'EOF'
[Profile0]
Name=default-release
IsRelative=1
Path=legacy1234.default-release
Default=1
EOF

run "$fake_home3"

chrome_css3="$fake_home3/.mozilla/firefox/legacy1234.default-release/chrome/userChrome.css"
if [[ ! -f "$chrome_css3" ]]; then
    echo "FAIL: $chrome_css3 was not created (legacy ~/.mozilla fallback)" >&2
    exit 1
fi

# --- Scenario 4: no profile anywhere — cold start goes through -CreateProfile
fake_home4="$tmp/home4"
mkdir -p "$fake_home4"
cat > "$tmp/bin/firefox" <<FAKE
#!/usr/bin/env bash
# Stand in for a real -CreateProfile run: write profiles.ini under the XDG
# path, matching what the real binary does on this Firefox build.
if [[ " \$* " == *" -CreateProfile "* ]]; then
    mkdir -p "$fake_home4/.config/mozilla/firefox/coldstart.default-release"
    cat > "$fake_home4/.config/mozilla/firefox/profiles.ini" <<'EOF'
[Profile0]
Name=default-release
IsRelative=1
Path=coldstart.default-release
Default=1
EOF
fi
exit 0
FAKE
chmod +x "$tmp/bin/firefox"

run "$fake_home4"

chrome_css4="$fake_home4/.config/mozilla/firefox/coldstart.default-release/chrome/userChrome.css"
if [[ ! -f "$chrome_css4" ]]; then
    echo "FAIL: $chrome_css4 was not created (cold-start -CreateProfile path)" >&2
    exit 1
fi

echo "PASS"
