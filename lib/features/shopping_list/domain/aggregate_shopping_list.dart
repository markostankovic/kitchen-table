/// The shopping list aggregation, as a pure function.
///
/// `docs/ARCHITECTURE.md` puts this on the client and in Dart: "pure
/// aggregation over rows the client can already read. No secret, fast, easier
/// to iterate on." Nothing here does I/O, so it is testable without a database
/// and works offline, which is the other half of why it is not an RPC.
///
/// The five steps are `docs/DATA_MODEL.md`'s, in order:
///   1. collect the lines of every non-leftover entry in range
///   2. scale by servings
///   3. group by ingredient id, falling back to normalized raw text
///   4. convert to the family's base unit and sum within a family, never across
///   5. flag pantry staples, with the household's override winning both ways
///
/// Pure Dart (rule 7).
library;

import '../../../core/text/text_normalizer.dart';
import '../../ingredients/domain/quantity.dart';
import '../../ingredients/domain/unit.dart';
import '../../ingredients/domain/unit_catalog.dart';
import '../../meal_plan/domain/meal_plan_entry.dart';
import '../../recipes/domain/recipe_ingredient.dart';
import 'rational.dart';
import 'shopping_item.dart';

/// One planned meal, reduced to what the aggregation needs from it.
///
/// The caller resolves entries to their lines; this function does not fetch.
typedef PlannedRecipe = ({
  MealPlanEntry entry,
  int? recipeServings,
  List<RecipeIngredient> lines,
});

/// Aggregates [planned] into shopping list items.
///
/// [pantryPrefs] maps an ingredient id to the household's `always_have`
/// override. A present entry wins over the catalog's global flag in BOTH
/// directions -- that is what the column is for, and a one-way override would
/// make "we never actually have sugar in this house" unsayable.
List<ShoppingItem> aggregateShoppingList({
  required List<PlannedRecipe> planned,
  required UnitCatalog units,
  Map<String, bool> pantryPrefs = const <String, bool>{},
}) {
  final Map<String, _Group> groups = <String, _Group>{};

  for (final PlannedRecipe meal in planned) {
    // Step 1. A leftover is a second serving of something already bought, and
    // a note is not food at all. `isLeftover` exists on MealPlanEntry for
    // exactly this line (D55 derives a leftover's recipe_id so no join is
    // needed to recognise one).
    if (meal.entry.isLeftover) continue;
    if (meal.entry.recipeId == null) continue;

    // Step 2.
    final Rational scale = _scaleFor(
      planned: meal.entry.servings,
      recipe: meal.recipeServings,
    );

    for (final RecipeIngredient line in meal.lines) {
      // Step 3. A matched line groups by its catalog id, so `brašno` from two
      // recipes is one item even when the two recipes spell it differently
      // (D1). An unmatched one groups by normalized raw text, which is the
      // same normalization Postgres applies -- `Šargarepa` and `sargarepa`
      // are one line, not two.
      final String key =
          line.ingredientId ?? 'raw:${TextNormalizer.normalize(line.rawText)}';
      final _Group group = groups.putIfAbsent(key, () => _Group(line));

      group.absorb(line, scale, units);
    }
  }

  return groups.values
      .map((_Group g) => g.toItem(units, pantryPrefs))
      .toList(growable: false);
}

/// `entry.servings / recipe.servings`, as an exact ratio.
///
/// Falls back to 1 whenever either side is missing or nonsensical. A recipe
/// with no serving count of its own cannot be scaled -- there is nothing to
/// scale *from* -- and silently guessing would change quantities the cook
/// never asked to change.
Rational _scaleFor({required int? planned, required int? recipe}) {
  if (planned == null || recipe == null) return Rational.one;
  if (planned <= 0 || recipe <= 0) return Rational.one;
  return Rational(planned, recipe);
}

/// One ingredient's accumulating totals, keyed by unit family.
class _Group {
  _Group(this.first);

  final RecipeIngredient first;
  final Map<UnitFamily, Rational> totals = <UnitFamily, Rational>{};

  /// The unit each family's total should be rendered in. Metric wins: a week
  /// that mixes `2 šolje` and `300 ml` is bought in millilitres, not in cups.
  final Map<UnitFamily, String> renderUnits = <UnitFamily, String>{};
  final List<String> unmatched = <String>[];

