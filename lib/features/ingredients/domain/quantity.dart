import 'package:freezed_annotation/freezed_annotation.dart';

part 'quantity.freezed.dart';
part 'quantity.g.dart';

/// A recipe quantity, as an exact integer fraction.
///
/// CLAUDE.md rule 5: quantities are `qty_num` / `qty_den`, never floats. The
/// reason is that a third of a cup is a third of a cup -- it is not 0.333, and
/// three of them are one cup, not 0.999. A shopping list that sums halves and
/// thirds across a week has to land on exact numbers or it will quietly ask
/// for 0.9999999 kg of flour.
///
/// Ranges (`2-3 kašike`) fill [maxNumerator] / [maxDenominator]. The lower
/// bound is always the main value, so anything that ignores ranges still reads
/// a correct, conservative number.
///
/// Pure Dart (rule 7).
@freezed
abstract class Quantity with _$Quantity {
  const Quantity._();

  const factory Quantity({
    required int numerator,
    required int denominator,
    int? maxNumerator,
    int? maxDenominator,
  }) = _Quantity;

  factory Quantity.fromJson(Map<String, dynamic> json) =>
      _$QuantityFromJson(json);

  /// A whole number: `3` -> 3/1.
  factory Quantity.whole(int value) =>
      Quantity(numerator: value, denominator: 1);

  /// A fraction, reduced. Throws on a zero denominator, which is a programming
  /// error rather than bad input -- the parser never produces one.
  factory Quantity.fraction(int numerator, int denominator) {
    if (denominator == 0) {
      throw ArgumentError.value(denominator, 'denominator', 'must not be zero');
    }
    final (int n, int d) = _reduce(numerator, denominator);
    return Quantity(numerator: n, denominator: d);
  }

  /// A range. Both bounds are reduced independently.
  factory Quantity.range({
    required int numerator,
    required int denominator,
    required int maxNumerator,
    required int maxDenominator,
  }) {
    final (int n, int d) = _reduce(numerator, denominator);
    final (int mn, int md) = _reduce(maxNumerator, maxDenominator);
    return Quantity(
      numerator: n,
      denominator: d,
      maxNumerator: mn,
      maxDenominator: md,
    );
  }

  bool get isRange => maxNumerator != null && maxDenominator != null;

  /// For display and for sorting only. Never write this back to the database
  /// and never sum with it -- that is what the fraction exists to prevent.
  double get approximate => numerator / denominator;

  @override
  String toString() => isRange
      ? '$numerator/$denominator-$maxNumerator/$maxDenominator'
      : '$numerator/$denominator';
}

/// Reduces a fraction and normalises the sign onto the numerator, so that
/// equality on the freezed value type means what it looks like: 2/4 and 1/2
/// are the same quantity and compare equal.
(int, int) _reduce(int numerator, int denominator) {
  if (denominator == 0) {
    throw ArgumentError.value(denominator, 'denominator', 'must not be zero');
  }
  int a = numerator.abs();
  int b = denominator.abs();
  while (b != 0) {
    final int t = b;
    b = a % b;
    a = t;
  }
  final int divisor = a == 0 ? 1 : a;
  final int sign = denominator < 0 ? -1 : 1;
  return (sign * numerator ~/ divisor, (sign * denominator) ~/ divisor);
}
