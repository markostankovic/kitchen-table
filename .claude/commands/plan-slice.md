---
description: Plan one vertical slice of work and write a self-contained handoff for a fresh implementation session
argument-hint: <slice-name>
---

Plan the slice named `$ARGUMENTS` (kebab-case, e.g. `phase3-part6`).

This command is meant for a planning session (Opus). It ends by writing one
file and telling the user to `/clear` — it does not implement anything.

## 1. Orient cheaply

Read `CLAUDE.md` and `docs/STATE.md` only. Do not read `docs/ROADMAP.md`,
`docs/DECISIONS.md` (it's a stub — see below), `docs/ARCHITECTURE.md`,
`docs/DATA_MODEL.md`, `docs/INGREDIENTS.md`, `docs/DESIGN.md`, or
`docs/IDEAS.md` yet. Follow `CLAUDE.md`'s "Finding context" routing table from
here — load only what the slice's actual subject requires.

If `$ARGUMENTS` is empty or its scope is unclear from `docs/STATE.md`'s
"Next" line, ask the user what the slice covers before going further.

## 2. Explore

Search the codebase for the files, patterns, and existing decisions the slice
touches. Prefer reusing a pattern from a recently-shipped feature over
inventing a new one. When you hit a `Dxx` citation in a code comment, open
`docs/decisions/Dxx-*.md` directly — do not open the whole decisions
directory or `INDEX.md` speculatively.

Budget: more than ~6 decision files, or reading a whole reference doc when
only one section is relevant, means the slice is bigger than it should be —
say so and propose splitting it.

## 3. Write `docs/active/$ARGUMENTS.md`

This file is the entire context the implementation session will have. It
must be self-contained: name every constraint by decision id and one-line
summary (not by reference — the implementer will not have the decision text
loaded), list the exact files to touch, name a pattern file to mirror, and
give a concrete acceptance check.

Use this shape:

```markdown
# Slice: <title>

## Goal
<one paragraph>

## Constraints already resolved (do not re-derive)
- Dxx — <one-line summary of what it settles for this slice>
- CLAUDE.md rule N — <if a hard rule is especially load-bearing here>

## Files to touch
- path/to/file.dart   (<what changes>)

## Pattern to follow
<a specific existing file/screen/module to mirror, and what to copy from it>

## Acceptance
`make check` clean. <anything slice-specific>

## To record on completion
<which docs/journal/phase-N.md file, and whether a new decision is expected>
```

## 4. Hand off

Tell the user the slice file is written, then say plainly: run `/clear`,
then `/build-slice $ARGUMENTS` in the fresh session. Do not start
implementing in this session even if asked to continue — that defeats the
point of the split.
