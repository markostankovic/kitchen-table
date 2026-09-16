## D66 — Writing the cached list is delete-then-insert, scoped to the household, not `insertOnConflictUpdate` alone

**Decided.** `LocalShoppingListDataSource.upsertLatest` deletes whatever row
the household already has, then inserts the new one, in one transaction.
`ShoppingListCache` also carries a `uniqueKeys` constraint on `householdId`,
as a defensive backstop.

**Why.** Found by the first test written against it, not by reading:
`insertOnConflictUpdate`'s conflict target is the PRIMARY KEY, which is the
list's own `id` — so writing a *regenerated* list (a new `id` for a household
that already has a cached row under the old one, the ordinary case
`ShoppingListRepository.watchLatest` writes through on every successful
network read once anything has ever been cached) is a plain INSERT against
that key, not an update of the existing row. Without the fix, that INSERT
either leaves two rows for one household or — once the `uniqueKeys`
constraint below is added — trips it and gets silently swallowed by
`cacheWrite`, leaving the stale row in place forever. Delete-then-insert
makes "one row per household" this method's own guarantee rather than a
discipline every caller (`watchLatest`'s write-through, `generate()`,
`discard()`) has to independently get right.

The `uniqueKeys` constraint stays even though `upsertLatest` alone now makes
it unreachable through any real code path: it is what turns "a household
only ever has one live list at a time" from a claim several doc comments make
into something the schema itself refuses to violate, and it is what keeps a
future bug that writes around `upsertLatest` from corrupting
`readLatest`'s `getSingleOrNull` instead of failing loudly (well, quietly —
see D69) at the point of the bad write.

**Rejected.** `insertOnConflictUpdate` alone, trusting every caller to evict
first — this is exactly the assumption the first test written against it
disproved.
