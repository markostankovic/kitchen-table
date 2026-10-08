# D157 — One shared ingredient list for the editor and import review
**Status:** active; #4 superseded by D162 (headings are their own list items)
**Touches:** lib/core/ingredients/widgets/ingredient_lines_editor.dart, lib/features/recipes/presentation/recipe_edit_screen.dart, lib/features/import/presentation/import_review_screen.dart, docs/DESIGN_SYSTEM.md

**Decided.** Round `2026-10-06-round-2-recipe-structure`, canvas § A4·1/A4·2/A4·4, 2026-10-07:
1. **`IngredientLinesEditor`** in `lib/core/ingredients/widgets/` is the
   ingredient list being edited, on both the recipe editor and import
   review. It owns the `ReorderableListView` and which line is open (`int?`,
   one at a time, as D123 #1 had it), along with section headings, fast
   entry (D159), the pill on closed rows (D160) and Add ingredient.
2. **It takes primitives and callbacks**, as `IngredientLineRow` does:
   `lines`, the recipe's `locale`, `units`, `parser`, `onReplace`,
   `onRemove`, `onReorder`, `onInsertAfter → id` and `onAdd → id`. It has no
   controller type and no base class. The open line is the widget's own
   `State`.
3. **`review` picks the row style.** `true` is import review's style: every
   row inset, no grip (long-press drags), and a trailer that leads with
   `→ catalog name` or the not-matched words (D142). `false` is the
   editor's style: a grip on every row, no inset, and a trailer of the note
   only. **`flagged`** (ids) tints rows in review only.
4. **A section heading rides inside its first line's child**, so the
   list's indices stay line indices for `onReorderItem`.

**Why.**
- Import review already worked this way (D123). The editor needed the same
  thing, and two copies of an open/closed list would drift. Two features
  using it clears the D43/D53 bar for the `core/` middle ground.
- Putting headings inside the first line's child keeps reordering a plain
  line move. Draggable headings are the next slice's problem.

**Rejected.**
- Keeping import review's `_lineRow` / `_openLineId` and copying them into
  the editor.
- A heading as its own child with index mapping on reorder.
- An `IngredientListController`, or an abstract list.

**Consequences.** A line dragged across a heading keeps its own `section`,
so D156's run rule can show an extra heading until
`phase8-ingredient-sections-edit`. Resolved there: a dropped line takes the
heading above it (D163 #1).
