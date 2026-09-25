# Design

**Moved.** The design language lives in **`docs/DESIGN_SYSTEM.md`** — the
Garden system, derived from the export in `docs/design/`. Colour, type,
spacing, shape, size, motion, the semantic layer and the bar for a shared
component are all sections of that file.

Load one section of it, not the whole thing.

This file described the pre-redesign theme: one seed colour through
`ColorScheme.fromSeed`, the platform font throughout, an `errorContainer`
offline banner. Phase 7 part 2 (D118) replaced all three, and
`docs/DESIGN_SYSTEM.md` became the description of the code rather than the
target. Nothing was carried across — what was true here is now either stated
there or deliberately gone. The history is in `docs/journal/phase-7.md` and
in D117 / D118.

The rule that outlived the content: **a slice that changes the design language
changes the design doc in the same slice**, the way a schema change updates
`docs/DATA_MODEL.md`. That doc is now `docs/DESIGN_SYSTEM.md`.
