/// The single point where a local cache failure is swallowed rather than
/// surfaced, and the reason `runGuarded` (`core/supabase/supabase_failure.dart`)
/// never sees one.
///
/// `runGuarded`'s bare `catch` maps anything unrecognised to
/// [UnknownFailure] -- "Something went wrong." A [SqliteException] from a
/// corrupt cache file, or a [FormatException] from a blob an older build
/// wrote in a shape this one no longer expects, is not a server problem and
/// must never be reported as one. So nothing from `package:drift` is allowed
/// to reach `runGuarded` at all: every local datasource method is wrapped in
/// [cacheOrElse] instead, which treats a failed read as a cache miss (falls
/// through to the network, exactly as if nothing had ever been cached) and a
/// failed write as a round trip that will simply happen again next time.
///
/// This also absorbs the `MissingPluginException` that `path_provider`
/// throws under `flutter test`, which is what lets every existing widget
/// test go on not knowing the cache exists: they see a permanent cache miss
/// and behave exactly as they did before this file was added.
library;

import 'dart:developer' as developer;

/// Runs a read [body]; on any failure, logs [op] and returns [orElse] rather
/// than letting the exception propagate. A failed read is a cache miss.
///
/// Per D47 ("a best-effort path needs something that notices it is always
/// failing"), this does not swallow silently -- it logs under the
/// `AppDatabase` name, the same best-effort-and-log shape `RecipeEditor`'s
/// orphaned-image cleanup already uses (`developer.log(name: 'RecipeEditor',
/// ...)` around the delete that must not undo an otherwise-successful save,
/// D48). Nothing reads that log today; naming a consumer for it is part 7's
/// admin screen, not this one.
Future<T> cacheOrElse<T>(
  String op,
  Future<T> Function() body,
  T orElse,
) async {
  try {
    return await body();
  } catch (e, s) {
    _log(op, e, s);
    return orElse;
  }
}

/// Runs a write [body]; on any failure, logs [op] and does nothing further.
/// A failed write costs a round trip next time and nothing else -- there is
/// no meaningful fallback value for a write, so this takes no [orElse].
Future<void> cacheWrite(String op, Future<void> Function() body) async {
  try {
    await body();
  } catch (e, s) {
    _log(op, e, s);
  }
}

void _log(String op, Object error, StackTrace stackTrace) {
  developer.log(
    'cache $op failed, falling through',
    name: 'AppDatabase',
    error: error,
    stackTrace: stackTrace,
  );
}
