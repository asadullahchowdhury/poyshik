import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates/clock.dart';
import '../../core/dates/periods.dart';
import '../../core/money/money.dart';
import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';
import '../transactions/transactions_repository.dart';
import 'recurrence.dart';

/// A rule with the rows it refers to, ready for display.
typedef RecurringView = ({
  RecurringRule rule,
  Account account,
  Category? category,
});

/// How a new rule repeats (from the add sheet's Repeat option).
typedef RepeatChoice = ({
  RecurrenceFrequency frequency,
  int interval,

  /// Log automatically when due, or remind as a bill to confirm.
  bool autoLog,
});

/// Repeating transactions. Auto-logged rules are written by [catchUp] when
/// the app opens; bills wait for "Mark paid" or "Skip".
class RecurringRepository {
  RecurringRepository(this._db, this._transactions);

  final AppDatabase _db;
  final TransactionsRepository _transactions;

  /// Makes [d] (already saved as [firstId]) repeat. The saved entry is the
  /// first occurrence; the next is due one period later.
  Future<String> createFrom(
    TransactionDraft d,
    RepeatChoice repeat, {
    required String firstId,
  }) async {
    final note = d.note?.trim();
    final rule = await _db
        .into(_db.recurringRules)
        .insertReturning(
          RecurringRulesCompanion.insert(
            type: d.type,
            amount: d.amount.minor,
            accountId: d.accountId,
            toAccountId: Value(d.toAccountId),
            categoryId: Value(d.categoryId),
            note: Value(note == null || note.isEmpty ? null : note),
            frequency: repeat.frequency,
            interval: Value(repeat.interval),
            startDate: d.occurredAt,
            nextDue: occurrence(
              d.occurredAt,
              repeat.frequency,
              repeat.interval,
              1,
            ),
            autoLog: Value(repeat.autoLog),
          ),
        );
    await (_db.update(_db.transactions)..where((t) => t.id.equals(firstId)))
        .write(TransactionsCompanion(recurringId: Value(rule.id)));
    return rule.id;
  }

  /// Logs every auto rule occurrence that has come due by [now], in one
  /// transaction. Returns how many entries were written.
  Future<int> catchUp(DateTime now) {
    return _db.transaction(() async {
      final due =
          await (_db.select(_db.recurringRules)..where(
                (r) =>
                    r.autoLog.equals(true) &
                    r.isPaused.equals(false) &
                    r.nextDue.isSmallerOrEqualValue(now),
              ))
              .get();
      var written = 0;
      for (final rule in due) {
        // At most a year of daily entries per run, as a safety valve.
        final dates = occurrencesBetween(
          rule,
          now.add(const Duration(microseconds: 1)),
        ).take(366).toList();
        for (final at in dates) {
          await _transactions.add(_draft(rule, at), recurringId: rule.id);
          written++;
        }
        final last = dates.isEmpty ? null : dates.last;
        await _advance(rule, after: last ?? rule.nextDue);
      }
      return written;
    });
  }

  /// Records a bill as paid now and moves it to the next period.
  Future<String> markPaid(RecurringRule rule, {required DateTime now}) {
    return _db.transaction(() async {
      final id = await _transactions.add(
        _draft(rule, now),
        recurringId: rule.id,
      );
      await _advance(rule, after: rule.nextDue);
      return id;
    });
  }

  /// Moves past this occurrence without logging it.
  Future<void> skip(RecurringRule rule) => _advance(rule, after: rule.nextDue);

  Future<void> setPaused(String id, {required bool paused}) =>
      (_db.update(_db.recurringRules)..where((r) => r.id.equals(id))).write(
        RecurringRulesCompanion(
          isPaused: Value(paused),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> update(
    String id, {
    required Money amount,
    required bool autoLog,
  }) => (_db.update(_db.recurringRules)..where((r) => r.id.equals(id))).write(
    RecurringRulesCompanion(
      amount: Value(amount.minor),
      autoLog: Value(autoLog),
      updatedAt: Value(DateTime.now()),
    ),
  );

  /// Deletes the rule. Entries it already logged stay, just unlinked.
  Future<void> delete(String id) => _db.transaction(() async {
    await (_db.update(_db.transactions)..where((t) => t.recurringId.equals(id)))
        .write(const TransactionsCompanion(recurringId: Value(null)));
    await (_db.delete(_db.recurringRules)..where((r) => r.id.equals(id))).go();
  });

  /// All rules, soonest first; paused rules last.
  Stream<List<RecurringView>> watchAll() {
    final q =
        _db.select(_db.recurringRules).join([
          innerJoin(
            _db.accounts,
            _db.accounts.id.equalsExp(_db.recurringRules.accountId),
          ),
          leftOuterJoin(
            _db.categories,
            _db.categories.id.equalsExp(_db.recurringRules.categoryId),
          ),
        ])..orderBy([
          OrderingTerm.asc(_db.recurringRules.isPaused),
          OrderingTerm.asc(_db.recurringRules.nextDue),
        ]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          (
            rule: r.readTable(_db.recurringRules),
            account: r.readTable(_db.accounts),
            category: r.readTableOrNull(_db.categories),
          ),
      ],
    );
  }

  Future<void> _advance(RecurringRule rule, {required DateTime after}) async {
    final next = nextOccurrenceAfter(
      rule.startDate,
      rule.frequency,
      rule.interval,
      after,
    );
    final ended = rule.endDate != null && next.isAfter(rule.endDate!);
    await (_db.update(
      _db.recurringRules,
    )..where((r) => r.id.equals(rule.id))).write(
      RecurringRulesCompanion(
        nextDue: Value(next),
        isPaused: ended ? const Value(true) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  static TransactionDraft _draft(RecurringRule r, DateTime at) => (
    type: r.type,
    amount: Money(r.amount),
    accountId: r.accountId,
    categoryId: r.categoryId,
    toAccountId: r.toAccountId,
    occurredAt: at,
    note: r.note,
  );
}

final recurringRepositoryProvider = Provider<RecurringRepository>(
  (ref) => RecurringRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(transactionsRepositoryProvider),
  ),
);

final recurringRulesProvider = StreamProvider<List<RecurringView>>(
  (ref) => ref.watch(recurringRepositoryProvider).watchAll(),
);

/// Active rules due within the next week (bills overdue included), for Home.
final upcomingRecurringProvider = Provider<List<RecurringView>>((ref) {
  final now = ref.watch(clockProvider)();
  final soon = dateOnly(now).add(const Duration(days: 8));
  final all = ref.watch(recurringRulesProvider).value ?? const [];
  return [
    for (final v in all)
      if (!v.rule.isPaused && v.rule.nextDue.isBefore(soon)) v,
  ];
});

/// Expenses still scheduled for the rest of this month, not yet logged
/// (feeds the month-end forecast).
final scheduledExpensesProvider = Provider<Money>((ref) {
  final now = ref.watch(clockProvider)();
  final monthEnd = monthRange(now).end;
  final all = ref.watch(recurringRulesProvider).value ?? const [];
  var total = 0;
  for (final v in all) {
    final r = v.rule;
    if (r.isPaused || r.type != TransactionType.expense) continue;
    // Bills already overdue are still to be paid this month.
    total += r.amount * occurrencesBetween(r, monthEnd).length;
  }
  return Money(total);
});
