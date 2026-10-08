import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import '../../theme/kitchen_colors.dart';

/// The review marker's width, named in DESIGN_SYSTEM. Private on purpose: one
/// number is not worth a cross-file constant.
const double _markerWidth = 3;

/// The divider's dash and the gap after it, named in DESIGN_SYSTEM
/// (`size-dash`, `size-dash-gap`). Private on `_markerWidth`'s precedent.
const double _dashLength = 6;
const double _dashGap = 4;

/// The divider's stroke, and the height it takes out of the row's 48dp.
const double _dividerHeight = 1;

/// One ingredient line, read-only: the name on the left, the amount on the
/// right (`docs/DESIGN_SYSTEM.md` § Ingredient lines, D127), with a dashed
/// divider under it.
///
/// **It takes primitives, not a model.** The recipe detail screen renders
/// `RecipeIngredient`s and the import review screen renders
/// `RecipeDraftLine`s -- two different types carrying the same five facts.
/// Taking `String?`s means the second screen reuses this row instead of
/// growing its own copy of it, which is the whole reason this file is in the
/// `core/ingredients/` middle ground (D43, D53) rather than in the recipes
/// feature.
///
/// The unit rides with the number, not the name: `½ kg` is one amount, set
/// as one `Text.rich` that never wraps, and the amounts line up on the right
/// edge down a list. The name takes whatever width is left and wraps on the
/// left. A line with no amount is the name alone, with no gap reserved.
///
/// [isMatched] `false` is **not an error state** (CLAUDE.md rule 3, and
/// `KitchenColors.unmatched`'s doc). The line renders exactly what the cook
/// typed, which is a fine outcome; the marker is a quiet dashed ring in
/// `outline`, inline after the name, and it is never red.
///
/// [nameMarker] is a generic slot for one more inline marker after the name
/// (and after the optional label), drawn the same way as the ring: a word
/// joiner, then a middle-aligned `WidgetSpan`, `xs` before it, in a 16dp
/// (`iconInMeta`) box. The row does not know what it means -- the shopping
/// list hands in its staple pin; the recipe detail and import review pass
/// nothing.
///
/// **A marker never sits alone on a line.** The word joiner is not enough:
/// Flutter breaks before a placeholder anyway when the last word and the
/// marker together overflow (the 2026-10-06 walk, a ring on its own fourth
/// line). So the row measures the name's last line, and when the markers
/// will not fit after it, turns the last space into a line break -- the last
/// word goes down with them. That is why the marker's box is fixed: its
/// width has to be known before layout.
///
/// [extraAmounts] stack under the first amount in the same right-aligned
/// column, each led by a `+` in `onSurfaceVariant` -- a second unit family
/// that was never merged into the first (D9). Only the shopping list has
/// more than one.
class IngredientLineRow extends StatelessWidget {
  const IngredientLineRow({
    required this.quantity,
    required this.unit,
    required this.name,
    this.optionalLabel,
    this.extraAmounts = const <({String? quantity, String? unit})>[],
    this.nameMarker,
    this.trailer,
    this.isMatched = true,
    this.isFlagged = false,
    this.inset = false,
    this.unmatchedTooltip,
    this.showDivider = true,
    super.key,
  });

  /// Already formatted as an exact fraction by `formatQuantity` -- this row
  /// never sees a [num] and so can never print `1.5` (rule 5).
  final String? quantity;

  /// The unit's display name in the reader's locale, never a unit code.
  final String? unit;

  /// The catalog's name for a matched line, the raw text for an unmatched
  /// one. One string either way: the caller has already resolved which.
  final String name;

  /// The localized `opciono` / `optional`, set as a muted suffix inline after
  /// the name. `null` for a required line.
  final String? optionalLabel;

  /// Further amounts, each already formatted like [quantity] and [unit],
  /// drawn one per line under the first. Empty for a single amount.
  final List<({String? quantity, String? unit})> extraAmounts;

  /// An inline marker after the name, optional label included. `null` draws
  /// nothing.
  final Widget? nameMarker;

  /// A second line under the name: the note, a `→ catalog name`, unmatched
  /// raw lines.
  final String? trailer;

  final bool isMatched;

  /// An import line a human still has to look at: a 3px `reviewMarker` left
  /// edge on a `surfaceContainerLow` tint. Nothing in the recipes surface sets
  /// this; it is here so the import review screen does not have to fork the
  /// row to get it.
  ///
  /// The marker is a *foreground* decoration, so it paints over the row
  /// without taking layout. A flagged row is always [inset], so the name
  /// clears the marker.
  final bool isFlagged;

  /// Pads the row's content `md` in from both edges, and the dashed divider
  /// with it, so the dashes start and end at the text. The flagged tint and
  /// marker still run the full width. Import review sets it on every row, so
  /// a flagged name lines up with its unflagged neighbours (`Review
  /// import@1x.png`); the recipe detail and the shopping list sit flush with
  /// the gutter.
  final bool inset;

