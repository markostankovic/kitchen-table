import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

/// Placeholder for Phase 1c (docs/ROADMAP.md).
class RecipeListScreen extends StatelessWidget {
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Recipes', icon: Icons.menu_book_outlined);
}
