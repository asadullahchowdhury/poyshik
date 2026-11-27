import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/app_database.dart';
import 'db/database_provider.dart';

/// Keys for [SettingsRepository]. Keep them stable: they live in user data.
abstract final class SettingKeys {
  static const lastAccountId = 'last_account_id';
  static const themeMode = 'theme_mode';
  static const weekStart = 'week_start';
  static const lastBackupAt = 'last_backup_at';
  static const onboardingDone = 'onboarding_done';
  static const currency = 'currency';
  static const language = 'language';
}

/// Small key-value store in the database, so backups include settings.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Future<String?> get(String key) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<Map<String, String>> getAll() async => {
    for (final s in await _db.select(_db.appSettings).get()) s.key: s.value,
  };

  Future<void> set(String key, String value) => _db
      .into(_db.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: key, value: value),
      );
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

/// Settings read once at startup (see main.dart), so the first frame already
/// has the right theme. Empty in tests.
final initialSettingsProvider = Provider<Map<String, String>>(
  (ref) => const {},
);
