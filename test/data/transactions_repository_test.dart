import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/data/db/app_database.dart';
import 'package:poyshik/data/db/balance_queries.dart';
import 'package:poyshik/data/settings_repository.dart';
import 'package:poyshik/features/accounts/accounts_repository.dart';
import 'package:poyshik/features/transactions/transactions_repository.dart';

void main() {
  late AppDatabase db;
  late TransactionsRepository repo;
  late AccountsRepository accounts;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TransactionsRepository(db, SettingsRepository(db));
    accounts = AccountsRepository(db);
  });
  tearDown(() => db.close());

  Future<Category> cat(String key) => (db.select(
    db.categories,
  )..where((c) => c.systemKey.equals(key))).getSingle();

  Future<String> cashId() async =>
      (await accounts.watchWithBalances().first).first.account.id;

  TransactionDraft expense(String accountId, String categoryId, int taka) => (
    type: TransactionType.expense,
    amount: Money.taka(taka),
    accountId: accountId,
    categoryId: categoryId,
    toAccountId: null,
    occurredAt: DateTime(2026, 11, 26, 13),
    note: '  lunch  ',
  );

  test('add saves the entry, trims the note and updates balance', () async {
    final cash = await cashId();
    final food = await cat('food');
    final id = await repo.add(expense(cash, food.id, 320));

    final row = (await repo.byId(id))!;
    expect(row.amount, 32000);
    expect(row.note, 'lunch');
    expect((await db.accountBalances())[cash], const Money.taka(-320));
  });

  test('blank note is stored as null', () async {
    final cash = await cashId();
    final food = await cat('food');
    final d = expense(cash, food.id, 10);
    final id = await repo.add((
      type: d.type,
      amount: d.amount,
      accountId: d.accountId,
      categoryId: d.categoryId,
      toAccountId: null,
      occurredAt: d.occurredAt,
      note: '   ',
    ));
    expect((await repo.byId(id))!.note, isNull);
  });

  test('default account is the last used active account', () async {
    final cash = await cashId();
    expect(await repo.defaultAccountId(), cash);

    final bkash = await accounts.create(
      name: 'bKash',
      type: AccountType.mobileWallet,
      colorIndex: 6,
    );
    final food = await cat('food');
    await repo.add(expense(bkash.id, food.id, 50));
    expect(await repo.defaultAccountId(), bkash.id);

    await accounts.setArchived(bkash.id, archived: true);
    expect(await repo.defaultAccountId(), cash);
  });

  test('categories are ordered by usage, then sort order', () async {
    final cash = await cashId();
    final transport = await cat('transport');
    final health = await cat('health');
    await repo.add(expense(cash, health.id, 1));
    await repo.add(expense(cash, transport.id, 1));
    await repo.add(expense(cash, transport.id, 1));

    final list = await repo.watchCategoriesByUsage(CategoryKind.expense).first;
    expect(list.take(3).map((c) => c.systemKey), [
      'transport',
      'health',
      'food',
    ]);
    expect(list.every((c) => c.kind == CategoryKind.expense), isTrue);
  });

  test('delete then restore brings the same row back', () async {
    final cash = await cashId();
    final food = await cat('food');
    final id = await repo.add(expense(cash, food.id, 99));

    final removed = await repo.delete(id);
    expect(await repo.byId(id), isNull);
    await repo.restore(removed!);
    expect((await repo.byId(id))!.amount, 9900);
  });

  test('update edits amount and category', () async {
    final cash = await cashId();
    final food = await cat('food');
    final rent = await cat('rent');
    final id = await repo.add(expense(cash, food.id, 100));
    await repo.update(id, expense(cash, rent.id, 150));
    final row = (await repo.byId(id))!;
    expect(row.amount, 15000);
    expect(row.categoryId, rent.id);
  });
}
