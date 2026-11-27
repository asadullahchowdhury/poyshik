import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../../core/dates/clock.dart';
import '../../core/dates/periods.dart';
import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/poyshik_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/state_views.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../categories/categories_repository.dart';
import '../categories/category_label.dart';
import '../home/summary_repository.dart';
import 'budget_repository.dart';
import 'budget_sheet.dart';

/// The overall monthly budget and optional per-category limits, each with
/// this month's spending against it.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final month = monthRange(ref.watch(clockProvider)());
    final overall = ref.watch(overallBudgetProvider);
    final limits = ref.watch(categoryLimitsProvider);
    final categories = ref.watch(
      categoryListProvider((kind: CategoryKind.expense, archived: false)),
    );
    final totals = ref.watch(categoryTotalsProvider(month));
    final spentMonth =
        ref
            .watch(
              periodTotalProvider((
                type: TransactionType.expense,
                range: month,
              )),
            )
            .value ??
        Money.zero;

    final failed = <AsyncValue<Object?>>[
      overall,
      limits,
      categories,
      totals,
    ].where((a) => a.hasError).firstOrNull;

    Widget body() {
      if (failed != null) return ErrorView(error: failed.error!);
      if (!categories.hasValue || !limits.hasValue) return const LoadingView();
      final spentBy = {
        for (final t in totals.value ?? const <CategoryTotal>[])
          t.category.id: t.total,
      };
      final budget = overall.value;
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.screen,
          Space.sm,
          Space.screen,
          Space.huge,
        ),
        children: [
          SectionHeader(l10n.budgetsOverall),
          PoyshikCard(
            onTap: () => unawaited(showBudgetSheet(context)),
            child: budget == null
                ? Text(
                    l10n.budgetsOverallNotSet,
                    style: AppType.body.copyWith(color: c.inkMuted),
                  )
                : _Progress(spent: spentMonth, limit: budget),
          ),
          const SizedBox(height: Space.xxl),
          SectionHeader(l10n.budgetsCategories),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.xs, 0, Space.xs, Space.md),
            child: Text(
              l10n.budgetsCategoriesHelp,
              style: AppType.caption.copyWith(color: c.inkMuted),
            ),
          ),
          PoyshikCard(
            padding: const EdgeInsets.symmetric(vertical: Space.xs),
            child: Column(
              children: [
                for (final (i, cat) in categories.value!.indexed) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.only(left: Space.lg + 38 + Space.md),
                      child: Divider(),
                    ),
                  _CategoryRow(
                    category: cat,
                    spent: spentBy[cat.id] ?? Money.zero,
                    limit: limits.value![cat.id],
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetsTitle)),
      body: body(),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.spent,
    required this.limit,
  });

  final Category category;
  final Money spent;
  final Money? limit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final limit = this.limit;
    return InkWell(
      onTap: () => unawaited(showBudgetSheet(context, category: category)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.md,
        ),
        child: Row(
          children: [
            CategoryIcon(
              icon: AppIcons.of(category.icon),
              color: PoyshikColors.categoryPalette[category.colorIndex],
              size: 38,
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: limit == null
                  ? Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.label(l10n),
                            style: AppType.bodyStrong.copyWith(color: c.ink),
                          ),
                        ),
                        Text(
                          l10n.budgetsNoLimit,
                          style: AppType.caption.copyWith(color: c.inkSubtle),
                        ),
                      ],
                    )
                  : _Progress(
                      title: category.label(l10n),
                      spent: spent,
                      limit: limit,
                      color: PoyshikColors.categoryPalette[category.colorIndex],
                    ),
            ),
            const SizedBox(width: Space.sm),
            Icon(Icons.chevron_right_rounded, color: c.inkSubtle),
          ],
        ),
      ),
    );
  }
}

/// Spent against a limit, with a bar that turns to the warning colour once
/// the limit is passed.
class _Progress extends StatelessWidget {
  const _Progress({
    required this.spent,
    required this.limit,
    this.title,
    this.color,
  });

  final Money spent;
  final Money limit;
  final String? title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final over = spent > limit;
    final progress = limit.isPositive ? spent.minor / limit.minor : 0.0;
    final status = over
        ? l10n.budgetsOverBy(MoneyFormat.format(spent - limit))
        : MoneyFormat.digits('${(progress * 100).round()}%');
    final spentOf = l10n.budgetsSpentOf(
      MoneyFormat.format(spent),
      MoneyFormat.format(limit),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title ?? spentOf,
                style: AppType.bodyStrong.copyWith(color: c.ink),
              ),
            ),
            Text(
              status,
              style: AppType.label.copyWith(
                color: over ? c.warning : c.inkMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (title != null) ...[
          const SizedBox(height: Space.xxs),
          Text(spentOf, style: AppType.caption.copyWith(color: c.inkMuted)),
        ],
        const SizedBox(height: Space.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.pill),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1).toDouble(),
            minHeight: 6,
            backgroundColor: c.surfaceRaised,
            color: over ? c.warning : color ?? c.brand,
          ),
        ),
      ],
    );
  }
}
