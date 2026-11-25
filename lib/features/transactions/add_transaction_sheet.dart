import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../../l10n/app_localizations.dart';

/// Opens the quick-entry sheet over whatever tab is showing.
/// Placeholder until the real entry flow is built in Phase 1.
Future<void> showAddTransactionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const _AddTransactionSheet(),
  );
}

class _AddTransactionSheet extends StatelessWidget {
  const _AddTransactionSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        0,
        Space.screen,
        Space.huge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.addTransaction,
            style: AppType.titleLarge.copyWith(color: c.ink),
          ),
          const SizedBox(height: Space.sm),
          Text(
            l10n.addSheetPlaceholder,
            style: AppType.body.copyWith(color: c.inkMuted),
          ),
        ],
      ),
    );
  }
}
