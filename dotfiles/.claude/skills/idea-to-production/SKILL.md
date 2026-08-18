---
name: idea-to-production
description: "Use for any net-new feature or app request, or when the user frames the ask as 'idea to production' / 'build this from scratch' / 'take this from concept to shipped'. Walks a rough idea through spec, plan, implementation, and verification stages instead of jumping straight to code. Skip for small bug fixes, one-off scripts, or edits to existing well-scoped features — use this only for genuinely new, non-trivial builds."
---

# idea-to-production

A staged pipeline for turning a rough idea into working, verified code — invoked instead of always-loading this checklist, only on net-new feature/app asks.

## When to use

- The user describes something that doesn't exist yet ("build a tool that...", "I want an app for...", "add a whole new X feature").
- The user explicitly says "idea to production" or equivalent.
- Not for: bug fixes, small edits, adding a field to an existing form, anything with an obvious 1-2 step implementation.

## Stages

1. **Clarify the idea.** Restate what's being asked in your own words before doing anything else. If the scope, target platform, or success criteria are ambiguous, ask — don't guess into a large build.
2. **Spec.** Write a short spec: what the thing does, who uses it, the smallest version that's actually useful (MVP cut), and what's explicitly out of scope for v1. Keep this proportional — a few paragraphs, not a design doc, unless the user wants more detail.
3. **Plan.** Break the spec into an ordered implementation plan — see the `implement-plan` command for how a plan gets executed once written. Identify the riskiest/least-certain part and sequence it early, not last.
4. **Implement.** Build in the planned order. Prefer the smallest working slice first (get something end-to-end before polishing), then layer in the rest of the spec.
5. **Verify.** Before calling it done: run the test suite / type checker if present, and actually exercise the golden path (and realistic edge cases) rather than trusting the code by inspection alone. For UI work, this means actually running it in a browser — see standing instructions on this.
6. **Wrap-up.** Summarize what was built, what's deliberately deferred (from the out-of-scope list in step 2), and any follow-up the user should know about. Don't over-narrate — the summary is for orientation, not a full changelog.

## Notes

- This is a sequence, not a rigid gate — for a small enough "idea", stages 2-3 can be a couple of sentences rather than separate documents.
- Don't invent scope beyond what was asked. The spec step exists to pin down the MVP, not to encourage building more than requested.
