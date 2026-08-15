# Claude Code setup

What's vendored from `~/.claude/` into this repo, how it gets applied,
and what's deliberately left out.

## What's vendored (`chezmoi/dot_claude/`)

| File | Purpose |
|---|---|
| `settings.json` | model, permissions, hooks wiring, statusline, enabled plugins/marketplaces |
| `executable_statusline-command.sh` | statusline: caveman badge + model + context/rate-limit usage |
| `hooks/executable_zshrc-zoxide-guard.sh` | `PostToolUse` hook — keeps `zoxide init` as the last line of `~/.zshrc` after edits |
| `CLAUDE.md`, `RTK.md` | global instructions (skill routing, tone/workflow preferences, RTK usage) |
| `commands/*.md` | custom slash commands (`/continue`, `/implement-plan`) |
| `agents/repo-initializer.md` | custom subagent definition |

Applied the same way as every other dotfile: `ansible/roles/dotfiles`
runs `chezmoi apply`, which symlinks/copies `chezmoi/dot_claude/*` to
`~/.claude/*`.

## What's installed alongside it (`ansible/roles/dev-tools`)

`ansible/group_vars/all/packages.yml` declares `claude_marketplaces`
(5 marketplace repos) and `claude_plugins` (12 plugin ids, in
`name@marketplace` form) — these mirror what's actually enabled in
`settings.json` on this machine. The `dev-tools` role runs `claude
plugin marketplace add <repo>` for each marketplace, then `claude
plugin install <plugin> -y --scope user` for each plugin, after
installing the Claude Code CLI itself (`@anthropic-ai/claude-code` via
npm, same role). This exists because `CLAUDE.md`'s instructions
reference plugins by name (superpowers, ponytail, caveman, serena,
etc.) — vendoring the text file alone would leave a fresh machine with
instructions pointing at nothing installed.

## What's deliberately NOT vendored

| Path | Why |
|---|---|
| `.credentials.json` | OAuth tokens — a secret, never belongs in git |
| `.claude.json` | per-machine session/project state, not config |
| `history.jsonl` | conversation history — private, huge, not config |
| `cache/`, `backups/`, `debug/`, `downloads/`, `paste-cache/`, `file-history/` | runtime/scratch state |
| `projects/` | session transcripts — private |
| `daemon.log`, `daemon.lock`, `daemon.status.json` | live process state |
| `.caveman-active`, `.ponytail-active`, `.last-cleanup`, `.last-update-result.json` | ephemeral mode/state flags, regenerate themselves |

This repo is **public** — none of the above should ever be added to
`chezmoi/dot_claude/`, regardless of how convenient it'd be. If you're
tempted to vendor something from `~/.claude/` not in the table above,
check it for tokens/keys/personal paths first.

## Adding a plugin, hook, or command

**Plugin**: add `<name>@<marketplace>` to `claude_plugins` in
`packages.yml` (add the marketplace repo to `claude_marketplaces` too,
if it's a new marketplace). Re-run the `dev-tools` role, or manually:
`claude plugin marketplace add <repo>` then `claude plugin install
<name>@<marketplace> -y`.

**Hook**: add the script under `chezmoi/dot_claude/hooks/` (name it
`executable_<name>.sh` so chezmoi sets the exec bit), then wire it into
the `hooks` block of `chezmoi/dot_claude/settings.json` following the
existing entries' shape (matcher + command).

**Command**: add a `.md` file under `chezmoi/dot_claude/commands/`
with YAML frontmatter (`description:`) and the prompt body — same
shape as `continue.md`/`implement-plan.md`.

**Agent**: add a `.md` file under `chezmoi/dot_claude/agents/` with
frontmatter (`name`, `description`, `tools`, `model`) and the system
prompt body — same shape as `repo-initializer.md`.

After any of these, `chezmoi apply` on the live machine to test before
committing.