  void absorb(RecipeIngredient line, Rational scale, UnitCatalog units) {
    final Quantity? quantity = line.quantity;
    if (quantity == null) {
      // Step 4, the rule-3 case: no number to sum, so the line survives as
      // itself rather than being dropped or guessed at.
      _noteUnmatched(line.rawText);
      return;
    }

    final Unit? unit = line.unitCode == null
        ? null
        : units.byCode(line.unitCode!);

    // A bare number with no unit is a count of pieces -- `3 jaja`.
    final UnitFamily family = unit?.family ?? UnitFamily.count;

    // `prstohvat` and `po ukusu` are not quantities (migration 4 says so in
    // as many words). Summing them would produce `4 prstohvata`, which is not
    // a thing anybody buys.
    if (family == UnitFamily.other) {
      _noteUnmatched(line.rawText);
      return;
    }

    // The lower bound of a range is the main value, so `2-3 kašike` buys 2.
    // Deliberately conservative, and consistent with everything else that
    // ignores the range half of a Quantity.
    final Rational amount = Rational(quantity.numerator, quantity.denominator);
    final Rational toBase = unit == null ? Rational.one : _toBaseOf(unit);

    final Rational contribution;
    try {
      contribution = amount * toBase * scale;
    } on StateError {
      // An overflow is a number this code refuses to assert. Falling back to
      // the raw line is rule 3 again: better an unsummed line the cook reads
      // than a confident wrong total.
      _noteUnmatched(line.rawText);
      return;
    }

    totals[family] = (totals[family] ?? Rational.zero) + contribution;
    _chooseRenderUnit(family, unit, units);
  }

  void _noteUnmatched(String rawText) {
    if (!unmatched.contains(rawText)) unmatched.add(rawText);
  }

  /// Prefers a metric unit, and among metric ones the family's base.
  ///
  /// `Unit.isMetric` exists for precisely this: its doc says it is "only
  /// consulted for mass and volume, where the shopping list uses it to choose
  /// a display unit". Rendering scales up from the base afterwards, so
  /// recording `g` here still produces `1.2 kg` on screen.
  void _chooseRenderUnit(UnitFamily family, Unit? unit, UnitCatalog units) {
    if (renderUnits.containsKey(family)) return;
    renderUnits[family] = switch (family) {
      UnitFamily.mass => 'g',
      UnitFamily.volume => 'ml',
      UnitFamily.count => unit?.code ?? 'kom',
      UnitFamily.other => unit?.code ?? 'kom',
    };
  }

  ShoppingItem toItem(UnitCatalog units, Map<String, bool> pantryPrefs) {
    final String? ingredientId = first.ingredientId;

    // Step 5. The household's opinion beats the catalog's, in both directions.
    final bool staple =
        ingredientId != null && pantryPrefs.containsKey(ingredientId)
        ? pantryPrefs[ingredientId]!
        : first.isPantryStaple;

    final List<ItemQuantity> quantities = <ItemQuantity>[];
    for (final UnitFamily family in UnitFamily.values) {
      final Rational? total = totals[family];
      if (total == null || total.isZero) continue;
      quantities.add(
        ItemQuantity(
          family: family,
          amount: total,
          unitCode: renderUnits[family] ?? 'kom',
        ),
      );
    }

    // An unmatched line whose text IS the item's name adds nothing -- the
    // name is already on screen, and rendering both makes one line look like
    // two of the same thing. What survives is the lines that say something
    // more: a second spelling, or a note beside a quantity that did sum.
    final String name = first.resolvedName;
    final List<String> extra = unmatched
        .where((String line) => line != name)
        .toList(growable: false);

    return ShoppingItem(
      ingredientId: ingredientId,
      displayName: name,
      category: first.category,
      isPantryStaple: staple,
      quantities: quantities,
      unmatchedLines: List<String>.unmodifiable(extra),
    );
  }
}

/// [Unit.toBase] without going through its `double`.
///
/// The column is `numeric` and every value in it is an exact decimal, so
/// reading it exactly is possible -- see [Rational.parseDecimal]. The double
/// on [Unit] is what the parser and the line editor use, where exactness does
/// not matter; here it does.
Rational _toBaseOf(Unit unit) {
  final String? exact = unit.toBaseExact;
  if (exact != null) {
    try {
      return Rational.parseDecimal(exact);
    } on FormatException {
      // Fall through to the double below rather than failing the whole list.
    }
  }
  return Rational.parseDecimal(unit.toBase.toString());
}
