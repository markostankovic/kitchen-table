/// Ingredient catalog data access -- reads AND the two narrow writes.
///
/// **The only catalog access in the codebase, as of D43.** Phase 1c paid for a
/// second copy in `features/recipes/data/ingredient_catalog_datasource.dart`
/// because a feature may not import another feature's `data/` (D33), and that
/// file's header named a third caller as the signal to reopen the decision.
/// Phase 1d's confirm screen was the third caller, so the copy is gone and the
/// providers moved to `core/ingredients/` where every feature can reach them.
///
/// The only place in this feature that touches Supabase (CLAUDE.md rule 1).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/supabase/supabase_failure.dart';
import '../domain/ingredient_match.dart';
import '../domain/unit.dart';
import '../domain/unit_catalog.dart';
import 'dto/unit_catalog_dto.dart';
import 'local_ingredient_datasource.dart';

class IngredientRepository {
  const IngredientRepository(this._client, this._local);

  final SupabaseClient _client;

  /// The offline cache for [fetchUnitCatalog] (Phase 2 part 5). Only this
  /// one method of the six here is cached today -- `search`,
  /// `createIngredient` and `linkAlias` all reach a live catalog by design
  /// and would be churn part 6 redoes anyway when it caches ingredient names
  /// properly, so this feature deliberately does not get the full
  /// Remote/Local datasource split `ShoppingListRepository` got this part.
  final LocalIngredientDataSource _local;

  /// Candidate ingredients for [query], best match first.
  ///
  /// Tiers 2 and 3 of the matcher. Goes through the `search_ingredients` RPC
  /// rather than a PostgREST query because the ranking is a `distinct on` over
  /// a union of an exact arm and a fuzzy arm -- and because the three
  /// thresholds it applies belong in one place, in SQL (D31).
  ///
  /// Not an Edge Function: it needs no secret and reads nothing RLS would not
  /// already hand the caller (docs/ARCHITECTURE.md, client/edge split).
  ///
  /// Returns an empty list for a blank query rather than asking the server.
  Future<List<IngredientMatch>> search(
    String query, {
    String locale = 'sr',
    int limit = 20,
  }) =>
      runGuarded(() async {
        if (query.trim().isEmpty) return const <IngredientMatch>[];

        final List<Map<String, dynamic>> rows =
            await _client.rpc<List<dynamic>>(
          'search_ingredients',
          params: <String, dynamic>{
            'search_query': query,
            'preferred_locale': locale,
            'max_results': limit,
          },
        ).then((List<dynamic> rows) => rows.cast<Map<String, dynamic>>());

        return rows.map(_toMatch).toList();
      });

  /// The whole unit lexicon, in one round trip -- network first, the cache
  /// as a fallback (Phase 2 part 5, D70).
  ///
  /// Twenty-odd units and a hundred-odd names, fetched once per session and
  /// handed to `IngredientLineParser`. Network-first rather than
  /// cache-then-network like the shopping list: this is two dozen immutable
  /// reference rows with no `updated_at` of their own to go stale, so there
  /// is nothing to gain from showing a cached answer before a fresh one a
  /// moment later, and a network-first read means one emission, not two, for
  /// a value nothing here treats as a stream.
  ///
  /// Only a [NetworkFailure] falls back to the cache -- a server that
  /// answers with something else wrong is not a reason to serve a stale
  /// lexicon, the same policy `ShoppingListRepository.watchLatest` applies.
  Future<UnitCatalog> fetchUnitCatalog() async {
    try {
      final UnitCatalogRows rows = await _fetchUnitCatalogRows();
      await _local.writeUnitCatalog(rows);
      return unitCatalogFromRows(rows);
    } on NetworkFailure {
      final UnitCatalogRows? cached = await _local.readUnitCatalog();
      if (cached == null) rethrow;
      return unitCatalogFromRows(cached);
    }
  }

  Future<UnitCatalogRows> _fetchUnitCatalogRows() => runGuarded(() async {
    final List<Map<String, dynamic>> unitRows = await _client
        .from('units')
        .select('code, family, to_base, is_metric')
        .order('code');

    final List<Map<String, dynamic>> nameRows = await _client
        .from('unit_names')
        .select('unit_code, name, locale, is_display_name');

    return (unitRows: unitRows, nameRows: nameRows);
  });

  /// Creates a new ingredient and returns its id, or returns the id of the
  /// one that already answers to [name] in [locale].
  ///
  /// Tier 5 of docs/INGREDIENTS.md, driven by a human. The dedupe is the
  /// server's job, not this method's: `create_ingredient` checks for an exact
  /// match first, so two people typing `urnebes` on the same evening get one
  /// row rather than a merge to do later (D34).
  ///
  /// [unitFamily] is a hint for the shopping list and may be omitted.
  /// `UnitFamily.other` is not a legal value -- it is the escape hatch for
  /// `prstohvat` and `po ukusu`, which are not families anything converts
  /// within -- so it is sent as null rather than rejected by the server.
  Future<String> createIngredient(
    String name, {
    String locale = 'sr',
    UnitFamily? unitFamily,
  }) =>
      runGuarded(() async {
        final dynamic id = await _client.rpc<dynamic>(
          'create_ingredient',
          params: <String, dynamic>{
            'ingredient_name': name,
            'loc': locale,
            'unit_family': unitFamily == null || unitFamily == UnitFamily.other
                ? null
                : unitFamily.name,
          },
        );
        return id as String;
      });

  /// Records that [aliasName] names [ingredientId], globally and forever.
  ///
  /// Tier 2 write-back: the string resolves by exact match from now on, for
  /// every household, which is what makes the catalog compound as the app is
  /// used (docs/INGREDIENTS.md, D8).
  ///
  /// Returns false when the string already names a DIFFERENT ingredient. That
  /// is not an error and must not be surfaced as one -- the recipe line is
  /// still valid and still saves; all that happened is that one household's
  /// wording did not get to redefine a word for everybody.
  Future<bool> linkAlias(
    String ingredientId,
    String aliasName, {
    String locale = 'sr',
  }) =>
      runGuarded(() async {
        final dynamic written = await _client.rpc<dynamic>(
          'link_ingredient_alias',
          params: <String, dynamic>{
            'ingredient': ingredientId,
            'alias_name': aliasName,
            'loc': locale,
          },
        );
        return written as bool? ?? false;
      });

  IngredientMatch _toMatch(Map<String, dynamic> row) => IngredientMatch(
        ingredientId: row['ingredient_id'] as String,
        displayName: row['display_name'] as String,
        matchedName: row['matched_name'] as String,
        matchedLocale: row['matched_locale'] as String,
        matchMethod: MatchMethod.values.byName(row['match_method'] as String),
        confidence: _toDouble(row['match_confidence']),
        autoAccept: row['auto_accept'] as bool? ?? false,
        isVerified: row['is_verified'] as bool? ?? false,
        isHouseholdAlias: row['is_household_alias'] as bool? ?? false,
      );

  /// Postgres `numeric` reaches Dart as a `String` when it will not fit a
  /// double exactly, and as a `num` otherwise. Both shapes have to be handled
  /// or a perfectly ordinary conversion factor crashes the parse.
  ///
  /// This is a display and conversion value, not a recipe quantity -- rule 5's
  /// integer fractions are `Quantity`, and nothing here feeds one.
  static double _toDouble(Object? value) => switch (value) {
        final num n => n.toDouble(),
        final String s => double.parse(s),
        _ => throw const UnknownFailure(
            message: 'The server sent an unexpected reply.'),
      };
}
