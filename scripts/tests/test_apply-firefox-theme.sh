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

# Second scenario: a profiles.ini with only the newer [InstallXXXX]
# Default=<path> form, no Default=1 on any [ProfileN] block — the fallback
# path this test guards against regressing.
fake_home2="$tmp/home2"
mkdir -p "$fake_home2/.mozilla/firefox/Profiles/install-default.default-release"
cat > "$fake_home2/.mozilla/firefox/profiles.ini" <<'EOF'
[Profile0]
Name=default-release
IsRelative=1
Path=Profiles/install-default.default-release

[Install4696BAC38E282B08]
Default=Profiles/install-default.default-release
Locked=1
EOF

HOME="$fake_home2" PATH="$tmp/bin:$PATH" "$tmp/repo/scripts/apply-firefox-theme.sh"

chrome_css2="$fake_home2/.mozilla/firefox/Profiles/install-default.default-release/chrome/userChrome.css"
if [[ ! -f "$chrome_css2" ]]; then
    echo "FAIL: $chrome_css2 was not created (Install-section fallback)" >&2
    exit 1
fi

echo "PASS"
