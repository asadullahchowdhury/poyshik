import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme/theme.dart';
import '../../core/dates/clock.dart';
import '../../core/dates/periods.dart';
import '../../core/dates/week_start_provider.dart';
import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../../core/widgets/amount_text.dart';
import '../../core/widgets/animated_amount.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/balance_text.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/poyshik_card.dart';
import '../../core/widgets/poyshik_logo.dart';
import '../../core/widgets/section_header.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../accounts/accounts_repository.dart';
import '../budgets/budget_repository.dart';
import '../budgets/budget_sheet.dart';
import '../transactions/add_transaction_sheet.dart';
import '../transactions/transaction_tile.dart';
import '../transactions/transactions_repository.dart';
import 'summary_repository.dart';

/// The month at a glance: what you spent, how that compares, what's safe to
/// spend, where it went, what you have, and what you logged last.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final now = ref.watch(clockProvider)();
    final views = ref.watch(transactionViewsProvider).value ?? const [];

    final sections = <Widget>[
      _HeroCard(now: now),
      _TodayWeek(now: now),
      const _AccountsStrip(),
      if (views.isEmpty)
        _FirstRun(title: l10n.homeFirstTitle, message: l10n.homeFirstMessage)
      else ...[
        _TopCategories(range: monthRange(now)),
        _Recent(views: views.take(5).toList()),
      ],
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            Space.lg,
            Space.screen,
            Space.huge,
          ),
          children: [
            Reveal(child: _Header(now: now)),
            const SizedBox(height: Space.xl),
            for (var i = 0; i < sections.length; i++) ...[
              if (i > 0) SizedBox(height: i == 1 ? Space.md : Space.xxl),
              Reveal(index: i + 1, child: sections[i]),
            ],
          ],
        ),
      ),
    );
  }
}

