# D102 — Filter in Dart, single-select tag keyed on the normalized form
**Status:** active
**Touches:** lib/features/recipes/data/recipe_repository.dart, lib/features/recipes/domain/recipe_tag.dart, lib/features/recipes/domain/recipe_filter.dart, lib/features/recipes/application/recipe_providers.dart, lib/features/recipes/presentation/recipe_list_screen.dart

**Amended (Phase 6, part 2):** `_filtered` is now a thin call into
`RecipeFilter.apply` (`lib/features/recipes/domain/recipe_filter.dart`) — the
same predicate, extracted to a pure-Dart file so it's unit-testable without a
database. A refinement, not a reversal: filtering still runs in Dart, after
decode, at the same call site, still two primitives plus the query string on
the provider family.

**Decided.** The recipe list's tag and favorites filters run in Dart, after
decode, in `RecipeRepository._filtered` — the same place and shape the
title search already uses (D67's cache-then-network emissions, both
filtered). `recipes.tags` stays an unindexed array column; no Drift column,
no schema change. Tag selection is single-select, keyed on
`TextNormalizer.normalize(tag)` rather than the display spelling, so
`Posno` and `posno` are one filter entry. The family's new args
(`recipeListProvider`) are two primitives — `String tag`, `bool
favoritesOnly` — not a freezed filter object.

**Why.** Filtering an already-fetched, already-cached list costs nothing new
to fetch and reuses D67's two-emission shape without touching it. Riverpod
families key on value for primitives but on identity for a `List`/object
argument, so a `List<String>` (multi-select) or a filter object would mint
a fresh provider entry on every rebuild even when the effective filter is
unchanged — two primitives sidestep that entirely. Keying on the normalized
form (not the display spelling) means the chip for "Posno" and one for
"posno" are the same selection, matching how the title search already
treats diacritics and case as insignificant.

**Rejected.** Promoting `tags` to a queryable Drift column, the way
`titleNormalized` was promoted out of the blob — costs another
`schemaVersion` bump and buys nothing while a household's recipe count is
small; the ROADMAP explicitly left this open "with a real recipe count in
front of you," and this slice didn't have one. Multi-select tags via a
`List<String>` family arg or a freezed filter object — more state shape
than a single-select chip row needs; the freezed-object route is the
documented escape hatch if multi-select is ever built.

**Consequences.** Promoting `tags` to a Drift column remains the answer once
a household's list is large enough to feel Dart-side filtering, or once
multi-select is wanted (a freezed filter object, at that point). The gap
this section used to describe — a household with zero tags having no way to
reach the Favorites filter, because the row hid whenever the vocabulary was
empty — is closed by D111: the row's visibility is now bound to the recipe
list, not the tag vocabulary.
