## D89 — The household read's bound is a per-request `.retry()`, not a global `postgrestOptions` timeout, because the global option never reaches `.from()` calls

**Decided.** `RemoteHouseholdDataSource.fetchMineRows()` chains
`.retry(count: 1, requestTimeout: const Duration(seconds: 5))` onto the one
call that gates every household-scoped screen. Nothing else in the app is
bounded this way, and nothing at any other call site changed.

**Why not `Supabase.initialize(postgrestOptions: PostgrestClientOptions(
requestTimeout: ...))`, which is where this started.** Verified directly
against the pinned package source
(`supabase-2.16.1/lib/src/supabase_client.dart`,
`supabase_query_builder.dart`): `SupabaseClient.from()` builds a
`SupabaseQueryBuilder` and forwards exactly one field of
`_postgrestOptions` to it — `schema`. Not `retryEnabled`, not
`retryCount`, not `requestTimeout`. Those only reach a call made through
`_client.rest`, i.e. `rpc()`. `fetchMine()`/`fetchMineRows()` is a
`.from()` call. A global timeout would have changed nothing about the bug
it was meant to fix — the fetch would still have hung for minutes.

**`retryCount` would have been dead configuration for this app even where
the option does reach.** `postgrest_builder.dart`'s `_executeWithRetry`
retries `GET`/`HEAD` only; every one of this app's twelve `rpc()` call
sites is a POST, single-shot regardless of `retryCount`. Global retry
tuning was never going to do anything here in either direction.

**Why per-request rather than per-repository-method.** `.retry()` is a
method on the postgrest builder chain, legal in `data/` where
`supabase_flutter` is already imported (rule 1) — one line, on the one
call, with no ripple into `runGuarded` or any call site outside
`RemoteHouseholdDataSource`. `runGuarded`'s `TimeoutException` arm has
caught for it since Phase 1a with nothing to produce one; this is its
first real producer.

**Why Storage, Edge Functions and auth (gotrue) are untouched, and this is
structural, not a choice made carefully each time.** `postgrestOptions`
cannot reach them regardless of what value it holds — confirmed in the
same read of `supabase_client.dart` that found the `.from()` gap. D79's
"`translate-recipe` must stay a long-running synchronous model call" is
therefore safe by construction, not by anyone remembering not to bound it.

**Why not set a global `requestTimeout` anyway, now that its real reach
(RPC only) is known.** It would bound every `rpc()` call, including
non-idempotent POSTs like `create_household` and `save_imported_recipe` —
a client-side timeout on a request the server actually committed turns a
successful write into a visible error. That needs its own idempotency
audit and is not a side effect of fixing D87.

**Rejected.** The global `postgrestOptions` timeout — verified not to
reach the call it was meant to fix. Reducing the global `retryCount` —
verified inert for every RPC call site and irrelevant to a `.from()` call
in the first place. An `httpClient:` wrapper covering every sub-client —
the only option that would also reach Storage/Functions/gotrue, at the
cost of a hand-written `http.BaseClient` and a new decision about what
each of those should be bounded to; out of scope for fixing one hanging
`.from()` call.
