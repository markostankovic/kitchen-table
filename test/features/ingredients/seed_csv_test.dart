// Validates the catalog seed CSVs before they ever become SQL.
//
// This is the fast loop for a 200-row hand-written catalog. Everything it
// checks would eventually be caught by a unique index or a check constraint in
// Postgres -- but as an opaque migration failure, minutes later, naming a
// constraint rather than the two lines that collided. Here it names both.
//
// tool/gen_ingredient_seed.dart runs the same validate() and refuses to emit a
// migration that fails it, so this test and the generator cannot disagree.

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/seed_csv.dart';

void main() {
  late SeedCatalog catalog;

  setUpAll(() {
    catalog = readCatalog();
  });

  test('the seed CSVs satisfy every catalog rule', () {
    final List<SeedProblem> problems = validate(catalog);
    expect(
      problems,
      isEmpty,
      reason: 'seed CSV problems:\n${problems.join("\n")}',
    );
  });

  test('the curated core is actually seeded', () {
    // A guard against the CSV being emptied or half-written by an editor. The
    // exact number is not the point; an order of magnitude is.
    expect(catalog.ingredients.length, greaterThanOrEqualTo(150));
    expect(catalog.names.length, greaterThan(catalog.ingredients.length * 2));
  });

  test('the Serbian items no external dataset carries are present', () {
    // docs/INGREDIENTS.md names these by hand as the reason the catalog is
    // built rather than imported. Losing one to a refactor of the CSV should
    // fail, not pass quietly.
    final Set<String> keys =
        catalog.ingredients.map((SeedIngredient i) => i.key).toSet();
    for (final String required in <String>[
      'kajmak', 'ajvar', 'pindjur', 'urnebes', 'vegeta', 'suvo_meso',
      'slanina', 'kulen', 'sudzuk', 'cvarci', 'prezle', 'mladi_sir',
      'beli_sir', 'kore_za_pitu', 'gotova_kora', 'prasak_za_pecivo',
      'gustin', 'mineralna_voda', 'rakija', 'zacin_c', 'majcina_dusica',
      'vlasac', 'celer_list', 'pavlaka_slatka', 'pavlaka_kisela',
      'aleva_paprika_slatka', 'aleva_paprika_ljuta',
    ]) {
      expect(keys, contains(required));
    }
  });

  test('the five pantry staples are flagged and nothing else is', () {
    // is_pantry_staple suppresses an item from the shopping list, so a stray
    // true here silently drops something a user needs to buy.
    final Set<String> staples = catalog.ingredients
        .where((SeedIngredient i) => i.isPantryStaple)
        .map((SeedIngredient i) => i.key)
        .toSet();
    expect(staples, <String>{'so', 'voda', 'biber', 'ulje', 'secer'});
  });

  test('parented sets stay one level deep and point at real parents', () {
    // Duplicates validate()'s D3 rule on purpose: this is the assertion a
    // reader looks for when they want to know whether D3 is enforced anywhere.
    final Map<String, String> links = catalog.parentLinks;
    for (final MapEntry<String, String> e in links.entries) {
      expect(links.containsKey(e.value), isFalse,
          reason: '${e.key} -> ${e.value} -> ${links[e.value]} is two levels');
    }
    expect(links['brasno_glatko'], 'brasno');
    expect(links['pavlaka_kisela'], 'pavlaka');
    expect(links['aleva_paprika_ljuta'], 'aleva_paprika');
  });

  test('the phrases the roadmap names resolve to the right ingredient', () {
    // ROADMAP's "done when" for this phase, asserted against the source data
    // rather than the database, so a broken CSV fails before a reset is needed.
    Set<String> keysFor(String normalized) => catalog.names
        .where((SeedName n) => n.normalized == normalized)
        .map((SeedName n) => n.ingredientKey)
        .toSet();

    expect(keysFor('cufte'), isEmpty,
        reason: 'cufte is a dish, not a catalog ingredient -- it must reach '
            'the matcher through the fuzzy tier or not at all');
    expect(keysFor('sargarepa'), <String>{'sargarepa'});
    expect(keysFor('sargarepe'), <String>{'sargarepa'});
    expect(keysFor('brasna'), <String>{'brasno'});
    expect(keysFor('flour'), <String>{'brasno'});
  });
}
