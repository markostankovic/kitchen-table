/// An exact rational number, for summing a week's quantities.
///
/// CLAUDE.md rule 5 says quantities are integer fractions, never floats, and
/// [Quantity] already honours that for what a recipe writes. The shopping list
/// is where that rule is actually cashed in: `⅓ šolje` three times over a week
/// is one šolja, not 0.999, and `Quantity`'s own doc says so in as many words.
///
/// The reason a separate type is needed at all is the conversion step. Summing
/// across units means multiplying by `units.to_base`, and [Unit.toBase] is a
/// `double` -- deliberately, its doc explains, because it is a conversion
/// constant rather than a recipe's number. But every value in that column is
/// an exact decimal rational (`28.349523125` is `28349523125 / 10^9`, not an
/// irrational), so nothing actually forces a float here. [parseDecimal] is
/// what keeps the exactness: it reads the `numeric` the way Postgres sent it,
/// as text, instead of through a `double` that has already lost it.
///
/// Distinct from [Quantity] on purpose, and not a replacement for it.
/// [Quantity] models what a cook wrote -- it carries ranges (`2-3 kašike`) and
/// renders as `1½`. This models an intermediate sum, has no range, and exists
/// only between aggregation and rendering.
///
/// Pure Dart (rule 7).
library;

/// The largest value [numerator] or [denominator] may reach before an
/// operation is refused.
///
/// Dart ints are 64-bit, so the true ceiling is 2^63-1. Stopping three orders
/// of magnitude short leaves room for the multiply that detects the overflow
/// to itself be exact. In practice nothing comes close: the worst denominator
/// in the unit table is `fl_oz`'s 10^10, recipe denominators are single
/// digits, and reducing after every operation keeps a sum at the LCM of its
/// contributors rather than their product.
const int _kMaxTerm = 1 << 52;

class Rational implements Comparable<Rational> {
  /// Reduces on construction, so equality means what it looks like: 2/4 and
  /// 1/2 are the same number and compare equal.
  factory Rational(int numerator, int denominator) {
    if (denominator == 0) {
      throw ArgumentError.value(denominator, 'denominator', 'must not be zero');
    }
    final int divisor = _gcd(numerator.abs(), denominator.abs());
    final int sign = denominator < 0 ? -1 : 1;
    return Rational._(
      sign * numerator ~/ divisor,
      (sign * denominator) ~/ divisor,
    );
  }

  const Rational._(this.numerator, this.denominator);

  factory Rational.whole(int value) => Rational._(value, 1);

  /// Reads an exact decimal as written, without going through a `double`.
  ///
  /// This is the whole point of the class. `double.parse('28.349523125')`
  /// already cannot represent that value, so converting afterwards would
  /// preserve an error rather than avoid one. Postgres hands `numeric` over
  /// the wire as text precisely so it can be read exactly, and
  /// `IngredientRepository._toDouble` is where the app currently throws that
  /// away.
  ///
  /// Accepts an optional sign, digits, and an optional fractional part.
  /// Exponent notation is deliberately unsupported: `units.to_base` never uses
  /// it, and silently accepting `1e3` here would mean a second, looser number
  /// grammar in the app.
  factory Rational.parseDecimal(String source) {
    final String text = source.trim();
    final RegExp pattern = RegExp(r'^([+-]?)(\d+)(?:\.(\d+))?$');
    final RegExpMatch? match = pattern.firstMatch(text);
    if (match == null) {
      throw FormatException('not an exact decimal', source);
    }

    final bool negative = match.group(1) == '-';
    final String whole = match.group(2)!;
    final String fraction = match.group(3) ?? '';

    if (fraction.length > 18) {
      throw FormatException('too many decimal places to hold exactly', source);
    }

    final int denominator = _pow10(fraction.length);
    final int numerator = int.parse('$whole$fraction');
    return Rational(negative ? -numerator : numerator, denominator);
  }

  static const Rational zero = Rational._(0, 1);
  static const Rational one = Rational._(1, 1);

  final int numerator;
  final int denominator;

  bool get isZero => numerator == 0;

  /// For display and for sorting only. Never sum with this -- that is what the
  /// whole class exists to prevent.
  double get approximate => numerator / denominator;

  Rational operator +(Rational other) {
    // Reduce the cross terms first: adding n/d + m/e over the LCM rather than
    // the product d*e is what keeps a long sum's denominator from growing.
    final int divisor = _gcd(denominator, other.denominator);
    final int leftScale = other.denominator ~/ divisor;
    final int rightScale = denominator ~/ divisor;
    return Rational(
      _mul(numerator, leftScale) + _mul(other.numerator, rightScale),
      _mul(denominator, leftScale),
    );
  }

  Rational operator *(Rational other) {
    // Cancel across the two fractions before multiplying, not after: 3/10 *
    // 10/3 must not build 30/30 on the way to 1/1, because on a long chain
    // that intermediate is where an overflow would happen.
    final int leftDivisor = _gcd(numerator.abs(), other.denominator);
    final int rightDivisor = _gcd(other.numerator.abs(), denominator);
    return Rational(
      _mul(numerator ~/ leftDivisor, other.numerator ~/ rightDivisor),
      _mul(denominator ~/ rightDivisor, other.denominator ~/ leftDivisor),
    );
  }

  @override
  int compareTo(Rational other) {
    final int divisor = _gcd(denominator, other.denominator);
    return _mul(
      numerator,
      other.denominator ~/ divisor,
    ).compareTo(_mul(other.numerator, denominator ~/ divisor));
  }

  @override
  bool operator ==(Object other) =>
      other is Rational &&
      other.numerator == numerator &&
      other.denominator == denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() =>
      denominator == 1 ? '$numerator' : '$numerator/$denominator';
}

int _gcd(int a, int b) {
  int x = a.abs();
  int y = b.abs();
  while (y != 0) {
    final int t = y;
    y = x % y;
    x = t;
  }
  return x == 0 ? 1 : x;
}

/// Multiplies, refusing rather than wrapping.
///
/// An overflow here would be the quietest possible failure -- a negative
/// shopping quantity, or a plausible wrong one -- which is precisely the class
/// of bug the exact-rational path exists to rule out. Better a loud throw the
/// aggregator can turn into an unmatched line.
int _mul(int a, int b) {
  final int product = a * b;
  if (a != 0 && (product ~/ a != b || product.abs() > _kMaxTerm)) {
    throw StateError('rational overflow: $a * $b');
  }
  return product;
}

int _pow10(int exponent) {
  int value = 1;
  for (int i = 0; i < exponent; i++) {
    value *= 10;
  }
  return value;
}