  /// The localized "not matched to an ingredient" string, shown on the ring.
  final String? unmatchedTooltip;

  /// `false` drops the dashed divider under the row -- for the last row of a
  /// block or card.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final KitchenColors kitchen = theme.extension<KitchenColors>()!;
    final String? trailerText = trailer;
    final String? quantityText = quantity?.isEmpty ?? true ? null : quantity;
    final String? unitText = unit?.isEmpty ?? true ? null : unit;
    final String? optionalText = optionalLabel?.isEmpty ?? true
        ? null
        : optionalLabel;
    final List<({String? quantity, String? unit})> extras =
        <({String? quantity, String? unit})>[
          for (final ({String? quantity, String? unit}) a in extraAmounts)
            if ((a.quantity?.isNotEmpty ?? false) ||
                (a.unit?.isNotEmpty ?? false))
              a,
        ];
    final bool hasAmount =
        quantityText != null || unitText != null || extras.isNotEmpty;
    final TextStyle? reading = theme.textTheme.bodyLarge;
    final TextStyle? muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final bool padded = inset || isFlagged;

    // What the markers take after the last word, gap included.
    final double markersWidth =
        (nameMarker != null ? AppSpacing.xs + AppSizes.iconInMeta : 0) +
        (isMatched ? 0 : AppSpacing.sm + AppSizes.iconInMeta);
    final TextStyle nameStyle = DefaultTextStyle.of(context).style
        .merge(reading?.copyWith(color: scheme.onSurface));

    final Widget content = Container(
      // The divider takes the 1dp the old solid border took, so row heights
      // do not shift.
      constraints: BoxConstraints(
        minHeight: AppSizes.target - (showDivider ? _dividerHeight : 0),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
        left: padded ? AppSpacing.md : 0,
        right: padded ? AppSpacing.md : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final ({String name, String? optional}) lines =
                        _keepMarkersWithLastWord(
                          context: context,
                          maxWidth: constraints.maxWidth,
                          markersWidth: markersWidth,
                          name: name,
                          optional: optionalText == null
                              ? null
                              : ' · $optionalText',
                          nameStyle: nameStyle,
                          optionalStyle: muted,
                        );
                    return Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          TextSpan(text: lines.name),
                          if (lines.optional != null)
                            TextSpan(text: lines.optional, style: muted),
                          // Same word joiner as the ring below, for the same
                          // reason.
                          if (nameMarker != null)
                            const TextSpan(text: '\u2060'),
                          if (nameMarker != null)
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: AppSpacing.xs,
                                ),
                                child: SizedBox.square(
                                  dimension: AppSizes.iconInMeta,
                                  child: nameMarker,
                                ),
                              ),
                            ),
                          // A word joiner glues the ring to the last word
                          // where the line has room; where it has none,
                          // `_keepMarkersWithLastWord` already moved the word.
                          if (!isMatched) const TextSpan(text: '\u2060'),
                          if (!isMatched)
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: AppSpacing.sm,
                                ),
                                child: Tooltip(
                                  message: unmatchedTooltip ?? '',
                                  // Keyed because `CustomPaint` is a common
                                  // enough internal for `find.byType` to be
                                  // useless against it -- `ratingStars`'
                                  // precedent, one screen over.
                                  child: CustomPaint(
                                    key: const Key('unmatchedMarker'),
                                    size: const Size.square(
                                      AppSizes.iconInMeta,
                                    ),
                                    painter: _DashedRingPainter(
                                      color: kitchen.unmatched,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      style: nameStyle,
                    );
                  },
                ),
                if (trailerText != null && trailerText.isNotEmpty)
                  Text(trailerText, style: muted),
              ],
            ),
          ),
          if (hasAmount) ...<Widget>[
            const SizedBox(width: AppSpacing.xl),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                if (quantityText != null || unitText != null)
                  _amount(
                    scheme: scheme,
                    style: reading,
                    quantity: quantityText,
                    unit: unitText,
                    key: const Key('ingredientAmount'),
                  ),
                // Every extra shares one finder key, so each sits under its
                // own index key: siblings must not share a key.
                for (int i = 0; i < extras.length; i++)
                  KeyedSubtree(
                    key: ValueKey<int>(i),
                    child: _amount(
                      scheme: scheme,
                      style: reading,
                      quantity: extras[i].quantity?.isEmpty ?? true
                          ? null
                          : extras[i].quantity,
                      unit: extras[i].unit?.isEmpty ?? true
                          ? null
                          : extras[i].unit,
                      key: const Key('ingredientExtraAmount'),
                      plus: true,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    // The divider sits inside the tinted box, so the flagged tint and marker
    // run down to the dashes with no gap.
    return Container(
      decoration: BoxDecoration(
        color: isFlagged ? scheme.surfaceContainerLow : null,
      ),
      foregroundDecoration: isFlagged
          ? BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: kitchen.reviewMarker,
                  width: _markerWidth,
                ),
              ),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          content,
          if (showDivider) IngredientLineDivider(inset: padded),
        ],
      ),
    );
  }

  /// [name] and [optional] as drawn: unchanged, or with the last space
  /// turned into a line break when the markers ([markersWidth]) would not fit
  /// after the last line -- see the class doc. A last line of one word has
  /// no space to break at and is left alone; nothing better is possible.
  static ({String name, String? optional}) _keepMarkersWithLastWord({
    required BuildContext context,
    required double maxWidth,
    required double markersWidth,
    required String name,
    required String? optional,
    required TextStyle nameStyle,
    required TextStyle? optionalStyle,
  }) {
    if (markersWidth == 0 || !maxWidth.isFinite) {
      return (name: name, optional: optional);
    }
    final TextPainter painter = TextPainter(
      text: TextSpan(
        style: nameStyle,
        children: <InlineSpan>[
          TextSpan(text: name),
          if (optional != null) TextSpan(text: optional, style: optionalStyle),
        ],
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
    )..layout(maxWidth: maxWidth);
    final List<LineMetrics> metrics = painter.computeLineMetrics();
    painter.dispose();
    if (metrics.isEmpty || metrics.last.width + markersWidth <= maxWidth) {
      return (name: name, optional: optional);
    }

    String breakLastSpace(String text, int at) =>
        '${text.substring(0, at)}\n${text.substring(at + 1)}';
    // The optional label's leading space is not a break worth taking: it
    // would leave the name alone above ` · opciono`.
    final int inOptional = optional?.lastIndexOf(' ') ?? -1;
    if (optional != null && inOptional > 0) {
      return (name: name, optional: breakLastSpace(optional, inOptional));
    }
    final int inName = name.lastIndexOf(' ');
    if (inName < 0) return (name: name, optional: optional);
    return (name: breakLastSpace(name, inName), optional: optional);
  }

  /// One amount line: the number in `primary` w600 with tabular figures, the
  /// unit in `onSurfaceVariant` w400, never wrapping. [plus] leads it with a
  /// `+` in `onSurfaceVariant` -- not the canvas's `outline`, which is never
  /// body text (DESIGN_SYSTEM § Content and lines).
  static Widget _amount({
    required ColorScheme scheme,
    required TextStyle? style,
    required String? quantity,
    required String? unit,
    required Key key,
    bool plus = false,
  }) {
    final TextStyle mutedSpan = TextStyle(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w400,
    );
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          if (plus) TextSpan(text: '+ ', style: mutedSpan),
          if (quantity != null)
            TextSpan(
              text: quantity,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          if (quantity != null && unit != null) const TextSpan(text: ' '),
          if (unit != null) TextSpan(text: unit, style: mutedSpan),
        ],
      ),
      key: key,
      style: style,
      softWrap: false,
      textAlign: TextAlign.end,
    );
  }
}

