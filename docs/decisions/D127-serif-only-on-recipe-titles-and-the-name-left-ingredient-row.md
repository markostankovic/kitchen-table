# D127 — Serif only on recipe titles and the wordmark, through `displaySmall` and a `KitchenType` extension; ingredient rows go name-left / amount-right
**Status:** active — supersedes the Type half of D118
**Touches:** lib/core/theme/app_theme.dart, lib/core/theme/kitchen_type.dart, lib/core/theme/app_sizes.dart, lib/core/ingredients/widgets/ingredient_line_row.dart, lib/features/recipes/presentation/recipe_detail_screen.dart, lib/features/import/presentation/import_review_screen.dart, lib/core/recipes/widgets/recipe_card.dart, lib/features/meal_plan/presentation/meal_plan_screen.dart, docs/DESIGN_SYSTEM.md

**Decided.**
1. **Literata reaches a screen only through `displaySmall` (the wordmark)
   or `KitchenType`.** Every other Material role is the platform sans.
   `bodyLarge` is 18/28. `KitchenType` is a `ThemeExtension`, shaped like
   `KitchenColors`, with two members:
   - `recipeTitle` (18/24): cards and plan entries;
   - `recipeTitleLarge` (26/32): the detail title and a card's monogram
     letter.

   Both are w600 `onSurface`.
2. **`headlineSmall` is sans**, against the design PDF, which kept it
   Literata. The Household mock draws `Kod Mire` in sans at that size, so the
   serif moved to a recipe-named token instead of a role.
3. **The ingredient row is name-left / amount-right.** The unit rides with
   the number (`½ kg`) in one `Text.rich` that never wraps. The number is
   `primary` w600 with tabular figures, and amounts line up on the right edge.
   - `optionalLabel` is inline after the name.
   - The unmatched ring is inline after the name, glued to the last word with
     a U+2060 word joiner.
   - `inset` pads the content `md` on both sides. Import review sets it on
     every row; a flagged row is always inset.
4. **An optional line shows the inline `opciono` only when it has no note.**
   The parser moves the marker (`po ukusu`, `opciono`) into the note.
5. **A recipe-detail line with no catalog name gets no amount of its own.**
   Its raw text already carries it (rule 3).

**Why.**
- The all-serif scale put the serif on steps, headings and app bars, and
  read heavy. The user picked option (b) on Claude Design's recommendation:
  keep the serif where it names a recipe.
- A role-based serif (`headlineSmall`) would leak onto non-recipe text such
  as the household name. A named token cannot.
- The "unit rides with the name, `½ kg mlevenog mesa` is one phrase" reason
  for the old row is inverted by the mock. Amounts aligned on the right scan
  better in a shop and on a stove.
- Points 4 and 5 and the ring's word joiner came from the device walks:
  - `limun · opciono` over an `opciono` note;
  - `1,5 kg mesa` beside `1½ kg`;
  - a ring stranded on its own line.

  The inset came from comparing with `Review import@1x.png`, where every row
  is inset so flagged names line up.

**Rejected.**
- All-sans, which would lose the only domestic cue in the type.
- Keeping `headlineSmall` Literata, as the PDF does.
- A 14dp ring token. 16 is `iconInMeta`, and a token for a 2dp difference is
  not worth it.
- Insetting only the flagged row, as the slice first planned. It put flagged
  names out of line with their neighbours.
- A trailing column for the ring.
- A font package (rule 8).

**Consequences.**
- The sign-in tagline is sans.
- Fields still pass `style: bodyMedium`, now for size rather than face.
- `stepDisc` is 28, one `bodyLarge` line. Steps are `lg` from the disc and
  `xl` apart. Stat values are w600.
- Unmatched names in tests need `find.textContaining`: the word joiner and the
  placeholder are part of the run's plain text.
