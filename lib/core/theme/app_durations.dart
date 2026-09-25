import 'package:flutter/animation.dart';

/// The app's motion scale (`docs/DESIGN_SYSTEM.md` § Motion).
///
/// Two durations and one curve, and that is the whole vocabulary. This class
/// exists so that the slices which follow have a name to reach for when
/// something genuinely needs to move -- not so that anything animates for the
/// sake of it. The design is explicit that there is **no decorative
/// animation**: motion here is for a state change a person needs to follow,
/// never for flourish.
abstract final class AppDurations {
  /// A small state change -- a chip selecting, a checkbox ticking.
  static const Duration short = Duration(milliseconds: 150);

  /// A transition -- a sheet rising, a screen replacing another.
  static const Duration medium = Duration(milliseconds: 250);

  /// The curve both use.
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
}
