import 'package:flutter/material.dart';

/// A blank, titled screen used to stand in for a tab that has no content yet.
///
/// Phase 0 ships four empty tabs so the shell and routing can be verified
/// before any feature exists (docs/ROADMAP.md, Phase 0). Each of these is
/// replaced by the real screen in Phase 1 onward.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    required this.icon,
    super.key,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
