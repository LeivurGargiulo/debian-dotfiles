@RTK.md
# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

# New project bootstrap
See `bootstrap-project` skill (`~/.claude/skills/bootstrap-project/SKILL.md`) — invoke on fresh/under-scaffolded repos instead of always-loading this checklist.

# Idea-to-production pipeline
See `idea-to-production` skill (`~/.claude/skills/idea-to-production/SKILL.md`) — invoke on any net-new feature/app or "idea to production" ask instead of always-loading this checklist.

# Global MCPs/plugins installed (2026-08-12)
Beyond the superpowers/caveman/ponytail/karpathy/remember/claude-md-management set already referenced above:
- Docs: `context7` MCP (library/API docs — see Docs-over-guessing below)
- Frontend/UI: `shadcn` MCP (live component search/install), `chrome-devtools` MCP (perf/console/DOM, complements playwright), `a11y` MCP (axe-core accessibility audits)
- Security: `semgrep` MCP (SAST, needs `SEMGREP_PATH=/home/leivur/.local/bin/semgrep` env — bundled pysemgrep is broken, don't remove that env var when editing this server's config), `socket-mcp` (npm/PyPI/Maven dependency vuln scoring, hosted, OAuth on first real use)
- Memory: `claude-mem` plugin (passive auto-capture across sessions via hooks — PostToolUse compresses, Stop summarizes, SessionStart/UserPromptSubmit inject relevant context back; worker via `npx claude-mem start` — check it's running if memory injection seems missing), `alley-oop` (claude-community, `/pass`+`/catch` cold-start session handoff, manual not automatic)
- Config hygiene: `agnix` (claude-community, lints Claude Code's own config/hooks/skills — run when hooks/skills misbehave)
- Marketplace: `claude-community` (`anthropics/claude-plugins-community`) added as a source — vet auth requirements before installing anything new from it, several entries need paid vendor accounts.
Removed (broken auth, zero usage): `github` and `greptile` MCP plugins — don't re-add without a token confirmed to actually work.

Second batch (2026-08-12), all claude-community: `tailwind-design-system` (Tailwind/Next.js token audit), `consistent-ui` (cross-codebase UI drift detector, P0-P3 report), `dependency-evaluator` (vets npm/Python packages before install — USE/EXTRACT/BUILD verdict, catches typosquatting), `perf` (10-phase perf investigation methodology), `git-weekly-changelog` (commits → Markdown changelog), `tailtest` (auto test-gen/run on file write, multi-language). Skipped `anti-slop-ui` — marketplace entry points to a dead repo (404), not installable as-is.

Also added from the design family: `design-with-claude` (29 domain-expert design agents — a11y/motion/color/dashboard/checkout, no deps), `universal-design-principles` (137 HCI-research-backed skills, auto-fire on UX/UI tasks). Skipped the rest of that family (58+ entries) — brand/methodology-specific (Doom neubrutalist, Distill look, DisC UML-to-code, IDD, PFD, Japanese-typography, Figma/Rayden-specific) or duplicates.

# Playwright usage
Playwright MCP installed global. **On-demand only** — invoke ONLY when user explicitly asks for it. Never auto-trigger for exploration, UI verification, or "final review" unless user requests it that turn.

# Docs over guessing
Coding + unsure of API/library/CLI behavior (syntax, config, flags, version migration): look it up, never guess. Order: context7 MCP first (`resolve-library-id` → `query-docs`), WebSearch/WebFetch fallback if context7 lacks it or target isn't a library (e.g. random tool docs, blog/changelog). Skip lookup only for stdlib/trivial one-liners you're actually certain of.

# Model restriction for reviews
Reviews, final reviews, code-review agents: sonnet only. Never dispatch opus for review work.

# Commit scope and auto-commit
Only ever commit inside the current working project's own directory — never commit changes in another repo (e.g. editing this dotfiles repo's CLAUDE.md while working in a different project) without asking first. Within the working project, commit automatically once a requested change is complete and verified — no need to ask each time, overriding the general "only commit when explicitly asked" default for this in-project case.

# Python packages: always use a venv
Never `pip install` into system/global Python for any project. Every Python project gets its own `.venv` (project root, `.gitignore`d), created with `python3 -m venv .venv` if missing, activated or invoked via `.venv/bin/python` / `.venv/bin/pip` for all installs and runs (including `pytest`).

# Token/cost levers (learned 2026-08-11 audit)
Real cost driver = API round-trip count, not turn count or plugin count. Every sequential single-tool call resends full cached context.
- Batch Bash commands (`&&`/`;`) instead of many sequential single calls. Fire independent tool calls in parallel in one response, not one-at-a-time.
- Batch TaskUpdate/TaskCreate calls where possible — each is its own round trip; per-task-per-round-trip churn is what made a prior dotfiles session hit 352 round trips / 52.9M cache_read tokens.
- Start a fresh session for unrelated work instead of growing one marathon thread.
- Don't over-trim always-on hook blocks (caveman/ponytail/remember/superpowers) chasing savings — fixed per-session cost, ~0.1% of a long session's total. Not the lever.

# No unverified local execution (ENFORCE — caused real incidents)
Never run compute-heavy or long-running processes on the user's own machine without asking first, even when framed internally as a "smoke test," "quick check," or "just verifying it compiles." If a tool claims isolation (e.g. Agent `isolation: "remote"`), verify it actually ran off-machine (check `ps aux` / worktree paths / no local CPU spike) before telling the user it didn't touch their PC — never assert "not your cores" / "not your machine" as a guess. If the user has said "don't run this on my PC," that instruction stands until they say otherwise; a differently-framed run (build check, timeout-bounded test) is still a violation if it burns real local CPU without asking. Reason: in one session, two separate local-execution incidents happened back to back — once trusting `isolation: "remote"` without checking it actually left the machine (it silently fell back to local, ran at 1186% CPU), and once immediately after, running an "innocent" 90s local smoke test on 12 cores without asking, right after promising not to.

# Proactive skill usage
Default posture: freely use any installed skill, plugin, or MCP tool whenever it fits the task, without waiting for the user to name it explicitly. Check the available-skills/plugins listing before defaulting to a manual approach a skill already covers.

Use these when they fit, don't wait to be asked by name:
- `hookify` (writing-rules) — after fixing a mistake or repeated correction in a session, offer to turn it into a hook so it doesn't recur.
- `skill-creator` — when a workflow gets repeated 2+ times in a project or would benefit from being reusable, offer to package it as a skill.
- `andrej-karpathy-skills:karpathy-guidelines` — apply when writing new code AND when reviewing/refactoring existing code (both directions: avoid overcomplication going in, catch it coming out).
- `claude-md-management:claude-md-improver` — periodically, or when a project's CLAUDE.md looks stale/thin, offer to audit/update it.
- `code-simplifier` — after implementing a feature or fix, before calling it done, consider a simplification pass on the touched code.

# No per-task reviewer subagents (ENFORCE — repeatedly not followed)
`superpowers:subagent-driven-development` and `superpowers:executing-plans` normally spawn a reviewer subagent (`asdd-taskN-review`) after each plan/spec task, printing "Task N Complete" + a "Spec Compliance" verdict block. **NEVER do this.** Skip that reviewer-subagent spawn step entirely — implement each task directly, no automatic per-task review output, no per-task verdict block.
Instead: after ALL tasks in the plan are done, run exactly ONE final review pass, sonnet only (see Model restriction below). No per-task reviews, no exceptions, regardless of what the skill's default flow says.
