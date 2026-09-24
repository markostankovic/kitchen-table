/// The app's spacing scale.
///
/// Phase 7 Part 1 names a scale that was already the de-facto one in the
/// codebase -- `EdgeInsets.all(24)`, `SizedBox(height: 8)` and `height: 16`
/// were each already common before this file existed. Naming the steps means
/// migrating a call site to it costs nothing: the number does not change,
/// only what it is called.
///
/// New code picks a step here instead of writing a literal. Existing call
/// sites migrate as later Phase 7 parts touch those screens; this slice does
/// not sweep every `EdgeInsets`/`SizedBox` in `lib/` onto it.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}
