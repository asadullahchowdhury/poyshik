import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../../data/db/app_database.dart';
import '../../data/db/balance_queries.dart';
import '../../data/db/database_provider.dart';

/// An account together with its computed current balance.
typedef AccountWithBalance = ({Account account, Money balance});

/// Default icon key for each account type.
String iconForAccountType(AccountType type) => switch (type) {
  AccountType.cash => 'cash',
  AccountType.bank => 'bank',
  AccountType.mobileWallet => 'wallet',
  AccountType.card => 'card',
  AccountType.other => 'wallet',
};

class AccountsRepository {
  AccountsRepository(this._db);

  final AppDatabase _db;

  /// Accounts with live balances, active or archived. One query, so it
  /// re-emits when either accounts or transactions change.
  Stream<List<AccountWithBalance>> watchWithBalances({bool archived = false}) {
    return _db
        .customSelect(
          'SELECT a.*, ${BalanceQueries.balanceExpression} AS balance '
          'FROM accounts a WHERE a.is_archived = ? '
          'ORDER BY a.sort_order, a.created_at',
          variables: [Variable.withBool(archived)],
          readsFrom: {_db.accounts, _db.transactions},
        )
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              (
                account: _db.accounts.map(row.data),
                balance: Money(row.read<int>('balance')),
              ),
          ],
        );
  }

  Future<Account?> byId(String id) => (_db.select(
    _db.accounts,
  )..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<Account> create({
    required String name,
    required AccountType type,
    required int colorIndex,
    Money openingBalance = Money.zero,
  }) async {
    final maxOrder = _db.accounts.sortOrder.max();
    final last = await (_db.selectOnly(
      _db.accounts,
    )..addColumns([maxOrder])).map((r) => r.read(maxOrder)).getSingle();
    return _db
        .into(_db.accounts)
        .insertReturning(
          AccountsCompanion.insert(
            name: name.trim(),
            type: type,
            icon: iconForAccountType(type),
            colorIndex: Value(colorIndex),
            openingBalance: Value(openingBalance.minor),
            sortOrder: Value((last ?? -1) + 1),
            currency: Value(MoneyFormat.currency.code),
          ),
        );
  }

  Future<void> update(
    String id, {
    required String name,
    required AccountType type,
    required int colorIndex,
    required Money openingBalance,
  }) {
    return (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        name: Value(name.trim()),
        type: Value(type),
        icon: Value(iconForAccountType(type)),
        colorIndex: Value(colorIndex),
        openingBalance: Value(openingBalance.minor),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Archived accounts keep their history but disappear from pickers.
  Future<void> setArchived(String id, {required bool archived}) {
    return (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        isArchived: Value(archived),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> activeCount() async {
    final count = countAll(filter: _db.accounts.isArchived.equals(false));
    return (_db.selectOnly(
      _db.accounts,
    )..addColumns([count])).map((r) => r.read(count)!).getSingle();
  }
}

final accountsRepositoryProvider = Provider<AccountsRepository>(
  (ref) => AccountsRepository(ref.watch(appDatabaseProvider)),
);

final activeAccountsProvider = StreamProvider<List<AccountWithBalance>>(
  (ref) => ref.watch(accountsRepositoryProvider).watchWithBalances(),
);

final archivedAccountsProvider = StreamProvider<List<AccountWithBalance>>(
  (ref) =>
      ref.watch(accountsRepositoryProvider).watchWithBalances(archived: true),
);

/// Sum of all active account balances.
final totalBalanceProvider = Provider<AsyncValue<Money>>((ref) {
  return ref
      .watch(activeAccountsProvider)
      .whenData((list) => list.fold(Money.zero, (sum, a) => sum + a.balance));
});
