---
name: bootstrap-project
description: "Use when starting work in a fresh or under-scaffolded repository — no CLAUDE.md, no README, missing package manifest, no test setup, or no git repo at all. Walks through project bootstrap: repo init, README, CLAUDE.md, package manifest, linting, test scaffold, .gitignore, initial commit. Skip if the repo already has these in place."
---

# bootstrap-project

Checklist-driven setup for a repo that hasn't been scaffolded yet. Invoke instead of guessing project layout from scratch, and instead of always-loading this checklist on every task — only when the repo is genuinely missing basics.

## When to use

- The working directory has no `.git`, or `.git` exists but there's no README/CLAUDE.md/package manifest yet.
- The user says "start a new project", "set this up", "scaffold this repo", or similar.
- Do **not** use on a repo that already has these — check first (`ls -a`, `git log -1`) rather than assuming.

## Checklist

1. **Git**: `git init` if not already a repo. Confirm the default branch name matches the user's convention (ask if unclear).
2. **README.md**: project name, one-paragraph purpose, how to run/build/test. Keep it short — expand later as the project grows.
3. **CLAUDE.md**: only if the project has real, non-obvious conventions worth recording (see the `init` skill/command for the fuller version of this). Skip if there's nothing yet worth writing down.
4. **Package manifest**: `package.json` / `pyproject.toml` / `Cargo.toml` / etc., matching the language the user specified or that's implied by existing files. Ask if the language/stack isn't clear from context.
5. **Linting/formatting**: wire up the ecosystem's standard tool (eslint/prettier, ruff, rustfmt, …) only if the user wants it now — don't force it unasked.
6. **Test scaffold**: one placeholder test proving the test runner works end-to-end, not a full suite.
7. **.gitignore**: standard template for the detected language/stack (build artifacts, dependency dirs, editor files, secrets).
8. **Initial commit**: once the above is in place, stage and commit as a single "Initial commit" (or ask the user's preferred message) — never commit without being asked, per standing git-safety rules.

## Notes

- This is a starting skeleton, not an opinionated framework choice — ask before picking a framework/library the user didn't specify.
- Re-run individual steps as needed; this isn't all-or-nothing. If the repo already has 5 of 8 items, only do the missing ones.
