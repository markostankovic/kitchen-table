// Phase 6, part 2 -- pure-Dart tests for `RecipeFilter.apply`, the predicate
// extracted from `RecipeRepository._filtered`.

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/recipes/domain/recipe.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_filter.dart';

Recipe _recipe(
  String id, {
  String title = 'Recipe',
  List<String> tags = const <String>[],
  bool isFavorite = false,
}) => Recipe(
      id: id,
      householdId: 'h1',
      title: title,
      originalLocale: 'sr',
      sourceType: RecipeSourceType.manual,
      status: RecipeStatus.draft,
      createdBy: 'u1',
      tags: tags,
      isFavorite: isFavorite,
    );

void main() {
  group('RecipeFilter.apply', () {
    test('the unfiltered fast path returns the input list', () {
      final List<Recipe> recipes = <Recipe>[_recipe('r1')];

      expect(identical(RecipeFilter.apply(recipes), recipes), isTrue);
    });

    test('a query substring-matches a tag as typed', () {
      final List<Recipe> recipes = <Recipe>[
        _recipe('r1', tags: <String>['Posno']),
        _recipe('r2', tags: <String>['Brzo']),
      ];

      expect(
        RecipeFilter.apply(recipes, query: 'posn').map((Recipe r) => r.id),
        <String>['r1'],
      );
    });

    test('a query substring-matches a translated spelling', () {
      final List<Recipe> recipes = <Recipe>[
        _recipe('r1', tags: <String>['Posno']),
      ];

      final List<Recipe> hit = RecipeFilter.apply(
        recipes,
        query: 'lent',
        spellingsByKey: <String, Set<String>>{
          'posno': <String>{'posno', 'lenten'},
        },
      );

      expect(hit.map((Recipe r) => r.id), <String>['r1']);
    });

    test('no hit when the spelling map is empty and only the other '
        "locale's word is typed", () {
      final List<Recipe> recipes = <Recipe>[
        _recipe('r1', tags: <String>['Posno']),
      ];

      expect(
        RecipeFilter.apply(recipes, query: 'lent'),
        isEmpty,
      );
    });

    test('title and tag are OR: a title match and a tag match both appear',
        () {
      final List<Recipe> recipes = <Recipe>[
        _recipe('r1', title: 'Posna torta'),
        _recipe('r2', title: 'Pita sa sirom', tags: <String>['Posno']),
        _recipe('r3', title: 'Kolač', tags: <String>['Brzo']),
      ];

      expect(
        RecipeFilter.apply(recipes, query: 'posn').map((Recipe r) => r.id),
        <String>['r1', 'r2'],
      );
    });

    test('tag and favoritesOnly still AND with the query and each other',
        () {
      final List<Recipe> recipes = <Recipe>[
        _recipe(
          'r1',
          title: 'Šargarepa torta',
          tags: <String>['Posno'],
          isFavorite: true,
        ),
        // Fails favoritesOnly.
        _recipe(
          'r2',
          title: 'Šargarepa pita',
          tags: <String>['Posno'],
        ),
        // Fails the tag.
        _recipe(
          'r3',
          title: 'Šargarepa salata',
          tags: <String>['Brzo'],
          isFavorite: true,
        ),
      ];

      expect(
        RecipeFilter.apply(
          recipes,
          query: 'sargarepa',
          tag: 'posno',
          favoritesOnly: true,
        ).map((Recipe r) => r.id),
        <String>['r1'],
      );
    });

    test('the chip path stays whole-token: tag "pos" does not match "Posno"',
        () {
      final List<Recipe> recipes = <Recipe>[
        _recipe('r1', tags: <String>['Posno']),
      ];

      expect(RecipeFilter.apply(recipes, tag: 'pos'), isEmpty);
    });

    test('diacritic-insensitivity: djuvec matches ĐUVEČ', () {
      final List<Recipe> recipes = <Recipe>[
        _recipe('r1', tags: <String>['ĐUVEČ']),
      ];

      expect(
        RecipeFilter.apply(recipes, query: 'djuvec').map((Recipe r) => r.id),
        <String>['r1'],
      );
    });
  });
}
