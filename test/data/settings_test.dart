import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:poyshik/app/theme/theme_mode_provider.dart';
import 'package:poyshik/core/dates/week_start_provider.dart';
import 'package:poyshik/data/db/app_database.dart';
import 'package:poyshik/data/db/database_provider.dart';
import 'package:poyshik/data/settings_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  ProviderContainer containerWith(Map<String, String> initial) =>
      ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          initialSettingsProvider.overrideWithValue(initial),
        ],
      );

  test('defaults: follow system theme, Saturday week start', () {
    final c = containerWith(const {});
    addTearDown(c.dispose);
    expect(c.read(themeModeProvider), ThemeMode.system);
    expect(c.read(weekStartProvider), DateTime.saturday);
  });

  test('changes are saved and restored on the next start', () async {
    final first = containerWith(const {});
    first.read(themeModeProvider.notifier).set(ThemeMode.dark);
    first.read(weekStartProvider.notifier).set(DateTime.monday);
    await pumpEventQueue();
    first.dispose();

    // Simulate a restart: main.dart reads all settings before the first frame.
    final saved = await SettingsRepository(db).getAll();
    final second = containerWith(saved);
    addTearDown(second.dispose);
    expect(second.read(themeModeProvider), ThemeMode.dark);
    expect(second.read(weekStartProvider), DateTime.monday);
  });

  test('bad saved values fall back to defaults', () {
    final c = containerWith(const {
      SettingKeys.themeMode: 'purple',
      SettingKeys.weekStart: '42',
    });
    addTearDown(c.dispose);
    expect(c.read(themeModeProvider), ThemeMode.system);
    expect(c.read(weekStartProvider), DateTime.saturday);
  });
}
