import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/shopping_list/domain/rational.dart';

void main() {
  group('construction', () {
    test('reduces, so equality means what it looks like', () {
      expect(Rational(2, 4), Rational(1, 2));
      expect(Rational(300, 100), Rational(3, 1));
    });

    test('normalises the sign onto the numerator', () {
      expect(Rational(1, -2), Rational(-1, 2));
      expect(Rational(-1, -2), Rational(1, 2));
    });

    test('refuses a zero denominator', () {
      expect(() => Rational(1, 0), throwsArgumentError);
    });
  });

  group('parseDecimal', () {
    test('reads an exact decimal without going through a double', () {
      // The case the whole class exists for. double.parse cannot hold this
      // value, so a conversion afterwards would preserve an error rather than
      // avoid one.
      final Rational ounce = Rational.parseDecimal('28.349523125');
      // Reduced on construction: 28349523125/10^9 cancels by 625. That it
      // lands on 45359237 is not a coincidence -- it is the numerator of a
      // pound in grams, and an ounce is exactly a sixteenth of one.
      expect(ounce, Rational(45359237, 1600000));
      expect(ounce * Rational(16, 1), Rational.parseDecimal('453.59237'));
    });

    test('handles every to_base value in the unit table', () {
      const List<String> values = <String>[
        '0.001', '1', '1000', '28.349523125', '453.59237',
        '100', '5', '15', '240', '200', '29.5735295625',
      ];
      for (final String value in values) {
        expect(Rational.parseDecimal(value).approximate,
            closeTo(double.parse(value), 1e-9),
            reason: value);
      }
    });

    test('accepts a sign and a bare integer', () {
      expect(Rational.parseDecimal('-2.5'), Rational(-5, 2));
      expect(Rational.parseDecimal('7'), Rational(7, 1));
    });

    test('refuses exponent notation rather than guessing', () {
      expect(() => Rational.parseDecimal('1e3'), throwsFormatException);
      expect(() => Rational.parseDecimal('kašika'), throwsFormatException);
    });
  });

  group('arithmetic', () {
    test('thirds sum to a whole, which is the entire point', () {
      final Rational third = Rational(1, 3);
      expect(third + third + third, Rational(1, 1));
    });

    test('a week of thirds of a cup lands on an exact millilitre count', () {
      // ⅓ šolje is 80 ml exactly; three of them are 240, not 239.99998.
      final Rational cup = Rational.parseDecimal('240');
      final Rational third = Rational(1, 3) * cup;
      expect(third, Rational(80, 1));
      expect(third + third + third, Rational(240, 1));
    });

    test('adds over the LCM, not the product, so denominators stay small', () {
      final Rational sum = Rational(1, 6) + Rational(1, 10);
      expect(sum, Rational(4, 15));
      expect(sum.denominator, 15);
    });

    test('cancels across a multiply before building the product', () {
      expect(Rational(3, 10) * Rational(10, 3), Rational(1, 1));
    });

    test('compares without losing precision', () {
      expect(Rational(1, 3).compareTo(Rational(1, 2)), lessThan(0));
      expect(Rational(2, 4).compareTo(Rational(1, 2)), 0);
    });

    test('refuses to overflow rather than wrapping silently', () {
      // A wrapped int would produce a plausible, negative shopping quantity,
      // which is exactly the class of bug this path exists to rule out.
      final Rational huge = Rational(1 << 50, 3);
      expect(() => huge * huge, throwsStateError);
    });
  });
}
