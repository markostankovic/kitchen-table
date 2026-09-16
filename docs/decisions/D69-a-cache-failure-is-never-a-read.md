## D69 — A cache failure is never a read failure or a write failure

**Decided.** `lib/core/db/cache_guard.dart` holds `cacheOrElse` (reads: log
and return a fallback) and `cacheWrite` (writes: log and do nothing further).
Every method on `LocalShoppingListDataSource` and `LocalIngredientDataSource`
is wrapped in one of the two. Nothing from `package:drift` — a
`SqliteException` from a corrupt file, a `FormatException` from a blob an
older build wrote in a shape this one no longer decodes — is allowed to reach
`runGuarded`.

**Why.** `runGuarded`'s bare `catch` maps anything unrecognised to
`UnknownFailure` — "Something went wrong" — which is the worst possible
outcome for a cache failure: it reports a local, disposable problem as a
server problem. A failed cache read is a miss and falls through to the
network exactly as if nothing had ever been cached; a failed cache write
costs a round trip next time and nothing else. Per D47, this does not swallow
silently: both functions log under the `AppDatabase` name, the same
best-effort-and-log shape `RecipeEditor`'s orphaned-image cleanup already
uses. Nothing reads that log yet — naming a consumer for it is part of a
later part's admin screen, not this one.

**Consequence worth knowing.** `cacheOrElse`/`cacheWrite` also absorb the
`MissingPluginException` that `path_provider` throws under `flutter test`,
which is what lets every existing widget test go on not knowing the cache
exists: they see a permanent cache miss and behave exactly as they did before
this part.

**Rejected.** Letting a drift exception fall through to `runGuarded`'s bare
`catch` — the `UnknownFailure` mislabelling above.
