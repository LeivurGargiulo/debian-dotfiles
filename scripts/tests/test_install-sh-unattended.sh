#!/usr/bin/env bash
set -euo pipefail

# Regression tests for the failure that left a real CachyOS install on a bare
# TTY: install.sh died on one unbuildable AUR package before HyDE's installer
# ever ran, and every prompt that would have explained why was swallowed by
# the log wrapper.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
install_sh="$repo_root/install.sh"

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

# --- 1. rustup gets a default toolchain before anything builds from the AUR ---
# Without this, rustup's shims shadow the system rustc/cargo and refuse to run,
# which is what broke journalview (exit status 4).
grep -q 'rustup default stable' "$install_sh" ||
    fail "install.sh never runs 'rustup default stable'"

rust_line="$(grep -n 'rustup default stable' "$install_sh" | head -1 | cut -d: -f1)"
aur_line="$(grep -n 'packages/aur.txt" | yay' "$install_sh" | head -1 | cut -d: -f1)"
[[ -n "$rust_line" && -n "$aur_line" ]] ||
    fail "could not locate the rustup and AUR steps"
(( rust_line < aur_line )) ||
    fail "rustup default is set at line $rust_line, after the AUR step at line $aur_line"

# --- 2. a failed AUR package must not abort the run before HyDE installs ---
grep -q 'aur_failed=1' "$install_sh" ||
    fail "the AUR step is still fatal; one bad package will again cost the desktop"

hyde_line="$(grep -n 'vendor/hyde/Scripts" && ./install.sh' "$install_sh" | head -1 | cut -d: -f1)"
[[ -n "$hyde_line" ]] || fail "could not locate the HyDE installer step"
(( aur_line < hyde_line )) ||
    fail "AUR step is not above the HyDE step; the ordering assumption changed"

# --- 3. HyDE's installer is fed an endless stream of blank lines ---
# Its sddm-theme and reboot prompts are plain reads whose defaults come from
# a bare Enter, so that's what stdin must supply. This must NOT be /dev/null
# (EOF): a layer deeper, HyDE's own dependency installer (deez) shells out to
# bare "sudo pacman -S <pkg>" with no --noconfirm for anything it finds
# missing, and EOF fails that confirmation prompt outright — which is how a
# real run silently ended up without sddm installed at all while deez logged
# it as a mere warning and still reported success.
grep -q 'vendor/hyde/Scripts" && ./install.sh < <(yes '"''"')' "$install_sh" ||
    fail "HyDE's installer is not fed blank lines via stdin (regression: deez's un-noconfirmed pacman prompts get starved by /dev/null, silently dropping packages like sddm)"

# It must never be `yes` (bare "y") — the closing prompt is "reboot now? [y/N]",
# and a literal "y" answer would talk an unattended run into rebooting itself.
if grep -qE '< <\(yes\)' "$install_sh" || grep -qE "echo\s+y\s*\|.*install\.sh" "$install_sh"; then
    fail "HyDE's installer is fed literal 'y' answers — this would auto-confirm the reboot prompt"
fi

# --- 3b. a stale sudo ticket must not silently break a long run ---
# The cursor theme build alone takes several minutes; combined with AUR
# builds a run can outlast the default 15-minute sudo ticket, right as deez's
# un-noconfirmed pacman calls need it.
grep -q "sudo -n true" "$install_sh" ||
    fail "no sudo keepalive around the HyDE installer step; a long run risks a stale sudo ticket"

# --- 4. the two timed prompts are pre-answered ---
grep -q 'export myShell=' "$install_sh" ||
    fail "myShell is not pre-set; HyDE will stall 120s on its shell prompt"
grep -q 'chaotic-aur' "$install_sh" ||
    fail "nothing declines Chaotic-AUR; HyDE's prompt defaults to installing it"

# --- 5. the log wrapper must flush partial lines (prompts have no newline) ---
# Run the real wrapper and check an unterminated prompt still reaches the log.
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

sed -n '/^exec > >(/,/^) 2>&1$/p' "$install_sh" > "$tmp_dir/wrapper.inc"
[[ -s "$tmp_dir/wrapper.inc" ]] || fail "could not extract the log wrapper from install.sh"

cat > "$tmp_dir/probe.sh" <<PROBE
#!/usr/bin/env bash
set -euo pipefail
log_file="$tmp_dir/probe.log"
: > "\$log_file"
$(cat "$tmp_dir/wrapper.inc")
echo "a complete line"
printf ' :: a prompt with no trailing newline : '
sleep 2
echo ""
PROBE

