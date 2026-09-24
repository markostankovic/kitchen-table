import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A centered, already-localized error message.
///
/// Phase 7 Part 1 replaces eight hand-written copies of
/// `Center(child: Padding(padding: EdgeInsets.all(24), child: Text(...)))`
/// across the app -- inconsistently centered, some with `textAlign.center`
/// and some without. This widget takes the finished `String` a caller already
/// produced with `localizedErrorMessage` (D92): it must never take the
/// `Object` error itself, since `core/widgets/` is generic and does not know
/// about `FailureCode`.
class AppErrorView extends StatelessWidget {
  const AppErrorView({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}
