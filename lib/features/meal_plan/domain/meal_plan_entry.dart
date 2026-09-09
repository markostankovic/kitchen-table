import 'package:freezed_annotation/freezed_annotation.dart';

import 'meal_slot.dart';

part 'meal_plan_entry.freezed.dart';
part 'meal_plan_entry.g.dart';

/// One slot of one day of a week -- a recipe, a leftover, or a note.
///
/// [recipeTitle] and [recipeServings] are resolved at read time from a
/// PostgREST embed and never persisted -- the same pattern as
/// `Recipe.imageUrl` and `RecipeIngredient.displayName`. A `Recipe` was
/// deliberately NOT reused here: it requires `householdId`, `originalLocale`,
/// `sourceType`, `status` and `createdBy`, and filling those with placeholders
/// for a two-column embed would be a lie the type system carries forward.
/// `meal_plan` therefore imports nothing from `recipes/domain` in this slice.
///
/// [position] is assigned server-side by `meal_plan_entries_before_write`
/// (migration 14) and is never computed on the client -- a client `max()+1`
/// would be a read-then-write race, the same argument D36 already made for
/// `recipe_ingredients.position`.
///
/// Pure Dart (CLAUDE.md rule 7).
@freezed
abstract class MealPlanEntry with _$MealPlanEntry {
  const MealPlanEntry._();

  const factory MealPlanEntry({
    required String id,
    required String mealPlanId,
    required DateTime entryDate,
    required MealSlot slot,
    required int position,
    required MealEntryKind entryKind,
    String? recipeId,

    /// D51: the column ships in migration 14; nothing writes it until a
    /// later part builds the leftover feature.
    String? leftoverOfEntryId,
    String? note,
    int? servings,

    /// Resolved, not stored -- see the class doc.
    String? recipeTitle,
    int? recipeServings,
  }) = _MealPlanEntry;

  factory MealPlanEntry.fromJson(Map<String, dynamic> json) =>
      _$MealPlanEntryFromJson(json);

  /// What to show on the tile: the recipe's title for a recipe entry, the
  /// note text for a note entry.
  ///
  /// Defined here, once, rather than in the grid widget -- the entry_kind
  /// check constraint in migration 14 already guarantees exactly one of
  /// [recipeTitle] / [note] is meaningful for a given [entryKind], so this is
  /// a lookup, not a decision.
  String get label => switch (entryKind) {
        MealEntryKind.recipe || MealEntryKind.leftover =>
          recipeTitle ?? 'Recipe',
        MealEntryKind.note => note ?? '',
      };
}
