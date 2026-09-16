## D65 — The cache stores the server's own wire shape in one JSON column; `ShoppingList` gains `updatedAt`, not `deletedAt`

**Decided.** `ShoppingListCache.data` and `UnitCatalogCache.data` hold exactly
the map a network response would otherwise produce and discard —
`ShoppingListWire.toWire()` / `shoppingListFromWire()` in
`features/shopping_list/data/dto/shopping_list_dto.dart` serve a Supabase row
and a cache blob with the one decoder, and `unitCatalogRowsToWire()` /
`unitCatalogRowsFromWire()` do the same for the two raw row arrays
`fetchUnitCatalog()` used to build and discard. `ShoppingList` gains a
required `updatedAt` field (`shopping_list_repository.dart`'s old
`_listColumns` already selected `updated_at` and threw it away); it gains no
`deletedAt` — see D68.

**Why.** One definition of "what a shopping list looks like on the wire" is
rule 6's own argument (one definition per side, verified against a shared
fixture) applied to a wire shape instead of a normalization function. The
alternative — building `ShoppingList`/`UnitCatalog` and re-serializing the
built object — cannot even be done honestly for the unit catalog:
`UnitCatalog._byAlias` and `_displayNames` are private with no getters, so a
built catalog cannot be re-serialized without widening its API for a reason
that has nothing to do with what the catalog is for. Caching the raw rows
instead also keeps `units.to_base` as the exact string PostgREST sent, which
is the whole of D60's guarantee — a second encode/decode through
`UnitCatalog`'s own `toBase` `double` would round it twice.

`updatedAt` is added truthfully now, on no live consumer yet, because a
household-scoped cache row with a column that has always lied is worse than
not having the column — see D71 for why this is not the same shipping-ahead
argument D35/D51 made.

**Rejected.**
- A second, generated serialization of `ShoppingList`/`UnitCatalog` (freezed
  `toJson`/`fromJson`) — would need a `Rational` converter for one and cannot
  be written for the other at all (see above), and would be a second
  definition of the wire shape to keep in step with the first.
- A `deletedAt` field on `ShoppingList`, "for symmetry" with `updatedAt` — it
  would be null in every instance the app can ever hold; see D68.
