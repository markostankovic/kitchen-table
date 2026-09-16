## D67 — A cached read is a two-emission `Stream`; reachability is a side-channel, not folded into the provider's value

**Decided.** `ShoppingListRepository.watchLatest` returns `Stream<ShoppingList?>`
— a cache hit (if any), then the network's answer — and `CurrentShoppingList`
is a `StreamNotifier`, not an `AsyncNotifier`. The provider's value type is
unchanged (`ShoppingList?`), so `ShoppingListScreen`'s `AsyncValue<ShoppingList?>.when`
and its test are untouched in shape. Every completed network attempt —
including one whose `NetworkFailure` is swallowed because a cache hit already
went out — reports through `onReachable`/`onUnreachable` callback parameters
to `lib/core/net/network_status.dart`'s `NetworkStatus`, a `keepAlive`
`Reachability` notifier `ShoppingListScreen`'s `_GeneratedAt` reads to show
"Showing your saved copy — no connection."

**Why.** `docs/ARCHITECTURE.md`'s own shape is "emit cached immediately ->
fetch -> upsert cache -> emit fresh", and `StreamNotifier` is the one shape
where the second emission is part of the provider's own lifecycle —
cancelled on dispose, routed into `AsyncValue` with no hand-rolled
`state = ...` after `build()` returns, which an `AsyncNotifier` would need
and which `unawaited_futures` (an error here) would force through
`unawaited()` with no cancellation to show for it.

Reachability could have ridden along on the stream's own value — a record
`({ShoppingList? list, bool stale})` — but that changes the provider's public
type to carry one screen's one sentence, for every present and future
consumer of `currentShoppingListProvider`. A plain callback keeps
`ShoppingListRepository` a `data/` file that knows nothing about Riverpod (it
takes `void Function()?` parameters, not a `core/net/` import), and a
side-channel `keepAlive` notifier is the same shape `data_revision.dart`
already uses for "something changed, watch here" — except this is "something
about the network changed", which is D47's "a best-effort path needs
something that notices it is always failing" made concrete, and it is
exactly what a later offline banner needs, built once rather than per screen.

**Rejected.**
- An `AsyncNotifier` setting `state` a second time after `build()` returns —
  a detached, unawaited continuation.
- `({ShoppingList? list, bool stale})` as the provider's value — see above.
- `connectivity_plus` (asked about, rejected before this part started) — a
  radio that is on but cannot reach Supabase is offline for our purposes, and
  `NetworkFailure` is already the signal `runGuarded` produces from a
  `SocketException`, a `TimeoutException`, or `FunctionException(status: 0)`.
  A second, independent connectivity check would disagree with that signal
  exactly when it matters (a captive portal answers a radio check and nothing
  else).
