/// Whether the last read that actually tried the network got through.
///
/// This is the `connectivity_plus` replacement chosen when this cache was
/// built: a radio that is on but cannot reach Supabase is offline for our
/// purposes, and [NetworkFailure] is the signal `runGuarded`
/// (`core/supabase/supabase_failure.dart`) already produces from a
/// `SocketException`, a `TimeoutException`, or `FunctionException(status:
/// 0)`. A second, independent connectivity check would disagree with that
/// signal exactly when it matters least (the radio is up, the server is
/// not) and exactly when it matters most (a captive portal answers the
/// radio check and nothing else).
///
/// Also the answer to D47 -- "a best-effort path needs something that
/// notices it is always failing" -- for the cache's own swallowed
/// [NetworkFailure]s: `CurrentShoppingList` reports here instead of letting
/// the failure vanish inside a kept-cache read.
///
/// One counter, not a stream of events, on `data_revision.dart`'s own
/// precedent: nothing downstream needs to know WHICH read failed, only
/// whether the most recent attempt got through. `core/` rather than a
/// feature, because every cached read reports into it and `offline_banner
/// .dart`'s global banner (Phase 2 part 6b, D76) reads it -- the same reason
/// `currentHouseholdIdProvider` lives here.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_status.g.dart';

enum Reachability {
  /// No read has completed yet this session.
  unknown,
  online,
  offline,
}

/// `keepAlive`: outlives every screen that watches it, the same
/// justification `data_revision.dart`'s counters give.
@Riverpod(keepAlive: true)
class NetworkStatus extends _$NetworkStatus {
  @override
  Reachability build() => Reachability.unknown;

  void reportReachable() => state = Reachability.online;

  void reportUnreachable() => state = Reachability.offline;
}
