import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/data/db/app_database.dart';
import 'package:poyshik/data/db/balance_queries.dart';
import 'package:poyshik/data/settings_repository.dart';
import 'package:poyshik/features/budgets/budget_repository.dart';
import 'package:poyshik/features/onboarding/onboarding_service.dart';
import 'package:poyshik/features/transactions/transactions_repository.dart';

void main() {
  late AppDatabase db;
  late OnboardingService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = OnboardingService(db);
  });
  tearDown(() => db.close());

  test('fresh install needs onboarding until completed', () async {
    expect(await service.needsOnboarding(), isTrue);
    await service.complete(cashOpening: Money.zero, extras: const []);
    expect(await service.needsOnboarding(), isFalse);
  });

  test('existing data skips onboarding and remembers that', () async {
    final cash = (await db.select(db.accounts).getSingle()).id;
    final food = (await (db.select(
      db.categories,
    )..where((c) => c.systemKey.equals('food'))).getSingle()).id;
    await TransactionsRepository(db, SettingsRepository(db)).add((
      type: TransactionType.expense,
      amount: const Money.taka(10),
      accountId: cash,
      categoryId: food,
      toAccountId: null,
      occurredAt: DateTime(2026, 11, 26),
      note: null,
    ));
    expect(await service.needsOnboarding(), isFalse);
    expect(
      await SettingsRepository(db).get(SettingKeys.onboardingDone),
      'true',
    );
  });

  test('complete sets Cash, adds accounts and budget', () async {
    await service.complete(
      cashOpening: const Money.taka(1500),
      extras: [
        (
          name: 'bKash',
          type: AccountType.mobileWallet,
          colorIndex: 6,
          opening: const Money.taka(3200),
        ),
        (
          name: 'Bank',
          type: AccountType.bank,
          colorIndex: 4,
          opening: const Money.taka(50000),
        ),
      ],
      monthlyBudget: const Money.taka(20000),
    );

    final accounts = await db.select(db.accounts).get();
    expect(accounts.map((a) => a.name), ['Cash', 'bKash', 'Bank']);
    final balances = await db.accountBalances();
    expect(balances[accounts[0].id], const Money.taka(1500));
    expect(balances[accounts[1].id], const Money.taka(3200));
    expect(
      await BudgetRepository(db).watchOverall().first,
      const Money.taka(20000),
    );
  });
}
