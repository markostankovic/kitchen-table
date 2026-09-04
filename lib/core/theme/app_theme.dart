import 'package:flutter/material.dart';

/// Application theme.
///
/// Deliberately minimal in Phase 0 -- enough for the shell to render on both
/// platforms. Real theming is not on the roadmap until there are screens to
/// theme.
abstract final class AppTheme {
  static ThemeData light() => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7A5C3E)),
      );

  static ThemeData dark() => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7A5C3E),
          brightness: Brightness.dark,
        ),
      );
}
