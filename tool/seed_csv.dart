// Reader and validator for the catalog seed CSVs.
//
// Shared deliberately: tool/gen_ingredient_seed.dart refuses to emit a
// migration that would not pass these checks, and
// test/features/ingredients/seed_csv_test.dart runs the same checks under
// `flutter test`. One definition, so a CSV cannot be valid to the fast loop
// and invalid to the generator.
//
// The checks exist because most of what can go wrong in a 200-row hand-written
// catalog is invisible until it produces a wrong match months later. Catching
// it here means the unique indexes in Postgres never have to reject a
// migration -- by the time SQL is generated, the content is already known good.

import 'dart:io';

import 'package:kitchen_table/core/text/text_normalizer.dart';

const String ingredientsPath = 'supabase/seeds/ingredients.csv';
const String namesPath = 'supabase/seeds/ingredient_names.csv';

/// Categories `ingredients.category` may take. Nullable in the database (only
/// Phase 4's aisle grouping reads it), but a free-text column nobody validates
/// becomes twelve spellings of "dairy".
const Set<String> categories = <String>{
  'produce', 'fruit', 'dairy', 'meat', 'fish',
  'pantry', 'spice', 'bakery', 'beverage', 'nuts',
};

const Set<String> unitFamilies = <String>{'mass', 'volume', 'count'};
const Set<String> locales = <String>{'sr', 'en'};

final RegExp _keyPattern = RegExp(r'^[a-z][a-z0-9_]*$');

class SeedIngredient {
  const SeedIngredient({
    required this.key,
    required this.parentKey,
    required this.category,
    required this.defaultUnitFamily,
    required this.isPantryStaple,
  });

  final String key;
  final String? parentKey;
  final String? category;
  final String? defaultUnitFamily;
  final bool isPantryStaple;
}

class SeedName {
  const SeedName({
    required this.ingredientKey,
    required this.locale,
    required this.name,
    required this.isDisplayName,
  });

  final String ingredientKey;
  final String locale;
  final String name;
  final bool isDisplayName;

  String get normalized => TextNormalizer.normalize(name);
}

class SeedCatalog {
  const SeedCatalog(this.ingredients, this.names);

  final List<SeedIngredient> ingredients;
  final List<SeedName> names;

  /// Child -> parent, for the rows that have a parent. Emitted as the seed
  /// migration's second pass.
  Map<String, String> get parentLinks => <String, String>{
        for (final SeedIngredient i in ingredients)
          if (i.parentKey != null) i.key: i.parentKey!,
      };
}

/// A single readable problem, `file:line - message`.
class SeedProblem {
  const SeedProblem(this.path, this.line, this.message);

  final String path;
  final int line;
  final String message;

  @override
  String toString() => '$path:$line - $message';
}

/// Reads both CSVs. Throws [FormatException] only on damage a validator could
/// not describe usefully (a missing file, a wrong column count).
SeedCatalog readCatalog({String root = '.'}) {
  final List<List<String>> ing = _readCsv('$root/$ingredientsPath', 5);
  final List<List<String>> nm = _readCsv('$root/$namesPath', 4);

  return SeedCatalog(
    <SeedIngredient>[
      for (final List<String> r in ing)
        SeedIngredient(
          key: r[0],
          parentKey: _orNull(r[1]),
          category: _orNull(r[2]),
          defaultUnitFamily: _orNull(r[3]),
          isPantryStaple: r[4] == 'true',
        ),
    ],
    <SeedName>[
      for (final List<String> r in nm)
        SeedName(
          ingredientKey: r[0],
          locale: r[1],
          name: r[2],
          isDisplayName: r[3] == 'true',
        ),
    ],
  );
}

