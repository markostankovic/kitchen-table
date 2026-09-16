---
description: Record a finished slice into the journal, decisions, roadmap and state, then remove its handoff file
argument-hint: <slice-name>
---

Close out the slice named `$ARGUMENTS` after `/build-slice $ARGUMENTS` has
finished and its acceptance check passed. This is the step that was being
skipped before this doc structure existed (see `docs/ROADMAP.md`'s Part 5
entry for what that cost) — do all of it, in order, even if it feels
redundant with what the build session already reported.

## 1. Read what's there

- `docs/active/$ARGUMENTS.md` — the plan that was executed
- `git log` / `git diff` since the slice started — what actually shipped
  (may differ slightly from the plan; record reality)
- `docs/STATE.md` — current pointer

If `docs/active/$ARGUMENTS.md` is missing, ask the user for a one-paragraph
summary of what shipped instead of reconstructing it from the diff alone.

## 2. Journal entry

Determine which phase this slice belongs to (ask if unclear) and append a
new `###`-level entry to `docs/journal/phase-<n>.md`, in the same voice and
shape as the entries already there: what shipped, the commit(s), decisions
taken, and — if the work was verified end-to-end (emulator, local stack,
manual walk) — what was actually checked and how, not just "tests pass".

## 3. New decisions, if any

For anything genuinely decided during the slice (not just implemented) that
a future session could second-guess or redo differently, write
`docs/decisions/D<next>-<slug>.md` using the compact shape (~40 lines):

```markdown
# D<n> — <title>
**Status:** active
**Touches:** <paths>

**Decided.**
**Why.**
**Rejected.**
**Consequences.** (optional)
```

Add one line to `docs/decisions/INDEX.md` in id order. Do not retrofit this
shape onto the pre-existing long-form decisions (D1–D92) — those stay as
they are.

## 4. Update `docs/STATE.md`

Rewrite it fully (it's meant to be cheap to regenerate, not edited
incrementally): today's date, current branch, what just shipped and its
commit, "In flight: none" unless another slice is already underway, the next
slice from the roadmap, and the latest decision id.

## 5. Update `docs/ROADMAP.md`

Flip the relevant part's status line to `**Status: complete** (`<commit>`).
Decisions taken during it: <ids>. See `docs/journal/phase-<n>.md`.` — matching
the format every other completed part already uses. If this slice wasn't a
roadmap part (e.g. a bugfix or refactor slice), skip this step.

## 6. Clean up

Delete `docs/active/$ARGUMENTS.md`. Report the files you changed and confirm
`docs/STATE.md` now matches reality.
