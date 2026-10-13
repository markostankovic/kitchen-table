import 'package:flutter/material.dart';

import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';

/// What a tab shows in place of its content between a household switch and
/// the new household's data (phase9-household-switch-loading): one flat
/// card of placeholder bars, top-aligned in the tab's `Expanded`.
///
/// No shimmer -- [HouseholdSwitchProgressBar] above it is the one thing that
/// moves -- and no semantics: the bar is what a screen reader announces. Not
/// scrollable, so no pull-to-refresh. One shape for all three tabs.
class HouseholdSwitchPlaceholder extends StatelessWidget {
  const HouseholdSwitchPlaceholder({super.key});

  /// Height, fraction of the row's width, and whether the row carries a
  /// trailing amount bar -- the mock's `skel` rows, on the spacing scale.
  static const List<(double, double, bool)> _rows = <(double, double, bool)>[
    (AppSpacing.md, 0.30, false),
    (AppSpacing.lg, 0.50, true),
    (AppSpacing.lg, 0.38, true),
    (AppSpacing.md, 0.24, false),
    (AppSpacing.lg, 0.56, true),
    (AppSpacing.lg, 0.44, true),
  ];

  /// The trailing amount bar's fraction of the row's width.
  static const double _amountWidth = 0.12;

  @override
  Widget build(BuildContext context) {
    final Color bar = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ExcludeSemantics(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (int i = 0; i < _rows.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: AppSpacing.lg),
                    _Row(
                      height: _rows[i].$1,
                      widthFactor: _rows[i].$2,
                      amount: _rows[i].$3,
                      color: bar,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One placeholder row: a bar from the start at [widthFactor] of the row,
/// and, with [amount], a second one at the end.
class _Row extends StatelessWidget {
  const _Row({
    required this.height,
    required this.widthFactor,
    required this.amount,
    required this.color,
  });

  final double height;
  final double widthFactor;
  final bool amount;
  final Color color;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final double width = constraints.maxWidth;
      return Row(
        children: <Widget>[
          _Bar(width: width * widthFactor, height: height, color: color),
          const Spacer(),
          if (amount)
            _Bar(
              width: width * HouseholdSwitchPlaceholder._amountWidth,
              height: AppSpacing.lg,
              color: color,
            ),
        ],
      );
    },
  );
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height, required this.color});

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppRadii.xs),
    ),
  );
}

/// The 4dp indeterminate bar a tab shows directly under its app bar while
/// [HouseholdSwitchPlaceholder] stands in for its content: first in the
/// body's `Column`, full-bleed, in the layout flow. In place of the tab's own
/// 2dp bar, never beside it.
class HouseholdSwitchProgressBar extends StatelessWidget {
  const HouseholdSwitchProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return LinearProgressIndicator(
      minHeight: AppSpacing.xs,
      color: scheme.primary,
      backgroundColor: scheme.surfaceContainerHighest,
    );
  }
}