timeout 30 bash "$tmp_dir/probe.sh" >/dev/null 2>&1 ||
    fail "the log wrapper did not terminate cleanly"

grep -q 'a complete line' "$tmp_dir/probe.log" ||
    fail "the log wrapper dropped a complete line"
grep -q 'a prompt with no trailing newline' "$tmp_dir/probe.log" ||
    fail "the log wrapper swallowed an unterminated prompt — a stalled run will look like a hang again"

# --- 6. the run cleans up after itself, but never the log ------------------
grep -q '==> cleaning up build caches' "$install_sh" ||
    fail "install.sh no longer has a cleanup step"

# The log is the record of the run; nothing may delete it.
if grep -nE '\brm\b[^|;&]*(\$log_file|install\.log)' "$install_sh"; then
    fail "install.sh deletes its own log"
fi
grep -q 'install.log is deliberately NOT touched' "$install_sh" ||
    fail "the note explaining that install.log survives cleanup is gone"

# ~/.cargo/bin holds `cargo install` binaries and must survive; only the
# download/build caches under ~/.cargo may be removed.
if grep -qE 'rm -rf[^\n]*\$HOME/\.cargo"' "$install_sh" ||
   grep -qE 'rm -rf[^\n]*\.cargo/bin' "$install_sh"; then
    fail "cleanup would remove ~/.cargo/bin or all of ~/.cargo"
fi

# Cache cleanup must be skipped when AUR builds failed — those cached sources
# are what make the retry fast.
grep -q 'if (( aur_failed )); then' "$install_sh" ||
    fail "cache cleanup is not gated on the AUR step succeeding"

# The scratch root must be removed however the script ends, including the
# paths that never reach the cleanup step. Exercise the real trap wiring.
grep -q 'cleanup_scratch' "$install_sh" ||
    fail "install.sh has no scratch-directory cleanup"

# Defining the function is not enough — it has to be called from the EXIT
# trap, which is the only thing that runs on every way out of the script.
exit_trap="$(grep -E "^trap '.*' EXIT\$" "$install_sh" | head -1)"
[[ -n "$exit_trap" ]] || fail "install.sh has no EXIT trap"
[[ "$exit_trap" == *cleanup_scratch* ]] ||
    fail "cleanup_scratch is defined but never called from the EXIT trap"

for mode in success failure early; do
    # Use install.sh's real EXIT trap, so rewiring it breaks this test.
    cat > "$tmp_dir/scratch.sh" <<SCRATCH
#!/usr/bin/env bash
set -euo pipefail
log_file="$tmp_dir/unused.log"
$(grep -A4 '^scratch_dir="\$(mktemp -d)"' "$install_sh")
${exit_trap}
echo "\$scratch_dir" > "$tmp_dir/ref"
mkdir -p "\$scratch_dir/work" && echo payload > "\$scratch_dir/work/f"
case "$mode" in
    failure) false ;;
    early)   exit 1 ;;
esac
SCRATCH
    bash "$tmp_dir/scratch.sh" >/dev/null 2>&1 || true
    ref="$(cat "$tmp_dir/ref")"
    [[ -n "$ref" ]] || fail "scratch probe ($mode) never recorded a directory"
    [[ -d "$ref" ]] && fail "scratch directory leaked on the '$mode' path: $ref"
done

# --- 7. blank-line stdin resolves every remaining prompt shape correctly --
# Exercise the exact `< <(yes '')` construct against the two prompt shapes
# this chain actually contains: a bare `read` defaulting on empty input
# (HyDE's sddm-theme picker, its reboot confirm), and a [Y/n]-vs-[y/N]-style
# confirm. A blank line must proceed the [Y/n] case and decline the [y/N]
# case — that asymmetry is exactly what keeps an unattended run from talking
# itself into an unwanted reboot.
cat > "$tmp_dir/prompts.sh" <<'PROBE'
#!/usr/bin/env bash
set -euo pipefail
read -r -p "sddm theme option: " opt
case "$opt" in
    1) theme="Candy" ;;
    2) theme="Corners" ;;
    *) theme="Corners" ;;
esac
echo "theme=$theme"

read -r -p "Proceed with installation? [Y/n] " proceed
if [[ -z "$proceed" || "$proceed" =~ ^[Yy] ]]; then
    echo "proceed=yes"
else
    echo "proceed=no"
fi

