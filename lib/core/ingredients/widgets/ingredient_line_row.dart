import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import '../../theme/kitchen_colors.dart';

/// One ingredient line, read-only: the quantity in its own column, then the
/// unit and the name as a single run of text.
///
/// **It takes primitives, not a model.** The recipe detail screen renders
/// `RecipeIngredient`s and the import review screen renders
/// `RecipeDraftLine`s -- two different types carrying the same five facts.
/// Taking `String?`s means the second screen reuses this row instead of
/// growing its own copy of it, which is the whole reason this file is in the
/// `core/ingredients/` middle ground (D43, D53) rather than in the recipes
/// feature.
///
/// The quantity sits alone in a fixed-width right-aligned column so that
/// fractions line up down the list -- `½` under `1¼` under `200` -- and the
/// unit rides with the name rather than with the number, because `½ kg
/// mlevenog mesa` is read as one phrase. That is why unit and name are one
/// `Text.rich` and not two `Text`s: a break between them would be a break
/// mid-phrase.
///
/// [isMatched] `false` is **not an error state** (CLAUDE.md rule 3, and
/// `KitchenColors.unmatched`'s doc). The line renders exactly what the cook
/// typed, which is a fine outcome; the marker is a quiet dashed ring in
/// `outline`, and it is never red.
class IngredientLineRow extends StatelessWidget {
  const IngredientLineRow({
    required this.quantity,
    required this.unit,
    required this.name,
    this.trailer,
    this.isMatched = true,
    this.isFlagged = false,
    this.unmatchedTooltip,
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

  /// The line's note, or the `opciono` / `optional` suffix.
  final String? trailer;

  final bool isMatched;

  /// An import line a human still has to look at: a 3px `reviewMarker` left
  /// edge. Nothing in the recipes surface sets this; it is here so the import
  /// review screen does not have to fork the row to get it.
  final bool isFlagged;

  /// The localized "not matched to an ingredient" string, shown on the ring.
  final String? unmatchedTooltip;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final KitchenColors kitchen = theme.extension<KitchenColors>()!;
    final String? trailerText = trailer;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          left: isFlagged
              ? BorderSide(color: kitchen.reviewMarker, width: 3)
              : BorderSide.none,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: AppSizes.thumb,
            child: Text(
              quantity ?? '',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      if (unit != null && unit!.isNotEmpty)
                        TextSpan(
                          text: '$unit ',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      TextSpan(text: name),
                    ],
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (trailerText != null && trailerText.isNotEmpty)
                  Text(
                    trailerText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (!isMatched) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            Tooltip(
              message: unmatchedTooltip ?? '',
              // Keyed because `CustomPaint` is a common enough internal for
              // `find.byType` to be useless against it -- `ratingStars`'
              // precedent, one screen over.
              child: CustomPaint(
                key: const Key('unmatchedMarker'),
                size: const Size.square(AppSizes.iconInMeta),
                painter: _DashedRingPainter(color: kitchen.unmatched),
              ),
            ),
          ],
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