/// The dashed divider under an [IngredientLineRow], on its own.
///
/// The row draws it itself; this is public for the one caller that has to put
/// something between a row and its divider -- the ingredient lines editor's
/// suggestion pill, which belongs to its line and so sits above the dashes.
/// Such a caller passes `showDivider: false` to the row and draws this under
/// the extra. [inset] matches the row's own.
class IngredientLineDivider extends StatelessWidget {
  const IngredientLineDivider({this.inset = false, super.key});

  final bool inset;

  @override
  Widget build(BuildContext context) {
    final KitchenColors kitchen = Theme.of(context).extension<KitchenColors>()!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset ? AppSpacing.md : 0),
      child: CustomPaint(
        key: const Key('ingredientDivider'),
        size: const Size.fromHeight(_dividerHeight),
        painter: _DashedLinePainter(color: kitchen.dividerDash),
      ),
    );
  }
}

/// A 16dp circle drawn as a run of short arcs.
///
/// Flutter has no dashed border, and CLAUDE.md rule 8 says a package is not
/// the answer to twenty lines of geometry. Dashes rather than a solid ring
/// because a solid one reads as a status dot -- something the app is telling
/// you *is* -- where a broken one reads as something unfinished, which is
/// exactly what an unmatched line is.
class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter({required this.color});

  final Color color;

  /// Eight dashes with eight gaps: enough to read as dashed at 16dp without
  /// turning into a grey smudge.
  static const int _dashes = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final Rect circle = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2 - paint.strokeWidth / 2,
    );
    const double step = 2 * math.pi / _dashes;
    for (int i = 0; i < _dashes; i++) {
      canvas.drawArc(circle, i * step, step / 2, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A 1dp horizontal run of 6dp dashes with 4dp gaps: the divider under a row.
///
/// Hand-drawn for the same reason as [_DashedRingPainter] (rule 8). It must
/// never read as that ring: this is long, flat, 1dp and in the lighter
/// `outlineVariant`, where the ring is small, closed, 1.5dp and `outline`.
class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.butt;

    final double y = size.height / 2;
    for (double x = 0; x < size.width; x += _dashLength + _dashGap) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + _dashLength, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
