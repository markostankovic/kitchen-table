import 'package:flutter/material.dart';

import 'app_radii.dart';
import 'app_sizes.dart';
import 'app_spacing.dart';
import 'kitchen_colors.dart';

/// Application theme -- the Garden design system
/// (`docs/DESIGN_SYSTEM.md` § Colour, § Type, § Component themes; D118).
///
/// There is no seed. Phase 7 Part 1 built both schemes from
/// `ColorScheme.fromSeed(0xFF7A5C3E)` and pinned the roles that came out
/// wrong (D117); this slice deletes the seed outright and writes every role
/// of both brightnesses as an explicit value from the design export. Light
/// and dark were designed as a pair, not generated from one another, so
/// neither can be derived -- and a palette change is now an edit to the two
/// `const ColorScheme`s below rather than a guess at what a generator will do
/// with a new seed.
///
/// D117's dark-mode `tertiary` override is superseded by the palette's own
/// paprika. The *constraint* that produced it survives: `tertiary` is a
/// signal-only role -- the 3px review marker, a filled heart, a star -- and
/// has to stay legible at 3px against a dark surface. It is never a surface
/// something else sits on.
///
/// Type is Literata (bundled under `assets/fonts/`, CLAUDE.md rule 8 -- no
/// font package) for anything a person *reads*, and the platform sans
/// (`fontFamily: null`) for UI furniture. A button label set in a serif reads
/// as decoration, which is why `labelLarge` is sans.
///
/// [KitchenColors] rides along on both themes as the app's semantic layer.
abstract final class AppTheme {
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
      extensions: <ThemeExtension<dynamic>>[KitchenColors.of(scheme)],

      // Flat by default: a container-role tone step plus a 1dp hairline does
      // the separating, not a shadow. `surfaceTint` being transparent in the
      // scheme kills Material's elevation tint app-wide, so the few themes
      // below that do elevate cast a plain shadow rather than tinting.
      appBarTheme: AppBarThemeData(
        toolbarHeight: AppSizes.appBar,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        // Left-aligned: a recipe box is a domestic object, not a masthead.
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      ),

      // Not Material's default. M3 gives the indicator `secondaryContainer`;
      // the design wants a `primary` pill with the icon knocked out in
      // `onPrimary`, so the active tab reads as the one green thing on an
      // otherwise cream screen.
      navigationBarTheme: NavigationBarThemeData(
        height: AppSizes.nav,
        backgroundColor: scheme.surfaceContainer,
        elevation: 0,
        indicatorColor: scheme.primary,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (Set<WidgetState> states) => IconThemeData(
            size: AppSizes.icon,
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (Set<WidgetState> states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),

      // `margin: zero` because callers space cards -- Material's default 4dp
      // margin fights the 12dp gap the design asks for between them.
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      // Selection reads as colour plus a check icon, not as an outline --
      // hence `BorderSide.none` on both states.
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.secondaryContainer,
        labelStyle: textTheme.labelLarge,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),

      // The label sits *above* the field in `titleSmall` at the call site, so
      // there is no floating label to style -- just a filled box with a 2dp
      // focus ring.
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        constraints: const BoxConstraints(minHeight: AppSizes.field),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
        // Sans, not the serif. `TextField` has no themed style for the text
        // the cook *types* -- it falls through to `bodyLarge`, which is
        // Literata since part 2 -- so each field also passes
        // `style: bodyMedium` at its call site. Only the hint can be set
        // from here, and it is set here so the two halves of a field cannot
        // disagree about their face. A search box is UI furniture.
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      // `primary`, not Material's `primaryContainer` default. Phase 7 part
      // 2's device walk found the unthemed FAB sitting at 1.94:1 against the
      // dark surface -- present in the tree and invisible to a person. The
      // one filled action on a screen is `primary` everywhere else in this
      // app; the FAB is no exception, and `primary`/`onPrimary` reads in
      // both brightnesses.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(0, AppSizes.button),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        ),
      ),

