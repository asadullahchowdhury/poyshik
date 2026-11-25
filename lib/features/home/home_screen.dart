import 'package:material_ui/material_ui.dart';

import '../../core/widgets/empty_state.dart';
import '../../l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: EmptyState(
        icon: Icons.donut_large_rounded,
        title: l10n.homeEmptyTitle,
        message: l10n.homeEmptyMessage,
      ),
    );
  }
}
