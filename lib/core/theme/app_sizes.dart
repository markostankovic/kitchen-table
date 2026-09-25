/// The app's fixed sizes: hit areas, control heights, icon sizes.
///
/// From the Garden design system (`docs/DESIGN_SYSTEM.md` § Size). These are
/// the numbers that are a decision rather than an arrangement -- how tall a
/// button is, how big an icon reads in a meta line -- as opposed to the gaps
/// between things, which are [AppSpacing]'s business.
///
/// Most are set once in `app_theme.dart`'s component themes, so a screen
/// rarely names one directly; [thumb], [emptyStateIcon] and the three icon
/// sizes are the ones call sites do reach for.
abstract final class AppSizes {
  /// Minimum hit area for any control. Nothing tappable is smaller.
  static const double target = 48;

  /// All buttons.
  static const double button = 48;

  /// A filled text field, and the search field.
  static const double field = 52;

  /// Filter chips. An input/tag chip is 32 -- it is not a control, so it is
  /// not held to [target].
  static const double chip = 40;

  /// The top app bar.
  static const double appBar = 64;

  /// The `NavigationBar`.
  static const double nav = 80;

  /// Action icons.
  static const double icon = 24;

  /// An icon inside a button, where it sits beside a label.
  static const double iconInButton = 20;

  /// An icon in a meta line, beside small text.
  static const double iconInMeta = 16;

  /// A recipe card's photo, and the monogram tile that stands in for one.
  static const double thumb = 72;

  /// `AppEmptyState`'s icon. Deliberately its own name rather than borrowing
  /// [target]: they are the same number today, but one is a hit area and the
  /// other is a drawing, and they have no reason to move together.
  static const double emptyStateIcon = 48;
}
