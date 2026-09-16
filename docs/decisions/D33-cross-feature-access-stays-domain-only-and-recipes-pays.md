## D33 — Cross-feature access stays `domain`-only, and `recipes` pays for it

**Decided.** `tool/check_layers.dart` allows a cross-feature import only into
another feature's `domain/`, and that rule was kept when Phase 1c needed things
that live behind `features/ingredients/` and `features/households/`. `recipes`
therefore carries its own copy of catalog access
(`lib/features/recipes/data/ingredient_catalog_datasource.dart`) and its own
household lookup (`RecipeRepository._currentHouseholdId`).

**What it costs.** The `search_ingredients` RPC contract exists twice. So does
the unit-catalog fetch, the `numeric`-arrives-as-`String` handling, and the
`households` select that `HouseholdRepository.fetchCurrent` already does. Three
duplications, all small, all in `data/`.

**Why.** The alternative was to relax the checker so `recipes/data` could import
`ingredients/data`, and the checker is the only thing making the layering real
— `docs/ARCHITECTURE.md` says "enforced by lint, not by documentation". A rule
that gets an exception the first time it costs anything is not a rule. The
duplication is also honest about what it is: the copy lives in its own file with
a header saying so, rather than smeared through the repository.

**Revisit when** a third feature needs `search_ingredients`. Phase 2's shopping
list is the likely one. That is the signal to reopen this and pull the catalog
into a shared place — not to write a third copy.
