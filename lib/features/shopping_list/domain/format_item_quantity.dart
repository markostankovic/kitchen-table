/// Rendering a summed quantity as a cook would write it on a list.
///
/// Separate from `core/ingredients/widgets/quantity_format.dart`, which
/// renders what a RECIPE says -- `1½ šolje`, the original unit, fractions kept
/// as fractions because D9's note says rounded conversions ruin baking. This
/// renders a TOTAL, which is a different job: nobody buys `1½ šolje` of
/// flour, they buy 360 ml or 1.2 kg, and the scale-up from the family's base
/// unit is the whole point.
///
/// Pure Dart (rule 7), so it is testable without a widget.
library;

import '../../ingredients/domain/unit.dart';
import '../../ingredients/domain/unit_catalog.dart';
import 'rational.dart';
import 'shopping_item.dart';

/// Metric steps per family, largest first. Only these are ever scaled up to:
/// a total in `cup` or `oz` is a total nobody asked for, because the sum that
/// produced it mixed units that were never comparable by eye.
/// Deliberately no `dl`. A decilitre is a recipe unit, not a shopping one --
/// nothing on a shelf is labelled 4.8 dl, and `480 ml` is the same number
/// written the way the carton is. Same reason there is no `tbsp` here: the
/// ladder is what a shop sells in, not what a recipe measures in.
const Map<UnitFamily, List<String>> _ladder = <UnitFamily, List<String>>{
  UnitFamily.mass: <String>['kg', 'g'],
  UnitFamily.volume: <String>['l', 'ml'],
};

/// `800 g`, `1.2 kg`, `2.5 l`, `3 kom`.
///
/// [locale] picks the unit's spelling from the catalog, so a Serbian list says
/// `kom` and never `pc`.
String formatItemQuantity(
  ItemQuantity quantity,
  UnitCatalog units, {
  String locale = 'sr',
}) {
  final (Rational amount, String code) = _scaled(quantity, units);
  return '${_number(amount)} ${units.displayName(code, locale: locale)}';
}

/// Picks the largest metric unit that leaves a value of at least 1.
///
/// 1200 g reads as `1.2 kg`; 800 g stays `800 g`, because `0.8 kg` is the same
/// number written worse. Count and other families never scale -- there is no
/// ladder above one piece.
(Rational, String) _scaled(ItemQuantity quantity, UnitCatalog units) {
  final List<String>? ladder = _ladder[quantity.family];
  if (ladder == null) return (quantity.amount, quantity.unitCode);

  for (final String code in ladder) {
    final Unit? unit = units.byCode(code);
    if (unit == null) continue;

    final Rational factor = _exact(unit);
    // amount / factor, as a rational: multiply by the reciprocal.
    final Rational scaled =
        quantity.amount * Rational(factor.denominator, factor.numerator);
    if (scaled.compareTo(Rational.one) >= 0) return (scaled, code);
  }

  return (quantity.amount, quantity.unitCode);
}

Rational _exact(Unit unit) {
  final String? text = unit.toBaseExact;
  if (text != null) {
    try {
      return Rational.parseDecimal(text);
    } on FormatException {
      // Fall through.
    }
  }
  return Rational.parseDecimal(unit.toBase.toString());
}

/// A whole number stays whole; anything else gets at most two decimals.
///
/// Decimals here and fractions on a recipe line is deliberate, not an
/// inconsistency. `1.2 kg` is how a scale reads and how a shelf is labelled;
/// `1⅕ kg` is not something anybody has ever weighed out. The exact rational
/// is what got us here correctly -- rounding is the last step, once the
/// arithmetic is over.
String _number(Rational amount) {
  if (amount.denominator == 1) return '${amount.numerator}';

  final double value = amount.approximate;
  final String text = value.toStringAsFixed(2);
  // Trim trailing zeros so 1.50 reads as 1.5 and 2.00 as 2.
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}
