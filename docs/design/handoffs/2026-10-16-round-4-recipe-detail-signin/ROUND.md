# Design round: round-4-recipe-detail-signin

Source: Claude Design handoff, 2026-10-16. Prompt: `PROMPT.md`. Bundle: `bundle/`.

The canvas is `bundle/Kitchen Table App.dc.html`, the same whole-app canvas
round 1 (`2026-10-02-sync-design-initial`) shipped. Diffed against round 1's
copy, it changes in exactly two places and nowhere else:

1. **Sign in** (§ `01 · Sign in`, around line 39): the
   `<img src="assets/recipe-card.png">` illustration and its 40 bottom margin
   are removed. The lockup (48 high), tagline and Google button are unchanged,
   and the content block is still centred vertically.
2. **Recipe detail** (`data-screen-label="Recipes"`, around lines 179–184):
   the Ingredients heading and its rows now sit inside a card:
   `background: var(--card)`, radius 12, padding `16 16 4`, 24 below the stat
   row. The heading's own top margin is gone, because the card padding
   provides it. Steps stays outside the card, 32 below it, unchanged.

## Token delta

None. `_ds/` (`_ds_bundle.js`, `styles.css`, every file in `tokens/`) and
`support.js` are byte-identical to round 3's. `assets/mark-master.svg` is the
same drawing as `docs/design/logo/mark-master.svg`. The remote copy only adds a
C2PA provenance block. The new card uses only existing names: `--card` →
`KitchenColors.card`, radius 12 → the card radius (§ Cards), and padding
16 / 4 → `AppSpacing.lg` / `AppSpacing.xs`.

So there is **no tokens slice** in this round.

One size goes away: `AppSizes.signInIllustration` (176) and its
§ Size and motion row, along with § Token map's `assets/recipe-card.png` →
`SignInIllustration` row. The sign-in slice removes them.

## Token map additions

None.

## Slices, in order

- [x] `phase9-recipe-detail-ingredients-card` (`2686df5`, D176): Recipe detail. Files:
      `lib/features/recipes/presentation/recipe_detail_screen.dart` (the
      `AppSectionHeading` + `_ingredientRows` block, around lines 532–547),
      possibly `lib/core/ingredients/widgets/ingredient_line_row.dart` if
      the last row's divider or padding needs to change inside a card, and
      `docs/DESIGN_SYSTEM.md` § Ingredient lines / § Cards. Bundle:
      `Kitchen Table App.dc.html` lines 170–190 (the recipe detail mock).
      This wraps the ingredients heading, the "for N servings" trailer and
      every row in one `KitchenColors.card` card (radius 12, padding 16
      sides/top and 4 bottom), with no dashed divider under the last row.
      **Planner checks:** where ingredient section headings
      (`RecipeGroupHeading`) and the "No ingredients yet" text sit inside the
      card (the mock has neither); whether `_RecipeNotesCard` on the same
      screen is the precedent to reuse; and that the Steps heading spacing
      below the card still comes out at 32. The editor and import review
      ingredient lists are **not** in scope, because the canvas leaves them
      bare.
- [ ] `phase9-sign-in-no-illustration`: Sign in. Files:
      `lib/features/auth/presentation/sign_in_screen.dart`,
      `lib/features/auth/presentation/sign_in_illustration.dart` (deleted),
      `lib/core/theme/app_sizes.dart` (`signInIllustration` removed),
      `test/features/auth/sign_in_screen_test.dart`, and
      `docs/DESIGN_SYSTEM.md` § Size and motion and § Token map. Bundle:
      `Kitchen Table App.dc.html` lines 30–45 (the sign-in mock). This drops
      the illustration and its `xxl + sm` gap. The lockup, tagline and Google
      button stay centred as today. It partly supersedes D137 (the
      illustration half), so `/close-slice` records a new decision. Check
      whether `assets/recipe-card.png` or anything under `assets/` was kept
      only for the illustration (D137 says it is painted, not the PNG).

Order: either order works, since the slices share no files. The recipe
detail goes first because it has the open layout questions.

## Out of scope

- **The canvas chrome**: the status-bar mock, row labels, the `#E9E4DB`
  canvas, and the annotation hex. This is web presentation only.
- **Every other screen in the canvas**: unchanged since round 1 and
  already built.
- **`readme.md`'s "One flat illustration exists (sign-in)"**: the design
  system's own readme is now stale. That is a note for the Claude Design
  project, not this repo.
- No new package is needed, and nothing here contradicts a Hard rule in
  `CLAUDE.md`.
