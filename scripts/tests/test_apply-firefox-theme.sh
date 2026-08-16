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

# Fake firefox on PATH (no-op — only used for the cold-start branch, not
# exercised by this test since we pre-seed profiles.ini below)
mkdir -p "$tmp/bin"
cat > "$tmp/bin/firefox" <<'FAKE'
#!/usr/bin/env bash
exit 0
FAKE
chmod +x "$tmp/bin/firefox"

# Fake $HOME with a pre-existing profiles.ini (Profile0 is Default=1)
fake_home="$tmp/home"
mkdir -p "$fake_home/.mozilla/firefox/Profiles/wxyz5678.default"
cat > "$fake_home/.mozilla/firefox/profiles.ini" <<'EOF'
[Profile1]
Name=default-release
IsRelative=1
Path=Profiles/abcd1234.default-release

[Profile0]
Name=default
IsRelative=1
Path=Profiles/wxyz5678.default
Default=1
EOF

HOME="$fake_home" PATH="$tmp/bin:$PATH" "$tmp/repo/scripts/apply-firefox-theme.sh"

chrome_css="$fake_home/.mozilla/firefox/Profiles/wxyz5678.default/chrome/userChrome.css"
user_js="$fake_home/.mozilla/firefox/Profiles/wxyz5678.default/user.js"

if [[ ! -f "$chrome_css" ]]; then
    echo "FAIL: $chrome_css was not created" >&2
    exit 1
fi
if [[ ! -f "$user_js" ]]; then
    echo "FAIL: $user_js was not created" >&2
    exit 1
fi

# Re-run to confirm idempotency (no error, files still present)
HOME="$fake_home" PATH="$tmp/bin:$PATH" "$tmp/repo/scripts/apply-firefox-theme.sh"
[[ -f "$chrome_css" ]] || { echo "FAIL: not idempotent"; exit 1; }

echo "PASS"
