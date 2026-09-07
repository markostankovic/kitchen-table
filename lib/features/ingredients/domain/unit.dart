import 'package:freezed_annotation/freezed_annotation.dart';

part 'unit.freezed.dart';
part 'unit.g.dart';

/// What a unit measures. Matches the `family` check constraint on `units`.
///
/// `other` is the escape hatch for measures that are not quantities at all --
/// `prstohvat`, `po ukusu`. The shopping list never converts or sums them (D9).
enum UnitFamily { mass, volume, count, other }

/// One row of the unit lexicon.
///
/// Pure Dart (CLAUDE.md rule 7).
@freezed
abstract class Unit with _$Unit {
  const factory Unit({
    required String code,
    required UnitFamily family,

    /// Multiplier to the family's base: grams, millilitres, or one piece.
    ///
    /// A `double`, and deliberately not the integer fraction rule 5 mandates
    /// for quantities. This is a conversion constant, not a quantity -- an
    /// ounce is 28.349523125 g and no fraction expresses that honestly. The
    /// rule exists so a recipe's `1/3 šolje` never becomes 0.3333; nothing
    /// here is a recipe's number.
    required double toBase,

    /// True only for the metric system proper. Only consulted for mass and
    /// volume, where the shopping list uses it to choose a display unit.
    @Default(false) bool isMetric,
  }) = _Unit;

  factory Unit.fromJson(Map<String, dynamic> json) => _$UnitFromJson(json);
}
