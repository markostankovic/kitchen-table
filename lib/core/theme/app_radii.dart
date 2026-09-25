/// The app's corner radius scale.
///
/// The Garden design system (`docs/DESIGN_SYSTEM.md` § Shape) gives corners
/// five steps, and which step a thing takes says what kind of thing it is: a
/// badge is tighter than a chip, a dialog is rounder than a card. Naming them
/// means a call site picks a meaning rather than a number.
///
/// "Full" -- buttons, the search field, the nav indicator -- is not here.
/// A stadium is a *shape*, not a radius: it is `const StadiumBorder()` at the
/// call site, so that a control which should stay pill-shaped at any height
/// cannot be quietly turned into a rounded rectangle by someone reaching for
/// the largest number in this class.
abstract final class AppRadii {
  /// Badges.
  static const double xs = 4;

  /// Chips, text fields, thumbnails, the snackbar, the offline banner.
  static const double sm = 8;

  /// Cards, meal entries.
  static const double md = 12;

  /// Menus, the FAB.
  static const double lg = 16;

  /// Dialogs, and the top corners of a bottom sheet.
  static const double xl = 28;
}
