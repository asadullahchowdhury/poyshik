import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:poyshik/app/app.dart';
import 'package:poyshik/core/locale/language_provider.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/core/money/money_format.dart';
import 'package:poyshik/data/settings_repository.dart';
import 'package:poyshik/features/accounts/accounts_repository.dart';
import 'package:poyshik/features/budgets/budget_repository.dart';
import 'package:poyshik/features/home/summary_repository.dart';
import 'package:poyshik/features/transactions/transactions_repository.dart';

void main() {
  testWidgets('the language setting switches the whole app', (tester) async {
    tester.view
      ..physicalSize = const Size(1400, 2400)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    addTearDown(() => MoneyFormat.bengaliDigits = false);

    final container = ProviderContainer(
      overrides: [
        initialSettingsProvider.overrideWithValue({SettingKeys.language: 'bn'}),
        recentViewsProvider.overrideWith((ref) => Stream.value(const [])),
        hasTransactionsProvider.overrideWith((ref) => Stream.value(false)),
        activeAccountsProvider.overrideWith((ref) => Stream.value(const [])),
        periodTotalProvider.overrideWith(
          (ref, q) => Stream.value(const Money.taka(320)),
        ),
        overallBudgetProvider.overrideWith((ref) => Stream.value(null)),
        categoryLimitsProvider.overrideWith((ref) => Stream.value(const {})),
        topCategoriesProvider.overrideWith((ref, r) => Stream.value(const [])),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PoyshikApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('হোম'), findsOneWidget);
    expect(MoneyFormat.bengaliDigits, isTrue);

    // Settings writes through the repository, which needs a database; set
    // the state directly, as the Settings control does.
    container.read(languageProvider.notifier).state = AppLanguage.en;
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('হোম'), findsNothing);
    expect(MoneyFormat.bengaliDigits, isFalse);
  });
}
