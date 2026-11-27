import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/core/dates/periods.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/data/db/app_database.dart';
import 'package:poyshik/data/settings_repository.dart';
import 'package:poyshik/features/accounts/accounts_repository.dart';
import 'package:poyshik/features/transactions/transactions_repository.dart';

void main() {
  late AppDatabase db;
  late TransactionsRepository repo;
  late String cash;
  late String bkash;
  late Map<String, String> cats;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = TransactionsRepository(db, SettingsRepository(db));
    cash = (await db.select(db.accounts).getSingle()).id;
    bkash = (await AccountsRepository(
      db,
    ).create(name: 'bKash', type: AccountType.mobileWallet, colorIndex: 6)).id;
    cats = {
      for (final c in await db.select(db.categories).get()) c.systemKey!: c.id,
    };

    Future<void> add(
      TransactionType type,
      int poisha,
      DateTime at, {
      String? cat,
      String? account,
      String? to,
      String? note,
    }) => repo.add((
      type: type,
      amount: Money(poisha),
      accountId: account ?? cash,
      categoryId: cat == null ? null : cats[cat],
      toAccountId: to,
      occurredAt: at,
      note: note,
    ));

    await add(
      TransactionType.expense,
      25000,
      DateTime(2026, 11, 3),
      cat: 'food',
      note: 'Biryani at Star',
    );
    await add(
      TransactionType.expense,
      25050,
      DateTime(2026, 11, 4),
      cat: 'transport',
      account: bkash,
    );
    await add(
      TransactionType.income,
      6500000,
      DateTime(2026, 11, 1),
      cat: 'salary',
    );
    await add(
      TransactionType.transfer,
      100000,
      DateTime(2026, 11, 5),
      to: bkash,
    );
    await add(
      TransactionType.expense,
      12000,
      DateTime(2026, 10, 20),
      cat: 'food',
    );
  });
  tearDown(() => db.close());

  Future<int> count(TransactionFilter f) async =>
      (await repo.watchViews(filter: f).first).length;

  TransactionFilter f({
    String query = '',
    TransactionType? type,
    String? account,
    String? category,
    DateRange? range,
  }) => (
    query: query,
    type: type,
    accountId: account,
    categoryId: category,
    range: range,
  );

  test('no filter returns everything', () async {
    expect(await count(noFilter), 5);
    expect(noFilter.isActive, isFalse);
  });

  test('type, category and month', () async {
    expect(await count(f(type: TransactionType.expense)), 3);
    expect(await count(f(category: cats['food'])), 2);
    expect(await count(f(range: monthRange(DateTime(2026, 11)))), 4);
    expect(
      await count(
        f(category: cats['food'], range: monthRange(DateTime(2026, 11))),
      ),
      1,
    );
  });

  test('account matches outgoing and incoming transfers', () async {
    // bKash: one expense from it + one transfer into it.
    expect(await count(f(account: bkash)), 2);
  });

  test('text search: note, category, account, case-insensitive', () async {
    expect(await count(f(query: 'biryani')), 1);
    expect(await count(f(query: 'TRANSPORT')), 1);
    expect(await count(f(query: 'salary')), 1);
    expect(await count(f(query: 'bkash')), 2); // expense from + transfer to
    expect(await count(f(query: 'nothing-like-this')), 0);
  });

  test('amount search: whole taka spans poisha, decimals are exact', () async {
    expect(await count(f(query: '250')), 2); // ৳250 and ৳250.50
    expect(await count(f(query: '250.50')), 1);
    expect(await count(f(query: '120')), 1);
  });

  test('limit pages newest first', () async {
    final page = await repo.watchViews(limit: 2).first;
    expect(page.map((v) => v.tx.occurredAt), [
      DateTime(2026, 11, 5),
      DateTime(2026, 11, 4),
    ]);
    expect(await repo.watchViews(limit: 10).first, hasLength(5));
  });

  test('summary counts and sums every match, not just a page', () async {
    final all = await repo.watchSummary(noFilter).first;
    expect(all.count, 5);
    // Expenses only: 250 + 250.50 + 120.
    expect(all.spent, const Money(25000 + 25050 + 12000));

    final food = await repo.watchSummary(f(query: 'food')).first;
    expect(food.count, 2);
    expect(food.spent, const Money(37000));
  });

  test('hasAny', () async {
    expect(await repo.watchHasAny().first, isTrue);
    await db.delete(db.transactions).go();
    expect(await repo.watchHasAny().first, isFalse);
  });
}
