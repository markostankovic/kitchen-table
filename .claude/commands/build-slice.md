---
description: Implement a slice from its handoff file, without loading the wider docs
argument-hint: <slice-name>
---

Implement the slice named `$ARGUMENTS`. This is meant to run in a session
that has just been `/clear`ed, right after `/plan-slice $ARGUMENTS`.

## 1. Load only the slice file

Read `docs/active/$ARGUMENTS.md`. That, plus `CLAUDE.md` (already in
context), is meant to be everything you need. If the file is missing, stop
and say so — do not fall back to inventing a plan from `docs/ROADMAP.md` or
`docs/DECISIONS.md`.

## 2. Implement

Follow the slice file's "Files to touch" and "Pattern to follow" exactly. Do
not open `docs/ARCHITECTURE.md`, `docs/DATA_MODEL.md`, `docs/INGREDIENTS.md`,
`docs/ROADMAP.md`, or any file under `docs/decisions/` unless you hit
something the slice file does not resolve.

If you do hit something unresolved: that means the plan was incomplete, not
that you should go explore. Read the one doc section or decision file that
answers it, note in your final report that the slice file was missing this,
and continue — but if more than one or two things are missing, stop and say
the slice needs re-planning rather than patching it piecemeal from here.

Follow `CLAUDE.md`'s hard rules throughout, especially: no `supabase_flutter`
outside `data/`, no hard deletes, quantities as integer fractions, domain
models stay pure Dart.

## 3. Verify

Run the slice file's "Acceptance" check (normally `make check`). Fix
failures before reporting done. Regenerate types/codegen if the schema or
Zod contracts changed, per `CLAUDE.md`'s working style.

## 4. Report, then stop

Summarize what changed and confirm the acceptance check passed. Tell the
user to run `/close-slice $ARGUMENTS` to record the work — do not do that
yourself; closing is a distinct step so the journal/decision/state updates
happen deliberately, not folded into a large diff.
