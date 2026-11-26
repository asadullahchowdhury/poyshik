import '../../core/dates/periods.dart';
import '../../core/money/money.dart';
import '../../data/db/app_database.dart';
import 'transactions_repository.dart';

/// Transactions of one calendar day with that day's totals.
/// Transfers move money between accounts, so they count as neither.
typedef DayGroup = ({
  DateTime day,
  List<TransactionView> items,
  Money spent,
  Money earned,
});

/// Groups views (already newest-first) by local calendar day.
List<DayGroup> groupByDay(List<TransactionView> views) {
  final groups = <DayGroup>[];
  for (final v in views) {
    final day = dateOnly(v.tx.occurredAt);
    final amount = Money(v.tx.amount);
    final isExpense = v.tx.type == TransactionType.expense;
    final isIncome = v.tx.type == TransactionType.income;
    if (groups.isNotEmpty && groups.last.day == day) {
      final g = groups.removeLast();
      groups.add((
        day: day,
        items: [...g.items, v],
        spent: isExpense ? g.spent + amount : g.spent,
        earned: isIncome ? g.earned + amount : g.earned,
      ));
    } else {
      groups.add((
        day: day,
        items: [v],
        spent: isExpense ? amount : Money.zero,
        earned: isIncome ? amount : Money.zero,
      ));
    }
  }
  return groups;
}
