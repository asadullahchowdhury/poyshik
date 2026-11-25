import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../features/dev/component_gallery_screen.dart';
import '../l10n/app_localizations.dart';
import 'theme/theme.dart';
import 'theme/theme_mode_provider.dart';

/// Root widget. The router replaces the temporary gallery home in step 0.4.
class PoyshikApp extends ConsumerWidget {
  const PoyshikApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
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
      home: const ComponentGalleryScreen(),
    );
  }
}
