/// Catalog reads for the recipe line editor.
///
/// **This duplicates `features/ingredients/data/ingredient_repository.dart`,
/// on purpose (D33).** `tool/check_layers.dart` allows a cross-feature import
/// only into `domain/`, and that boundary was kept rather than relaxed when
/// Phase 1c needed `search_ingredients`. So the RPC contract, the unit fetch
/// and the numeric-as-String handling exist twice.
///
/// It is kept in its own file rather than folded into `RecipeRepository` so
/// the duplication is visible and easy to delete. The domain types it returns
/// -- [IngredientMatch], [UnitCatalog], [Unit] -- are the originals, not
/// copies; only the wire access is duplicated.
///
/// If a third caller appears -- Phase 2's shopping list is the likely one --
/// that is the signal to reopen D33 rather than to write a third copy.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/supabase/supabase_failure.dart';
import '../../ingredients/domain/ingredient_match.dart';
import '../../ingredients/domain/unit.dart';
import '../../ingredients/domain/unit_catalog.dart';

class IngredientCatalogDatasource {
  const IngredientCatalogDatasource(this._client);

  final SupabaseClient _client;

  /// Candidate ingredients for [query], best match first.
  ///
  /// Tiers 2 and 3 of the matcher. The three thresholds it applies -- the
  /// four-character floor, 0.4, and the 0.75 auto-accept line -- live in SQL
  /// and have no copy on this side (D31). Read [IngredientMatch.autoAccept];
  /// never compare [IngredientMatch.confidence] against a number here.
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

  /// The whole unit lexicon, in one round trip, for the line parser.
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
          // The is_display_name rows, keyed by code and locale. Already in
          // the response -- both columns were being selected and dropped.
          displayNames: <String, String>{
            for (final Map<String, dynamic> row in nameRows)
              if (row['is_display_name'] as bool? ?? false)
                '${row['unit_code']}|${row['locale']}': row['name'] as String,
          },
        );
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

  Unit _toUnit(Map<String, dynamic> row) => Unit(
        code: row['code'] as String,
        family: UnitFamily.values.byName(row['family'] as String),
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

  /// Postgres `numeric` arrives as a `String` when it will not fit a double
  /// exactly, and as a `num` otherwise. Both shapes have to be handled or an
  /// ordinary conversion factor crashes the parse.
  static double _toDouble(Object? value) => switch (value) {
        final num n => n.toDouble(),
        final String s => double.parse(s),
        _ => throw const UnknownFailure(
            message: 'The server sent an unexpected reply.'),
      };
}
