/// Recipe data access. The only place in this feature that touches Supabase
/// (CLAUDE.md rule 1).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/supabase/supabase_failure.dart';
import '../../../core/text/text_normalizer.dart';
import '../../ingredients/domain/ingredient_match.dart';
import '../../ingredients/domain/quantity.dart';
import '../domain/recipe.dart';
import '../domain/recipe_detail.dart';
import '../domain/recipe_ingredient.dart';
import '../domain/recipe_step.dart';

/// The columns of `recipes` this feature reads. Written once so the list
/// cannot drift between the search query and the detail query.
const String _recipeColumns = '''
id, household_id, title, description, servings, prep_minutes, cook_minutes,
original_locale, source_type, source_url, source_attribution, status,
image_path, tags, created_by, updated_at, deleted_at''';

class RecipeRepository {
  const RecipeRepository(this._client);

  final SupabaseClient _client;

  /// Recipes in the caller's household, newest first, excluding soft-deleted
  /// ones.
  ///
  /// The `deleted_at` filter is applied here and not in the RLS policy: the
  /// policy has to keep returning tombstones so the Phase 2 delta fetch can
  /// evict them from the cache (D23).
  ///
  /// A non-empty [query] is normalised through [TextNormalizer] before it is
  /// compared against `title_normalized`, which is a stored generated column
  /// over Postgres' `normalize_text()`. Both sides of the comparison therefore
  /// go through the same definition (rule 6) and `Šargarepa` finds a recipe
  /// stored as `sargarepa`.
  Future<List<Recipe>> search([String? query]) => runGuarded(() async {
        final String term = TextNormalizer.normalize(query ?? '');

        PostgrestFilterBuilder<List<Map<String, dynamic>>> filter =
            _client.from('recipes').select(_recipeColumns).isFilter(
                  'deleted_at',
                  null,
                );

        if (term.isNotEmpty) {
          // ilike rather than the trigram `%` operator: this is a substring
          // search over a normalised column, and the user is still typing.
          // Ranking by similarity is a search_ingredients concern, not a
          // recipe-list one.
          filter = filter.ilike('title_normalized', '%$term%');
        }

        final List<Map<String, dynamic>> rows =
            await filter.order('created_at', ascending: false);

        return rows.map(_toRecipe).toList();
      });

  /// One recipe with its lines and steps, with ingredient names resolved from
  /// the catalog in [locale].
  ///
  /// Two round trips, not one: the lines come back embedded, and then a single
  /// `ingredient_display_names` call resolves every matched id at once. The
  /// alternative was embedding `ingredient_names` and picking a winner in
  /// Dart, which would put a second definition of the display-name fallback
  /// chain on this side of the wire, out of reach of the SQL tests.
  Future<RecipeDetail> fetchDetail(String id, {String locale = 'sr'}) =>
      runGuarded(() async {
        final Map<String, dynamic> row = await _client
            .from('recipes')
            .select('''
$_recipeColumns,
recipe_ingredients(id, position, section, raw_text, ingredient_id,
                   qty_num, qty_den, qty_max_num, qty_max_den,
                   unit_code, note, is_optional,
                   match_method, match_confidence, matched_at),
recipe_steps(id, position, text, timer_seconds)''')
            .eq('id', id)
            .isFilter('deleted_at', null)
            .single();

        final List<RecipeIngredient> lines =
            (row['recipe_ingredients'] as List<dynamic>? ?? <dynamic>[])
                .cast<Map<String, dynamic>>()
                .map(_toIngredient)
                .toList()
              ..sort((RecipeIngredient a, RecipeIngredient b) =>
                  a.position.compareTo(b.position));

        final List<RecipeStep> steps =
            (row['recipe_steps'] as List<dynamic>? ?? <dynamic>[])
                .cast<Map<String, dynamic>>()
                .map(_toStep)
                .toList()
              ..sort((RecipeStep a, RecipeStep b) =>
                  a.position.compareTo(b.position));

        return RecipeDetail(
          recipe: _toRecipe(row),
          ingredients: await _withDisplayNames(lines, locale),
          steps: steps,
        );
      });

