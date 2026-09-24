import 'package:flutter/material.dart';

import 'app_spacing.dart';

/// Application theme.
///
/// Phase 7 Part 1 replaces the Phase 0 stub -- a bare `ColorScheme.fromSeed`
/// and nothing else -- with roles the app actually decided on. The seed
/// itself did not change (`docs/DESIGN.md` § Colour): the same warm brown
/// still drives Material 3's tonal palette. What changed is that the roles
/// the app reads (`error`, `tertiary`, `outline`, `onSurfaceVariant`, ...) are
/// now pinned deliberately instead of left to whatever the generator
/// produces, and the handful of component themes screens actually rely on
/// (`AppBar`, `Chip`, `FilledButton`, `ListTile`, `InputDecoration`) are set
/// once here instead of drifting per screen.
abstract final class AppTheme {
  static const Color _seed = Color(0xFF7A5C3E);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final ColorScheme scheme = _colorScheme(brightness);
    final TextTheme textTheme = _textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.secondaryContainer,
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        side: BorderSide.none,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static ColorScheme _colorScheme(Brightness brightness) {
    final ColorScheme generated = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    // fromSeed's own tertiary is the role import review's "needs attention"
    // marker and the offline banner lean on, so it has to read clearly against
    // surface in both brightnesses. The generated dark-mode tertiary sits too
    // close in tone to the generated dark secondary to tell apart at the
    // 3px border width `import_review_screen.dart` draws it at -- pin it
    // instead of taking the generator's value as-is.
    if (brightness == Brightness.dark) {
      return generated.copyWith(
        tertiary: const Color(0xFFE7C17E),
        onTertiary: const Color(0xFF422C00),
      );
    }
    return generated;
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    const TextTheme base = TextTheme(
      // Screen and dialog titles ("Recipes", "Add a household").
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      // Section headings within a screen (AppSectionHeading), AppBar titles.
      titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      // Field labels, list tile titles.
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      // Primary reading text: recipe steps, ingredient lines.
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      // Default body copy, empty-state text.
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      // Captions, secondary/muted text.
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      // Buttons, chip labels.
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      // Small chip labels, tooltips.
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    );
    return base.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
  }
}
