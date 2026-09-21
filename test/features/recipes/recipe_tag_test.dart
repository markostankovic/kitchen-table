// Phase 5, part 2 -- pure-Dart tests for `RecipeTag.vocabularyOf`, the
// derivation the tag filter chips are built from.

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/recipes/domain/recipe.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_tag.dart';

Recipe _recipe(String id, List<String> tags) => Recipe(
      id: id,
      householdId: 'h1',
      title: 'Recipe $id',
      originalLocale: 'sr',
      sourceType: RecipeSourceType.manual,
      status: RecipeStatus.draft,
      createdBy: 'u1',
      tags: tags,
    );

void main() {
  group('vocabularyOf', () {
    test('Posno and posno collapse to one entry', () {
      final List<RecipeTag> vocabulary = RecipeTag.vocabularyOf(<Recipe>[
        _recipe('r1', <String>['Posno']),
        _recipe('r2', <String>['posno']),
      ]);

      expect(vocabulary.map((RecipeTag t) => t.key), <String>['posno']);
    });

    test('the label is deterministic: the alphabetically-first spelling', () {
      final List<RecipeTag> vocabulary = RecipeTag.vocabularyOf(<Recipe>[
        _recipe('r1', <String>['posno']),
        _recipe('r2', <String>['Posno']),
      ]);

      expect(vocabulary.single.label, 'Posno');

      // Order of the recipes carrying the spelling must not matter.
      final List<RecipeTag> reversed = RecipeTag.vocabularyOf(<Recipe>[
        _recipe('r2', <String>['Posno']),
        _recipe('r1', <String>['posno']),
      ]);
      expect(reversed.single.label, 'Posno');
    });

    test('order is stable, sorted by key, independent of recipe order', () {
      final List<RecipeTag> vocabulary = RecipeTag.vocabularyOf(<Recipe>[
        _recipe('r1', <String>['Brzo']),
        _recipe('r2', <String>['Posno']),
      ]);
      final List<RecipeTag> reordered = RecipeTag.vocabularyOf(<Recipe>[
        _recipe('r2', <String>['Posno']),
        _recipe('r1', <String>['Brzo']),
      ]);

      expect(vocabulary.map((RecipeTag t) => t.key), <String>['brzo', 'posno']);
      expect(
        reordered.map((RecipeTag t) => t.key),
        vocabulary.map((RecipeTag t) => t.key),
      );
    });

    test('empty and blank tags are dropped', () {
      final List<RecipeTag> vocabulary = RecipeTag.vocabularyOf(<Recipe>[
        _recipe('r1', <String>['', '   ', 'Brzo']),
      ]);

      expect(vocabulary.map((RecipeTag t) => t.key), <String>['brzo']);
    });

    test('recipes with no tags contribute nothing', () {
      expect(
        RecipeTag.vocabularyOf(<Recipe>[_recipe('r1', <String>[])]),
        isEmpty,
      );
    });
  });

  group('relabelled', () {
    test('a tag with a pair is relabelled, key unchanged', () {
      final List<RecipeTag> relabelled = RecipeTag.relabelled(
        <RecipeTag>[const RecipeTag(key: 'posno', label: 'Posno')],
        <String, String>{'posno': 'Lenten'},
      );

      expect(relabelled.single.key, 'posno');
      expect(relabelled.single.label, 'Lenten');
    });

    test('a tag with no pair falls back to the as-typed label', () {
      final List<RecipeTag> relabelled = RecipeTag.relabelled(
        <RecipeTag>[const RecipeTag(key: 'brzo', label: 'Brzo')],
        <String, String>{'posno': 'Lenten'},
      );

      expect(relabelled.single.label, 'Brzo');
    });

    test('an empty label map leaves every tag as typed', () {
      final List<RecipeTag> vocabulary = <RecipeTag>[
        const RecipeTag(key: 'brzo', label: 'Brzo'),
        const RecipeTag(key: 'posno', label: 'Posno'),
      ];

      expect(
        RecipeTag.relabelled(vocabulary, const <String, String>{}),
        vocabulary,
      );
    });

    test('order is preserved', () {
      final List<RecipeTag> vocabulary = <RecipeTag>[
        const RecipeTag(key: 'brzo', label: 'Brzo'),
        const RecipeTag(key: 'posno', label: 'Posno'),
      ];

      final List<RecipeTag> relabelled = RecipeTag.relabelled(
        vocabulary,
        <String, String>{'posno': 'Lenten', 'brzo': 'Quick'},
      );

      expect(
        relabelled.map((RecipeTag t) => t.key),
        <String>['brzo', 'posno'],
      );
    });
  });
}
