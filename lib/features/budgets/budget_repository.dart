import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates/periods.dart';
import '../../core/money/money.dart';
import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';

/// The single overall monthly budget (category budgets come later and use
/// the same table with a categoryId).
class BudgetRepository {
  BudgetRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$BudgetsTable, Budget> _overall() =>
      _db.select(_db.budgets)..where((b) => b.categoryId.isNull());

  Stream<Money?> watchOverall() => _overall().watch().map(
    (rows) => rows.isEmpty ? null : Money(rows.first.amount),
  );

  /// Sets the overall budget, keeping exactly one row.
  Future<void> setOverall(Money amount) {
    return _db.transaction(() async {
      await (_db.delete(_db.budgets)..where((b) => b.categoryId.isNull())).go();
      await _db
          .into(_db.budgets)
          .insert(BudgetsCompanion.insert(amount: amount.minor));
    });
  }

  Future<void> clearOverall() =>
      (_db.delete(_db.budgets)..where((b) => b.categoryId.isNull())).go();
}

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => BudgetRepository(ref.watch(appDatabaseProvider)),
);

final overallBudgetProvider = StreamProvider<Money?>(
  (ref) => ref.watch(budgetRepositoryProvider).watchOverall(),
);

/// Where the month stands against its budget.
typedef BudgetStatus = ({
  Money budget,
  Money spent,
  Money remaining,

  /// What can be spent each remaining day (including today) to finish on
  /// budget. Zero once over budget.
  Money perDay,
  int daysLeft,

  /// spent / budget; above 1 when over budget.
  double progress,
  bool isOver,
});

BudgetStatus budgetStatus({
  required Money budget,
  required Money spent,
  required DateTime now,
}) {
  final remaining = budget - spent;
  final daysLeft = daysLeftInMonth(now);
  final isOver = remaining.isNegative;
  return (
    budget: budget,
    spent: spent,
    remaining: remaining,
    perDay: isOver || daysLeft == 0 ? Money.zero : remaining.divide(daysLeft),
    daysLeft: daysLeft,
    progress: budget.isPositive ? spent.minor / budget.minor : 0,
    isOver: isOver,
  );
}
