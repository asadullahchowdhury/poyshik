import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/db/app_database.dart';
import 'data/db/database_provider.dart';
import 'data/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw behind the status and navigation bars; widgets pad themselves.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Open the database once and read saved settings before the first frame,
  // so the theme doesn't flash.
  final db = AppDatabase();
  final settings = await SettingsRepository(db).getAll();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        initialSettingsProvider.overrideWithValue(settings),
      ],
      child: const PoyshikApp(),
    ),
  );
}
