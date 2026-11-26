import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/core/dates/periods.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/data/db/app_database.dart';
import 'package:poyshik/data/settings_repository.dart';
import 'package:poyshik/features/home/summary_repository.dart';
import 'package:poyshik/features/transactions/transactions_repository.dart';

void main() {
  late AppDatabase db;
  late TransactionsRepository tx;
  late SummaryRepository summary;
  late String cash;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tx = TransactionsRepository(db, SettingsRepository(db));
    summary = SummaryRepository(db);
    cash = (await db.select(db.accounts).getSingle()).id;
  });
  tearDown(() => db.close());

  Future<String> cat(String key) async => (await (db.select(
    db.categories,
  )..where((c) => c.systemKey.equals(key))).getSingle()).id;

  Future<void> add(
    TransactionType type,
    String? key,
    int taka,
    DateTime at,
  ) async {
    String? toAccount;
    if (type == TransactionType.transfer) {
      toAccount =
          (await db
                  .into(db.accounts)
                  .insertReturning(
                    AccountsCompanion.insert(
                      name: 'B$taka',
                      type: AccountType.bank,
                      icon: 'bank',
                    ),
                  ))
              .id;
    }
    await tx.add((
      type: type,
      amount: Money.taka(taka),
      accountId: cash,
      categoryId: key == null ? null : await cat(key),
      toAccountId: toAccount,
      occurredAt: at,
      note: null,
    ));
  }

  final nov = monthRange(DateTime(2026, 11, 15));

  test(
    'month total counts only that type inside the half-open range',
    () async {
      await add(TransactionType.expense, 'food', 100, DateTime(2026, 11));
      await add(
        TransactionType.expense,
        'food',
        50,
        DateTime(2026, 11, 30, 23, 59),
      );
      await add(
        TransactionType.expense,
        'food',
        999,
        DateTime(2026, 12),
      ); // next
      await add(
        TransactionType.expense,
        'food',
        999,
        DateTime(2026, 10, 31, 23),
      );
      await add(TransactionType.income, 'salary', 5000, DateTime(2026, 11, 5));
      await add(TransactionType.transfer, null, 300, DateTime(2026, 11, 6));

      expect(
        await summary.watchTotal(TransactionType.expense, nov).first,
        const Money.taka(150),
      );
      expect(
        await summary.watchTotal(TransactionType.income, nov).first,
        const Money.taka(5000),
      );
    },
  );

  test('category totals are grouped and sorted, transfers excluded', () async {
    await add(TransactionType.expense, 'food', 100, DateTime(2026, 11, 2));
    await add(TransactionType.expense, 'food', 150, DateTime(2026, 11, 3));
    await add(TransactionType.expense, 'rent', 200, DateTime(2026, 11, 4));
    await add(TransactionType.expense, 'transport', 20, DateTime(2026, 11, 4));
    await add(TransactionType.transfer, null, 9999, DateTime(2026, 11, 4));

    final totals = await summary.watchCategoryTotals(nov, limit: 2).first;
    expect(totals.map((t) => t.category.systemKey), ['food', 'rent']);
    expect(totals.first.total, const Money.taka(250));
  });

  test('percentChange', () {
    expect(percentChange(const Money(150), const Money(100)), 50);
    expect(percentChange(const Money(80), const Money(100)), -20);
    expect(percentChange(const Money(80), Money.zero), isNull);
  });
}
