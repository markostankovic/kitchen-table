/// Renders a [Quantity] the way a recipe writes one.
///
/// Fractions stay fractions. `3/2` is `1½`, never `1.5`, and a range is
/// `2–3` with an en dash, the way it was typed. The whole reason quantities
/// are stored as integer pairs (rule 5) is that a third of a cup is a third of
/// a cup; printing it as `0.33` would give that away at the last step.
library;

import '../../../ingredients/domain/quantity.dart';

/// The single-character forms Unicode has. Anything else falls back to `n/d`,
/// which reads perfectly well.
const Map<String, String> _vulgar = <String, String>{
  '1/2': '½',
  '1/3': '⅓',
  '2/3': '⅔',
  '1/4': '¼',
  '3/4': '¾',
  '1/5': '⅕',
  '1/8': '⅛',
  '3/8': '⅜',
  '5/8': '⅝',
  '7/8': '⅞',
};

String formatQuantity(Quantity quantity) {
  final String low = _formatPair(quantity.numerator, quantity.denominator);
  if (!quantity.isRange) return low;

  // Non-null by isRange, but read through locals so this does not depend on
  // promotion across a getter.
  final int? maxNumerator = quantity.maxNumerator;
  final int? maxDenominator = quantity.maxDenominator;
  if (maxNumerator == null || maxDenominator == null) return low;

  return '$low–${_formatPair(maxNumerator, maxDenominator)}';
}

String _formatPair(int numerator, int denominator) {
  if (denominator == 1) return '$numerator';

  final int whole = numerator ~/ denominator;
  final int remainder = numerator.remainder(denominator).abs();
  if (remainder == 0) return '$whole';

  final String fraction =
      _vulgar['$remainder/$denominator'] ?? '$remainder/$denominator';

  // A mixed number closes up around a vulgar fraction (`1½`) but needs a space
  // around a written one (`1 5/16`), or it reads as one long number.
  if (whole == 0) return fraction;
  return _vulgar.containsKey('$remainder/$denominator')
      ? '$whole$fraction'
      : '$whole $fraction';
}
