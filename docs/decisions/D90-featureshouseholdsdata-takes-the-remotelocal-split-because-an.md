## D90 — `features/households/data/` takes the Remote/Local split, because an untested read order is what D87 is a report about

**Decided.** `HouseholdRepository` is now composed from
`RemoteHouseholdDataSource` and `LocalHouseholdDataSource`, the fourth
Remote/Local split after shopping_list (Phase 2 part 5), recipes (part
6a) and meal_plan (part 6b).

**Why D70's precedent does not transfer.** D70 declined this same split
for `IngredientRepository` — "one cached method out of six" — and kept a
bare `SupabaseClient` field with the network call inlined.
`fetchUnitCatalog()`'s own network-first-with-fallback read order has
never had a test as a direct consequence: `unit_catalog_cache_test.dart`
proves the cache round trip, never the repository's `try`/`on
NetworkFailure` branching, because there was no seam to fake
`SupabaseClient` against. D87 exists precisely because an unverified
offline read order shipped and stayed that way for two phases. Repeating
the same untested shape to fix it would be the wrong lesson to draw from
it, even though households is — by the same "one cached method" count —
exactly as small a candidate for the split as ingredients was.

`household_repository_offline_test.dart` is what the split buys:
`_FakeRemote implements RemoteHouseholdDataSource` (`recipe_repository_
offline_test.dart`'s own shape — `implements`, not `extends`, so a test
that accidentally reaches an unstubbed method throws by omission), proving
the network-first/cache-fallback/cold-cache-rethrows/wrong-household-
eviction behavior directly rather than only on the emulator.

**Rejected.** Leaving `HouseholdRepository` as a single file and proving
the fix only on the emulator walk — the walk still happened (it is how
D87 was found in the first place), but a fix whose read order can only be
proven by a manual walk is the exact shape of gap this decision closes.