      // Destructive text buttons pass `error` at the call site -- the default
      // foreground stays `primary`.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(0, AppSizes.button),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(0, AppSizes.button),
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          iconSize: AppSizes.icon,
          minimumSize: const Size(AppSizes.target, AppSizes.target),
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.secondaryContainer,
          selectedForegroundColor: scheme.onSecondaryContainer,
          foregroundColor: scheme.onSurfaceVariant,
          minimumSize: const Size(0, AppSizes.button),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        elevation: 3,
        shadowColor: scheme.shadow,
        barrierColor: _barrierColor(brightness),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        elevation: 3,
        shadowColor: scheme.shadow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
        ),
      ),

      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(
            scheme.surfaceContainerHigh,
          ),
          elevation: const WidgetStatePropertyAll<double>(2),
          shadowColor: WidgetStatePropertyAll<Color>(scheme.shadow),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
          ),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        elevation: 2,
        shadowColor: scheme.shadow,
        textStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        elevation: 2,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        titleTextStyle: textTheme.titleSmall?.copyWith(color: scheme.onSurface),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// The scrim behind a dialog. `scrim` itself is opaque; what the design
  /// asks for is that colour at 32% in light and black at 50% in dark -- dark
  /// needs the heavier veil because its surfaces are already close in tone to
  /// the ground behind them.
  static Color _barrierColor(Brightness brightness) =>
      brightness == Brightness.light
      ? const Color(0xFF1F190F).withValues(alpha: 0.32)
      : Colors.black.withValues(alpha: 0.5);

  static ColorScheme _colorScheme(Brightness brightness) =>
      brightness == Brightness.light ? _lightScheme : _darkScheme;

  /// Cream ground, green for the one action that matters. A screen that reads
  /// as *mostly green* has gone wrong.
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF366A35),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFB9F1B3),
    onPrimaryContainer: Color(0xFF032B00),
    secondary: Color(0xFF775A0E),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFDEA4),
    onSecondaryContainer: Color(0xFF2F2201),
    tertiary: Color(0xFFAC3F25),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFDBD0),
    onTertiaryContainer: Color(0xFF461200),
    error: Color(0xFFA50048),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDDE2),
    onErrorContainer: Color(0xFF520020),
    surface: Color(0xFFFFF7EC),
    surfaceBright: Color(0xFFFFFAF4),
    surfaceDim: Color(0xFFE5DBD0),
    surfaceContainerLowest: Color(0xFFFFFDFA),
    surfaceContainerLow: Color(0xFFFAF1E5),
    surfaceContainer: Color(0xFFF5EBDF),
    surfaceContainerHigh: Color(0xFFEFE5DA),
    surfaceContainerHighest: Color(0xFFE8DED3),
    onSurface: Color(0xFF1F190F),
    onSurfaceVariant: Color(0xFF484134),
    outline: Color(0xFF6F6759),
    outlineVariant: Color(0xFFD1C8B8),
    inverseSurface: Color(0xFF342D24),
    onInverseSurface: Color(0xFFF9EFE3),
    inversePrimary: Color(0xFF9ED498),
    // Transparent in the scheme is what kills Material's elevation tint
    // app-wide, in one place, for every component at once.
    surfaceTint: Colors.transparent,
    scrim: Color(0xFF1F190F),
    shadow: Color(0xFF1F190F),
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF9ED498),
    onPrimary: Color(0xFF013908),
    primaryContainer: Color(0xFF1D511E),
    onPrimaryContainer: Color(0xFFBFF6B8),
    secondary: Color(0xFFE8C174),
    onSecondary: Color(0xFF3F2E00),
    secondaryContainer: Color(0xFF5B4300),
    onSecondaryContainer: Color(0xFFFFE5B9),
    // Paprika. D117 pinned `0xFFE7C17E` here because the generated value read
    // too close to secondary at the 3px width the import review marker is
    // drawn at; this is the palette's own answer to the same constraint, and
    // it separates from the mustard secondary cleanly.
    tertiary: Color(0xFFFF9569),
    onTertiary: Color(0xFF461200),
    tertiaryContainer: Color(0xFF881F09),
    onTertiaryContainer: Color(0xFFFFE2DA),
    error: Color(0xFFFEB9CB),
    onError: Color(0xFF650030),
    errorContainer: Color(0xFF891446),
    onErrorContainer: Color(0xFFFFE1E8),
    surface: Color(0xFF16160F),
    surfaceBright: Color(0xFF373731),
    surfaceDim: Color(0xFF16160F),
    surfaceContainerLowest: Color(0xFF101007),
    surfaceContainerLow: Color(0xFF1C1C16),
    surfaceContainer: Color(0xFF20201A),
    surfaceContainerHigh: Color(0xFF292923),
    surfaceContainerHighest: Color(0xFF34342E),
    onSurface: Color(0xFFEBEBE4),
    onSurfaceVariant: Color(0xFFCFD0C2),
    outline: Color(0xFF96978A),
    outlineVariant: Color(0xFF494A3F),
    inverseSurface: Color(0xFFE3E3DB),
    onInverseSurface: Color(0xFF2E2F29),
    inversePrimary: Color(0xFF366A35),
    surfaceTint: Colors.transparent,
    scrim: Color(0xFF000000),
    shadow: Color(0xFF000000),
  );

  /// Literata for what a person reads, the platform sans for UI furniture.
  ///
  /// `fontFamily: null` is not an omission -- it is how a role asks for
  /// Roboto / San Francisco. Line heights are written as the ratio literal
  /// (`44 / 36`) so the pair stays readable against
  /// `docs/DESIGN_SYSTEM.md` § Type. Roles not set here keep Material's
  /// defaults.
  static TextTheme _textTheme(ColorScheme scheme) {
    const String serif = 'Literata';
    const TextTheme base = TextTheme(
      // The wordmark, and nothing else.
      displaySmall: TextStyle(
        fontFamily: serif,
        fontSize: 36,
        height: 44 / 36,
        fontWeight: FontWeight.w600,
      ),
      // A recipe's title on its detail screen.
      headlineSmall: TextStyle(
        fontFamily: serif,
        fontSize: 26,
        height: 32 / 26,
        fontWeight: FontWeight.w600,
      ),
      // Screen and dialog titles.
      titleLarge: TextStyle(
        fontFamily: serif,
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
      ),
      // Section headings, card titles.
      titleMedium: TextStyle(
        fontFamily: serif,
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w600,
      ),
      // Field labels, tile titles. Sans: furniture, not reading.
      titleSmall: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
      ),
      // Reading text: steps, ingredient lines.
      bodyLarge: TextStyle(
        fontFamily: serif,
        fontSize: 17,
        height: 26 / 17,
        fontWeight: FontWeight.w400,
      ),
      // Default copy, empty states.
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
      ),
      // Captions, meta lines.
      bodySmall: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
      ),
      // Buttons, chips. Sans on purpose: a serif button label reads as
      // decoration.
      labelLarge: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
      ),
      // Badges, nav labels.
      labelMedium: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
      ),
    );
    return base.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
  }
}
