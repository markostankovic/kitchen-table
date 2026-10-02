# D140 — The editor's vocabulary: one grip for every reorderable row, a 16:9 photo well, labelled steps, a ringed original
**Status:** active — amends D134 (the `dragHandle` grip is no longer the meal plan's alone); D84 stands
**Touches:** lib/features/recipes/presentation/recipe_edit_screen.dart, lib/features/recipes/presentation/translation_review_screen.dart, lib/core/ingredients/widgets/ingredient_line_field.dart, lib/core/theme/app_sizes.dart, docs/DESIGN_SYSTEM.md

**Decided.** For frames 08–09 of round `sync-design-initial` (2026-10-02):
1. **One grip.** Every reorderable row (meal-plan entries, the editor's
   ingredient and step rows, the import review's lines through
   `IngredientLineField`) draws `Icons.drag_indicator` at `AppSizes.grip`
   (20) in `KitchenColors.dragHandle`. `Icons.drag_handle` is gone.
2. **The photo well.** 16:9, `surfaceContainerHighest`, radius `md`. Empty,
   a 32dp `image_outlined` in `outline`, `md`, then tonal Camera / Gallery
   in a `Wrap` (`sm` apart). Filled, the photo in the same 16:9 box at
   radius `md`, then `sm` and the tonal row with the remove button.
3. **A step is labelled, not hinted:** `AppFieldLabel` `Korak N` / `Step N`
   above its row, indented past the grip; steps `md` apart.
4. **The review's original** is a `docLanguage` panel with a 1dp
   `outlineVariant` ring, radius `sm`, padded `md`/`sm`, still above its
   field. The review opens with the detail's tonal Machine translation badge.

**Why.**
- Two grips for one gesture said two different things; the meal plan's is
  quieter and already tokenised.
- A shared 16:9 shape means the well and the photo occupy the same box, and
  an empty well says "a photo goes here" where two bare buttons did not.
- A hint vanishes the moment the cook types, taking the step number with it.
- Dark `docLanguage` (`#1C1C16`) on `#16160F` is invisible without its
  ring, which is the token's own definition.

**Rejected.**
- The frame's original *below* the field: D84.
- The frame's app-bar Save with a ✕ and no bottom bar (D124): no
  unsaved-changes guard exists for the ✕ to promise.
- Static ingredient text with dashed dividers: rule 3 keeps editable lines.
- A 144dp well: it would not match the photo's 16:9.
- A `Row` for the well's buttons: it overflows at a large text scale (and
  under `flutter_test`'s Ahem font at 360dp in Serbian).
- A shared `core/widgets/` photo well or original panel: one user each.

**Consequences.** Picking a photo still moves the form by the button row
under it (~55dp); only the image box is shared. The review in Serbian
chrome and the import review's grip were not seen on a device.
