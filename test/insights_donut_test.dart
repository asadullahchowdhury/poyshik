import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:poyshik/app/app.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/data/db/app_database.dart';
import 'package:poyshik/features/accounts/accounts_repository.dart';
import 'package:poyshik/features/budgets/budget_repository.dart';
import 'package:poyshik/features/home/summary_repository.dart';
import 'package:poyshik/features/transactions/transactions_repository.dart';

Category _cat(String id, String name, int color) => Category(
  id: id,
  name: name,
  kind: CategoryKind.expense,
  icon: 'more',
  colorIndex: color,
  sortOrder: 0,
  isArchived: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

/// Regression: touching or scrolling across the donut's empty centre made
/// fl_chart report section -1, which crashed the Insights screen (a blank
/// block in release builds).
void main() {
  testWidgets('nothing to chart while spent is zero', (tester) async {
    tester.view
      ..physicalSize = const Size(1400, 2400)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final totals = <CategoryTotal>[
      (category: _cat('a', 'Rent', 8), total: const Money.taka(1800)),
      (category: _cat('b', 'Food', 0), total: const Money.taka(830)),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recentViewsProvider.overrideWith((ref) => Stream.value(const [])),
          hasTransactionsProvider.overrideWith((ref) => Stream.value(true)),
          filteredViewsProvider.overrideWith((ref) => Stream.value(const [])),
          filteredSummaryProvider.overrideWith(
            (ref) => Stream.value((count: 0, spent: Money.zero)),
          ),
          activeAccountsProvider.overrideWith((ref) => Stream.value(const [])),
          // Spent stays zero, as while totals are still loading: the
          // percentages must not divide by it.
          periodTotalProvider.overrideWith(
            (ref, q) => Stream.value(Money.zero),
          ),
          overallBudgetProvider.overrideWith((ref) => Stream.value(null)),
          categoryLimitsProvider.overrideWith((ref) => Stream.value(const {})),
          categoryTotalsProvider.overrideWith((ref, r) => Stream.value(totals)),
          expenseEntriesProvider.overrideWith(
            (ref, r) => Stream.value(const []),
          ),
          topCategoriesProvider.overrideWith((ref, r) => Stream.value(totals)),
        ],
        child: const PoyshikApp(),
      ),
    );
    await tester.pumpAndSettle();
    // With zero spent the screen shows its empty state; give it income so
    // the cards render.
    expect(find.byType(PieChart), findsNothing);
  });

  testWidgets('donut survives touches in its hole and while scrolling', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1400, 2400)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final totals = <CategoryTotal>[
      (category: _cat('a', 'Rent', 8), total: const Money.taka(1800)),
      (category: _cat('b', 'Food', 0), total: const Money.taka(830)),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recentViewsProvider.overrideWith((ref) => Stream.value(const [])),
          hasTransactionsProvider.overrideWith((ref) => Stream.value(true)),
          filteredViewsProvider.overrideWith((ref) => Stream.value(const [])),
          filteredSummaryProvider.overrideWith(
            (ref) => Stream.value((count: 0, spent: Money.zero)),
          ),
          activeAccountsProvider.overrideWith((ref) => Stream.value(const [])),
          periodTotalProvider.overrideWith(
            (ref, q) => Stream.value(const Money.taka(2630)),
          ),
          overallBudgetProvider.overrideWith((ref) => Stream.value(null)),
          categoryLimitsProvider.overrideWith((ref) => Stream.value(const {})),
          categoryTotalsProvider.overrideWith((ref, r) => Stream.value(totals)),
          expenseEntriesProvider.overrideWith(
            (ref, r) => Stream.value(const []),
          ),
          topCategoriesProvider.overrideWith((ref, r) => Stream.value(totals)),
        ],
        child: const PoyshikApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Insights').last);
    await tester.pumpAndSettle();

    final donut = find.byType(PieChart);
    await tester.scrollUntilVisible(
      donut,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    // Touch the chart's empty corner (outside the ring), then scroll with
    // the finger starting there: fl_chart reports section -1 for both.
    final corner = tester.getTopLeft(donut) + const Offset(12, 12);
    await tester.tapAt(corner);
    await tester.pumpAndSettle();
    await tester.dragFrom(corner, const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Food'), findsWidgets);
  });
}
