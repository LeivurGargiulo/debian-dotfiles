---
description: Execute an implementation plan with subagent-driven-development, but skip per-task reviewer subagents — only one final whole-branch review, on sonnet.
argument-hint: <path to plan file>
---

Execute the plan at "$ARGUMENTS" using `superpowers:subagent-driven-development` as the base process, with two overrides that replace, not supplement, that skill's own instructions on these points:

## Override 1 — no per-task review

Follow the skill's Setup, Model Selection, and Task Loop steps 1 ("Dispatch the implementer") and 2 ("Handle the report") exactly as written.

Skip step 3 ("Review the task") and step 4 ("The fix loop") entirely. Do **not** generate a review package per task, do **not** dispatch a task-reviewer subagent, and do **not** run a per-task fix loop. The implementer's own tests and self-review (already part of its dispatch contract) are the only gate before a task is marked complete.

Step 5 ("Complete the task") still applies, minus anything that references the task review: once the implementer reports DONE (or DONE_WITH_CONCERNS with the concerns resolved), append the completion line to the ledger —
`Task <N>: complete (commits <base7>..<head7>, no per-task review — see final review)`
— mark the todo complete, and move to the next task.

## Override 2 — final review only, sonnet only

Once every task is complete, run exactly the skill's "Final Review" step, unmodified except for model choice: dispatch the final whole-branch reviewer on **sonnet**, never opus and never a cheaper model, regardless of what the skill's own Model Selection section would otherwise pick for this role. Use `scripts/review-package PLAN_FILE MERGE_BASE HEAD` and `superpowers:requesting-code-review`'s `code-reviewer.md`, exactly as the base skill describes.

If the final review returns findings: one fix dispatch with the complete findings list, one scoped re-review (also sonnet), then adjudicate any residuals exactly as the base skill's breaker describes. This is the only review loop that runs in this whole process — there is no other review gate anywhere in the plan's execution.

Then finish per the base skill: `superpowers:finishing-a-development-branch`.

## Why

Per-task reviewer subagents duplicate the one review pass that actually matters and burn a full extra review seat per task for no gain the final whole-branch review doesn't already provide. This command exists because that per-task review step keeps getting run anyway when relying on a standing instruction alone — invoke `/sdd <plan>` instead of the bare skill name whenever you want subagent-driven-development with this override in force.
