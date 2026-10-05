# D143 — Adding a meal is one sheet: the day, the slot as chips with Dinner preselected, then a recipe or a note
**Status:** active — amends D121 #1 (the slot chooser is gone) and D132 (`+ Dodaj obrok` opens this sheet, not the slot chooser)
**Touches:** lib/core/recipes/widgets/recipe_picker_sheet.dart, lib/features/meal_plan/presentation/meal_plan_screen.dart, docs/DESIGN_SYSTEM.md

**Decided.** For frames 15–17 of round `sync-design-initial` (2026-10-05,
the user's choice):
1. **A day's `+ Dodaj obrok` opens one sheet**, `showRecipePicker(context,
   day:, initialSlot:)`, which returns `({MealSlot slot, RecipePick pick})?`.
   From top to bottom it shows the title `Dodaj obrok` (`titleMedium`), the
   day's `shortDateLabel` directly under it (`bodyMedium`
   `onSurfaceVariant`), the four slots as `ChoiceChip`s in a `Wrap`, the
   search field, the `RecipeCard` results and `Add a note instead`.
2. **Dinner is preselected, and exactly one slot is always selected.** Every
   slot is offered, filled ones included, which is how a second entry gets
   into a slot.
3. **The search field is not autofocused.** The sheet opens on the slot
   choice above it, and at 0.8 of the screen the keyboard would cover the
   results.
4. **The chips are a `Wrap`, never a scrolling row.** In English `Snack`
   wraps to a second row, and in Serbian all four fit on one.
5. The sheet keeps its home in `core/recipes/` (D53) and keeps `RecipeCard`
   rows. It writes nothing: the meal plan acts on the result. The
   snack-repeat advisory (D58) runs on the returned slot.

**Why.**
- Two sheets cost one more tap, and neither of them showed the date.
- Dinner matches the recipe detail's `Add to meal plan` sheet, which has
  defaulted to it since Phase 4, so the two ways in agree.
- A `Wrap` cannot hide a slot behind a scroll. Serbian labels run long.

**Rejected.**
- **Preselecting the first empty slot.** It is a guess that silently files a
  meal into breakfast.
- **The frame's compact 48dp monogram rows.** `RecipeCard` in this sheet is
  what justifies its home in `core/recipes/` (D53). The user chose to keep it.
- **Keeping two sheets.** One more tap, and the date is never shown.
- The frame's `titleLarge` title and its horizontally scrolling chip row.
- The frame's `Added to …` snackbar with Undo. The user deferred it to a
  later slice.

**Consequences.** `_showSlotChooser` and `_chooseSlotThenAdd` are deleted.
Any future way into a day (a per-slot button, a FAB) passes `initialSlot`
rather than adding another sheet.
