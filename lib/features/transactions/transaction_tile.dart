import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../../core/money/money.dart';
import '../../core/widgets/amount_text.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/category_icon.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../categories/category_label.dart';
import 'transactions_repository.dart';

/// One transaction row: category icon, title, account · time · note, amount.
/// Expenses read in ink with "−" (calm, not alarming), income in sage with
/// "+", transfers in slate without a sign.
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.view, this.onTap});

  final TransactionView view;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tx = view.tx;
    final isTransfer = tx.type == TransactionType.transfer;
    final category = view.category;

    final title = isTransfer
        ? '${view.account.name} → ${view.toAccount?.name ?? '?'}'
        : category?.label(AppLocalizations.of(context)) ?? '?';
    final icon = isTransfer
        ? Icons.swap_horiz_rounded
        : AppIcons.of(category?.icon ?? 'more');
    final color = isTransfer
        ? c.transfer
        : PoyshikColors.categoryPalette[category?.colorIndex ?? 11];
    final time = DateFormat.jm().format(tx.occurredAt);
    final subtitle = [
      if (!isTransfer) view.account.name,
      time,
      if (tx.note != null) tx.note!,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.md,
        ),
        child: Row(
          children: [
            CategoryIcon(icon: icon, color: color, size: 42),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.bodyStrong.copyWith(color: c.ink),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.caption.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.md),
            AmountText(
              Money(tx.amount),
              size: AmountSize.small,
              tone: switch (tx.type) {
                TransactionType.expense => AmountTone.expense,
                TransactionType.income => AmountTone.income,
                TransactionType.transfer => AmountTone.transfer,
              },
              showSign: !isTransfer,
              color: tx.type == TransactionType.expense ? c.ink : null,
            ),
          ],
        ),
      ),
    );
  }
}
