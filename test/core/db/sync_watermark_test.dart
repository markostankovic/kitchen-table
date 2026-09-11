// Phase 2 part 6a -- D71's own warning made concrete: the watermark must
// advance to the max(updated_at) of rows a fetch actually received, never
// to DateTime.now(), because the server's clock and the phone's differ and
// a local clock silently drops rows written in the gap.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/db/app_database.dart';
import 'package:kitchen_table/core/db/sync_watermark.dart';

void main() {
  late AppDatabase db;
  late SyncWatermarkStore store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = SyncWatermarkStore(db);
  });

  tearDown(() => db.close());

  test('no watermark reads as null -- fetch everything', () async {
    expect(
      await store.read(entity: 'recipes', scope: 'household-1'),
      isNull,
    );
  });

  test('advances to exactly the timestamp given, not to now()', () async {
    // Deliberately in the past relative to the test's own wall clock --
    // proves nothing here ever substitutes DateTime.now().
    final DateTime serverTime = DateTime.utc(2020, 1, 1);

    await store.advance(
      entity: 'recipes',
      scope: 'household-1',
      syncedAt: serverTime,
    );

    final DateTime? read = await store.read(
      entity: 'recipes',
      scope: 'household-1',
    );
    expect(read, serverTime);
  });

  test('entity and scope are independent watermarks', () async {
    await store.advance(
      entity: 'recipes',
      scope: 'household-1',
      syncedAt: DateTime.utc(2026, 1, 1),
    );
    await store.advance(
      entity: 'ingredient_names',
      scope: globalSyncScope,
      syncedAt: DateTime.utc(2026, 6, 1),
    );

    // A second household's recipes watermark is untouched by the first's.
    expect(
      await store.read(entity: 'recipes', scope: 'household-2'),
      isNull,
    );
    // The global entity is unaffected by a household-scoped one advancing.
    expect(
      await store.read(entity: 'ingredient_names', scope: globalSyncScope),
      DateTime.utc(2026, 6, 1),
    );
    expect(
      await store.read(entity: 'recipes', scope: 'household-1'),
      DateTime.utc(2026, 1, 1),
    );
  });

  test('advancing again replaces the previous watermark', () async {
    await store.advance(
      entity: 'recipes',
      scope: 'household-1',
      syncedAt: DateTime.utc(2026, 1, 1),
    );
    await store.advance(
      entity: 'recipes',
      scope: 'household-1',
      syncedAt: DateTime.utc(2026, 2, 1),
    );

    expect(
      await store.read(entity: 'recipes', scope: 'household-1'),
      DateTime.utc(2026, 2, 1),
    );
  });

  test(
    'clearHouseholdCache drops a household watermark, keeps the global one',
    () async {
      await store.advance(
        entity: 'recipes',
        scope: 'household-1',
        syncedAt: DateTime.utc(2026, 1, 1),
      );
      await store.advance(
        entity: 'ingredient_names',
        scope: globalSyncScope,
        syncedAt: DateTime.utc(2026, 1, 1),
      );

      await db.clearHouseholdCache();

      expect(
        await store.read(entity: 'recipes', scope: 'household-1'),
        isNull,
      );
      expect(
        await store.read(entity: 'ingredient_names', scope: globalSyncScope),
        DateTime.utc(2026, 1, 1),
      );
    },
  );
}
