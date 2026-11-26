import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../../core/dates/periods.dart';
import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/poyshik_card.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/app_localizations.dart';
import 'activity_filter_bar.dart';
import 'add_transaction_sheet.dart';
import 'day_groups.dart';
import 'transaction_tile.dart';
import 'transactions_repository.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final hasAny =
        (ref.watch(transactionViewsProvider).value ?? const []).isNotEmpty;
    final filter = ref.watch(activityFilterProvider);
    final views = ref.watch(filteredViewsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabActivity)),
      body: Column(
        children: [
          if (hasAny || filter.isActive) const ActivityFilterBar(),
          Expanded(
            child: views.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(error: e),
              data: (list) {
                if (list.isEmpty) {
                  return filter.isActive
                      ? EmptyState(
                          icon: Icons.search_off_rounded,
                          title: l10n.activityNoMatches,
                          message: l10n.activityNoMatchesHint,
                        )
                      : EmptyState(
                          icon: Icons.receipt_long_rounded,
                          title: l10n.activityEmptyTitle,
                          message: l10n.activityEmptyMessage,
                        );
                }
                final groups = groupByDay(list);
                final spent = groups.fold(
                  Money.zero,
                  (sum, g) => sum + g.spent,
                );
                return ListView.builder(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    Space.screen,
                    Space.xs,
                    Space.screen,
                    Space.huge,
                  ),
                  itemCount: groups.length + (filter.isActive ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (filter.isActive && i == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Space.xs,
                          Space.sm,
                          Space.xs,
                          0,
                        ),
                        child: Text(
                          l10n.activityResults(
                            list.length,
                            MoneyFormat.format(spent),
                          ),
                          style: AppType.label.copyWith(color: c.inkMuted),
                        ),
                      );
                    }
                    final group = groups[i - (filter.isActive ? 1 : 0)];
                    // Only the first screenful staggers in; later groups
                    // appear immediately while scrolling.
                    return i < 6
                        ? Reveal(
                            key: ValueKey(group.day),
                            index: i,
                            child: _DaySection(group: group),
                          )
                        : _DaySection(group: group);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySection extends ConsumerWidget {
  const _DaySection({required this.group});

  final DayGroup group;

  String _dayLabel(AppLocalizations l10n) {
    final days = calendarDaysBetween(group.day, DateTime.now());
    if (days == 0) return l10n.txToday;
    if (days == 1) return l10n.txYesterday;
    final sameYear = group.day.year == DateTime.now().year;
    return (sameYear ? DateFormat('EEE, d MMM') : DateFormat('EEE, d MMM y'))
        .format(group.day);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TransactionView v,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(transactionsRepositoryProvider);
    unawaited(HapticFeedback.mediumImpact());
    final removed = await repo.delete(v.tx.id);
    if (removed == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.txDeleted),
          action: SnackBarAction(
            label: l10n.txUndo,
            onPressed: () => unawaited(repo.restore(removed)),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final totals = [
      if (group.spent.isPositive)
        l10n.activitySpent(MoneyFormat.format(group.spent)),
      if (group.earned.isPositive)
        l10n.activityEarned(MoneyFormat.format(group.earned)),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.xs,
            Space.xl,
            Space.xs,
            Space.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _dayLabel(l10n),
                  style: AppType.label.copyWith(
                    color: c.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(totals, style: AppType.caption.copyWith(color: c.inkMuted)),
            ],
          ),
        ),
        PoyshikCard(
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          child: Column(
            children: [
              for (var i = 0; i < group.items.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.only(left: Space.lg + 42 + Space.md),
                    child: Divider(),
                  ),
                Dismissible(
                  key: ValueKey(group.items[i].tx.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: c.expense,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: Space.xl),
                    child: Icon(Icons.delete_outline_rounded, color: c.onInk),
                  ),
                  onDismissed: (_) =>
                      unawaited(_delete(context, ref, group.items[i])),
                  child: TransactionTile(
                    view: group.items[i],
                    onTap: () => unawaited(
                      showAddTransactionSheet(
                        context,
                        existing: group.items[i].tx,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
