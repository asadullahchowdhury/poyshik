import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/accounts/accounts_screen.dart';
import '../features/categories/categories_screen.dart';
import '../features/dev/component_gallery_screen.dart';
import '../features/dev/database_debug_screen.dart';
import '../features/home/home_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/onboarding_service.dart';
import '../features/settings/backup_screen.dart';
import '../features/settings/more_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/transactions/activity_screen.dart';
import 'shell/app_shell.dart';

/// Route paths, so screens never hard-code strings.
abstract final class Routes {
  static const welcome = '/welcome';
  static const home = '/home';
  static const activity = '/activity';
  static const insights = '/insights';
  static const more = '/more';
  static const accounts = '/more/accounts';
  static const categories = '/more/categories';
  static const settings = '/more/settings';
  static const backup = '/more/backup';
  static const gallery = '/more/gallery';
  static const database = '/more/database';
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: Routes.home,
    // First launch goes through setup; afterwards /welcome is unreachable.
    redirect: (context, state) {
      final needsSetup = ref.read(onboardingProvider);
      final atWelcome = state.matchedLocation == Routes.welcome;
      if (needsSetup && !atWelcome) return Routes.welcome;
      if (!needsSetup && atWelcome) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.welcome,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.activity,
                builder: (context, state) => const ActivityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.insights,
                builder: (context, state) => const InsightsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.more,
                builder: (context, state) => const MoreScreen(),
                routes: [
                  GoRoute(
                    path: 'accounts',
                    builder: (context, state) => const AccountsScreen(),
                  ),
                  GoRoute(
                    path: 'categories',
                    builder: (context, state) => const CategoriesScreen(),
                  ),
                  GoRoute(
                    path: 'backup',
                    builder: (context, state) => const BackupScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                  GoRoute(
                    path: 'gallery',
                    builder: (context, state) => const ComponentGalleryScreen(),
                  ),
                  GoRoute(
                    path: 'database',
                    builder: (context, state) => const DatabaseDebugScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
