/// Shopping list data access, composed from a Remote half (Supabase) and a
/// Local half (the Drift cache) -- `docs/ARCHITECTURE.md`'s "Offline (Phase
/// 2)" split, built for the first time in this feature (Phase 2 part 5).
///
/// This file itself imports neither `supabase_flutter` nor `drift`: rule 1's
/// "the only place `supabase_flutter` may be imported" now belongs to
/// `RemoteShoppingListDataSource`, and `LocalShoppingListDataSource` is the
/// drift half. This class only orchestrates the two.
library;

import '../../../core/error/app_failure.dart';
import '../../meal_plan/domain/meal_plan_entry.dart';
import '../../meal_plan/domain/plan_week.dart';
import '../domain/shopping_item.dart';
import '../domain/shopping_list.dart';
import 'local_shopping_list_datasource.dart';
import 'remote_shopping_list_datasource.dart';

class ShoppingListRepository {
  const ShoppingListRepository(this._remote, this._local);

  final RemoteShoppingListDataSource _remote;
  final LocalShoppingListDataSource _local;

  /// The household's current list: cache immediately, then the network.
  ///
  /// `docs/ARCHITECTURE.md`'s own shape -- "emit cached immediately -> fetch
  /// -> upsert cache -> emit fresh". A cache hit followed by a
  /// [NetworkFailure] completes the stream quietly rather than erroring it:
  /// there is something on screen and it stays there (D67). A cache MISS
  /// followed by a [NetworkFailure] rethrows with a sentence that says so --
  /// there is genuinely nothing to show, and an honest error beats an empty
  /// state that implies "you never generated a list". Any other [AppFailure]
  /// -- an expired session, a policy refusal -- always propagates: serving a
  /// stale list while the session itself is dead would be wrong.
  ///
  /// [onReachable]/[onUnreachable] report every completed network attempt --
  /// including a swallowed [NetworkFailure] on a cache hit, which otherwise
  /// leaves nothing observable outside this method (D47, D67). Plain
  /// callbacks rather than a `core/net/` import: this stays a `data/` file
  /// that knows nothing about Riverpod, and `application/` is what wires
  /// them to `NetworkStatus`.
  Stream<ShoppingList?> watchLatest({
    required String householdId,
    void Function()? onReachable,
    void Function()? onUnreachable,
  }) async* {
    final ShoppingList? cached = await _local.readLatest(
      householdId: householdId,
    );
    if (cached != null) yield cached;

    try {
      final ShoppingList? fresh = await _remote.fetchLatest(
        householdId: householdId,
      );
      if (fresh != null) {
        await _local.upsertLatest(householdId: householdId, list: fresh);
      } else if (cached != null) {
        // The server no longer has a live list for this household -- it was
        // discarded or regenerated elsewhere -- but the cache still does.
        // Evict it so a later offline read cannot serve what the server has
        // already retired.
        await _local.evict(cached.id);
      }
      onReachable?.call();
      yield fresh;
    } on NetworkFailure catch (e) {
      onUnreachable?.call();
      if (cached != null) return;
      throw NetworkFailure(
        message: 'No connection, and no saved list on this phone yet.',
        cause: e.cause,
      );
    }
  }

  /// Writes a generated list and all its items in one transaction, then
  /// caches it.
  ///
  /// One RPC rather than an insert followed by an insert: a failure between
  /// the two would leave a headless list, which on screen is indistinguishable
  /// from a week with nothing planned. Same argument as `replace_recipe_lines`
  /// (D36) and `save_imported_recipe` (D44).
  ///
  /// Does not write the cache itself -- the server assigns `generated_at`,
  /// so this only has an id. `CurrentShoppingList.generate()` bumps
  /// `shoppingListRevisionProvider` after this returns, which rebuilds
  /// [watchLatest] with an empty cache (the previous entry was evicted by
  /// [softDelete]) and lets the ordinary network-then-cache path populate it
  /// with the row the server actually wrote.
  Future<String> save({
    required String householdId,
    String? mealPlanId,
    required DateTime dateFrom,
    required DateTime dateTo,
    required String locale,
    required List<ShoppingItem> items,
  }) async {
    final String id = await _remote.save(
      householdId: householdId,
      mealPlanId: mealPlanId,
      dateFrom: dateFrom,
      dateTo: dateTo,
      locale: locale,
      items: items,
    );
    return id;
  }

  /// Retires a list, remotely and in the cache. A soft delete on the server
  /// (rule 4); a hard delete here -- see [ShoppingListCache]'s own doc
  /// comment for why the cache never carries a `deleted_at` of its own.
  Future<void> softDelete(String id) async {
    await _remote.softDelete(id);
    await _local.evict(id);
  }

  /// The household's pantry overrides, as ingredient id -> always_have.
  Future<Map<String, bool>> fetchPantryPrefs({required String householdId}) =>
      _remote.fetchPantryPrefs(householdId: householdId);

  /// Records or clears "we always have this".
  Future<void> setPantryPref({
    required String householdId,
    required String ingredientId,
    required bool? alwaysHave,
  }) => _remote.setPantryPref(
    householdId: householdId,
    ingredientId: ingredientId,
    alwaysHave: alwaysHave,
  );

  /// Every planned entry in a date range, across however many weeks it spans.
  Future<List<MealPlanEntry>> fetchEntriesInRange({
    required String householdId,
    required DateTime from,
    required DateTime to,
  }) => _remote.fetchEntriesInRange(
    householdId: householdId,
    from: from,
    to: to,
  );

  /// The plan id a list generated for [week] should point at, if one exists.
  Future<String?> findPlanId({
    required String householdId,
    required PlanWeek week,
  }) => _remote.findPlanId(householdId: householdId, week: week);
}
