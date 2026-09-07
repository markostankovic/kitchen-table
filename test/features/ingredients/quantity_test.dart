// CLAUDE.md rule 5 lives in this class, so it is tested on its own.
//
// The rule is "quantities are integer fractions, never floats", and the reason
// is arithmetic that has to land exactly: three thirds of a cup are one cup,
// and a week's shopping list that sums halves and thirds must not ask for
// 0.9999999 kg of flour.

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/ingredients/domain/quantity.dart';

void main() {
  test('whole numbers are n/1', () {
    expect(Quantity.whole(3), const Quantity(numerator: 3, denominator: 1));
  });

  test('fractions are reduced, so equal quantities compare equal', () {
    // Without reduction these are three different freezed values, and
    // deduplicating a shopping list would treat them as three ingredients.
    expect(Quantity.fraction(2, 4), Quantity.fraction(1, 2));
    expect(Quantity.fraction(50, 100), Quantity.fraction(1, 2));
    expect(Quantity.fraction(6, 3), Quantity.whole(2));
  });

  test('the sign lives on the numerator', () {
    // Two representations of the same number must not compare unequal.
    expect(Quantity.fraction(1, -2), Quantity.fraction(-1, 2));
    expect(Quantity.fraction(1, -2).denominator, 2);
  });

  test('zero is representable and does not divide by zero', () {
    expect(Quantity.fraction(0, 5), const Quantity(numerator: 0, denominator: 1));
  });

  test('a zero denominator is rejected rather than silently accepted', () {
    // A programming error, not user input -- the parser cannot produce one,
    // since `1/0` fails the fraction read and falls through to the name.
    expect(() => Quantity.fraction(1, 0), throwsArgumentError);
  });

  test('ranges reduce both bounds independently', () {
    final Quantity q = Quantity.range(
      numerator: 2,
      denominator: 4,
      maxNumerator: 6,
      maxDenominator: 4,
    );
    expect(q.numerator, 1);
    expect(q.denominator, 2);
    expect(q.maxNumerator, 3);
    expect(q.maxDenominator, 2);
    expect(q.isRange, isTrue);
  });

  test('a plain quantity is not a range', () {
    expect(Quantity.whole(2).isRange, isFalse);
    expect(Quantity.fraction(1, 2).isRange, isFalse);
  });

  test('the lower bound is the main value, so range-blind code stays correct', () {
    // Anything that ignores maxNumerator reads 2, not 3 -- conservative, and
    // never over-orders.
    final Quantity q = Quantity.range(
      numerator: 2, denominator: 1, maxNumerator: 3, maxDenominator: 1,
    );
    expect(q.numerator, 2);
    expect(q.denominator, 1);
  });

  test('fractions sum exactly where doubles do not', () {
    // Three thirds of a cup are one cup.
    const Quantity third = Quantity(numerator: 1, denominator: 3);
    expect(
      Quantity.fraction(third.numerator * 3, third.denominator),
      Quantity.whole(1),
    );

    // And the classic, on a line a recipe really writes -- 100 g of something
    // plus 200 g of the same thing.
    expect(0.1 + 0.2 == 0.3, isFalse,
        reason: 'this is the arithmetic rule 5 exists to avoid');

    const Quantity a = Quantity(numerator: 1, denominator: 10);
    const Quantity b = Quantity(numerator: 2, denominator: 10);
    expect(
      Quantity.fraction(
        a.numerator * b.denominator + b.numerator * a.denominator,
        a.denominator * b.denominator,
      ),
      Quantity.fraction(3, 10),
    );
  });

  test('serialises as the two integers the database stores', () {
    final Map<String, dynamic> json = Quantity.fraction(3, 2).toJson();
    expect(json['numerator'], 3);
    expect(json['denominator'], 2);
    expect(Quantity.fromJson(json), Quantity.fraction(3, 2));
  });
}
