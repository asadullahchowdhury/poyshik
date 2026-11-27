import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

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
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/poyshik_card.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../categories/category_label.dart';
import '../home/summary_repository.dart';
import 'insights_logic.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final now = ref.watch(clockProvider)();
    final period = ref.watch(insightsPeriodProvider);
    final weekStart = ref.watch(weekStartProvider);
    final range = periodRange(period, now, weekStart: weekStart);
    final previous = periodRange(
      (kind: period.kind, offset: period.offset - 1),
      now,
      weekStart: weekStart,
    );

    Money total(TransactionType t, DateRange r) =>
        ref.watch(periodTotalProvider((type: t, range: r))).value ?? Money.zero;
    final spent = total(TransactionType.expense, range);
    final income = total(TransactionType.income, range);
    final previousSpent = total(TransactionType.expense, previous);
    final categories =
        ref.watch(categoryTotalsProvider(range)).value ?? const [];
    final daily = dailyTotals(
      range,
      ref.watch(expenseEntriesProvider(range)).value ?? const [],
    );
    final insights = buildInsights(
      range: range,
      now: now,
      spent: spent,
      previousSpent: previousSpent,
      categories: categories,
      daily: daily,
    );
    final isEmpty = !spent.isPositive && !income.isPositive;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabInsights)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.screen,
          Space.sm,
          Space.screen,
          Space.huge,
        ),
        children: [
          _PeriodBar(period: period, range: range),
          const SizedBox(height: Space.lg),
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Space.huge),
              child: EmptyState(
                icon: Icons.insights_rounded,
                title: l10n.insightsEmptyTitle,
                message: l10n.insightsEmptyPeriod,
              ),
            )
          else ...[
            // Keyed by period so cards re-reveal when switching periods.
            for (final (i, card) in [
              _SummaryCard(spent: spent, income: income),
              if (insights.isNotEmpty)
                _HighlightsCard(insights: insights, kind: period.kind),
              _DailyBarsCard(daily: daily, kind: period.kind, now: now),
              if (categories.isNotEmpty)
                _CategoryDonutCard(categories: categories, spent: spent),
            ].indexed) ...[
              if (i > 0) const SizedBox(height: Space.md),
              Reveal(
                key: ValueKey('${period.kind}${period.offset}-$i'),
                index: i,
                child: card,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PeriodBar extends ConsumerWidget {
  const _PeriodBar({required this.period, required this.range});

  final InsightsPeriod period;
  final DateRange range;

  String _label() {
    if (period.kind == PeriodKind.month) {
      return DateFormat('MMMM y').format(range.start);
    }
    final last = range.end.subtract(const Duration(days: 1));
    final sameMonth = range.start.month == last.month;
    final start = DateFormat(sameMonth ? 'd' : 'd MMM').format(range.start);
    return '$start – ${DateFormat('d MMM').format(last)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final notifier = ref.read(insightsPeriodProvider.notifier);
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<PeriodKind>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: PeriodKind.week,
                label: Text(l10n.insightsWeek),
              ),
              ButtonSegment(
                value: PeriodKind.month,
                label: Text(l10n.insightsMonth),
              ),
            ],
            selected: {period.kind},
            onSelectionChanged: (s) => notifier.setKind(s.first),
          ),
        ),
        const SizedBox(height: Space.md),
        Row(
          children: [
            IconButton(
              onPressed: notifier.previous,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: Motion.base,
                child: Text(
                  _label(),
                  key: ValueKey(_label()),
                  textAlign: TextAlign.center,
                  style: AppType.displaySmall.copyWith(color: c.ink),
                ),
              ),
            ),
            IconButton(
              onPressed: period.offset < 0 ? notifier.next : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.spent, required this.income});

  final Money spent;
  final Money income;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    Widget figure(String label, Widget value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppType.label.copyWith(color: c.inkMuted)),
        const SizedBox(height: Space.xxs),
        value,
      ],
    );
    return PoyshikCard(
      padding: const EdgeInsets.all(Space.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.insightsSpent.toUpperCase(),
            style: AppType.overline.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: Space.sm),
          AnimatedAmountText(spent, size: AmountSize.large),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              Expanded(
                child: figure(
                  l10n.homeIncome,
                  AnimatedAmountText(income, tone: AmountTone.income),
                ),
              ),
              Expanded(
                child: figure(l10n.homeNet, BalanceText(income - spent)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HighlightsCard extends StatelessWidget {
  const _HighlightsCard({required this.insights, required this.kind});

  final List<Insight> insights;
  final PeriodKind kind;

  String _sentence(AppLocalizations l10n, Insight i) => switch (i) {
    TopCategoryShare(:final category, :final percent) =>
      l10n.insightTopCategory(category.label(l10n), percent),
    ChangeVsPrevious(:final percent) => l10n.insightChange(
      percent.abs(),
      percent > 0 ? 'more' : 'less',
      kind.name,
    ),
    DailyAverage(:final amount) => l10n.insightDailyAverage(
      MoneyFormat.formatWhole(amount),
    ),
    BiggestDay(:final day, :final amount) => l10n.insightBiggestDay(
      DateFormat('EEE, d MMM').format(day),
      MoneyFormat.formatWhole(amount),
    ),
  };

  IconData _icon(Insight i) => switch (i) {
    TopCategoryShare() => Icons.pie_chart_outline_rounded,
    ChangeVsPrevious(:final percent) =>
      percent > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
    DailyAverage() => Icons.calendar_view_day_rounded,
    BiggestDay() => Icons.bolt_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return PoyshikCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.insightsHighlights.toUpperCase(),
            style: AppType.overline.copyWith(color: c.inkMuted),
          ),
          for (final i in insights) ...[
            const SizedBox(height: Space.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_icon(i), size: 18, color: c.accent),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Text(
                    _sentence(l10n, i),
                    style: AppType.body.copyWith(color: c.ink),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyBarsCard extends StatelessWidget {
  const _DailyBarsCard({
    required this.daily,
    required this.kind,
    required this.now,
  });

  final List<(DateTime, Money)> daily;
  final PeriodKind kind;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final maxValue = daily.fold<int>(
      0,
      (m, d) => d.$2.minor > m ? d.$2.minor : m,
    );
    final isWeek = kind == PeriodKind.week;
    final scale = barScale([for (final d in daily) d.$2]);
    // Average over days so far (future days in the current period are 0).
    final today = dateOnly(now);
    final elapsed = daily.where((d) => !d.$1.isAfter(today)).toList();
    final average = elapsed.isEmpty
        ? 0.0
        : elapsed.fold<int>(0, (s, d) => s + d.$2.minor) / elapsed.length;

    return PoyshikCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.insightsDayByDay.toUpperCase(),
            style: AppType.overline.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: Space.xl),
          SizedBox(
            height: 170,
            child: TweenAnimationBuilder<double>(
              // Bars grow from the baseline once, when the card appears.
              tween: Tween(begin: 0, end: 1),
              duration: Motion.reduced(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 700),
              curve: Motion.curve,
              builder: (context, grow, _) => BarChart(
                duration: Motion.base,
                BarChartData(
                  maxY: scale.maxY,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      if (average > 0)
                        HorizontalLine(
                          y: average,
                          color: c.inkSubtle.withValues(alpha: 0.6),
                          strokeWidth: 1,
                          dashArray: const [4, 4],
                        ),
                    ],
                  ),
                  alignment: BarChartAlignment.spaceBetween,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => c.ink,
                      tooltipBorderRadius: BorderRadius.circular(Radii.sm),
                      getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                        '${DateFormat('d MMM').format(daily[group.x].$1)}\n'
                        '${MoneyFormat.formatWhole(daily[group.x].$2)}',
                        AppType.caption.copyWith(color: c.onInk),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          final day = daily[i].$1;
                          final show =
                              isWeek || day.day == 1 || day.day % 7 == 1;
                          if (!show) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              isWeek
                                  ? DateFormat.E().format(day).substring(0, 2)
                                  : '${day.day}',
                              style: AppType.caption.copyWith(
                                color: c.inkSubtle,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < daily.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY:
                                grow *
                                (daily[i].$2.minor.toDouble() > scale.cap
                                    ? scale.cap
                                    : daily[i].$2.minor.toDouble()),
                            width: isWeek ? 22 : 7,
                            color: daily[i].$2.minor == maxValue && maxValue > 0
                                ? c.accent
                                : dateOnly(daily[i].$1) == dateOnly(now)
                                ? c.brand
                                : c.brand.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(isWeek ? 6 : 4),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (average > 0) ...[
            const SizedBox(height: Space.md),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  child: Divider(color: c.inkSubtle, thickness: 1),
                ),
                const SizedBox(width: Space.sm),
                Text(
                  l10n.insightsDailyAverage(
                    MoneyFormat.formatWhole(Money(average.round())),
                  ),
                  style: AppType.caption.copyWith(color: c.inkMuted),
                ),
                const Spacer(),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Text(
                  l10n.insightsBiggestDay,
                  style: AppType.caption.copyWith(color: c.inkMuted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryDonutCard extends StatefulWidget {
  const _CategoryDonutCard({required this.categories, required this.spent});

  final List<CategoryTotal> categories;
  final Money spent;

  @override
  State<_CategoryDonutCard> createState() => _CategoryDonutCardState();
}

class _CategoryDonutCardState extends State<_CategoryDonutCard> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final cats = widget.categories;
    final touched = _touched;
    final focus = touched == null || touched < 0 || touched >= cats.length
        ? null
        : cats[touched];
    // Percentages use the categories' own sum: never zero while any are
    // shown, and it can't disagree with the list while totals load.
    final sum = cats.fold<int>(0, (s, t) => s + t.total.minor);

    return PoyshikCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.insightsByCategory.toUpperCase(),
            style: AppType.overline.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: Space.lg),
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  duration: Motion.base,
                  PieChartData(
                    centerSpaceRadius: 64,
                    sectionsSpace: 2,
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions) return;
                        // fl_chart reports -1 when the finger is in the hole
                        // or between slices (e.g. while scrolling past).
                        final index =
                            response?.touchedSection?.touchedSectionIndex;
                        setState(
                          () => _touched = index == null || index < 0
                              ? null
                              : index,
                        );
                      },
                    ),
                    sections: [
                      for (var i = 0; i < cats.length; i++)
                        PieChartSectionData(
                          value: cats[i].total.minor.toDouble(),
                          color: PoyshikColors
                              .categoryPalette[cats[i].category.colorIndex],
                          radius: _touched == i ? 30 : 24,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      focus?.category.label(l10n) ?? l10n.insightsSpent,
                      style: AppType.caption.copyWith(color: c.inkMuted),
                    ),
                    AmountText(
                      focus?.total ?? widget.spent,
                      size: AmountSize.medium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          for (var i = 0; i < cats.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: Space.md),
              child: Row(
                children: [
                  CategoryIcon(
                    icon: AppIcons.of(cats[i].category.icon),
                    color: PoyshikColors
                        .categoryPalette[cats[i].category.colorIndex],
                    size: 34,
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Text(
                      cats[i].category.label(l10n),
                      style: AppType.label.copyWith(
                        color: c.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    sum <= 0
                        ? ''
                        : '${(cats[i].total.minor * 100 / sum).round()}%',
                    style: AppType.caption.copyWith(color: c.inkMuted),
                  ),
                  const SizedBox(width: Space.md),
                  AmountText(cats[i].total, size: AmountSize.small),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
