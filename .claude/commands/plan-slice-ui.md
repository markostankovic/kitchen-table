---
description: Plan one UI/redesign slice, design rules inlined, and write a self-contained handoff
argument-hint: <slice-name>
---

Plan the UI slice named `$ARGUMENTS` (kebab-case, e.g. `phase7-recipe-list`).

This is the design-aware sibling of `/plan-slice`. Use it when the subject of
the slice is *what a screen looks like*; use `/plan-slice` for everything
else. Same contract as its sibling: a planning session (Opus) that ends by
writing one file and telling the user to `/clear`. It does not implement.

## 1. Orient cheaply

Read `CLAUDE.md`, `docs/STATE.md`, and `docs/DESIGN.md` — that third one is
the difference from `/plan-slice`, which deliberately excludes it. Do not
read `docs/ROADMAP.md`, `docs/ARCHITECTURE.md`, `docs/DATA_MODEL.md`,
`docs/INGREDIENTS.md`, or `docs/IDEAS.md`.

`docs/DESIGN.md` says to load one section, not the file. For a UI slice that
normally means **Colour**, **Type**, and **Spacing and layout**; add
**Components** only if the slice might add or promote a widget, and **Both
languages** / **Light and dark** only if you need their wording verbatim for
the handoff's acceptance section.

If `$ARGUMENTS` is empty or its scope is unclear from `docs/STATE.md`'s
"Next" line, ask the user which surface the slice covers before going further.

## 2. Explore

Search the codebase for the files the slice touches, and answer these three
before writing anything. Each one is something to *find* and carry into the
handoff, not a rule to recite back.

- **Which screens.** Which files under `lib/features/*/presentation/` (and
  the feature's own widgets) this slice redesigns. For each, whether any of
  its private widgets duplicate a shape already in `lib/core/widgets/` —
  `AppErrorView`, `AppSectionHeading`, `AppEmptyState`. Phase 7 part 1
  deleted several such duplicates; the slice should reuse those, not re-add a
  private copy.

- **Where a new widget goes.** If the slice adds one, does it clear
  `docs/DESIGN.md` § Components' bar for `lib/core/widgets/` — generic,
  feature-agnostic, and a *second* feature actually needs it? If it knows
  what a recipe or a meal plan is, it belongs in the `core/<feature>/widgets/`
  middle ground (D43, D53) or in the feature's own `presentation/`.

- **What is still hardcoded.** Raw `Color` literals, raw `fontSize`, and
  literal `EdgeInsets`/`SizedBox` numbers in the files being touched.
  `docs/DESIGN.md` § Spacing is explicit that migration is not retroactive
  across the app, but *is* expected for files a slice already opens — so list
  the ones in scope rather than leaving the builder to decide.

When you hit a `Dxx` citation in a code comment, open `docs/decisions/Dxx-*.md`
directly. Budget: more than ~6 decision files means the slice is too big —
say so and propose splitting it by surface.

## 3. Write `docs/active/$ARGUMENTS.md`

This file is the entire context the implementation session will have. The
build session is deliberately context-starved: "see `docs/DESIGN.md` §
Colour" in a handoff is a bug. **Inline the actual values.**

```markdown
# Slice: <title>

## Goal
<one paragraph>

## Constraints already resolved (do not re-derive)
- Dxx — <one-line summary of what it settles for this slice>
- CLAUDE.md rule N — <if a hard rule is especially load-bearing here>

## Design rules in force
- Colour — <the role names this slice uses and what each means here, e.g.
  "outline = muted icon colour, never body text". Never a raw Color.>
- Type — <the rows of the type table this slice uses, with size/weight>
- Spacing — AppSpacing.xs/sm/md/lg/xl/xxl = 4/8/12/16/24/32
- Components — <reuse AppErrorView/AppSectionHeading/AppEmptyState where they
  fit; whether anything new goes in core/widgets/, and why it clears the bar>

## Files to touch
- path/to/file.dart   (<what changes>)

## Pattern to follow
<a specific existing file/screen to mirror, and what to copy from it>

## Acceptance
`make check` clean — except `seed-check`, which has been red on `main` since
`c8be2bc` for an unrelated reason (see `docs/STATE.md`); everything else must
be green.
Device walk: `/design-walk <surface>` — sr/en x light/dark. Nothing
truncates, wraps badly or overflows in Serbian; nothing is unreadable in dark.

## DESIGN.md sections to update
<which sections this slice makes stale — DESIGN.md requires a slice that
changes the design language to update it in the same slice, the way a schema
change updates DATA_MODEL.md. Write "none — applies existing rules only" if
that is genuinely the case.>

## To record on completion
<which docs/journal/phase-N.md file, and whether a new decision is expected>
```

## 4. Hand off

Tell the user the slice file is written, then say plainly: run `/clear`, then
`/build-slice $ARGUMENTS` in the fresh session — the build command is shared
with `/plan-slice` and needs no design-specific variant, because the handoff
already carries the rules. Do not start implementing in this session even if
asked to continue — that defeats the point of the split.
