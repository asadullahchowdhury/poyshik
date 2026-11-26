import 'package:drift/drift.dart';

import '../../core/money/money.dart';
import 'app_database.dart';

/// Account balances are computed, never stored, so they can't drift from
/// the transactions that produce them:
///   opening + income − expense − transfers out + transfers in
extension BalanceQueries on AppDatabase {
  /// SQL for the balance of the account aliased `a`. Reused by queries that
  /// select accounts together with their balances.
  static const balanceExpression = '''
    (a.opening_balance
      + COALESCE((
          SELECT SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE -t.amount END)
          FROM transactions t WHERE t.account_id = a.id
        ), 0)
      + COALESCE((
          SELECT SUM(t.amount) FROM transactions t
          WHERE t.type = 'transfer' AND t.to_account_id = a.id
        ), 0))''';

  Selectable<(String, Money)> _balances() {
    return customSelect(
      'SELECT a.id AS id, $balanceExpression AS balance FROM accounts a',
      readsFrom: {accounts, transactions},
    ).map((row) => (row.read<String>('id'), Money(row.read<int>('balance'))));
  }

  /// Live balances for all accounts, keyed by account id.
  Stream<Map<String, Money>> watchAccountBalances() =>
      _balances().watch().map(_toMap);

  Future<Map<String, Money>> accountBalances() async =>
      _toMap(await _balances().get());
}

Map<String, Money> _toMap(List<(String, Money)> rows) => {
  for (final (id, money) in rows) id: money,
};
