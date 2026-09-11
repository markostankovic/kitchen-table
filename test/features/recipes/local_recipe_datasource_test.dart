// Phase 2 part 6a -- the recipe cache round trip, and the ingredient-name
// cache + DisplayNameChain integration LocalRecipeDataSource also owns
// (D73). Deliberately not a widget test: neither concern has a Flutter
// dependency, and the claim is about what a real drift database round-trips,
// not about anything a screen renders.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/db/app_database.dart';
import 'package:kitchen_table/features/recipes/data/local_recipe_datasource.dart';

Map<String, dynamic> _recipeRow(
  String id, {
  String title = 'Pita',
  required String updatedAt,
  bool withLines = true,
}) => <String, dynamic>{
  'id': id,
  'household_id': 'h1',
  'title': title,
  'description': null,
  'servings': 4,
  'prep_minutes': null,
  'cook_minutes': null,
  'original_locale': 'sr',
  'source_type': 'manual',
  'source_url': null,
  'source_attribution': null,
  'status': 'draft',
  'image_path': null,
  'tags': <String>[],
  'created_by': 'u1',
  'updated_at': updatedAt,
  'deleted_at': null,
  if (withLines) 'recipe_ingredients': <Map<String, dynamic>>[],
  if (withLines) 'recipe_steps': <Map<String, dynamic>>[],
};

Map<String, dynamic> _nameRow(
  String id, {
  required String ingredientId,
  required String name,
  String locale = 'sr',
  bool isDisplayName = true,
  String createdAt = '2020-01-01T00:00:00Z',
  String updatedAt = '2020-01-01T00:00:00Z',
}) => <String, dynamic>{
  'id': id,
  'ingredient_id': ingredientId,
  'name': name,
  'locale': locale,
  'is_display_name': isDisplayName,
  'created_at': createdAt,
  'updated_at': updatedAt,
};

void main() {
  late AppDatabase db;
  late LocalRecipeDataSource local;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    local = LocalRecipeDataSource(db);
  });

  tearDown(() => db.close());

  group('recipes', () {
    test('a miss returns an empty list / null', () async {
      expect(await local.readAll(householdId: 'h1'), isEmpty);
      expect(await local.readOne('r1'), isNull);
      expect(await local.readRecipesWatermark('h1'), isNull);
    });

    test('readAll orders newest-updatedAt first', () async {
      await local.upsertMany(
        householdId: 'h1',
        rows: <Map<String, dynamic>>[
          _recipeRow('r1', title: 'Older', updatedAt: '2026-01-01T00:00:00Z'),
          _recipeRow('r2', title: 'Newer', updatedAt: '2026-06-01T00:00:00Z'),
        ],
      );

      final titles = (await local.readAll(householdId: 'h1'))
          .map((r) => r.title)
          .toList();
      expect(titles, <String>['Newer', 'Older']);
    });

    test('readAll is scoped to the household', () async {
      await local.upsertMany(
        householdId: 'h1',
        rows: <Map<String, dynamic>>[
          _recipeRow('r1', updatedAt: '2026-01-01T00:00:00Z'),
        ],
      );
      await local.upsertMany(
        householdId: 'h2',
        rows: <Map<String, dynamic>>[
          _recipeRow('r2', updatedAt: '2026-01-01T00:00:00Z'),
        ],
      );

      expect((await local.readAll(householdId: 'h1')).map((r) => r.id), <String>['r1']);
      expect((await local.readAll(householdId: 'h2')).map((r) => r.id), <String>['r2']);
    });

    test('an id cached without embedded lines reads back with none', () async {
      await local.upsertMany(
        householdId: 'h1',
        rows: <Map<String, dynamic>>[
          _recipeRow('r1', updatedAt: '2026-01-01T00:00:00Z', withLines: false),
        ],
      );

      final Map<String, dynamic>? row = await local.readOne('r1');
      expect(row, isNotNull);
      expect(row!.containsKey('recipe_ingredients'), isFalse);
    });

    test('an id cached with embedded lines reads them back', () async {
      await local.upsertMany(
        householdId: 'h1',
        rows: <Map<String, dynamic>>[
          _recipeRow('r1', updatedAt: '2026-01-01T00:00:00Z'),
        ],
      );

      final Map<String, dynamic>? row = await local.readOne('r1');
      expect(row!.containsKey('recipe_ingredients'), isTrue);
    });

    test('evict drops exactly the named row', () async {
      await local.upsertMany(
        householdId: 'h1',
        rows: <Map<String, dynamic>>[
          _recipeRow('r1', updatedAt: '2026-01-01T00:00:00Z'),
          _recipeRow('r2', updatedAt: '2026-01-01T00:00:00Z'),
        ],
      );

      await local.evict('r1');

      expect((await local.readAll(householdId: 'h1')).map((r) => r.id), <String>['r2']);
    });

    test('the recipes watermark advances to the exact timestamp given', () async {
      await local.advanceRecipesWatermark('h1', DateTime.utc(2026, 3, 1));
      expect(await local.readRecipesWatermark('h1'), DateTime.utc(2026, 3, 1));
      // A second household's watermark is untouched.
      expect(await local.readRecipesWatermark('h2'), isNull);
    });
  });

  group('ingredient names (D73)', () {
    test('resolveDisplayNames returns nothing cached for an unknown id', () async {
      expect(await local.resolveDisplayNames(<String>['i1'], 'sr'), isEmpty);
    });

    test(
      'resolveDisplayNames runs the real DisplayNameChain over cached rows',
      () async {
        await local.upsertNames(<Map<String, dynamic>>[
          _nameRow('n1', ingredientId: 'i1', name: 'flour', locale: 'en'),
          _nameRow('n2', ingredientId: 'i1', name: 'brašno', locale: 'sr'),
        ]);

        final names = await local.resolveDisplayNames(<String>['i1'], 'sr');
        expect(names, <String, String>{'i1': 'brašno'});
      },
    );

    test('evictName removes exactly the named row from resolution', () async {
      await local.upsertNames(<Map<String, dynamic>>[
        _nameRow('n1', ingredientId: 'i1', name: 'brašno'),
      ]);
      await local.evictName('n1');

      expect(await local.resolveDisplayNames(<String>['i1'], 'sr'), isEmpty);
    });

    test('the names watermark is global, independent of any household', () async {
      await local.advanceNamesWatermark(DateTime.utc(2026, 5, 1));
      expect(await local.readNamesWatermark(), DateTime.utc(2026, 5, 1));
    });
  });
}
