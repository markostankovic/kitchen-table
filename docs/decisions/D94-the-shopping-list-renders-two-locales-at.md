# D94 — The shopping list renders two locales at once: the snapshot in `list.locale`, the chrome in the reader's
**Status:** active
**Touches:** lib/features/shopping_list/presentation/shopping_list_screen.dart

**Decided.** `_ListBody` -- category headings, `_GeneratedAt`'s dates, item
quantities -- renders in `list.locale` (`shopping_lists.locale`, migration
16), looked up once via `lookupAppLocalizations(Locale(list.locale))` on
`ingredient_line_field.dart`'s own precedent (D86). Everything around it --
the `AppBar`, `_RangeBar` (which describes the list about to be *generated*,
not the one on screen), `_EmptyState`, every snackbar and every error --
renders in the reader's own locale, `AppLocalizations.of(context)`, same as
every other screen. `MealPlanScreen` has no equivalent split: a meal plan is
live data, not a snapshot, so it stays reader's-locale throughout.

**Why.** A generated shopping list is a document already written in one
language; `shopping_lists.locale` exists precisely so it does not render
half-translated after a later locale toggle (migration 16's own comment).
`_ItemTile` had already made this fix for unit names, one column over,
before this part existed (Phase 3 part 2/3, folded into D81's own naming);
this decision is that same argument generalized to the rest of the
document, not a new one.

**Rejected.** Rendering the whole screen in the reader's locale, letting the
snapshot's own words drift from the language it was generated in. Rejected
because it is exactly the bug `shopping_lists.locale` was added to prevent,
now visible on headings and dates instead of unit names.

**Consequences.** A category code the catalog has not yet been taught
(`test/features/shopping_list/shopping_list_screen_test.dart`'s
`'zzz-not-a-real-code'` case) falls through to itself rather than vanishing
or being folded into "Other" -- the uncategorised bucket is its own sentinel
now, not the display string `'Other'` doing double duty as a map key.
`ingredients.category` is a ten-code vocabulary (`produce fruit dairy meat
fish pantry spice bakery beverage nuts`), not eight -- the two-line CSV
comment this was cited from wraps, and both new codes got ARB keys here.
