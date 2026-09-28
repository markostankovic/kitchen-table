/// The app's Light or Dark choice (D128) -- device-local, stored in
/// [DevicePreferences] rather than on `profiles`, unlike the language (D77).
///
/// Two options, Light by default. There is no System option: the app does
/// not follow the phone's own setting.
///
/// `core/` because the app root needs it, on `app_locale.dart`'s precedent.
/// `main.dart` awaits [appThemeModeProvider]'s future before `runApp`, so a
/// Dark user never sees a Light first frame.
library;

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../db/app_database.dart';
import '../db/device_preferences.dart';

part 'app_theme_mode.g.dart';

@Riverpod(keepAlive: true)
class AppThemeMode extends _$AppThemeMode {
  @override
  Future<ThemeMode> build() async {
    final String? stored = await DevicePreferenceStore(
      ref.watch(appDatabaseProvider),
    ).read(themeModeKey);
    return stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  /// Writes [mode], then repaints. Anything other than [ThemeMode.dark] is
  /// stored and shown as Light -- there is no System option.
  Future<void> set(ThemeMode mode) async {
    final ThemeMode resolved =
        mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
    await DevicePreferenceStore(ref.read(appDatabaseProvider)).write(
      themeModeKey,
      resolved == ThemeMode.dark ? 'dark' : 'light',
    );
    state = AsyncData<ThemeMode>(resolved);
  }
}
