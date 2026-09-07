import 'package:freezed_annotation/freezed_annotation.dart';

part 'ingredient_match.freezed.dart';
part 'ingredient_match.g.dart';

/// How a string was resolved to an ingredient (D7).
///
/// The provenance is the reason improving the matcher later is a background
/// job rather than a migration: a human decision is never overwritten by a
/// machine guess, because the two are distinguishable.
///
/// [exact] and [alias] both mean normalized equality and both carry confidence
/// 1.0. They differ in *which* name matched -- [exact] is the ingredient's
/// display name, [alias] is any other spelling or translation. Keeping them
/// apart is what shows how much the alias table is actually earning.
enum MatchMethod {
  exact,
  alias,
  fuzzy,

  /// Phase 1d. Never produced in Phase 1b.
  llm,

  /// A human said so, on the confirm screen (D8). Never overwritten.
  manual,
}

/// One candidate from `search_ingredients`.
///
/// Pure Dart (CLAUDE.md rule 7).
@freezed
abstract class IngredientMatch with _$IngredientMatch {
  const factory IngredientMatch({
    required String ingredientId,

    /// The ingredient's name in the requested locale -- so searching `flour`
    /// with locale `sr` shows *brašno*. That hop is the product's wedge.
    required String displayName,

    /// The spelling that actually matched, which may be in the other locale.
    /// Worth showing when it differs from [displayName], so a user can see
    /// *why* a result is in the list.
    required String matchedName,
    required String matchedLocale,
    required MatchMethod matchMethod,

    /// 1.0 for [MatchMethod.exact] and [MatchMethod.alias]; the trigram
    /// similarity for [MatchMethod.fuzzy].
    required double confidence,

    /// Whether this match may be taken without asking a human.
    ///
    /// Computed server-side against the 0.75 line from docs/INGREDIENTS.md, so
    /// there is no copy of that constant on this side to drift (D31). Do not
    /// reimplement it by comparing [confidence].
    required bool autoAccept,

    /// False means nobody has vouched for the ingredient yet.
    @Default(false) bool isVerified,

    /// The match came from the household's own private alias rather than the
    /// global catalog.
    @Default(false) bool isHouseholdAlias,
  }) = _IngredientMatch;

  factory IngredientMatch.fromJson(Map<String, dynamic> json) =>
      _$IngredientMatchFromJson(json);
}
