---
description: Append a task to this project's task list, creating the list first if it doesn't exist yet.
argument-hint: <task description>
---

Append the following task to this project's task list: "$ARGUMENTS"

1. Look for an existing task list in the current repo — check, in order: `TASKS.md`, `TODO.md`, or a "Tasks"/"TODO" section inside `CLAUDE.md`. Use whichever already exists.
2. If none exist, create `TASKS.md` at the repo root with a short header and a Markdown checklist (`- [ ] ...`).
3. Append the given task as a new unchecked checklist item (`- [ ] <task description>`) at the **end** of the list — never reorder or edit existing entries.
4. Don't start implementing the task now — this command only records it.