read -r -p "reboot now? [y/N] " answer
if [[ "$answer" == [Yy] ]]; then
    echo "reboot=yes"
else
    echo "reboot=no"
fi
PROBE

out="$(bash "$tmp_dir/prompts.sh" < <(yes ''))"
echo "$out" | grep -q '^theme=Corners$' ||
    fail "blank-line stdin did not fall through to the Corners default"
echo "$out" | grep -q '^proceed=yes$' ||
    fail "blank-line stdin did not proceed past a [Y/n] prompt — deez's pacman installs would fail again"
echo "$out" | grep -q '^reboot=no$' ||
    fail "blank-line stdin answered the reboot prompt — an unattended run must never reboot itself"

# --- 8. pipewire-jack is installed before it can conflict with jack2 ------
# packages/pacman.txt pulls in ffmpeg/mpv/cava, which need a JACK
# implementation; left to --needed --noconfirm, pacman picks jack2. HyDE's
# core deps require pipewire-jack, which conflicts with jack2 outright
# (confirmed via `pacman -Si`: both provide the same jack/libjack.so, and
# pipewire-jack lists jack2 under Conflicts With). That conflict aborts
# HyDE's entire core-deps transaction as one unit — a real run reported
# sddm, hyprland, waybar, rofi and dunst all "missing" simultaneously from
# a single unresolved jack2 conflict. Neither --noconfirm nor a blank-line
# stdin changes the prompt's default (both take the same N-by-default
# "unresolvable package conflicts detected" failure) — it has to be
# answered "y" explicitly, and only for this one command.
grep -q 'pipewire-jack' "$install_sh" ||
    fail "install.sh no longer installs pipewire-jack ahead of jack2"

pw_line="$(grep -n "pacman -S --needed pipewire-jack" "$install_sh" | head -1 | cut -d: -f1)"
pacman_txt_line="$(grep -n 'packages/pacman.txt" | sudo pacman' "$install_sh" | head -1 | cut -d: -f1)"
[[ -n "$pw_line" && -n "$pacman_txt_line" ]] ||
    fail "could not locate the pipewire-jack step or the pacman.txt install step"
(( pw_line < pacman_txt_line )) ||
    fail "pipewire-jack is installed at line $pw_line, after packages/pacman.txt at line $pacman_txt_line — too late to stop jack2 from being pulled in first"

# The line installing pipewire-jack must itself answer "y" (a scoped `yes |`,
# not the run-wide blank-line stream) — a blank line takes the prompt's own
# N default and reproduces the exact same conflict failure.
pw_full_line="$(sed -n "${pw_line}p" "$install_sh")"
[[ "$pw_full_line" == *"yes |"* ]] ||
    fail "the pipewire-jack install doesn't answer its conflict prompt with 'y' — it will hit the same jack2 conflict"

# --- 9. the pipewire-jack install doesn't false-fail on yes's own SIGPIPE -
# `yes | sudo pacman -S --needed pipewire-jack` succeeds in practice —
# pacman reads the one line it needs to confirm the jack2 conflict, then
# exits. `yes` is still writing to a now-closed pipe at that point, gets
# SIGPIPE, and exits 141. Under `set -o pipefail` (on for the whole script)
# that 141 becomes the *pipeline's* exit status even though pacman itself
# succeeded — confirmed live: a real run installed pipewire-jack and removed
# jack2 correctly, then still reported "FAILED (exit 141)" and aborted.
# pipefail must be turned off for just that one line.
pw_block="$(sed -n '/if ! pacman -Qq pipewire-jack/,/^fi$/p' "$install_sh")"
[[ -n "$pw_block" ]] || fail "could not locate the pipewire-jack install block"
echo "$pw_block" | grep -q '^\s*set +o pipefail\s*$' ||
    fail "the pipewire-jack install doesn't disable pipefail — yes's own SIGPIPE (exit 141) will be reported as a failure even when pacman itself succeeds"
echo "$pw_block" | grep -q '^\s*set -o pipefail\s*$' ||
    fail "pipefail is disabled for the pipewire-jack install but never re-enabled — every later pipeline in the script would stop being pipefail-checked"