  /// Creates a recipe and returns the row that was written.
  ///
  /// Unlike `create_household`, this is a plain insert: `recipes` has an INSERT
  /// policy and there is nothing to make atomic, so an RPC would be ceremony.
  ///
  /// The whole row comes back rather than just the id because the caller needs
  /// the fields it did not send -- `household_id`, `created_by` -- in order to
  /// issue an update afterwards. A first save is this call followed by
  /// `saveLines`, and if the second half fails the editor retries against the
  /// recipe this returned instead of creating a second one (D37).
  Future<Recipe> create({
    required String title,
    required String originalLocale,
    String? description,
    int? servings,
    int? prepMinutes,
    int? cookMinutes,
    List<String> tags = const <String>[],
    RecipeSourceType sourceType = RecipeSourceType.manual,
    RecipeStatus status = RecipeStatus.draft,
    String? sourceUrl,
    String? sourceAttribution,
  }) =>
      runGuarded(() async {
        final String householdId = await _currentHouseholdId();
        final String? userId = _client.auth.currentUser?.id;
        if (userId == null) {
          throw const UnauthorizedFailure(
              message: 'You are not signed in any more.');
        }

        final Map<String, dynamic> row = await _client
            .from('recipes')
            .insert(<String, dynamic>{
              'household_id': householdId,
              'title': title.trim(),
              'description': _blankToNull(description),
              'servings': servings,
              'prep_minutes': prepMinutes,
              'cook_minutes': cookMinutes,
              'original_locale': originalLocale,
              'source_type': sourceType.wireValue,
              'source_url': _blankToNull(sourceUrl),
              'source_attribution': _blankToNull(sourceAttribution),
              'status': status.name,
              'tags': tags,
              'created_by': userId,
            })
            .select(_recipeColumns)
            .single();

        return _toRecipe(row);
      });

  /// Saves the editable fields of an existing recipe.
  ///
  /// `household_id`, `created_by` and `created_at` are deliberately not in the
  /// payload: none of them is editable, and sending them would let a bug move
  /// a recipe between households through a policy that only checks the row's
  /// current owner.
  Future<void> update(Recipe recipe) => runGuarded(() async {
        await _client.from('recipes').update(<String, dynamic>{
          'title': recipe.title.trim(),
          'description': _blankToNull(recipe.description),
          'servings': recipe.servings,
          'prep_minutes': recipe.prepMinutes,
          'cook_minutes': recipe.cookMinutes,
          'original_locale': recipe.originalLocale,
          'source_url': _blankToNull(recipe.sourceUrl),
          'source_attribution': _blankToNull(recipe.sourceAttribution),
          'status': recipe.status.name,
          'tags': recipe.tags,
        }).eq('id', recipe.id);
      });

  /// Replaces a recipe's ingredient lines and steps.
  ///
  /// Goes through `replace_recipe_lines` because this is four statements and
  /// PostgREST offers the client no transaction. A half-applied save would
  /// delete the old lines and fail to write the new ones (D36).
  Future<void> saveLines(
    String recipeId, {
    required List<RecipeIngredient> ingredients,
    required List<RecipeStep> steps,
  }) =>
      runGuarded(() async {
        await _client.rpc<void>(
          'replace_recipe_lines',
          params: <String, dynamic>{
            'recipe': recipeId,
            'ingredient_lines':
                ingredients.map(_ingredientPayload).toList(growable: false),
            'steps': steps.map(_stepPayload).toList(growable: false),
          },
        );
      });

