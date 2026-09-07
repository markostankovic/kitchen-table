/// Ingredient catalog data access. The only place in this feature that touches
/// Supabase (CLAUDE.md rule 1).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/supabase/supabase_failure.dart';
import '../domain/ingredient_match.dart';
import '../domain/unit.dart';
import '../domain/unit_catalog.dart';

class IngredientRepository {
  const IngredientRepository(this._client);

  final SupabaseClient _client;

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

  /// The whole unit lexicon, in one round trip.
  ///
  /// Twenty-odd units and a hundred-odd names, fetched once per session and
  /// handed to `IngredientLineParser`. That is what keeps parsing local: no
  /// request while somebody types, and it still works offline once Phase 2
  /// caches it.
  Future<UnitCatalog> fetchUnitCatalog() => runGuarded(() async {
        final List<Map<String, dynamic>> unitRows = await _client
            .from('units')
            .select('code, family, to_base, is_metric')
            .order('code');

        final List<Map<String, dynamic>> nameRows = await _client
            .from('unit_names')
            .select('unit_code, name, locale, is_display_name');

        return UnitCatalog(
          units: unitRows.map(_toUnit).toList(),
          aliases: <String, String>{
            for (final Map<String, dynamic> row in nameRows)
              row['name'] as String: row['unit_code'] as String,
          },
        );
      });

  Unit _toUnit(Map<String, dynamic> row) => Unit(
        code: row['code'] as String,
        family: UnitFamily.values.byName(row['family'] as String),
        // numeric arrives as num or String depending on the value's precision,
        // so it is normalised here rather than trusted.
        toBase: _toDouble(row['to_base']),
        isMetric: row['is_metric'] as bool? ?? false,
      );

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
