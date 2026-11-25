import 'package:material_ui/material_ui.dart';

import '../../core/widgets/empty_state.dart';
import '../../l10n/app_localizations.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabInsights)),
      body: EmptyState(
        icon: Icons.insights_rounded,
        title: l10n.insightsEmptyTitle,
        message: l10n.insightsEmptyMessage,
      ),
    );
  }
}
