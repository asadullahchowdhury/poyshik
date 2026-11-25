import 'package:material_ui/material_ui.dart';

import '../../core/widgets/empty_state.dart';
import '../../l10n/app_localizations.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabActivity)),
      body: EmptyState(
        icon: Icons.receipt_long_rounded,
        title: l10n.activityEmptyTitle,
        message: l10n.activityEmptyMessage,
      ),
    );
  }
}
