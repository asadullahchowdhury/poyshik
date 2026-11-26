import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates/periods.dart';
import '../../core/money/money.dart';
import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';

typedef CategoryTotal = ({Category category, Money total});

/// Totals for a [type] within a [range].
typedef PeriodQuery = ({TransactionType type, DateRange range});

/// Aggregate queries for the dashboard and insights. All ranges are
/// half-open ([start, end)), matching [DateRange].
class SummaryRepository {
  SummaryRepository(this._db);

  final AppDatabase _db;

  List<Variable<Object>> _rangeVars(DateRange r) => [
    Variable.withDateTime(r.start),
    Variable.withDateTime(r.end),
  ];

  /// Sum of [type] amounts in [range]. Transfers are their own type, so
  /// expense/income totals never include them.
  Stream<Money> watchTotal(TransactionType type, DateRange range) {
    return _db
        .customSelect(
          'SELECT COALESCE(SUM(amount), 0) AS total FROM transactions '
          'WHERE type = ? AND occurred_at >= ? AND occurred_at < ?',
          variables: [Variable.withString(type.name), ..._rangeVars(range)],
          readsFrom: {_db.transactions},
        )
        .watchSingle()
        .map((row) => Money(row.read<int>('total')));
  }

  /// (time, amount) of every [type] entry in [range], for per-day charts.
  /// Bucketed in Dart so days follow local time exactly.
  Stream<List<(DateTime, Money)>> watchEntries(
    TransactionType type,
    DateRange range,
  ) {
    return (_db.selectOnly(_db.transactions)
          ..addColumns([_db.transactions.occurredAt, _db.transactions.amount])
          ..where(
            _db.transactions.type.equalsValue(type) &
                _db.transactions.occurredAt.isBiggerOrEqualValue(range.start) &
                _db.transactions.occurredAt.isSmallerThanValue(range.end),
          ))
        .watch()
        .map(
          (rows) => [
            for (final r in rows)
              (
                r.read(_db.transactions.occurredAt)!,
                Money(r.read(_db.transactions.amount)!),
              ),
          ],
        );
  }

  /// Biggest categories of [type] in [range], largest first.
  Stream<List<CategoryTotal>> watchCategoryTotals(
    DateRange range, {
    TransactionType type = TransactionType.expense,
    int? limit,
  }) {
    return _db
        .customSelect(
          'SELECT c.*, t.total AS total FROM categories c JOIN ('
          '  SELECT category_id, SUM(amount) AS total FROM transactions'
          '  WHERE type = ? AND occurred_at >= ? AND occurred_at < ?'
          '  GROUP BY category_id'
          ') t ON t.category_id = c.id '
          'ORDER BY t.total DESC${limit == null ? '' : ' LIMIT $limit'}',
          variables: [Variable.withString(type.name), ..._rangeVars(range)],
          readsFrom: {_db.transactions, _db.categories},
        )
        .watch()
        .map(
          (rows) => [
            for (final r in rows)
              (
                category: _db.categories.map(r.data),
                total: Money(r.read<int>('total')),
              ),
          ],
        );
  }
}

final summaryRepositoryProvider = Provider<SummaryRepository>(
  (ref) => SummaryRepository(ref.watch(appDatabaseProvider)),
);

final periodTotalProvider = StreamProvider.family<Money, PeriodQuery>(
  (ref, q) => ref.watch(summaryRepositoryProvider).watchTotal(q.type, q.range),
);

final topCategoriesProvider =
    StreamProvider.family<List<CategoryTotal>, DateRange>(
      (ref, range) => ref
          .watch(summaryRepositoryProvider)
          .watchCategoryTotals(range, limit: 4),
    );

/// Every expense category in a range, largest first (Insights donut).
final categoryTotalsProvider =
    StreamProvider.family<List<CategoryTotal>, DateRange>(
      (ref, range) =>
          ref.watch(summaryRepositoryProvider).watchCategoryTotals(range),
    );

/// Expense entries in a range (Insights daily bars).
final expenseEntriesProvider =
    StreamProvider.family<List<(DateTime, Money)>, DateRange>(
      (ref, range) => ref
          .watch(summaryRepositoryProvider)
          .watchEntries(TransactionType.expense, range),
    );

/// Percentage change from [previous] to [current], rounded; null when there
/// is nothing to compare against.
int? percentChange(Money current, Money previous) {
  if (!previous.isPositive) return null;
  return (((current.minor - previous.minor) * 100) / previous.minor).round();
}
