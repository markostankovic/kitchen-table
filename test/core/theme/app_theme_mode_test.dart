// Phase 7 part 9b (D128): Light by default, Dark only when stored.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/db/app_database.dart';
import 'package:kitchen_table/core/db/device_preferences.dart';
import 'package:kitchen_table/core/theme/app_theme_mode.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('defaults to Light when nothing is stored', () async {
    expect(await container.read(appThemeModeProvider.future), ThemeMode.light);
  });

  test('an unknown stored value reads as Light', () async {
    await DevicePreferenceStore(db).write(themeModeKey, 'system');
    expect(await container.read(appThemeModeProvider.future), ThemeMode.light);
  });

  test('set(dark) writes the store and updates the state', () async {
    await container.read(appThemeModeProvider.future);
    await container.read(appThemeModeProvider.notifier).set(ThemeMode.dark);

    expect(container.read(appThemeModeProvider).value, ThemeMode.dark);
    expect(await DevicePreferenceStore(db).read(themeModeKey), 'dark');
  });

  test('a stored Dark is what the next launch reads', () async {
    await DevicePreferenceStore(db).write(themeModeKey, 'dark');
    expect(await container.read(appThemeModeProvider.future), ThemeMode.dark);
  });
}
