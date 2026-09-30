import 'package:flutter/material.dart';

/// The semantic type layer: the styles that mean "this is a recipe's name",
/// which are deliberately not a Material role (`docs/DESIGN_SYSTEM.md`
/// § Type, D134).
///
/// Read as `Theme.of(context).extension<KitchenType>()!`.
///
/// **There is one face, the platform sans.** What sets a recipe's name apart
/// is weight 700, so bold in a title position means a recipe (a recipe card,
/// a meal entry, a leftover, the detail title). A meal-plan note is the one
/// place the [recipeTitle] metrics are worn at w400, because a note is not a
/// recipe (D134). Screen titles, section headings and the household name are
/// Material roles, not this class.
///
/// Every member is sans w700 in `onSurface`, built from a scheme like
/// `KitchenColors.of` so light and dark follow automatically.
@immutable
class KitchenType extends ThemeExtension<KitchenType> {
  const KitchenType({
    required this.recipeTitle,
    required this.recipeTitleLarge,
    required this.monogram,
  });

  /// Builds the extension from a scheme.
  factory KitchenType.of(ColorScheme scheme) => KitchenType(
    recipeTitle: TextStyle(
      fontSize: 17,
      height: 24 / 17,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.1,
      color: scheme.onSurface,
    ),
    recipeTitleLarge: TextStyle(
      fontSize: 28,
      height: 34 / 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: scheme.onSurface,
    ),
    monogram: TextStyle(
      fontSize: 30,
      height: 36 / 30,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      color: scheme.onSurface,
    ),
  );

  /// 17/24 w700. A recipe's name on a recipe card and on a meal-plan entry,
  /// and a leftover's title.
  final TextStyle recipeTitle;

  /// 28/34 w700. A recipe's title on its detail screen.
  final TextStyle recipeTitleLarge;

  /// 30/36 w700. The letter on a recipe card's 72dp monogram tile.
  final TextStyle monogram;

  @override
  KitchenType copyWith({
    TextStyle? recipeTitle,
    TextStyle? recipeTitleLarge,
    TextStyle? monogram,
  }) => KitchenType(
    recipeTitle: recipeTitle ?? this.recipeTitle,
    recipeTitleLarge: recipeTitleLarge ?? this.recipeTitleLarge,
    monogram: monogram ?? this.monogram,
  );

  @override
  KitchenType lerp(ThemeExtension<KitchenType>? other, double t) {
    if (other is! KitchenType) return this;
    return KitchenType(
      recipeTitle: TextStyle.lerp(recipeTitle, other.recipeTitle, t)!,
      recipeTitleLarge: TextStyle.lerp(
        recipeTitleLarge,
        other.recipeTitleLarge,
        t,
      )!,
      monogram: TextStyle.lerp(monogram, other.monogram, t)!,
    );
  }
}
