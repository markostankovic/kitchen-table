# D124 — The form vocabulary: `AppFieldLabel` and `AppActionBar` in `core/widgets/`, a two-row numbers row, onboarding on `titleLarge`, and the match chip's status words following the reader
**Status:** active
**Touches:** lib/core/widgets/app_field_label.dart, lib/core/widgets/app_action_bar.dart, lib/features/recipes/presentation/recipe_edit_screen.dart, lib/features/recipes/presentation/translation_review_screen.dart, lib/features/import/presentation/, lib/features/households/presentation/create_household_screen.dart, lib/features/households/presentation/join_household_screen.dart, lib/core/ingredients/widgets/ingredient_match_chip.dart, docs/DESIGN_SYSTEM.md

**Decided.** Phase 7 part 7 puts every remaining form on one vocabulary.
Five calls:

1. **`AppFieldLabel` is promoted to `core/widgets/`.** It is `titleSmall`
   and has no padding of its own: the call site writes `sm` to its field
   and `lg` to the next label. It is used by four features: recipes, import,
   households and (already) import review.
2. **`AppActionBar` is promoted to `core/widgets/`.** It is D123's bar,
   lifted whole: `surface`, a 1dp `outlineVariant` hairline, padded
   `lg`/`md`, and an optional already-localized error line. The call site
   supplies the child and the busy spinner. It is used by recipes (the editor
   and translation review) and import (paste, URL, photo, review).
   Onboarding does not use it, because it has no app bar and centres its
   form.
3. **A row of short fields labels its columns in a separate row**, with the
   labels bottom-aligned above the fields. A wrapped label pushes all the
   fields down together instead of staggering them.
4. **Onboarding titles are `titleLarge`**, not `headlineSmall`, which is
   reserved for a recipe's own title. The join code is `titleLarge` with
   `sm` letter spacing and tabular figures.
5. **The match chip's status words follow the reader.** These are `No
   match` / `Nema poklapanja` and the `{name}?` wrapper. The amount, units,
   suggested name and field hint still follow the recipe. This narrows the
   chip's old "all in the recipe's own language" comment under D86: the
   status words are chrome, not recipe content.

**Why.** Both widgets were written out privately in two or more places, and
every copy disagreed a little (`_FieldLabel` was in `labelLarge`, a
button's role). Each bottom save button sat in a bare padded `SafeArea`
that merged into the nav bar. At 360dp each numbers column is about 101dp
wide, and `Priprema (min)` in `titleSmall` can wrap. Part 6's walk read
`Nema poklapanja` under an English reader.

**Rejected.**
- Baking a `FilledButton` or spinner into `AppActionBar`: import review's
  child is a two-button `Row`.
- Floating labels (`labelText`) kept for the short fields.
- A single `Row` of labelled columns for the numbers.
- Putting the onboarding button on `AppActionBar`.
- Moving the hint or unit names to the reader, which would break D86's
  "an example of what to type in this recipe".

**Consequences.** Every `TextField` still needs `style: bodyMedium` at its
call site, because the typed style cannot be themed. The photo import's
pickers became `Camera` / `Gallery` (`Kamera` / `Galerija`), matching the
editor's own words: on the walk, `Izaberi fotografiju` wrapped even at `lg`
padding. Those are ARB value changes only; the keys stayed.