/// Logo, greeting in the serif voice, and today's date.
class _Header extends StatelessWidget {
  const _Header({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final greeting = now.hour < 12
        ? l10n.homeGreetingMorning
        : now.hour < 17
        ? l10n.homeGreetingAfternoon
        : l10n.homeGreetingEvening;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PoyshikLogo(size: 22),
        const SizedBox(height: Space.xl),
        Text('$greeting.', style: AppType.display.copyWith(color: c.ink)),
        const SizedBox(height: Space.xs),
        Text(
          DateFormat('EEEE, d MMMM').format(now),
          style: AppType.body.copyWith(color: c.inkMuted),
        ),
      ],
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
    final change = percentChange(
      spent,
      total(TransactionType.expense, lastSoFar),
    );
    final budget = ref.watch(overallBudgetProvider).value;
    final status = budget == null
        ? null
        : budgetStatus(budget: budget, spent: spent, now: now);

    return PoyshikCard(
      color: c.hero,
      bordered: false,
      elevated: true,
      radius: Radii.xl,
      padding: EdgeInsets.zero,
      onTap: () => unawaited(showBudgetSheet(context)),
      child: Stack(
        children: [
          // Brand moment: the leaf mark as a faint watermark.
          Positioned(
            right: -46,
            top: -26,
            child: PoyshikSymbol(
              height: 170,
              ink: c.onHero.withValues(alpha: 0.045),
              accent: c.accent.withValues(alpha: 0.09),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n
                      .homeSpentThisMonth(DateFormat.MMMM().format(now))
                      .toUpperCase(),
                  style: AppType.overline.copyWith(color: c.onHeroMuted),
                ),
                const SizedBox(height: Space.sm),
                AnimatedAmountText(
                  spent,
                  size: AmountSize.hero,
                  color: c.onHero,
                ),
                if (change != null) ...[
                  const SizedBox(height: Space.md),
                  _ComparePill(change: change),
                ],
                const SizedBox(height: Space.xl),
                if (status != null)
                  _BudgetBlock(status: status)
                else
                  _SetBudgetPrompt(label: l10n.budgetSetPrompt),
                const SizedBox(height: Space.xl),
                Container(height: 1, color: c.onHero.withValues(alpha: 0.12)),
                const SizedBox(height: Space.lg),
                Row(
                  children: [
                    Expanded(
                      child: _HeroFigure(
                        label: l10n.homeIncome,
                        child: AnimatedAmountText(income, color: c.onHero),
                      ),
                    ),
                    Expanded(
                      child: _HeroFigure(
                        label: l10n.homeNet,
                        child: AnimatedAmountText(
                          (income - spent).abs(),
                          showSign: true,
                          tone: (income - spent).isNegative
                              ? AmountTone.expense
                              : AmountTone.income,
                          color: c.onHero,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparePill extends StatelessWidget {
  const _ComparePill({required this.change});

  final int change;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final (icon, text, color) = change > 0
        ? (
            Icons.trending_up_rounded,
            l10n.homeMoreThanLastMonth(change),
            c.accent,
          )
        : change < 0
        ? (
            Icons.trending_down_rounded,
            l10n.homeLessThanLastMonth(-change),
            Color.lerp(c.income, Colors.white, 0.45)!,
          )
        : (
            Icons.trending_flat_rounded,
            l10n.homeSameAsLastMonth,
            c.onHeroMuted,
          );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.xs + 2,
      ),
      decoration: BoxDecoration(
        color: c.onHero.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: Space.xs + 2),
          Flexible(
            child: Text(text, style: AppType.caption.copyWith(color: c.onHero)),
          ),
        ],
      ),
    );
  }
}

class _SetBudgetPrompt extends StatelessWidget {
  const _SetBudgetPrompt({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
          child: Icon(Icons.add_rounded, size: 18, color: c.onAccent),
        ),
        const SizedBox(width: Space.md),
        Text(label, style: AppType.bodyStrong.copyWith(color: c.onHero)),
      ],
    );
  }
}

/// Budget progress and the daily "safe to spend" figure, on the hero.
class _BudgetBlock extends StatelessWidget {
  const _BudgetBlock({required this.status});

  final BudgetStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final bar = status.isOver
        ? c.warning
        : status.progress > 0.85
        ? Color.lerp(c.accent, c.expense, 0.5)!
        : c.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.budgetOf(MoneyFormat.format(status.budget)),
                style: AppType.label.copyWith(color: c.onHeroMuted),
              ),
            ),
            Text(
              '${(status.progress * 100).round()}%',
              style: AppType.label.copyWith(
                color: c.onHero,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.pill),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: status.progress.clamp(0, 1)),
            duration: Motion.reduced(context)
                ? Duration.zero
                : const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 8,
              backgroundColor: c.onHero.withValues(alpha: 0.14),
              color: bar,
            ),
          ),
        ),
        const SizedBox(height: Space.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: status.isOver
                  ? Text(
                      l10n.budgetOver(MoneyFormat.format(-status.remaining)),
                      style: AppType.bodyStrong.copyWith(color: c.accent),
                    )
                  : _HeroFigure(
                      label: l10n.budgetSafeToSpend,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          AnimatedAmountText(status.perDay, color: c.onHero),
                          Text(
                            l10n.budgetPerDay,
                            style: AppType.label.copyWith(color: c.onHeroMuted),
                          ),
                        ],
                      ),
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.md,
                vertical: Space.xs + 2,
              ),
              decoration: BoxDecoration(
                color: c.onHero.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Text(
                l10n.budgetDaysLeft(status.daysLeft),
                style: AppType.caption.copyWith(color: c.onHero),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroFigure extends StatelessWidget {
  const _HeroFigure({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppType.label.copyWith(color: context.colors.onHeroMuted),
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
    final c = context.colors;
    Money spent(DateRange r) =>
        ref
            .watch(
              periodTotalProvider((type: TransactionType.expense, range: r)),
            )
            .value ??
        Money.zero;

    Widget tile(IconData icon, String label, Money amount) => Expanded(
      child: PoyshikCard(
        padding: const EdgeInsets.all(Space.lg),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.surfaceRaised,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Icon(icon, size: 18, color: c.brand),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppType.caption.copyWith(color: c.inkMuted),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AnimatedAmountText(amount),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Row(
      children: [
        tile(Icons.wb_sunny_outlined, l10n.homeToday, spent(dayRange(now))),
        const SizedBox(width: Space.md),
        tile(
          Icons.date_range_rounded,
          l10n.homeThisWeek,
          spent(weekRange(now, startDay: ref.watch(weekStartProvider))),
        ),
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
        SectionHeader(
          l10n.homeAccounts,
          trailing: SectionAction(
            label: MoneyFormat.format(total),
            onTap: () => context.go(Routes.accounts),
          ),
        ),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: accounts.length,
            separatorBuilder: (_, _) => const SizedBox(width: Space.md),
            itemBuilder: (context, i) {
              final a = accounts[i];
              final color = PoyshikColors.categoryPalette[a.account.colorIndex];
              return SizedBox(
                width: 148,
                child: PoyshikCard(
                  onTap: () => context.go(Routes.accounts),
                  padding: const EdgeInsets.all(Space.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CategoryIcon(
                            icon: AppIcons.of(a.account.icon),
                            color: color,
                            size: 26,
                          ),
                          const SizedBox(width: Space.sm),
                          Expanded(
                            child: Text(
                              a.account.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.caption.copyWith(
                                color: c.inkMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: BalanceText(a.balance),
                      ),
                    ],
                  ),
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
    final reduced = Motion.reduced(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          l10n.homeTopCategories,
          trailing: SectionAction(
            label: l10n.tabInsights,
            onTap: () => context.go(Routes.insights),
          ),
        ),
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
                      size: 38,
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
                          const SizedBox(height: Space.sm),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(Radii.pill),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: max == 0 ? 0 : totals[i].total.minor / max,
                              ),
                              duration: reduced
                                  ? Duration.zero
                                  : Duration(milliseconds: 600 + i * 120),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, _) =>
                                  LinearProgressIndicator(
                                    value: v,
                                    minHeight: 6,
                                    backgroundColor: c.surfaceRaised,
                                    color:
                                        PoyshikColors.categoryPalette[totals[i]
                                            .category
                                            .colorIndex],
                                  ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          l10n.homeRecent,
          trailing: SectionAction(
            label: l10n.homeSeeAll,
            onTap: () => context.go(Routes.activity),
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
            width: 52,
            height: 52,
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
                Text(title, style: AppType.displaySmall.copyWith(color: c.ink)),
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
