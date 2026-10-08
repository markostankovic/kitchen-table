# D164 — Section edits are one `setSections`; remove joins the group above; Add section opens a heading
**Status:** active
**Touches:** lib/features/recipes/domain/recipe_draft.dart, lib/core/ingredients/widgets/ingredient_lines_editor.dart, lib/core/ingredients/widgets/ingredient_line_field.dart, lib/features/recipes/application/recipe_editor.dart, lib/features/import/application/import_confirm.dart, lib/core/l10n/arb/app_sr.arb, docs/DESIGN_SYSTEM.md

**Decided.** Round `2026-10-06-round-2-recipe-structure`, canvas § A4,
`phase8-ingredient-sections-edit`, 2026-10-08:
1. **`RecipeDraft.setSections(Map<int, String?>)`** is the one operation
   behind rename (the run → the name), remove (the run → the group above)
   and Undo (each line → its own old section). Blank is stored as null,
   anything else as typed. `toIngredient` trims, so `Fil ` saves as `Fil`.
   Unknown ids are ignored.
2. **Tapping a heading opens it**, through the same one-thing-open path as
   a line (D158/D159), so a blank line that closes is still removed. The
   open heading is the open line's box with one `titleSmall` `primary`
   field, hint `ingredientSectionHint` (`Za testo` / `For the dough`) in
   the **recipe's** locale. Its layout is `[grip] [box] [✕ 48]`, with no
   grip and an `md` inset in review. It is a private widget in the list's
   file.
3. **The open heading keeps the run's ids and its typed name in state**,
   captured when it opens. Every keystroke writes only those ids, so a name
   that passes through the next group's cannot swallow that group. The name
   is read from state, not `widget.lines`, which lags a frame behind a
   keystroke that Next follows.
4. **Remove (✕) joins the run to the group above.** Each line takes the
   name of the group the heading sat under, or null at the top. Nothing
   moves and nothing is deleted. `Odeljak je uklonjen.` with Undo,
   `persist: false`, shown from inside the list so both hosts get it.
5. **Closing a heading blank counts as remove**, and its Undo restores the
   name it had before it opened. Add section's unnamed heading closes with
   **no snackbar**, because its "before" is all null.
6. **Add section** (`Icons.title`, `Dodaj odeljak`) sits beside Add
   ingredient in a `Wrap` (`xs`). It appends a blank line and opens a
   heading over it. Next on a heading enters its first line if that is
   blank, otherwise closes it. To make that work, `IngredientLineField`
   requests focus when `autofocus` turns on, because the blank line was
   already built open.

**Why.**
- One map operation covers three edits and their Undo, and needs no fresh
  ids, unlike D154 #5, because no line is removed.
- Restoring by id per line undoes exactly what was there, including a
  mixed run.

**Rejected.**
- Taking the literal line above's section on remove. That line may be a
  null continuation, which looks the same but leaves the run ungrouped if
  lines later move.
- Separate rename, remove and restore operations.
