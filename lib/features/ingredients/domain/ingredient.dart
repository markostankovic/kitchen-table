import 'package:freezed_annotation/freezed_annotation.dart';

import 'unit.dart';

part 'ingredient.freezed.dart';
part 'ingredient.g.dart';

/// A language-neutral ingredient concept.
///
/// It deliberately carries no name: every string a human would recognise lives
/// in `ingredient_names`, which is what lets *brašno* and *flour* be one
/// ingredient and one shopping-list line (D1). [IngredientMatch] is what
/// carries a name back from a search.
///
/// Pure Dart (CLAUDE.md rule 7).
@freezed
abstract class Ingredient with _$Ingredient {
  const factory Ingredient({
    required String id,

    /// The curated seed key (`brasno_glatko`), or null for the auto-created
    /// tail (D27). Not a user-facing slug -- only the seed migration writes it.
    String? key,

    /// One level only (D3). Shopping lists do not roll up to the parent.
    String? parentId,
    String? category,

    /// What it is usually measured in, for the shopping list's display choice.
    /// Never a constraint on what a recipe may write.
    UnitFamily? defaultUnitFamily,

    /// False means nobody has vouched for this row -- it was created by the
    /// matcher rather than seeded. Merge candidates live here (D2).
    @Default(false) bool isVerified,

    /// Suppressed from the shopping list unless a household overrides it.
    @Default(false) bool isPantryStaple,
  }) = _Ingredient;

  factory Ingredient.fromJson(Map<String, dynamic> json) =>
      _$IngredientFromJson(json);
}
