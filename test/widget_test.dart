import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/app/app.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/features/accounts/accounts_repository.dart';
import 'package:poyshik/features/budgets/budget_repository.dart';
import 'package:poyshik/features/home/summary_repository.dart';
import 'package:poyshik/features/onboarding/onboarding_service.dart';
import 'package:poyshik/features/transactions/transactions_repository.dart';

Future<void> _pumpApp(WidgetTester tester, {bool firstLaunch = false}) async {
  await tester.pumpWidget(
    ProviderScope(
      // Widget tests avoid the real database; data logic is tested in test/data.
      overrides: [
        startupNeedsOnboardingProvider.overrideWithValue(firstLaunch),
        transactionViewsProvider.overrideWith((ref) => Stream.value(const [])),
        filteredViewsProvider.overrideWith((ref) => Stream.value(const [])),
        activeAccountsProvider.overrideWith((ref) => Stream.value(const [])),
        periodTotalProvider.overrideWith(
          (ref, query) => Stream.value(Money.zero),
        ),
        overallBudgetProvider.overrideWith((ref) => Stream.value(null)),
        categoryTotalsProvider.overrideWith(
          (ref, range) => Stream.value(const []),
        ),
        expenseEntriesProvider.overrideWith(
          (ref, range) => Stream.value(const []),
        ),
        topCategoriesProvider.overrideWith(
          (ref, range) => Stream.value(const []),
        ),
      ],
      child: const PoyshikApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts on Home with four tabs and a first-run prompt', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('Log your first expense'), findsOneWidget);
    for (final tab in ['Home', 'Activity', 'Insights', 'More']) {
      expect(find.text(tab), findsWidgets);
    }
  });

  testWidgets('first launch goes through setup pages', (tester) async {
    await _pumpApp(tester, firstLaunch: true);

    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Home'), findsNothing); // no tab bar during setup

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text("Where's your money?"), findsOneWidget);
    expect(find.text('bKash'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('A monthly budget?'), findsOneWidget);
  });

  testWidgets('switches tabs', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(find.text('No transactions yet'), findsOneWidget);

    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(find.text('Insights need a little data'), findsOneWidget);
  });

  testWidgets('More opens the design gallery and keeps tab state', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Design system'));
    await tester.pumpAndSettle();
    expect(find.text('SPENT IN NOVEMBER'), findsOneWidget);

    // Leave and come back: the More tab still shows the gallery.
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('SPENT IN NOVEMBER'), findsOneWidget);
  });
}