  /// Soft-deletes a recipe. There is no hard delete (rule 4).
  Future<void> softDelete(String id) => runGuarded(() async {
        // The timestamp comes from the client because PostgREST cannot send
        // `now()` in an update payload. Only ordering against other client
        // writes could be affected, and nothing orders by deleted_at.
        await _client.from('recipes').update(<String, dynamic>{
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', id);
      });

  // ---------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------

  /// The caller's current household.
  ///
  /// This duplicates `HouseholdRepository.fetchCurrent` on purpose. `recipes`
  /// may not import another feature's `data/` or `application/` layer -- only
  /// its `domain/` -- and that boundary was kept rather than relaxed (D33).
  /// The cost is this query, in two places. If a third feature needs it, that
  /// is the signal to revisit D33 rather than to write a third copy.
  Future<String> _currentHouseholdId() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('households')
        .select('id')
        .isFilter('deleted_at', null)
        .order('created_at')
        .limit(1);

    if (rows.isEmpty) {
      throw const NotFoundFailure(
          message: 'You are not in a household yet.');
    }
    return rows.first['id'] as String;
  }

  /// Fills in [RecipeIngredient.displayName] for every matched line, in one
  /// round trip.
  Future<List<RecipeIngredient>> _withDisplayNames(
    List<RecipeIngredient> lines,
    String locale,
  ) async {
    final List<String> ids = lines
        .map((RecipeIngredient line) => line.ingredientId)
        .whereType<String>()
        .toSet()
        .toList(growable: false);

    if (ids.isEmpty) return lines;

    final List<Map<String, dynamic>> rows = await _client
        .rpc<List<dynamic>>(
          'ingredient_display_names',
          params: <String, dynamic>{'ids': ids, 'loc': locale},
        )
        .then((List<dynamic> rows) => rows.cast<Map<String, dynamic>>());

    final Map<String, String> names = <String, String>{
      for (final Map<String, dynamic> row in rows)
        if (row['display_name'] != null)
          row['ingredient_id'] as String: row['display_name'] as String,
    };

    return lines
        .map((RecipeIngredient line) => line.copyWith(
            displayName: names[line.ingredientId ?? '']))
        .toList(growable: false);
  }

  Recipe _toRecipe(Map<String, dynamic> row) => Recipe(
        id: row['id'] as String,
        householdId: row['household_id'] as String,
        title: row['title'] as String,
        description: row['description'] as String?,
        servings: row['servings'] as int?,
        prepMinutes: row['prep_minutes'] as int?,
        cookMinutes: row['cook_minutes'] as int?,
        originalLocale: row['original_locale'] as String,
        sourceType: RecipeSourceType.fromWire(row['source_type'] as String),
        sourceUrl: row['source_url'] as String?,
        sourceAttribution: row['source_attribution'] as String?,
        status: RecipeStatus.values.byName(row['status'] as String),
        imagePath: row['image_path'] as String?,
        tags: (row['tags'] as List<dynamic>? ?? <dynamic>[]).cast<String>(),
        createdBy: row['created_by'] as String,
        updatedAt: _toDate(row['updated_at']),
        deletedAt: _toDate(row['deleted_at']),
      );

  RecipeIngredient _toIngredient(Map<String, dynamic> row) => RecipeIngredient(
        id: row['id'] as String?,
        position: row['position'] as int,
        section: row['section'] as String?,
        rawText: row['raw_text'] as String,
        ingredientId: row['ingredient_id'] as String?,
        quantity: _toQuantity(row),
        unitCode: row['unit_code'] as String?,
        note: row['note'] as String?,
        isOptional: row['is_optional'] as bool? ?? false,
        matchMethod: row['match_method'] == null
            ? null
            : MatchMethod.values.byName(row['match_method'] as String),
        matchConfidence: _toNullableDouble(row['match_confidence']),
        matchedAt: _toDate(row['matched_at']),
      );

  RecipeStep _toStep(Map<String, dynamic> row) => RecipeStep(
        id: row['id'] as String?,
        position: row['position'] as int,
        text: row['text'] as String,
        timerSeconds: row['timer_seconds'] as int?,
      );

  /// Both halves of a fraction or neither -- the table's check constraints say
  /// the same thing, so a half-null pair here means the row was written by
  /// something that bypassed them.
  Quantity? _toQuantity(Map<String, dynamic> row) {
    final int? numerator = row['qty_num'] as int?;
    final int? denominator = row['qty_den'] as int?;
    if (numerator == null || denominator == null) return null;

    final int? maxNumerator = row['qty_max_num'] as int?;
    final int? maxDenominator = row['qty_max_den'] as int?;
    if (maxNumerator != null && maxDenominator != null) {
      return Quantity.range(
        numerator: numerator,
        denominator: denominator,
        maxNumerator: maxNumerator,
        maxDenominator: maxDenominator,
      );
    }
    return Quantity.fraction(numerator, denominator);
  }

  Map<String, dynamic> _ingredientPayload(RecipeIngredient line) =>
      <String, dynamic>{
        'raw_text': line.rawText,
        'section': line.section,
        'ingredient_id': line.ingredientId,
        'qty_num': line.quantity?.numerator,
        'qty_den': line.quantity?.denominator,
        'qty_max_num': line.quantity?.maxNumerator,
        'qty_max_den': line.quantity?.maxDenominator,
        'unit_code': line.unitCode,
        'note': line.note,
        'is_optional': line.isOptional,
        'match_method': line.matchMethod?.name,
        'match_confidence': line.matchConfidence,
        'matched_at': line.matchedAt?.toUtc().toIso8601String(),
      };

  Map<String, dynamic> _stepPayload(RecipeStep step) => <String, dynamic>{
        'text': step.text,
        'timer_seconds': step.timerSeconds,
      };

  static String? _blankToNull(String? value) {
    final String? trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static DateTime? _toDate(Object? value) =>
      value == null ? null : DateTime.parse(value as String);

  /// Postgres `numeric` reaches Dart as a `String` when it will not fit a
  /// double exactly, and as a `num` otherwise -- the same trap
  /// `IngredientRepository` documents. This is match confidence, a score;
  /// recipe quantities are `Quantity` and never touch a float (rule 5).
  static double? _toNullableDouble(Object? value) => switch (value) {
        null => null,
        final num n => n.toDouble(),
        final String s => double.parse(s),
        _ => throw const UnknownFailure(
            message: 'The server sent an unexpected reply.'),
      };
}
