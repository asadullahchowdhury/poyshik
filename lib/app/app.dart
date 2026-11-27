import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/money/currency_provider.dart';
import '../l10n/app_localizations.dart';
import 'intro.dart';
import 'router.dart';
import 'theme/theme.dart';
import 'theme/theme_mode_provider.dart';

/// Root widget: theme, localization and the router.
class PoyshikApp extends ConsumerWidget {
  const PoyshikApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Amounts are formatted through MoneyFormat's static currency, which
    // widgets don't depend on; re-keying the tree under the app makes every
    // amount redraw when the currency setting changes (a rare event).
    final currency = ref.watch(currencyProvider);
    return MaterialApp.router(
      // The intro sits outside the currency key, so it plays once per launch.
      builder: (context, child) => AppIntro(
        child: KeyedSubtree(key: ValueKey(currency.code), child: child!),
      ),
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      // Use material_ui's delegates (not flutter_localizations') so the
      // Material widgets from material_ui get matching localizations.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
