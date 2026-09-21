# D108 — The tag name cache is replace-wholesale per household
**Status:** active
**Touches:** lib/core/db/app_database.dart, lib/features/recipes/data/local_recipe_datasource.dart, lib/features/recipes/data/recipe_repository.dart

**Decided.** `RecipeTagNameCache` carries no `SyncWatermarks` entry and is
never delta-synced. `LocalRecipeDataSource.replaceTagNames` deletes the
household's cached set (its own rows plus every previously-cached global
row) and inserts whatever the latest fetch returned, in one transaction —
`UnitCatalogCache`'s "a successful fetch replaces the row outright"
reasoning, scoped per household instead of to one global row, rather than
`IngredientNameCache`'s watermark-and-upsert sync.

**Why.** A watermark exists to make a large, slowly-changing catalog cheap
to keep current without refetching it whole every time — the ingredient
catalog is hundreds of rows. One household's tag vocabulary is a handful of
pairs; the cost of fetching everything on every `fetchTagLabels` call is
negligible, and a wholesale replace needs no tombstone handling at all — a
row the server has since soft-deleted is simply absent from the next fetch,
with nothing left over to evict.

**Rejected.** `IngredientNameCache`'s own shape (a `SyncWatermarks` row,
`upsertNames`/`evictName`, delta fetch since last sync) — the precedent the
slice plan pointed at first, rejected once the row count made a watermark's
complexity not worth carrying for a household-scoped table this small.

**Consequences.** A device offline since a translation pair was added won't
see it until the next successful `fetchTagLabels` network round trip —
acceptable, since the same is already true of `UnitCatalogCache` and the
tag vocabulary changes far less often than a recipe does. If this table
ever needs to scale past "one household's pairs" (a shared cross-household
vocabulary, say), the watermark story would need revisiting rather than
assumed to still not be worth it.
