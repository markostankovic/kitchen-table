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
class IngredientLineRow extends StatelessWidget {
  const IngredientLineRow({
    required this.quantity,
    required this.unit,
    required this.name,
    this.optionalLabel,
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

  /// A second line under the name: the note, a `→ catalog name`, extra
  /// quantities, unmatched raw lines.
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
    final bool hasAmount = quantityText != null || unitText != null;
    final TextStyle? reading = theme.textTheme.bodyLarge;
    final TextStyle? muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final bool padded = inset || isFlagged;

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
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(text: name),
                      if (optionalText != null)
                        TextSpan(text: ' · $optionalText', style: muted),
                      // A word joiner glues the ring to the last word: a
                      // line may otherwise break before the placeholder and
                      // strand the ring alone on the next line.
                      if (!isMatched) const TextSpan(text: '\u2060'),
                      if (!isMatched)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.sm),
                            child: Tooltip(
                              message: unmatchedTooltip ?? '',
                              // Keyed because `CustomPaint` is a common
                              // enough internal for `find.byType` to be
                              // useless against it -- `ratingStars`'
                              // precedent, one screen over.
                              child: CustomPaint(
                                key: const Key('unmatchedMarker'),
                                size: const Size.square(AppSizes.iconInMeta),
                                painter: _DashedRingPainter(
                                  color: kitchen.unmatched,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  style: reading?.copyWith(color: scheme.onSurface),
                ),
                if (trailerText != null && trailerText.isNotEmpty)
                  Text(trailerText, style: muted),
              ],
            ),
          ),
          if (hasAmount) ...<Widget>[
            const SizedBox(width: AppSpacing.xl),
            Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  if (quantityText != null)
                    TextSpan(
                      text: quantityText,
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  if (quantityText != null && unitText != null)
                    const TextSpan(text: ' '),
                  if (unitText != null)
                    TextSpan(
                      text: unitText,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
              key: const Key('ingredientAmount'),
              style: reading,
              softWrap: false,
              textAlign: TextAlign.end,
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
          if (showDivider)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: padded ? AppSpacing.md : 0,
              ),
              child: CustomPaint(
                key: const Key('ingredientDivider'),
                size: const Size.fromHeight(_dividerHeight),
                painter: _DashedLinePainter(color: kitchen.dividerDash),
              ),
            ),
        ],
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
