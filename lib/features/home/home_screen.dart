import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme/theme.dart';
import '../../core/dates/clock.dart';
import '../../core/dates/periods.dart';
import '../../core/money/money.dart';
import '../../core/widgets/amount_text.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/balance_text.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/poyshik_card.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../accounts/accounts_repository.dart';
import '../transactions/add_transaction_sheet.dart';
import '../transactions/transaction_tile.dart';
import '../transactions/transactions_repository.dart';
import 'summary_repository.dart';

/// The month at a glance: what you spent, how that compares, where it went,
/// what you have, and what you logged last.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final now = ref.watch(clockProvider)();
    final views = ref.watch(transactionViewsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(DateFormat('MMMM y').format(now))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.screen,
          Space.sm,
          Space.screen,
          Space.huge,
        ),
        children: [
          _HeroCard(now: now),
          const SizedBox(height: Space.md),
          _TodayWeek(now: now),
          const SizedBox(height: Space.xxl),
          const _AccountsStrip(),
          if (views.isEmpty) ...[
            const SizedBox(height: Space.xxl),
            _FirstRun(
              title: l10n.homeFirstTitle,
              message: l10n.homeFirstMessage,
            ),
          ] else ...[
            const SizedBox(height: Space.xxl),
            _TopCategories(range: monthRange(now)),
            const SizedBox(height: Space.xxl),
            _Recent(views: views.take(5).toList()),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: Space.xs, bottom: Space.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: AppType.overline.copyWith(color: context.colors.inkMuted),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final month = monthRange(now);
    // Last month up to the same moment, for a fair "by today" comparison.
    final lastSoFar = DateRange(
      previousMonthRange(now).start,
      sameDayLastMonth(now),
    );
    Money total(TransactionType type, DateRange r) =>
        ref.watch(periodTotalProvider((type: type, range: r))).value ??
        Money.zero;

    final spent = total(TransactionType.expense, month);
    final income = total(TransactionType.income, month);
    final lastSpent = total(TransactionType.expense, lastSoFar);
    final change = percentChange(spent, lastSpent);
    final net = income - spent;

    String? compare;
    Color compareColor = c.inkMuted;
    if (change != null) {
      if (change > 0) {
        compare = l10n.homeMoreThanLastMonth(change);
        compareColor = c.warning;
      } else if (change < 0) {
        compare = l10n.homeLessThanLastMonth(-change);
        compareColor = c.income;
      } else {
        compare = l10n.homeSameAsLastMonth;
      }
    }

    return PoyshikCard(
      padding: const EdgeInsets.all(Space.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n
                .homeSpentThisMonth(DateFormat.MMMM().format(now))
                .toUpperCase(),
            style: AppType.overline.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: Space.sm),
          AmountText(spent, size: AmountSize.hero),
          if (compare != null) ...[
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Icon(
                  change! > 0
                      ? Icons.trending_up_rounded
                      : change < 0
                      ? Icons.trending_down_rounded
                      : Icons.trending_flat_rounded,
                  size: 16,
                  color: compareColor,
                ),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: Text(
                    compare,
                    style: AppType.label.copyWith(color: compareColor),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: Space.xl),
          const Divider(),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              Expanded(
                child: _Figure(
                  label: l10n.homeIncome,
                  child: AmountText(income, tone: AmountTone.income),
                ),
              ),
              Expanded(
                child: _Figure(label: l10n.homeNet, child: BalanceText(net)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppType.label.copyWith(color: context.colors.inkMuted),
        ),
        const SizedBox(height: Space.xxs),
        child,
      ],
    );
  }
}

class _TodayWeek extends ConsumerWidget {
  const _TodayWeek({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    Money spent(DateRange r) =>
        ref
            .watch(
              periodTotalProvider((type: TransactionType.expense, range: r)),
            )
            .value ??
        Money.zero;

    Widget tile(String label, Money amount) => Expanded(
      child: PoyshikCard(
        padding: const EdgeInsets.all(Space.lg),
        child: _Figure(label: label, child: AmountText(amount)),
      ),
    );

    return Row(
      children: [
        tile(l10n.homeToday, spent(dayRange(now))),
        const SizedBox(width: Space.md),
        tile(l10n.homeThisWeek, spent(weekRange(now))),
      ],
    );
  }
}

class _AccountsStrip extends ConsumerWidget {
  const _AccountsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final accounts = ref.watch(activeAccountsProvider).value ?? const [];
    final total = ref.watch(totalBalanceProvider).value ?? Money.zero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          l10n.homeAccounts,
          trailing: BalanceText(total, size: AmountSize.small),
        ),
        SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: accounts.length,
            separatorBuilder: (_, _) => const SizedBox(width: Space.md),
            itemBuilder: (context, i) {
              final a = accounts[i];
              return PoyshikCard(
                onTap: () => context.go(Routes.accounts),
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  Space.md,
                  Space.lg,
                  Space.md,
                ),
                child: Row(
                  children: [
                    CategoryIcon(
                      icon: AppIcons.of(a.account.icon),
                      color:
                          PoyshikColors.categoryPalette[a.account.colorIndex],
                      size: 38,
                    ),
                    const SizedBox(width: Space.md),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.account.name,
                          style: AppType.caption.copyWith(color: c.inkMuted),
                        ),
                        BalanceText(a.balance, size: AmountSize.small),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TopCategories extends ConsumerWidget {
  const _TopCategories({required this.range});

  final DateRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final totals = ref.watch(topCategoriesProvider(range)).value ?? const [];
    if (totals.isEmpty) return const SizedBox.shrink();
    final max = totals.first.total.minor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(l10n.homeTopCategories),
        PoyshikCard(
          child: Column(
            children: [
              for (var i = 0; i < totals.length; i++) ...[
                if (i > 0) const SizedBox(height: Space.lg),
                Row(
                  children: [
                    CategoryIcon(
                      icon: AppIcons.of(totals[i].category.icon),
                      color: PoyshikColors
                          .categoryPalette[totals[i].category.colorIndex],
                      size: 36,
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  totals[i].category.name,
                                  style: AppType.label.copyWith(
                                    color: c.ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              AmountText(
                                totals[i].total,
                                size: AmountSize.small,
                              ),
                            ],
                          ),
                          const SizedBox(height: Space.xs + 2),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(Radii.pill),
                            child: LinearProgressIndicator(
                              value: max == 0 ? 0 : totals[i].total.minor / max,
                              minHeight: 6,
                              backgroundColor: c.surfaceRaised,
                              color:
                                  PoyshikColors.categoryPalette[totals[i]
                                      .category
                                      .colorIndex],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Recent extends StatelessWidget {
  const _Recent({required this.views});

  final List<TransactionView> views;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          l10n.homeRecent,
          trailing: GestureDetector(
            onTap: () => context.go(Routes.activity),
            child: Text(
              l10n.homeSeeAll,
              style: AppType.label.copyWith(
                color: c.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        PoyshikCard(
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          child: Column(
            children: [
              for (var i = 0; i < views.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.only(left: Space.lg + 42 + Space.md),
                    child: Divider(),
                  ),
                TransactionTile(
                  view: views[i],
                  onTap: () => unawaited(
                    showAddTransactionSheet(context, existing: views[i].tx),
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

class _FirstRun extends StatelessWidget {
  const _FirstRun({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PoyshikCard(
      onTap: () => unawaited(showAddTransactionSheet(context)),
      padding: const EdgeInsets.all(Space.xxl),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Icon(Icons.add_rounded, color: c.onAccent, size: 28),
          ),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppType.titleMedium.copyWith(color: c.ink)),
                const SizedBox(height: Space.xs),
                Text(message, style: AppType.label.copyWith(color: c.inkMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
