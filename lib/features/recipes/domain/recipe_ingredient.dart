import 'package:freezed_annotation/freezed_annotation.dart';

import '../../ingredients/domain/ingredient_match.dart';
import '../../ingredients/domain/quantity.dart';

part 'recipe_ingredient.freezed.dart';
part 'recipe_ingredient.g.dart';

/// One line of a recipe's ingredient list.
///
/// [rawText] is required and every structured field beside it is nullable.
/// That asymmetry is CLAUDE.md rule 3 expressed as a type: a line that failed
/// to parse, or parsed but matched nothing, is a supported state and still
/// renders exactly as the cook wrote it. Nothing here may be made non-nullable
/// later without breaking that.
///
/// [MatchMethod] and [Quantity] come from `features/ingredients/domain/` --
/// a cross-feature import, which `tool/check_layers.dart` permits only into
/// `domain/`. That is the whole reason those two types live in `domain/` and
/// not next to the repository that produces them.
///
/// Pure Dart (rule 7).
@freezed
abstract class RecipeIngredient with _$RecipeIngredient {
  const RecipeIngredient._();

  const factory RecipeIngredient({
    required int position,

    /// HARD RULE (rule 3). What the cook typed, always.
    required String rawText,

    /// Null for a saved-but-unsaved line, or one that has never been written.
    String? id,

    /// A heading within the list -- 'Za fil', 'For the sauce'.
    String? section,

    /// Null means the line resolved to nothing in the catalog. Normal, not an
    /// error.
    String? ingredientId,

    /// The catalog's name for [ingredientId] in the reader's locale, resolved
    /// at read time by `ingredient_display_names`. Not persisted on the line
    /// -- the whole point of D1 is that this is looked up rather than copied,
    /// so one recipe written in Serbian and one in English render the same
    /// word.
    String? displayName,

    /// An exact integer fraction, never a float (rule 5).
    Quantity? quantity,

    /// A `units.code`, never a display name.
    String? unitCode,
    String? note,
    @Default(false) bool isOptional,

    /// Match provenance (D7). A [MatchMethod.manual] link is a human decision
    /// and is never overwritten by a later machine pass.
    MatchMethod? matchMethod,
    double? matchConfidence,
    DateTime? matchedAt,
  }) = _RecipeIngredient;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      _$RecipeIngredientFromJson(json);

  /// Whether this line resolved to a catalog ingredient.
  bool get isMatched => ingredientId != null;

  /// What to show as the ingredient's name: the catalog's word for it if the
  /// line matched, and otherwise the line itself.
  ///
  /// Defined here rather than in a widget so the recipe detail screen, the
  /// line editor and Phase 2's shopping list cannot each answer it differently.
  String get resolvedName => displayName ?? rawText;
}
