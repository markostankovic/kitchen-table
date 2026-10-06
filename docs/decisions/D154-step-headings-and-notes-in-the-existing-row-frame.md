# D154 — Step headings and notes keep the editor's row frame; the note is `Beleška`
**Status:** active
**Touches:** lib/features/recipes/presentation/recipe_detail_screen.dart, lib/features/recipes/presentation/recipe_edit_screen.dart, lib/features/recipes/domain/recipe_draft.dart, lib/features/import/presentation/import_review_screen.dart, lib/features/recipes/presentation/translation_review_screen.dart, lib/core/l10n/arb/app_sr.arb, docs/DESIGN_SYSTEM.md

**Decided.** Round `2026-10-06-round-2-recipe-structure`, canvas § A1, 2026-10-06:
1. **The editor keeps `_EditableRow`'s frame** for all three kinds: the
   label above, then grip | field | ✕. Only the label changes by kind (an
   icon plus `Naslov` / `Beleška`). The canvas's ✕ in the label row, as a
   40dp button, is not taken.
2. **No drawn drop line.** The gap `ReorderableListView` opens where the
   row will land is the indicator. The dragged step row lifts to level 3
   through `proxyDecorator`, on `surfaceContainerHigh`.
3. **The step note's word is `Beleška` / `Note`**, keeping `Napomena` for
   the recipe's end note (`phase8-recipe-end-note`).
4. **Connector geometry**, from the canvas's `break` and `panel` defaults:
   - a step draws its line only when a step or note follows;
   - a note draws one when a step or note precedes it or a step follows;
     before a heading or at the end it stops level with the panel;
   - a heading draws none and has no disc column.

   A step-only method builds the same tree as before.
5. **Numbers count step-kind rows and continue across headings**, on
   detail, in the editor's labels and in translation review. Undo is for a
   heading only, and it re-inserts under a fresh local id.

**Why.**
- `iconButtonTheme` forces a 48dp minimum (see `_RatingStars`), so a 40dp
  ✕ in the label row would need a local style override. The ingredient rows
  already use grip | field | ✕, and the canvas's own requirement (grip,
  label, ✕ on every row) is met either way.
- Two kinds sharing one Serbian word would make the editor's labels and the
  end note's heading ambiguous.
- A hand-drawn line would duplicate what the gap already says.
- A fresh id on Undo: `_nextStepId` is max+1, so once the highest row is
  removed, an add can take its id. Re-inserting the old id would key two
  live widgets the same.

**Rejected.**
- The canvas's ✕-in-label-row and its 2dp drop line (above).
- `Napomena` for the step note.
- The canvas's `continue` connector (one line through headings) and its
  inline `info` icon note; a warning tint (never red or paprika).
- Undo for steps and notes. The round asked for headings only.

**Consequences.** A heading or note on import review carries an `outline`
prefix icon, and the Method subline counts steps only. The snackbar sits
over the Save button for its 4s, so a late Undo tap saves (seen on the
walk, not changed). The lifted row has no top padding, so its label sits
close to its top edge.
