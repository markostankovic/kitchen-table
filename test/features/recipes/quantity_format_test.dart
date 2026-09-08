import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/ingredients/domain/quantity.dart';
import 'package:kitchen_table/core/ingredients/widgets/quantity_format.dart';

/// A recipe writes `1½`, not `1.5`. Rule 5 keeps quantities exact all the way
/// through the database and the domain; this is the last step, where getting
/// it wrong would undo the whole point at the moment a human reads it.
void main() {
  group('formatQuantity', () {
    test('whole numbers lose the denominator', () {
      expect(formatQuantity(Quantity.whole(2)), '2');
      expect(formatQuantity(Quantity.whole(200)), '200');
    });

    test('vulgar fractions use the single character', () {
      expect(formatQuantity(Quantity.fraction(1, 2)), '½');
      expect(formatQuantity(Quantity.fraction(1, 3)), '⅓');
      expect(formatQuantity(Quantity.fraction(2, 3)), '⅔');
      expect(formatQuantity(Quantity.fraction(3, 4)), '¾');
    });

    test('mixed numbers close up around a vulgar fraction', () {
      expect(formatQuantity(Quantity.fraction(3, 2)), '1½');
      expect(formatQuantity(Quantity.fraction(7, 4)), '1¾');
    });

    test('a fraction Unicode has no character for stays as n/d', () {
      expect(formatQuantity(Quantity.fraction(1, 6)), '1/6');
      // ...and a mixed one takes a space, or `1 5/16` would read as one number.
      expect(formatQuantity(Quantity.fraction(21, 16)), '1 5/16');
    });

    test('an improper fraction that reduces to a whole prints as a whole', () {
      expect(formatQuantity(Quantity.fraction(4, 2)), '2');
      expect(formatQuantity(Quantity.fraction(6, 3)), '2');
    });

    test('ranges use an en dash', () {
      expect(
        formatQuantity(Quantity.range(
          numerator: 2,
          denominator: 1,
          maxNumerator: 3,
          maxDenominator: 1,
        )),
        '2–3',
      );
      expect(
        formatQuantity(Quantity.range(
          numerator: 1,
          denominator: 2,
          maxNumerator: 3,
          maxDenominator: 4,
        )),
        '½–¾',
      );
    });

    test('never renders a decimal', () {
      for (int d = 1; d <= 16; d++) {
        for (int n = 1; n <= 32; n++) {
          expect(formatQuantity(Quantity.fraction(n, d)), isNot(contains('.')),
              reason: '$n/$d rendered with a decimal point');
        }
      }
    });
  });
}
