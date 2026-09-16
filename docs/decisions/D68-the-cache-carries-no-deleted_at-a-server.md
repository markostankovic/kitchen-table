## D68 — The cache carries no `deleted_at`; a server tombstone is a hard delete locally

**Decided.** `ShoppingListCache` has no lifecycle column of its own. A row is
either the household's current list, or it is gone.

**Why.** D23 keeps a soft-deleted `shopping_lists` row visible to the
*repository* so a later delta fetch can evict it — it is never visible to the
*screen*, because `RemoteShoppingListDataSource.fetchLatest` already filters
`deleted_at is null`. The cache's job is to answer "what would the server
show me right now", which never includes a tombstone, so the cache has
nothing to remember once a row is retired — only somewhere to stop having it.
`ShoppingListRepository.softDelete` evicts the local row in the same call
that soft-deletes it remotely; `watchLatest` evicts on the household's behalf
when a fresh network read comes back with nothing a cache hit had promised.

**Rejected.** A `deletedAt` column mirroring the server's, "for completeness"
— it would need a value nothing ever writes (an evicted row is deleted, not
marked), and it is the thing D65 explicitly declined to add to `ShoppingList`
for the same reason.
