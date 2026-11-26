import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/data/db/app_database.dart';
import 'package:poyshik/features/transactions/day_groups.dart';
import 'package:poyshik/features/transactions/transactions_repository.dart';

final _account = Account(
  id: 'a',
  name: 'Cash',
  type: AccountType.cash,
  icon: 'cash',
  colorIndex: 0,
  openingBalance: 0,
  currency: 'BDT',
  sortOrder: 0,
  isArchived: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

TransactionView _view(TransactionType type, int amount, DateTime at) => (
  tx: TransactionRecord(
    id: '$type$amount$at',
    type: type,
    amount: amount,
    accountId: 'a',
    toAccountId: type == TransactionType.transfer ? 'b' : null,
    categoryId: type == TransactionType.transfer ? null : 'c',
    occurredAt: at,
    note: null,
    createdAt: at,
    updatedAt: at,
  ),
  account: _account,
  toAccount: null,
  category: null,
);

void main() {
  test('groups by calendar day with spent/earned totals', () {
    final groups = groupByDay([
      _view(TransactionType.expense, 300, DateTime(2026, 11, 26, 20)),
      _view(TransactionType.income, 5000, DateTime(2026, 11, 26, 9)),
      _view(TransactionType.transfer, 999, DateTime(2026, 11, 26, 8)),
      _view(TransactionType.expense, 200, DateTime(2026, 11, 26, 0, 5)),
      _view(TransactionType.expense, 100, DateTime(2026, 11, 25, 23, 59)),
    ]);

    expect(groups, hasLength(2));
    expect(groups[0].day, DateTime(2026, 11, 26));
    expect(groups[0].items, hasLength(4));
    expect(groups[0].spent, const Money(500));
    expect(groups[0].earned, const Money(5000));
    expect(groups[1].day, DateTime(2026, 11, 25));
    expect(groups[1].spent, const Money(100));
  });

  test('empty list gives no groups', () {
    expect(groupByDay(const []), isEmpty);
  });
}
