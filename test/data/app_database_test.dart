import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/data/db/app_database.dart';
import 'package:poyshik/data/db/balance_queries.dart';
import 'package:poyshik/data/db/seed.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<Account> cash() =>
      (db.select(db.accounts)..where((a) => a.name.equals('Cash'))).getSingle();

  Future<Category> category(String key) => (db.select(
    db.categories,
  )..where((c) => c.systemKey.equals(key))).getSingle();

  Future<Account> addAccount(String name, {int opening = 0}) async {
    return db
        .into(db.accounts)
        .insertReturning(
          AccountsCompanion.insert(
            name: name,
            type: AccountType.mobileWallet,
            icon: 'wallet',
            openingBalance: Value(opening),
          ),
        );
  }

  Future<void> addTx({
    required TransactionType type,
    required int amount,
    required String accountId,
    String? toAccountId,
    String? categoryId,
  }) {
    return db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: type,
            amount: amount,
            accountId: accountId,
            toAccountId: Value(toAccountId),
            categoryId: Value(categoryId),
            occurredAt: DateTime(2026, 11, 25, 12),
          ),
        );
  }

  group('seed', () {
    test('creates Cash and the default categories once', () async {
      final accounts = await db.select(db.accounts).get();
      expect(accounts.map((a) => a.name), ['Cash']);
      expect(accounts.single.type, AccountType.cash);
      expect(accounts.single.openingBalance, 0);
      expect(accounts.single.id, hasLength(36)); // UUID

      final categories = await db.select(db.categories).get();
      final expense = categories.where((c) => c.kind == CategoryKind.expense);
      final income = categories.where((c) => c.kind == CategoryKind.income);
      expect(expense, hasLength(defaultExpenseCategories.length));
      expect(income, hasLength(defaultIncomeCategories.length));
      expect(categories.every((c) => c.systemKey != null), isTrue);
    });
  });

  group('constraints', () {
    test('foreign keys are enforced', () async {
      final food = await category('food');
      await expectLater(
        addTx(
          type: TransactionType.expense,
          amount: 100,
          accountId: 'does-not-exist',
          categoryId: food.id,
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('amount must be positive', () async {
      final a = await cash();
      final food = await category('food');
      await expectLater(
        addTx(
          type: TransactionType.expense,
          amount: 0,
          accountId: a.id,
          categoryId: food.id,
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('expense needs a category and no target account', () async {
      final a = await cash();
      final b = await addAccount('bKash');
      await expectLater(
        addTx(type: TransactionType.expense, amount: 100, accountId: a.id),
        throwsA(isA<SqliteException>()),
      );
      final food = await category('food');
      await expectLater(
        addTx(
          type: TransactionType.expense,
          amount: 100,
          accountId: a.id,
          toAccountId: b.id,
          categoryId: food.id,
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('transfer needs a different target and no category', () async {
      final a = await cash();
      await expectLater(
        addTx(
          type: TransactionType.transfer,
          amount: 100,
          accountId: a.id,
          toAccountId: a.id,
        ),
        throwsA(isA<SqliteException>()),
      );
      final food = await category('food');
      final b = await addAccount('bKash');
      await expectLater(
        addTx(
          type: TransactionType.transfer,
          amount: 100,
          accountId: a.id,
          toAccountId: b.id,
          categoryId: food.id,
        ),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('balances', () {
    test('opening + income − expense − transfer out + transfer in', () async {
      final a = await cash();
      final bkash = await addAccount('bKash', opening: 50000); // ৳500
      final salary = await category('salary');
      final food = await category('food');

      await addTx(
        type: TransactionType.income,
        amount: 100000, // +৳1,000
        accountId: a.id,
        categoryId: salary.id,
      );
      await addTx(
        type: TransactionType.expense,
        amount: 25050, // −৳250.50
        accountId: a.id,
        categoryId: food.id,
      );
      await addTx(
        type: TransactionType.transfer,
        amount: 30000, // Cash → bKash ৳300
        accountId: a.id,
        toAccountId: bkash.id,
      );

      final balances = await db.accountBalances();
      expect(balances[a.id], const Money(44950)); // 1000 − 250.50 − 300
      expect(balances[bkash.id], const Money(80000)); // 500 + 300
    });

    test('watch emits when transactions change', () async {
      final a = await cash();
      final food = await category('food');
      final stream = db.watchAccountBalances().map((m) => m[a.id]);

      final expectation = expectLater(
        stream,
        emitsInOrder([Money.zero, const Money(-1000)]),
      );
      await Future<void>.delayed(Duration.zero);
      await addTx(
        type: TransactionType.expense,
        amount: 1000,
        accountId: a.id,
        categoryId: food.id,
      );
      await expectation;
    });
  });
}
