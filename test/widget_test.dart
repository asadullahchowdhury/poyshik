import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/app/app.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/features/accounts/accounts_repository.dart';
import 'package:poyshik/features/home/summary_repository.dart';
import 'package:poyshik/features/transactions/transactions_repository.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      // Widget tests avoid the real database; data logic is tested in test/data.
      overrides: [
        transactionViewsProvider.overrideWith((ref) => Stream.value(const [])),
        activeAccountsProvider.overrideWith((ref) => Stream.value(const [])),
        periodTotalProvider.overrideWith(
          (ref, query) => Stream.value(Money.zero),
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
