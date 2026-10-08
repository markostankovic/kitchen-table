import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../text/rich_text_markup.dart';
import '../theme/app_spacing.dart';

/// Recipe text in the light-formatting subset (D165), drawn as formatting
/// rather than literal markers. The parsing is `parseRichText`'s.
///
/// - Bold is **w600**, never w700: w700 marks a recipe's name (D134), and
///   bold body text must not read as a title. Italic is true italic. Both
///   keep [style]'s colour.
/// - Bullets are a 6dp `onSurfaceVariant` disc, inset `xs` in a 20 marker
///   column, centred on the item's first line. Numbers are
///   `onSurfaceVariant` tabular figures on the text's baseline; a numbered
///   list widens its column to fit its widest marker (`10.`), shared by
///   every item. Wrapped lines hang under the item text.
/// - `md` between blocks, `xs` between items, nothing above the first block
///   or below the last -- the caller's gaps stay the caller's.
///
/// It never picks a type role: [style] is the caller's, including colour.
/// No `LayoutBuilder`: step rows sit inside `IntrinsicHeight`.
class AppRichText extends StatelessWidget {
  const AppRichText(this.text, {required this.style, super.key});

  final String text;
  final TextStyle style;

  static const double _markerColumn = 20;
  static const double _bulletDisc = 6;

  @override
  Widget build(BuildContext context) {
    final List<RichBlock> blocks = parseRichText(text);
    if (blocks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final (int index, RichBlock block) in blocks.indexed) ...<Widget>[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          switch (block) {
            RichParagraph(:final List<RichRun> runs) => _runs(runs),
            RichList() => _list(context, block),
          },
        ],
      ],
    );
  }

  Widget _runs(List<RichRun> runs) => Text.rich(
    TextSpan(
      style: style,
      children: <InlineSpan>[
        for (final RichRun run in runs)
          TextSpan(
            text: run.text,
            style: switch (run.style) {
              RichRunStyle.plain => null,
              RichRunStyle.bold => const TextStyle(fontWeight: FontWeight.w600),
              RichRunStyle.italic => const TextStyle(
                fontStyle: FontStyle.italic,
              ),
            },
          ),
      ],
    ),
  );

  Widget _list(BuildContext context, RichList list) {
    final ThemeData theme = Theme.of(context);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final Color markerColor = theme.colorScheme.onSurfaceVariant;
    final TextStyle numberStyle = style.copyWith(
      color: markerColor,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );

    double column = _markerColumn;
    if (list.ordered) {
      final TextStyle measuredStyle = DefaultTextStyle.of(context).style
          .merge(numberStyle);
      for (final RichListItem item in list.items) {
        // Measured in the style `Text` will actually draw: merged over
        // the ambient default, whose letter spacing it inherits.
        final TextPainter painter = TextPainter(
          text: TextSpan(text: item.number, style: measuredStyle),
          textDirection: Directionality.of(context),
          textScaler: scaler,
        )..layout();
        column = math.max(column, painter.width + AppSpacing.xs);
        painter.dispose();
      }
    }

    final double firstLineHeight =
        scaler.scale(style.fontSize ?? 14) * (style.height ?? 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final (int index, RichListItem item)
            in list.items.indexed) ...<Widget>[
          if (index > 0) const SizedBox(height: AppSpacing.xs),
          if (list.ordered)
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                SizedBox(
                  width: column,
                  child: Text(item.number!, style: numberStyle),
                ),
                Expanded(child: _runs(item.runs)),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: column,
                  height: firstLineHeight,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xs),
                      child: Container(
                        key: const Key('richTextBullet'),
                        width: _bulletDisc,
                        height: _bulletDisc,
                        decoration: BoxDecoration(
                          color: markerColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(child: _runs(item.runs)),
              ],
            ),
        ],
      ],
    );
  }
}
