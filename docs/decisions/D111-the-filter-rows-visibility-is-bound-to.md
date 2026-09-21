# D111 — The filter row's visibility is bound to the recipe list, not the tag vocabulary
**Status:** active
**Touches:** lib/features/recipes/presentation/recipe_list_screen.dart

**Decided.** `_FilterRow` now renders whenever the household's unfiltered
recipe list (`recipeListProvider()`) is non-empty, or a filter is already
selected (`selectedTag` set, or `favoritesOnly`) — not, as before, only when
the tag vocabulary is non-empty or a filter is already selected. A household
with recipes but zero tags now sees the row, with only the Favorites chip in
it. Zero recipes is still zero row.

**Why.** Closes D102's own open consequence: with the old guard
(`chips.isEmpty && !favoritesOnly`), a household whose recipes carry no tags
at all had no way to ever reach the Favorites filter, since the row that
carries it never rendered. Binding to the recipe list instead of the tag
vocabulary fixes that directly — Favorites doesn't depend on tags existing,
so its row shouldn't either. Keeping the "filter already selected" clause
prevents the row from disappearing mid-selection while `recipeListProvider()`
is momentarily loading.

**Rejected.** Giving the Favorites toggle its own row, separate from the tag
chips — more layout for no behavioural gain, and the two are one row of
`FilterChip`s conceptually. Rendering the row unconditionally (even for zero
recipes) — rejected per the slice's own spec; an empty household should see
no filter affordance at all, matching the empty-state screen it gets instead.

**Consequences.** None outstanding — this was D102's own named gap, and it's
now closed rather than deferred.
