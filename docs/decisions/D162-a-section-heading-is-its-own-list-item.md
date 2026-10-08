# D162 — A section heading is its own list item, laid out by a pure helper
**Status:** active
**Touches:** lib/core/ingredients/widgets/ingredient_list_layout.dart, lib/core/ingredients/widgets/ingredient_lines_editor.dart, test/core/ingredients/ingredient_list_layout_test.dart

**Decided.** Round `2026-10-06-round-2-recipe-structure`, canvas § A4 (A4·4),
`phase8-ingredient-sections-edit`, 2026-10-08. **Amends D157 #4.**
1. **Each heading is its own child of the `ReorderableListView`**, not part
   of its first line's child. A line can then be dropped between a heading
   and its first line.
2. **A pure helper lays the list out** (`ingredient_list_layout.dart`, no
   Flutter import): a sealed `IngredientListItem` of `LineItem(lineIndex)`
   and `HeadingItem(start, end, section)`. `[start, end)` is the heading's
   **visual run**, up to the next heading, so it includes D156's
   null-continuation lines. `ingredientListItems(lines, {openHeadingLineId})`
   adds a heading where D156 starts a group, **or** at the open heading's
   line, so a heading being named stays a heading while it is blank or,
   mid-word, equal to the group above.
3. **Item indices map back to line indices only in the helper**
   (`resolveLineDrop`, `resolveRunDrop`; D163), never in the widget.
4. The widget's callbacks become `onMoveLine(old, new, section)`,
   `onMoveRun(start, end, newIndex)` and `onSetSections(map)`, replacing
   `onReorder`.

**Why.**
- With the heading inside the first line's child, a drop there was
  impossible: the only drop point put the line above the heading.
- A pure helper makes the drop rules testable without a widget tree, the
  same reason `RecipeDraft` is pure (D12).

**Rejected.**
- Keeping headings in line children and adding a "drop into group" gesture.
- Index mapping inside the widget's `onReorderItem`.

**Consequences.** A line drops its divider before *any* heading item,
the open one included.
