// Phase 7 part 9b (D128): the theme choice lives in `device_preferences`, a
// table that is not a cache -- it must survive both a cache schema bump and
// the sign-out wipe.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/db/app_database.dart';
import 'package:kitchen_table/core/db/device_preferences.dart';

/// [AppDatabase] reporting [version] instead of its own, so a test can
/// simulate the next cache bump over a file the real schema wrote.
class _FutureDatabase extends AppDatabase {
  _FutureDatabase(super.executor, this.version);

  final int version;

  @override
  int get schemaVersion => version;
}

void main() {
  group('DevicePreferenceStore', () {
    late AppDatabase db;
    late DevicePreferenceStore store;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      store = DevicePreferenceStore(db);
    });

    tearDown(() => db.close());

    test('an unwritten key reads as null', () async {
      expect(await store.read(themeModeKey), isNull);
    });

    test('round-trips, and a second write replaces the first', () async {
      await store.write(themeModeKey, 'dark');
      expect(await store.read(themeModeKey), 'dark');

      await store.write(themeModeKey, 'light');
      expect(await store.read(themeModeKey), 'light');
    });

    test('clearHouseholdCache leaves it alone', () async {
      await store.write(themeModeKey, 'dark');

      await db.clearHouseholdCache();

      expect(await store.read(themeModeKey), 'dark');
    });
  });

  group('migration', () {
    late Directory dir;
    late File file;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('kt_db_');
      file = File('${dir.path}/cache.sqlite');
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('a v7 file upgrades to v8 with the table created', () async {
      // A v7 database: a cache table with a row, and no device_preferences.
      final AppDatabase v7 = _FutureDatabase(NativeDatabase(file), 7);
      await v7.customStatement('SELECT 1');
      await v7.customStatement('DROP TABLE device_preferences');
      await v7
          .into(v7.unitCatalogCache)
          .insert(
            UnitCatalogCacheCompanion.insert(
              id: unitCatalogCacheKey,
              fetchedAt: DateTime.utc(2026),
              data: '{}',
            ),
          );
      await v7.close();

      final AppDatabase v8 = AppDatabase(NativeDatabase(file));
      final DevicePreferenceStore store = DevicePreferenceStore(v8);
      await store.write(themeModeKey, 'dark');
      expect(await store.read(themeModeKey), 'dark');
      // The caches are still dropped and refetched, as before (D71).
      expect(await v8.select(v8.unitCatalogCache).get(), isEmpty);
      await v8.close();
    });

    test('a later cache bump keeps the stored theme', () async {
      final AppDatabase v8 = AppDatabase(NativeDatabase(file));
      await DevicePreferenceStore(v8).write(themeModeKey, 'dark');
      await v8
          .into(v8.unitCatalogCache)
          .insert(
            UnitCatalogCacheCompanion.insert(
              id: unitCatalogCacheKey,
              fetchedAt: DateTime.utc(2026),
              data: '{}',
            ),
          );
      await v8.close();

      final AppDatabase v9 = _FutureDatabase(NativeDatabase(file), 9);
      expect(await DevicePreferenceStore(v9).read(themeModeKey), 'dark');
      expect(await v9.select(v9.unitCatalogCache).get(), isEmpty);
      await v9.close();
    });
  });
}
