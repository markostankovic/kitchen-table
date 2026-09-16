## D70 — Two kinds of cached row, and only one of them reads cache-first or dies with the session

**Decided.** The shopping list cache is household-scoped
(`ShoppingListCache.householdId`), read cache-then-network, and wiped by
`AppDatabase.clearHouseholdCache()` on sign-out
(`SettingsScreen._signOut`, before `AuthRepository.signOut()`). The unit
catalog cache (`UnitCatalogCache`, always exactly one row, key
`unitCatalogCacheKey`) is global, read network-first with the cache only as a
fallback on `NetworkFailure`, and is never touched by the sign-out wipe.

**Why.** A shopping list left on a shared device after sign-out is a privacy
question; `units`/`unit_names` carry no `household_id` at all
(`docs/DATA_MODEL.md`: "two dozen immutable reference rows that only a
migration writes"), are readable by any authenticated caller, and wiping them
would put `3 clove` back on the very first offline session after the next
person signs in — the exact bug this part exists to fix
(`shopping_list_screen.dart`'s old `ref.watch(unitCatalogProvider).value ??
UnitCatalog.empty()` fallback, and `formatItemQuantity`'s `_scaled()` finding
no `kg`/`l` rung on an empty catalog).

The read order differs for the same reason. The shopping list is a
household's own data that changes on someone else's say-so (a second device
regenerating it) and is worth showing stale rather than not at all — the
whole of D12's argument. The unit catalog is reference data with no
`updated_at` of its own to go stale between one session and the next, so
there is nothing to gain from showing a cached answer before a fresh one a
moment later, and network-first means `fetchUnitCatalog()` stays one
emission, a plain `Future<UnitCatalog>`, for a value nothing here treats as a
stream.

**Rejected.** Wiping the whole cache indiscriminately on sign-out — see above.
Cache-then-network for the unit catalog, matching the shopping list "for
consistency" — the two entities do not share the property (staleness has a
size) that makes cache-then-network worth its extra emission.
