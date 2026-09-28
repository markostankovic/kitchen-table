/// Reads and writes a [DevicePreferences] row -- choices that belong to this
/// phone, not to the user or the household (D128), so they live here rather
/// than on `profiles`.
///
/// Every method goes through [cacheOrElse]/[cacheWrite] (D69), on
/// `sync_watermark.dart`'s pattern: a read that fails is "no preference
/// stored", and the caller's default applies. A failed write costs the
/// choice surviving a restart and nothing else. Nothing here ever throws.
library;

import 'app_database.dart';
import 'cache_guard.dart';

/// The key the app's Light/Dark choice is stored under (`light` or `dark`).
const String themeModeKey = 'theme_mode';

class DevicePreferenceStore {
  const DevicePreferenceStore(this._db);

  final AppDatabase _db;

  /// The stored value for [key], or null if none was ever written (or the
  /// read itself failed).
  Future<String?> read(String key) =>
      cacheOrElse('device_preferences read ($key)', () async {
        final DevicePreference? row = await (_db.select(_db.devicePreferences)
              ..where((DevicePreferences t) => t.key.equals(key)))
            .getSingleOrNull();
        return row?.value;
      }, null);

  Future<void> write(String key, String value) => cacheWrite(
        'device_preferences write ($key)',
        () => _db
            .into(_db.devicePreferences)
            .insertOnConflictUpdate(
              DevicePreferencesCompanion.insert(key: key, value: value),
            ),
      );
}
