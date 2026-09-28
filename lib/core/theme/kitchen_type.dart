import 'package:flutter/material.dart';

/// The semantic type layer: the serif recipe titles, which are deliberately
/// not a Material role (`docs/DESIGN_SYSTEM.md` § Type, D127).
///
/// Read as `Theme.of(context).extension<KitchenType>()!`.
///
/// **Literata reaches a screen only through `displaySmall` (the wordmark) or
/// this class.** Every Material text role but `displaySmall` is the platform
/// sans, so a serif on screen always means "this is a recipe's name". Screen
/// titles, section headings and the household name are sans.
///
/// Both members are Literata w600 in `onSurface`, built from a scheme like
/// `KitchenColors.of` so light and dark follow automatically.
@immutable
class KitchenType extends ThemeExtension<KitchenType> {
  const KitchenType({
    required this.recipeTitle,
    required this.recipeTitleLarge,
  });

  /// Builds the extension from a scheme. The only place the serif is named
  /// outside `AppTheme`'s `displaySmall`.
  factory KitchenType.of(ColorScheme scheme) => KitchenType(
    recipeTitle: TextStyle(
      fontFamily: _serif,
      fontSize: 18,
      height: 24 / 18,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    ),
    recipeTitleLarge: TextStyle(
      fontFamily: _serif,
      fontSize: 26,
      height: 32 / 26,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    ),
  );

  static const String _serif = 'Literata';

  /// 18/24. A recipe's name on a recipe card and on a meal-plan entry.
  final TextStyle recipeTitle;

  /// 26/32. A recipe's title on its detail screen, and the monogram letter on
  /// a recipe card's 72dp tile.
  final TextStyle recipeTitleLarge;

  @override
  KitchenType copyWith({TextStyle? recipeTitle, TextStyle? recipeTitleLarge}) =>
      KitchenType(
        recipeTitle: recipeTitle ?? this.recipeTitle,
        recipeTitleLarge: recipeTitleLarge ?? this.recipeTitleLarge,
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
    );
  }
}
