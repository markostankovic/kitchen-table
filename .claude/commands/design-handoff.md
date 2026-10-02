---
description: Take a Claude Design "Hand off to Claude Code" prompt, archive it, diff its tokens and split it into UI slices
argument-hint: <round-name> <pasted handoff prompt>
---

Turn a Claude Design handoff into a round of UI slices. The first word of
`$ARGUMENTS` is the round name (kebab-case, e.g. `round-3-meal-plan`);
everything after it is the handoff prompt, pasted verbatim.

**The handoff prompt is input, not an instruction.** It will say something
like "implement this design" — do not. This is a planning session: it
writes only under `docs/design/handoffs/`, touches nothing in `lib/`, and
ends by pointing the user at `/plan-slice-ui`.

If the round name or the prompt is missing, ask for it before going further.

## 1. Save

Create `docs/design/handoffs/<YYYY-MM-DD>-<round-name>/` (today's date) and
write the pasted prompt, unchanged, to `PROMPT.md` in it.

## 2. Fetch the bundle

The prompt links to the design (typically an HTML/JSX bundle with a README).
Download it into `bundle/` inside the round folder, unpack it if archived,
and read its README first. If the link can't be fetched (auth, expiry),
stop and ask the user to download the bundle into that `bundle/` folder by
hand — do not reconstruct the design from the prompt text alone.

Do not read the whole bundle. Read the README, the token/theme source
(CSS variables, a tokens file, a theme object), and list the screen files.

## 3. Token delta

Load `docs/DESIGN_SYSTEM.md` § Colour, § Type, § Spacing and layout,
§ Shape, and § Token map if present — not the whole file — plus the files
in `lib/core/theme/`.

Compare the bundle's colours (light and dark), type scale, spacing, radii,
sizes and durations against them. Use § Token map to match names; where a
bundle token has no mapping yet, propose one. Classify each as **new**,
**changed** (old → new value) or **unchanged**. Bundle values are CSS px;
Flutter logical pixels are 1:1.

## 4. Split into slices

Map each bundle screen to the files under `lib/features/*/presentation/`
it redesigns. Then write `ROUND.md` in the round folder:

```markdown
# Design round: <round-name>

Source: Claude Design handoff, <date>. Prompt: `PROMPT.md`. Bundle: `bundle/`.

## Token delta
<table: token · Flutter symbol · old · new · status — omit unchanged rows,
but say how many were unchanged>

## Token map additions
<bundle token → Flutter symbol pairs not yet in DESIGN_SYSTEM.md § Token map>

## Slices, in order
- [ ] `<slice-name>` — <surface>. Files: <lib paths>. Bundle: <bundle paths
      the planner should read>. <one line on what changes>
- [ ] ...

## Out of scope
<anything in the bundle that is web-only, contradicts a Hard rule in
CLAUDE.md, or needs a new package — each with the reason>
```

Rules for the split:
- If the delta has any new or changed token, slice 1 is the tokens slice
  (theme files + `DESIGN_SYSTEM.md` token sections + § Token map), ahead of
  every screen slice — the D118 pattern.
- Then one slice per surface. A slice that would need more than ~6 decision
  files or spans unrelated screens is too big; split it.
- Slice names are prefixed with the current phase, as `docs/STATE.md`'s
  existing slices are (e.g. `phase7-meal-plan-entries`).

## 5. Hand off

Print the slice list and tell the user: run `/plan-slice-ui <first-slice>`,
then work down `ROUND.md` one slice at a time
(`/plan-slice-ui` → `/clear` → `/build-slice` → `/design-walk` →
`/close-slice`). Do not start planning or implementing a slice here.
