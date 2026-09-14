// Phase 2 part 7 (D87, D88) -- the current-household cache: the first
// PER-USER table in a database that has so far only ever been per-household
// or global. The property that matters most is the one a singleton row
// could never have: a second user's id must never see the first user's row.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/db/app_database.dart';
import 'package:kitchen_table/core/db/sync_watermark.dart';
import 'package:kitchen_table/features/households/data/dto/household_dto.dart';
import 'package:kitchen_table/features/households/data/local_household_datasource.dart';
import 'package:kitchen_table/features/households/domain/household.dart';

Map<String, dynamic> _row({
  String id = 'h1',
  String name = 'Test household',
  String createdBy = 'u1',
  String? deletedAt,
}) => <String, dynamic>{
  'id': id,
  'name': name,
  'created_by': createdBy,
  'deleted_at': deletedAt,
};

void main() {
  late AppDatabase db;
  late LocalHouseholdDataSource local;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    local = LocalHouseholdDataSource(db);
  });

  tearDown(() => db.close());

  test('a miss reads as null', () async {
    expect(await local.readCurrent('u1'), isNull);
  });

  test('round trip decodes through the real production decoder', () async {
    await local.writeCurrent('u1', _row());

    final Map<String, dynamic>? cached = await local.readCurrent('u1');
    expect(cached, isNotNull);

    final Household household = householdFromWire(cached!);
    expect(household.id, 'h1');
    expect(household.name, 'Test household');
    expect(household.createdBy, 'u1');
    expect(household.deletedAt, isNull);
  });

  test('deletedAt survives the round trip', () async {
    await local.writeCurrent(
      'u1',
      _row(deletedAt: '2026-01-01T00:00:00Z'),
    );

    final Household household = householdFromWire(
      (await local.readCurrent('u1'))!,
    );
    expect(household.deletedAt, DateTime.parse('2026-01-01T00:00:00Z'));
  });

  test(
    'a second user\'s id reads null even with the first user\'s row present -- '
    'the wrong-user read the per-user key exists to make impossible',
    () async {
      await local.writeCurrent('u1', _row(id: 'h1'));

      expect(await local.readCurrent('u2'), isNull);
      expect((await local.readCurrent('u1'))!['id'], 'h1');
    },
  );

  test('writing again for the same user replaces, one row', () async {
    await local.writeCurrent('u1', _row(id: 'h1'));
    await local.writeCurrent('u1', _row(id: 'h2'));

    final List<CurrentHouseholdCacheData> rows =
        await db.select(db.currentHouseholdCache).get();
    expect(rows, hasLength(1));
    expect((await local.readCurrent('u1'))!['id'], 'h2');
  });

  test('clearCurrent removes only that user\'s row', () async {
    await local.writeCurrent('u1', _row(id: 'h1'));
    await local.writeCurrent('u2', _row(id: 'h2'));

    await local.clearCurrent('u1');

    expect(await local.readCurrent('u1'), isNull);
    expect((await local.readCurrent('u2'))!['id'], 'h2');
  });

  test('clearAll empties every user\'s row', () async {
    await local.writeCurrent('u1', _row(id: 'h1'));
    await local.writeCurrent('u2', _row(id: 'h2'));

    await local.clearAll();

    expect(await local.readCurrent('u1'), isNull);
    expect(await local.readCurrent('u2'), isNull);
  });

  test(
    'clearHouseholdCache drops the current-household row, keeps the unit '
    'catalog and the global watermark (D70\'s split still holds)',
    () async {
      final SyncWatermarkStore watermarks = SyncWatermarkStore(db);
      await local.writeCurrent('u1', _row());
      await db
          .into(db.unitCatalogCache)
          .insertOnConflictUpdate(
            UnitCatalogCacheCompanion.insert(
              id: unitCatalogCacheKey,
              fetchedAt: DateTime.now().toUtc(),
              data: '{}',
            ),
          );
      await watermarks.advance(
        entity: 'ingredient_names',
        scope: globalSyncScope,
        syncedAt: DateTime.utc(2026, 1, 1),
      );

      await db.clearHouseholdCache();

      expect(await local.readCurrent('u1'), isNull);
      final UnitCatalogCacheData? unitRow = await (db.select(
        db.unitCatalogCache,
      )..where((UnitCatalogCache t) => t.id.equals(unitCatalogCacheKey)))
          .getSingleOrNull();
      expect(unitRow, isNotNull);
      expect(
        await watermarks.read(
          entity: 'ingredient_names',
          scope: globalSyncScope,
        ),
        DateTime.utc(2026, 1, 1),
      );
    },
  );
}
