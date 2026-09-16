## D64 — The Drift database lives in `core/db/`, and `check_layers.dart` gets a second `core/` exemption for it

**Decided.** `lib/core/db/app_database.dart` holds `AppDatabase`, its two
tables and the `appDatabaseProvider` that constructs it. `tool/check_layers.dart`'s
drift rule (`if (uri.startsWith('package:drift'))`) gains a `lib/core/db/`
arm, exactly parallel to the `lib/core/supabase/` arm `supabase_flutter`
already has.

**Why.** One SQLite file is inherently shared, and Phase 2's remaining parts
put three more features on it (recipes, meal plans, the ingredient name
catalog). D33's "duplicate until a second caller shows up, then move to
`core/`" rhythm assumes the intermediate shape — the thing living in one
feature's `data/` while a second feature needs it — is legal. It is not,
here: `features/recipes/data/local_recipe_datasource.dart` importing
`features/shopping_list/data/app_database.dart` is exactly the cross-feature
import `_checkImport` refuses. The second, third and fourth callers are
already known, so paying the `core/` move now is not shipping ahead of a
need — it is the same move D43 made for the ingredient catalog and D52 made
for `currentHouseholdIdProvider`, on the same schedule those were made.

**Rejected.**
- One SQLite file per feature — four openers, four `schemaVersion`s, four
  things to wipe on sign-out, for a library whose whole idiom is one database.
- Deferring the move to Phase 2's next part, on the D33 precedent — the
  precedent does not apply; see above.
- Constructing `AppDatabase` from `core/` without ever naming a drift type
  (the D43 move) as the *whole* answer — it is still used at the boundary
  (`ingredient_catalog_providers.dart` and `shopping_list_providers.dart` name
  `AppDatabase`/`LocalShoppingListDataSource`, never `package:drift`), but the
  `@DriftDatabase`-annotated class itself has to import `package:drift`
  somewhere, and that somewhere needs its own sanctioned home.