# Exercise the exact failure mode: a `yes`-fed pipeline whose reader exits
# well before yes runs out of input must not be reported as a failure, but a
# reader that genuinely fails must still abort the script.
cat > "$tmp_dir/sigpipe.sh" <<'PROBE'
#!/usr/bin/env bash
set -euo pipefail
set +o pipefail
yes | bash -c 'read -r _; exit 0'
set -o pipefail
echo "reached-end"
PROBE
out="$(bash "$tmp_dir/sigpipe.sh" 2>&1)" || fail "a successful reader behind 'yes |' was reported as a script failure (this is exactly what broke a real, successful pipewire-jack install)"
[[ "$out" == *"reached-end"* ]] ||
    fail "the pipefail-off pattern did not let the script continue past a successful yes-fed pipeline"

cat > "$tmp_dir/sigpipe_real_fail.sh" <<'PROBE'
#!/usr/bin/env bash
set -euo pipefail
set +o pipefail
yes | bash -c 'read -r _; exit 7'
set -o pipefail
echo "reached-end"
PROBE
if bash "$tmp_dir/sigpipe_real_fail.sh" >/dev/null 2>&1; then
    fail "the pipefail-off pattern also swallows a genuine reader failure — a real pacman error would go unnoticed"
fi

# --- 10. the login shell is set before HyDE's installer, not left to chsh -
# vendor/hyde/Scripts/restore_shl.sh changes the shell with a bare
# `chsh -s <path>` — no sudo, so it authenticates via the account's own
# login password, which nothing in this script can supply. Every HyDE
# script sources global_fn.sh, which sets `set -e`, so that failure isn't
# contained: it cascades all the way up through install_pst.sh and aborts
# HyDE's top-level install.sh before it ever reaches the services step
# (NetworkManager, bluetooth) or migrations. Confirmed live: a real run's
# log showed "chsh: Authentication failure" immediately followed by control
# returning to this script, with nothing from HyDE's services/migrations
# steps anywhere in between.
grep -q 'sudo chsh -s' "$install_sh" ||
    fail "install.sh no longer pre-sets the login shell with sudo chsh — HyDE's own chsh call will fail (it needs the account's own login password) and abort HyDE's installer before it reaches services/migrations"

chsh_line="$(grep -n 'sudo chsh -s' "$install_sh" | head -1 | cut -d: -f1)"
[[ -n "$chsh_line" && -n "$hyde_line" ]] ||
    fail "could not locate the sudo-chsh step or the HyDE installer step"
(( chsh_line < hyde_line )) ||
    fail "sudo chsh runs at line $chsh_line, after HyDE's installer at line $hyde_line — too late to stop restore_shl.sh's own chsh call from failing"

# It must compare against a plain basename ("zsh"), matching how HyDE's own
# login_shell()/resolve_shell() compare (vendor/hyde/Scripts/global_fn.sh) —
# comparing against a full path here would never match and chsh would run
# unconditionally on every single install.sh invocation, sudo prompt or not.
grep -q '"\$current_shell" != "zsh"' "$install_sh" ||
    fail "the shell comparison doesn't match HyDE's own basename comparison — sudo chsh would run on every invocation instead of only when needed"

# --- 11. hydectl is found even though this script never runs inside a --
#         Hyprland/uwsm session where ~/.local/bin is normally on PATH
# hydectl lives in ~/.local/bin, only added to PATH by Hyprland/uwsm's own
# session environment files (~/.config/uwsm/env.d/00-hyde.sh) — sourced
# when a Hyprland session starts, never by this plain-terminal bash script.
# Confirmed live: `command -v hydectl` silently found nothing right after a
# real HyDE install, so "hydectl theme set Monokai-Pro" never ran and the
# desktop came up on HyDE's own default theme (Catppuccin Mocha) instead —
# install.log showed "applying Monokai Pro HyDE theme" with nothing after
# it, no error, because the whole guarded block was quietly skipped.
grep -q 'HOME/.local/lib/hyde:\$HOME/.local/bin:\$PATH' "$install_sh" ||
    fail "install.sh doesn't add ~/.local/bin to PATH before checking for hydectl — the theme-set call will silently no-op again on a fresh install, same as it did on a real box"

pathexport_line="$(grep -n 'HOME/.local/lib/hyde:\$HOME/.local/bin:\$PATH' "$install_sh" | head -1 | cut -d: -f1)"
hydectl_check_line="$(grep -n 'if command -v hydectl' "$install_sh" | head -1 | cut -d: -f1)"
[[ -n "$pathexport_line" && -n "$hydectl_check_line" ]] ||
    fail "could not locate the PATH export or the hydectl check"
(( pathexport_line < hydectl_check_line )) ||
    fail "PATH export is at line $pathexport_line, after the hydectl check at line $hydectl_check_line — too late to help"

echo "PASS"
