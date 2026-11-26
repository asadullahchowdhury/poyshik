import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/data/db/app_database.dart';
import 'package:poyshik/features/accounts/accounts_repository.dart';

void main() {
  late AppDatabase db;
  late AccountsRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = AccountsRepository(db);
  });
  tearDown(() => db.close());

  test(
    'create appends with type icon, trimmed name and opening balance',
    () async {
      final a = await repo.create(
        name: '  bKash ',
        type: AccountType.mobileWallet,
        colorIndex: 6,
        openingBalance: const Money.taka(500),
      );
      expect(a.name, 'bKash');
      expect(a.icon, 'wallet');
      expect(a.openingBalance, 50000);
      expect(a.sortOrder, 1); // after seeded Cash (0)

      final list = await repo.watchWithBalances().first;
      expect(list.map((e) => e.account.name), ['Cash', 'bKash']);
      expect(list.last.balance, const Money.taka(500));
    },
  );

  test('stream re-emits for new accounts and new transactions', () async {
    final stream = repo.watchWithBalances();
    final emissions = <List<AccountWithBalance>>[];
    final sub = stream.listen(emissions.add);
    await pumpEventQueue();

    final bank = await repo.create(
      name: 'Bank',
      type: AccountType.bank,
      colorIndex: 4,
    );
    await pumpEventQueue();
    expect(emissions.last.map((e) => e.account.name), ['Cash', 'Bank']);

    final salary = await (db.select(
      db.categories,
    )..where((c) => c.systemKey.equals('salary'))).getSingle();
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: TransactionType.income,
            amount: 100000,
            accountId: bank.id,
            categoryId: Value(salary.id),
            occurredAt: DateTime(2026, 11, 26),
          ),
        );
    await pumpEventQueue();
    expect(emissions.last.last.balance, const Money.taka(1000));
    await sub.cancel();
  });

  test('update changes fields and icon follows type', () async {
    final a = await repo.create(
      name: 'Card',
      type: AccountType.card,
      colorIndex: 1,
    );
    await repo.update(
      a.id,
      name: 'City Bank',
      type: AccountType.bank,
      colorIndex: 3,
      openingBalance: const Money.taka(10),
    );
    final updated = (await repo.byId(a.id))!;
    expect(updated.name, 'City Bank');
    expect(updated.icon, 'bank');
    expect(updated.colorIndex, 3);
    expect(updated.openingBalance, 1000);
  });

  test('archive moves an account between active and archived', () async {
    final a = await repo.create(
      name: 'Old',
      type: AccountType.other,
      colorIndex: 0,
    );
    await repo.setArchived(a.id, archived: true);
    expect((await repo.watchWithBalances().first).map((e) => e.account.name), [
      'Cash',
    ]);
    expect(
      (await repo.watchWithBalances(archived: true).first).single.account.id,
      a.id,
    );
    expect(await repo.activeCount(), 1);
  });
}
