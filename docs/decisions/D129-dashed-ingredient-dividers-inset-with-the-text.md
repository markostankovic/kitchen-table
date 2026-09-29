# D129 — The ingredient row's divider is dashed on all three surfaces, drawn inside the row and inset with the text; recipe steps are a timeline
**Status:** active
**Touches:** lib/core/ingredients/widgets/ingredient_line_row.dart, lib/core/theme/kitchen_colors.dart, lib/features/recipes/presentation/recipe_detail_screen.dart, docs/DESIGN_SYSTEM.md

**Decided.**
1. **The solid hairline under `IngredientLineRow` is a dashed divider**:
   6dp on, 4dp off, 1dp, butt caps, in a new `KitchenColors.dividerDash`
   (alias of `outlineVariant`). It is a private `_DashedLinePainter`, keyed
   `ingredientDivider`, and not a package (rule 8).
2. **All three surfaces that share the row get it**: recipe detail, the
   shopping list and import review. The row stays identical everywhere.
3. **An inset row insets its dashes `md` on both sides**, so they start and
   end at the text. The flagged tint and the 3px marker still run the full
   width.
4. **The divider is drawn inside the tinted container**, with the 48dp
   minimum moved onto the content minus the divider's 1dp. So the tint and
   marker reach the dashes with no gap, a one-line row is still exactly
   48dp, and the dashes sit at the row's bottom edge.
5. **The last ingredient on recipe detail draws no divider** (`Recipe@1x.png`).
6. **Steps are a timeline**: a 2dp `KitchenColors.stepConnector` line
   (alias of `outlineVariant`) runs from each disc to the next, stopping 4dp
   short of both. The 24dp gap between steps sits inside the step above, so
   the line crosses it and stretches with wrapped text. There is no line
   above step 1 or below the last step. The 2, 4, 6 and 4 are private consts
   in the one file that uses each, not `AppSizes` members.

**Why.**
- The user chose dashed dividers on all three surfaces, which was also
  Claude Design's recommendation. One shared row should not grow a
  per-surface stroke flag.
- The dashes are inset because `Review import@1x.png` draws them starting at
  the text. A full-width dash under an inset row would line up with nothing.
- Point 4 is a deviation from the slice plan, which put the divider below
  the container. That would leave the 1dp strip outside the tint and, on a
  one-line row, put the dashes above the 48dp bottom with 3dp of empty space
  under them.

**Rejected.**
- A dash package (rule 8), or `Border` tricks (Flutter has no dashed border).
- Dashes on recipe detail only, with solid lines on the list and import
  review. That would need a flag on the shared row for no reader benefit.
- Full-width dashes under inset rows.
- `AppSizes` tokens for the four new numbers. Each is used in one file only
  (`_markerWidth`'s precedent).

**Consequences.**
- The divider must never read as the unmatched ring. The ring is small,
  closed, 1.5dp, 8 dashes and in `outline`; the divider is long, flat, 1dp
  and in the lighter `outlineVariant`. Keep them apart if either changes.
- Tests find the divider by key, not by `Border.bottom`
  (`ingredient_line_row_test.dart`, `shopping_list_screen_test.dart`).
- Known nit from the recipe-detail walk: the pattern restarts every 10dp
  from the left, so it ends up to ~9dp short of the right edge when the
  width is not a multiple of 10. Spreading the leftover across the gaps
  would fix it.
