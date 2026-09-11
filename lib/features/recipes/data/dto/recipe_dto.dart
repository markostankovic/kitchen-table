/// The wire shape of `recipes` plus its embedded `recipe_ingredients` and
/// `recipe_steps` -- and the cache's own encoding of that exact shape
/// (Phase 2 part 6a, on `shopping_list_dto.dart`'s precedent, D65).
///
/// The cache stores the *raw* PostgREST response map verbatim (`jsonEncode`
/// of exactly what the network returned), so there is one decoder for both
/// a fresh read and a cache hit -- no separate `toWire()` encoder exists
/// here, unlike `shopping_list_dto.dart`: a recipe row is never built up
/// from a domain object before being cached, only ever read off the wire
/// and stored as-is.
///
/// [recipeIngredientFromWire] carries the same null-safe handling
/// `RecipeRepository._toIngredient` always has -- an embedded
/// `ingredients(is_pantry_staple, category)` is present only when the
/// caller asked for it (the shopping list's `fetchLinesForRecipes`), and
/// absent (and therefore defaulted) for a single recipe's own detail.
library;

import '../../domain/recipe.dart';
import '../../domain/recipe_ingredient.dart';
import '../../domain/recipe_step.dart';
import '../../../ingredients/domain/ingredient_match.dart';
import '../../../ingredients/domain/quantity.dart';

/// The columns of `recipes` every read names. Written once so the list
/// cannot drift between the search query, the detail query and the delta
/// fetch.
const String recipeColumns = '''
id, household_id, title, description, servings, prep_minutes, cook_minutes,
original_locale, source_type, source_url, source_attribution, status,
image_path, tags, created_by, updated_at, deleted_at''';

/// The embedded lines and steps a detail-shaped fetch asks for, on top of
/// [recipeColumns].
const String recipeDetailEmbed = '''
recipe_ingredients(id, position, section, raw_text, ingredient_id,
                   qty_num, qty_den, qty_max_num, qty_max_den,
                   unit_code, note, is_optional,
                   match_method, match_confidence, matched_at),
recipe_steps(id, position, text, timer_seconds)''';

Recipe recipeFromWire(Map<String, dynamic> row) => Recipe(
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

/// Every line embedded on [row], sorted by `position` -- PostgREST does not
/// promise embed order (`shopping_list_dto.dart` makes the same point).
/// Absent entirely for a row fetched without [recipeDetailEmbed].
List<RecipeIngredient> recipeIngredientsFromWire(Map<String, dynamic> row) =>
    (row['recipe_ingredients'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>()
        .map(recipeIngredientFromWire)
        .toList()
      ..sort((RecipeIngredient a, RecipeIngredient b) =>
          a.position.compareTo(b.position));

List<RecipeStep> recipeStepsFromWire(Map<String, dynamic> row) =>
    (row['recipe_steps'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>()
        .map(recipeStepFromWire)
        .toList()
      ..sort((RecipeStep a, RecipeStep b) => a.position.compareTo(b.position));

RecipeIngredient recipeIngredientFromWire(Map<String, dynamic> row) {
  // Present only when `ingredients(...)` was embedded -- fetchDetail does
  // not ask for it, because a recipe does not care whether an ingredient is
  // a cupboard staple. fetchLinesForRecipes does.
  final Map<String, dynamic>? catalog =
      row['ingredients'] as Map<String, dynamic>?;
  return RecipeIngredient(
    id: row['id'] as String?,
    recipeId: row['recipe_id'] as String?,
    isPantryStaple: catalog?['is_pantry_staple'] as bool? ?? false,
    category: catalog?['category'] as String?,
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
}

RecipeStep recipeStepFromWire(Map<String, dynamic> row) => RecipeStep(
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

DateTime? _toDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

/// Postgres `numeric` reaches Dart as a `String` when it will not fit a
/// double exactly, and as a `num` otherwise -- the same trap
/// `IngredientRepository` documents. This is match confidence, a score;
/// recipe quantities are `Quantity` and never touch a float (rule 5).
double? _toNullableDouble(Object? value) => switch (value) {
      null => null,
      final num n => n.toDouble(),
      final String s => double.parse(s),
      _ => throw FormatException('unexpected match_confidence: $value'),
    };
