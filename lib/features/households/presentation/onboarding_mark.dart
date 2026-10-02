import 'package:flutter/widgets.dart';

import '../../../core/theme/app_sizes.dart';

/// The app's mark as a rounded tile, at the top of the create and join
/// household screens -- the one feature that uses it, so it lives here rather
/// than in `core/widgets/`.
///
/// The corners are baked into the PNG (`make icons`, radius 24/108 like the
/// Android legacy launcher icon), so there is no clip here (D137).
class OnboardingMark extends StatelessWidget {
  const OnboardingMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/mark.png',
      width: AppSizes.onboardingMark,
      height: AppSizes.onboardingMark,
      excludeFromSemantics: true,
    );
  }
}
