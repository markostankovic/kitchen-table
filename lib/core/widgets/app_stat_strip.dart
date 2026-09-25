import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A band of label-above-value columns between two hairlines.
///
/// It replaces the dot-joined meta sentence the recipe detail screen used to
/// carry (`8 porcija · 30 min priprema · 45 min kuvanja`). Four facts read
/// faster as four columns than as one sentence, and — the reason this shape
/// was picked over a wrapping meta row — a column that is one of four is the
/// same width in both languages, so the Serbian labels do not reflow the
/// strip into a second line the way a run of text would.
///
/// A caller passes only the columns that have a value: a recipe with no cook
/// time gets three columns across the full width, not four with a gap.
class AppStatStrip extends StatelessWidget {
  const AppStatStrip({required this.columns, super.key});

  final List<AppStatColumn> columns;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? valueStyle = theme.textTheme.bodyLarge;

    // Every value sits in a box one `bodyLarge` line tall and is centred in
    // it, so a column whose value is five 16dp stars lines up with one whose
    // value is a 26dp line of text. Without it each column's value hangs from
    // its own top edge and the strip reads as four things at four heights --
    // which is how it rendered on the device before this.
    //
    // A minimum rather than a fixed height: a value that somehow needs two
    // lines grows instead of clipping.
    final double valueHeight =
        (valueStyle?.fontSize ?? 0) * (valueStyle?.height ?? 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final AppStatColumn column in columns)
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text(
                        column.label,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ConstrainedBox(
                        constraints: BoxConstraints(minHeight: valueHeight),
                        child: Center(
                          heightFactor: 1,
                          child: column.value,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }
}

/// One column of an [AppStatStrip].
///
/// [value] is a `Widget` rather than a `String` because one of the four
/// columns on a recipe is five stars, and it is an interactive control. A
/// text value is a `Text` in `bodyLarge` tinted `KitchenColors.statValue`;
/// the call site builds it, since only the call site knows whether what it is
/// showing is a number or a rating.
class AppStatColumn {
  const AppStatColumn({required this.label, required this.value});

  final String label;
  final Widget value;
}
