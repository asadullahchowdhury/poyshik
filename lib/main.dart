import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/db/app_database.dart';
import 'data/db/database_provider.dart';
import 'data/settings_repository.dart';
import 'features/onboarding/onboarding_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw behind the status and navigation bars; widgets pad themselves.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Open the database once and decide startup state before the first frame:
  // no theme flash, and no flicker between setup and Home.
  final db = AppDatabase();
  final needsSetup = await OnboardingService(db).needsOnboarding();
  final settings = await SettingsRepository(db).getAll();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        initialSettingsProvider.overrideWithValue(settings),
        startupNeedsOnboardingProvider.overrideWithValue(needsSetup),
      ],
      child: const PoyshikApp(),
    ),
  );
}