/// Every rule the catalog has to satisfy. Empty list means the CSVs are safe
/// to generate from.
List<SeedProblem> validate(SeedCatalog catalog) {
  final List<SeedProblem> problems = <SeedProblem>[];

  // Line numbers are reconstructed by position, since the reader drops
  // comments and blanks. Good enough to find the row; the key is in the text.
  int lineOf(int index) => index + 1;

  final Set<String> keys = <String>{};
  for (int i = 0; i < catalog.ingredients.length; i++) {
    final SeedIngredient ing = catalog.ingredients[i];
    void bad(String m) =>
        problems.add(SeedProblem(ingredientsPath, lineOf(i), m));

    if (!_keyPattern.hasMatch(ing.key)) {
      bad('key "${ing.key}" is not ^[a-z][a-z0-9_]*\$');
    }
    if (!keys.add(ing.key)) {
      bad('duplicate key "${ing.key}"');
    }
    if (ing.category != null && !categories.contains(ing.category)) {
      bad('"${ing.key}" has unknown category "${ing.category}"');
    }
    if (ing.defaultUnitFamily != null &&
        !unitFamilies.contains(ing.defaultUnitFamily)) {
      bad('"${ing.key}" has unknown unit family "${ing.defaultUnitFamily}"');
    }
  }

  // D3: one level. A parent must exist and must not itself have a parent.
  final Map<String, String> links = catalog.parentLinks;
  for (int i = 0; i < catalog.ingredients.length; i++) {
    final SeedIngredient ing = catalog.ingredients[i];
    final String? parent = ing.parentKey;
    if (parent == null) continue;
    void bad(String m) =>
        problems.add(SeedProblem(ingredientsPath, lineOf(i), m));

    if (!keys.contains(parent)) {
      bad('"${ing.key}" has parent_key "$parent" which is not an ingredient');
    } else if (links.containsKey(parent)) {
      bad('"${ing.key}" -> "$parent" -> "${links[parent]}" is two levels (D3)');
    }
    if (parent == ing.key) {
      bad('"${ing.key}" is its own parent');
    }
  }

  // Names.
  final Map<String, Set<String>> localesSeen = <String, Set<String>>{};
  final Map<String, List<String>> displayNames = <String, List<String>>{};
  final Map<String, String> normalizedOwner = <String, String>{};

  for (int i = 0; i < catalog.names.length; i++) {
    final SeedName n = catalog.names[i];
    void bad(String m) => problems.add(SeedProblem(namesPath, lineOf(i), m));

    if (!keys.contains(n.ingredientKey)) {
      bad('name "${n.name}" points at unknown key "${n.ingredientKey}"');
      continue;
    }
    if (!locales.contains(n.locale)) {
      bad('name "${n.name}" has locale "${n.locale}" (only sr / en)');
      continue;
    }
    if (n.name.trim().isEmpty) {
      bad('empty name for "${n.ingredientKey}"');
      continue;
    }
    if (n.normalized.isEmpty) {
      bad('name "${n.name}" normalizes to nothing');
    }

    localesSeen.putIfAbsent(n.ingredientKey, () => <String>{}).add(n.locale);
    if (n.isDisplayName) {
      displayNames
          .putIfAbsent('${n.ingredientKey}|${n.locale}', () => <String>[])
          .add(n.name);
    }

    // The one that actually bites. Two rows normalizing the same inside one
    // locale means one string resolving two ways -- the unique index rejects
    // it, but the interesting part is *which* two, which SQL will not tell you.
    final String slot = '${n.locale}|${n.normalized}';
    final String? owner = normalizedOwner[slot];
    if (owner != null) {
      bad('"${n.name}" normalizes to "${n.normalized}", already claimed by '
          '"$owner" in locale ${n.locale}');
    } else {
      normalizedOwner[slot] = n.ingredientKey;
    }
  }

  for (final String key in keys) {
    final Set<String> seen = localesSeen[key] ?? const <String>{};
    for (final String loc in locales) {
      if (!seen.contains(loc)) {
        problems.add(SeedProblem(namesPath, 0, '"$key" has no $loc name'));
      }
      final List<String> displays = displayNames['$key|$loc'] ?? const <String>[];
      if (displays.isEmpty) {
        problems
            .add(SeedProblem(namesPath, 0, '"$key" has no $loc display name'));
      } else if (displays.length > 1) {
        problems.add(SeedProblem(namesPath, 0,
            '"$key" has ${displays.length} $loc display names: '
            '${displays.join(", ")}'));
      }
    }
  }

  return problems;
}

/// FNV-1a over both CSVs, for the drift guard in gen_ingredient_seed.dart.
///
/// Not a cryptographic hash and does not need to be -- it answers "did these
/// files change since the last generated migration", against no adversary.
/// Hand-rolled so the toolchain gains no dependency for it (CLAUDE.md rule 8).
String catalogFingerprint({String root = '.'}) {
  int hash = 0xcbf29ce484222325;
  const int prime = 0x100000001b3;
  const int mask = 0xFFFFFFFFFFFFFFFF;

  for (final String path in <String>[ingredientsPath, namesPath]) {
    for (final int byte in File('$root/$path').readAsBytesSync()) {
      hash = ((hash ^ byte) * prime) & mask;
    }
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

String? _orNull(String v) => v.isEmpty ? null : v;

/// Minimal CSV: splits on commas, drops blank lines and `#` comments, and
/// treats the first surviving line as the header. Fields may not contain
/// commas, which the CSV headers state and [validate] does not need to
/// re-check -- a stray comma shows up as a wrong column count right here.
List<List<String>> _readCsv(String path, int columns) {
  final File file = File(path);
  if (!file.existsSync()) {
    throw FormatException('missing seed CSV: $path');
  }

  final List<List<String>> rows = <List<String>>[];
  bool headerSeen = false;
  int lineNumber = 0;

  for (final String raw in file.readAsLinesSync()) {
    lineNumber++;
    final String line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;

    final List<String> fields =
        line.split(',').map((String f) => f.trim()).toList();

    if (!headerSeen) {
      headerSeen = true;
      if (fields.length != columns) {
        throw FormatException(
            '$path:$lineNumber - header has ${fields.length} columns, '
            'expected $columns');
      }
      continue;
    }

    if (fields.length != columns) {
      throw FormatException('$path:$lineNumber - ${fields.length} columns, '
          'expected $columns (a field probably contains a comma)');
    }
    rows.add(fields);
  }

  return rows;
}
