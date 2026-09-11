// Phase 2 part 6a -- the recipe list and detail's offline behaviour, proved
// against a real RecipeRepository/LocalRecipeDataSource over
// NativeDatabase.memory() and a hand-written fake for the network edge (no
// mocking package, the house style, on
// shopping_list_repository_offline_test.dart's precedent).

import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/db/app_database.dart';
import 'package:kitchen_table/core/error/app_failure.dart';
import 'package:kitchen_table/features/recipes/data/local_recipe_datasource.dart';
import 'package:kitchen_table/features/recipes/data/recipe_repository.dart';
import 'package:kitchen_table/features/recipes/data/remote_recipe_datasource.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_detail.dart';

Map<String, dynamic> _row(
  String id, {
  String title = 'Pita',
  String updatedAt = '2026-01-01T00:00:00Z',
  String? deletedAt,
  List<Map<String, dynamic>> lines = const <Map<String, dynamic>>[],
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
  'deleted_at': deletedAt,
  'recipe_ingredients': lines,
  'recipe_steps': const <Map<String, dynamic>>[],
};

/// Controls exactly the network calls the two methods under test make.
/// `implements` rather than `extends`: every other member throws by
/// omission, so a test that accidentally reached one fails loudly.
class _FakeRemote implements RemoteRecipeDataSource {
  List<Map<String, dynamic>> changed = <Map<String, dynamic>>[];
  Map<String, dynamic>? oneRow;
  AppFailure? nextFailure;
  int fetchChangedCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> fetchChangedSince({
    required String householdId,
    DateTime? since,
  }) async {
    fetchChangedCalls++;
    final AppFailure? failure = nextFailure;
    if (failure != null) throw failure;
    return changed;
  }

  @override
  Future<Map<String, dynamic>> fetchOne(String id) async {
    final AppFailure? failure = nextFailure;
    if (failure != null) throw failure;
    return oneRow!;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchNamesSince(DateTime? since) async =>
      const <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> fetchLinesForRecipesRaw(
    List<String> recipeIds,
  ) => throw UnimplementedError();

  @override
  Future<Map<String, String>> fetchDisplayNames(
    List<String> ids,
    String locale,
  ) async => const <String, String>{};

  @override
  Future<Map<String, String>> signImageUrls(List<String> paths) async =>
      const <String, String>{};

  @override
  Future<Map<String, dynamic>> create({
    required String householdId,
    required String title,
    required String originalLocale,
    String? description,
    int? servings,
    int? prepMinutes,
    int? cookMinutes,
    List<String> tags = const <String>[],
    required String sourceTypeWire,
    required String statusName,
    String? sourceUrl,
    String? sourceAttribution,
    String? imagePath,
  }) => throw UnimplementedError();

  @override
  Future<void> update({
    required String id,
    required String title,
    String? description,
    int? servings,
    int? prepMinutes,
    int? cookMinutes,
    required String originalLocale,
    String? sourceUrl,
    String? sourceAttribution,
    required String statusName,
    List<String> tags = const <String>[],
    String? imagePath,
  }) => throw UnimplementedError();

  @override
  Future<void> saveLines(
    String recipeId, {
    required List<Map<String, dynamic>> ingredientLines,
    required List<Map<String, dynamic>> stepPayloads,
  }) => throw UnimplementedError();

  @override
  Future<String> uploadImage(
    Uint8List bytes, {
    required String householdId,
    required String contentType,
    required String extension,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteImage(String path) => throw UnimplementedError();

  @override
  Future<void> softDelete(String id) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  late _FakeRemote remote;
  late RecipeRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    remote = _FakeRemote();
    repository = RecipeRepository(remote, LocalRecipeDataSource(db));
  });

  tearDown(() => db.close());

  group('watchList', () {
    test('a cold cache with a successful network read yields the fresh list once', () async {
      remote.changed = <Map<String, dynamic>>[_row('r1')];

      final emitted = await repository.watchList(householdId: 'h1').toList();

      expect(emitted.map((rs) => rs.map((r) => r.id)).toList(), <List<String>>[
        <String>['r1'],
      ]);
    });

    test('a cold cache with a NetworkFailure rethrows, honestly', () async {
      remote.nextFailure = const NetworkFailure();

      await expectLater(
        repository.watchList(householdId: 'h1'),
        emitsError(
          isA<NetworkFailure>().having(
            (NetworkFailure e) => e.message,
            'message',
            contains('no saved recipes on this phone yet'),
          ),
        ),
      );
    });

    test(
      'a warm cache with a NetworkFailure completes quietly, keeping the cached list',
      () async {
        await LocalRecipeDataSource(db).upsertMany(
          householdId: 'h1',
          rows: <Map<String, dynamic>>[_row('r1')],
        );
        remote.nextFailure = const NetworkFailure();

        final emitted = await repository.watchList(householdId: 'h1').toList();

        expect(emitted.single.map((r) => r.id), <String>['r1']);
      },
    );

    test('a soft-deleted row in the delta evicts it from the cache', () async {
      await LocalRecipeDataSource(db).upsertMany(
        householdId: 'h1',
        rows: <Map<String, dynamic>>[_row('r1')],
      );
      remote.changed = <Map<String, dynamic>>[
        _row('r1', deletedAt: '2026-02-01T00:00:00Z'),
      ];

      final emitted = await repository.watchList(householdId: 'h1').toList();

      expect(emitted.last, isEmpty);
      expect(await LocalRecipeDataSource(db).readOne('r1'), isNull);
    });

    test(
      'the watermark advances to the max(updated_at) actually received, not now()',
      () async {
        remote.changed = <Map<String, dynamic>>[
          _row('r1', updatedAt: '2020-06-01T00:00:00Z'),
          _row('r2', updatedAt: '2020-01-01T00:00:00Z'),
        ];

        await repository.watchList(householdId: 'h1').toList();

        expect(
          await LocalRecipeDataSource(db).readRecipesWatermark('h1'),
          DateTime.utc(2020, 6, 1),
        );
      },
    );

    test('a query filters both the cached and the fresh emission', () async {
      await LocalRecipeDataSource(db).upsertMany(
        householdId: 'h1',
        rows: <Map<String, dynamic>>[
          _row('r1', title: 'Šargarepa torta'),
          _row('r2', title: 'Pita sa sirom'),
        ],
      );
      remote.changed = <Map<String, dynamic>>[];

      final emitted = await repository
          .watchList(householdId: 'h1', query: 'sargarepa')
          .toList();

      // Diacritic- and case-insensitive, the same normalized comparison the
      // old server-side ilike made (rule 6).
      for (final batch in emitted) {
        expect(batch.map((r) => r.id), <String>['r1']);
      }
    });
  });

  group('fetchDetail', () {
    test('online reads through the network and warms the cache', () async {
      remote.oneRow = _row('r1');

      final RecipeDetail detail = await repository.fetchDetail('r1');

      expect(detail.recipe.id, 'r1');
      expect((await LocalRecipeDataSource(db).readOne('r1'))?['id'], 'r1');
    });

    test('offline with a detail-shaped cache hit serves the cached copy', () async {
      await LocalRecipeDataSource(db).upsertMany(
        householdId: 'h1',
        rows: <Map<String, dynamic>>[_row('r1', title: 'Cached Pita')],
      );
      remote.nextFailure = const NetworkFailure();

      final RecipeDetail detail = await repository.fetchDetail('r1');

      expect(detail.recipe.title, 'Cached Pita');
      // A cached recipe carries no signed URL -- there is no network to ask.
      expect(detail.recipe.imageUrl, isNull);
    });

    test('offline with nothing cached for this id rethrows honestly', () async {
      remote.nextFailure = const NetworkFailure();

      await expectLater(
        repository.fetchDetail('unknown'),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}
