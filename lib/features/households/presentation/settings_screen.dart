import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

/// Placeholder for Phase 1a (docs/ROADMAP.md).
///
/// Lives under `households/` rather than a `settings/` feature: there is no
/// settings feature in CLAUDE.md's list, and what this tab actually grows into
/// is household management -- create/join, member list, invites.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Settings',
        icon: Icons.settings_outlined,
      );
}
