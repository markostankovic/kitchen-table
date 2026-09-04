import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

/// Placeholder for Phase 2 (docs/ROADMAP.md).
class MealPlanScreen extends StatelessWidget {
  const MealPlanScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Plan',
        icon: Icons.calendar_month_outlined,
      );
}
