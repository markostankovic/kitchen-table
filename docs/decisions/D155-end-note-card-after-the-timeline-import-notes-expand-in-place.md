# D155 — The end note is a card after the timeline; import review's Notes expands in place
**Status:** active; #6 superseded by D165 (the end note renders through `AppRichText`)
**Touches:** lib/features/recipes/presentation/recipe_detail_screen.dart, lib/features/recipes/presentation/recipe_edit_screen.dart, lib/features/import/presentation/import_review_screen.dart, lib/features/recipes/presentation/translation_review_screen.dart, lib/core/l10n/arb/app_sr.arb, docs/DESIGN_SYSTEM.md

**Decided.** Round `2026-10-06-round-2-recipe-structure`, canvas § A2, 2026-10-06:
1. **On detail the end note is a themed `Card`, full width, outside the
   timeline.** It is padded `lg`. Its header is `edit_note` at 20
   (`iconInButton`) in `onSurfaceVariant`, then `Napomena` in
   `titleMedium`, then the body in `bodyLarge`. It reads `displayNotes`. An
   empty or blank note renders nothing, no heading and no gap.
2. **The 32 above the card is `sm` on top of the last row's own `xl`**
   (`xxl` after the plain `noStepsYet` text). A method that ends in a
   heading keeps the `md` it leaves.
3. **The source footer keeps its `xxl`**, not the canvas's 24, so the
   footer sits the same with or without a note above it.
4. **The editor takes no dividers between sections.** Notes follows the
   add row as `xl` + `AppSectionHeading` + one field (`minLines` 3, growing,
   with helper text), the way Ingredients and Steps already do.
5. **Import review's Notes copies Method:** a collapsed `ExpansionTile`
   with `expand_more`, expanding in place to one field. The frame's
   `chevron_right` is read as an abbreviated summary, not a route. The
   subline is the note's first words on one line, or `Nije pronađena` /
   `None found`.
6. **The note renders as plain `Text`** behind a private
   `_RecipeNotesCard` until `phase8-rich-text-render` swaps in the
   renderer. Until then, markdown markers show literally. Done by D165
   (`phase8-rich-text-render`): the card frame is unchanged.

**Why.**
- Making up the 32 from the existing `xl` keeps a recipe with no note
  building exactly the tree it built before.
- A footer whose spacing depended on what sits above it would move whenever
  a note is added or cleared.
- D8: import review is for reading, and a route for one field would break
  the screen's one-pass flow. Method already sets the pattern.
- `Nije pronađena` agrees with the feminine `Napomena`. It read naturally
  on the walk.

**Rejected.**
- The canvas's section dividers in the editor, and its Source field below
  Notes (the editor has no source field).
- A `chevron_right` row that opens a separate screen for the import note.
- Reusing `stepKindNote` (`Beleška`, D154) or the meal plan's
  `mealEntryNoteLabel` for the end note's heading.
- A new 20dp icon token: `iconInButton` is the existing 20.

**Consequences.** The rich-text slice replaces one `Text` per surface. The
end note above a source footer has not yet been seen on a device (an open
walk loop in `docs/STATE.md`).
