import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates/periods.dart';
import '../../core/money/money.dart';
import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';
import '../../data/settings_repository.dart';

/// Activity search and filters. Every field is optional; empty = everything.
typedef TransactionFilter = ({
  String query,
  TransactionType? type,
  String? accountId,
  String? categoryId,
  DateRange? range,
});

const TransactionFilter noFilter = (
  query: '',
  type: null,
  accountId: null,
  categoryId: null,
  range: null,
);

extension TransactionFilterX on TransactionFilter {
  bool get isActive =>
      query.trim().isNotEmpty ||
      type != null ||
      accountId != null ||
      categoryId != null ||
      range != null;
}

/// The fields of an expense, income or transfer entry.
typedef TransactionDraft = ({
  TransactionType type,
  Money amount,
  String accountId,
  String? categoryId,
  String? toAccountId,
  DateTime occurredAt,
  String? note,
});

/// A transaction with the rows it refers to, ready for display.
typedef TransactionView = ({
  TransactionRecord tx,
  Account account,
  Account? toAccount,
  Category? category,
});

class TransactionsRepository {
  TransactionsRepository(this._db, this._settings);

  final AppDatabase _db;
  final SettingsRepository _settings;

  TransactionsCompanion _companion(TransactionDraft d) {
    final note = d.note?.trim();
    return TransactionsCompanion(
      type: Value(d.type),
      amount: Value(d.amount.minor),
      accountId: Value(d.accountId),
      toAccountId: Value(d.toAccountId),
      categoryId: Value(d.categoryId),
      occurredAt: Value(d.occurredAt),
      note: Value(note == null || note.isEmpty ? null : note),
    );
  }

  /// Saves a new entry and remembers its account as the next default.
  Future<String> add(TransactionDraft d) async {
    final row = await _db.into(_db.transactions).insertReturning(_companion(d));
    await _settings.set(SettingKeys.lastAccountId, d.accountId);
    return row.id;
  }

  Future<void> update(String id, TransactionDraft d) {
    return (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      _companion(d).copyWith(updatedAt: Value(DateTime.now())),
    );
  }

  Future<TransactionRecord?> byId(String id) => (_db.select(
    _db.transactions,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Deletes and returns the row, so the caller can offer undo.
  Future<TransactionRecord?> delete(String id) async {
    final row = await byId(id);
    if (row != null) {
      await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
    }
    return row;
  }

  /// Puts back a row removed by [delete] (same id and timestamps).
  Future<void> restore(TransactionRecord row) =>
      _db.into(_db.transactions).insert(row);

  /// Newest first, with account/category joined in, narrowed by [filter].
  /// [limit] keeps the list light; paging can come later if needed.
  Stream<List<TransactionView>> watchViews({
    TransactionFilter filter = noFilter,
    int limit = 500,
  }) {
    final t = _db.transactions;
    final toAccounts = _db.alias(_db.accounts, 'to_acc');
    final conditions = <Expression<bool>>[
      if (filter.type != null) t.type.equalsValue(filter.type),
      // An account matches money leaving it or (transfers) arriving in it.
      if (filter.accountId != null)
        t.accountId.equals(filter.accountId!) |
            t.toAccountId.equals(filter.accountId!),
      if (filter.categoryId != null) t.categoryId.equals(filter.categoryId!),
      if (filter.range != null) ...[
        t.occurredAt.isBiggerOrEqualValue(filter.range!.start),
        t.occurredAt.isSmallerThanValue(filter.range!.end),
      ],
      ?_searchCondition(filter.query, toAccounts),
    ];

    final query =
        _db.select(_db.transactions).join([
            innerJoin(
              _db.accounts,
              _db.accounts.id.equalsExp(_db.transactions.accountId),
            ),
            leftOuterJoin(
              toAccounts,
              toAccounts.id.equalsExp(_db.transactions.toAccountId),
            ),
            leftOuterJoin(
              _db.categories,
              _db.categories.id.equalsExp(_db.transactions.categoryId),
            ),
          ])
          ..orderBy([
            OrderingTerm.desc(_db.transactions.occurredAt),
            OrderingTerm.desc(_db.transactions.createdAt),
          ])
          ..limit(limit);
    if (conditions.isNotEmpty) {
      query.where(conditions.reduce((a, b) => a & b));
    }
    return query.watch().map(
      (rows) => [
        for (final r in rows)
          (
            tx: r.readTable(_db.transactions),
            account: r.readTable(_db.accounts),
            toAccount: r.readTableOrNull(toAccounts),
            category: r.readTableOrNull(_db.categories),
          ),
      ],
    );
  }

  /// Matches notes, category and account names (case-insensitive), and
  /// amounts: "250" finds ৳250–৳250.99, "250.5" finds exactly ৳250.50.
  Expression<bool>? _searchCondition(String raw, $AccountsTable toAccounts) {
    final q = raw.trim();
    if (q.isEmpty) return null;
    final pattern = '%${q.toLowerCase()}%';
    Expression<bool> like(Expression<String> e) => e.lower().like(pattern);

    var text =
        like(_db.transactions.note) |
        like(_db.categories.name) |
        like(_db.accounts.name) |
        like(toAccounts.name);

    final amount = Money.tryParse(q);
    if (amount != null && amount.isPositive) {
      final a = _db.transactions.amount;
      text |= q.contains('.')
          ? a.equals(amount.minor)
          : a.isBetweenValues(amount.minor, amount.minor + 99);
    }
    return text;
  }

  /// Active categories of [kind], most used first, then by sort order —
  /// so the categories you actually use sit within reach.
  Stream<List<Category>> watchCategoriesByUsage(CategoryKind kind) {
    return _db
        .customSelect(
          'SELECT c.* FROM categories c '
          'LEFT JOIN (SELECT category_id, COUNT(*) AS uses FROM transactions '
          'GROUP BY category_id) u ON u.category_id = c.id '
          'WHERE c.kind = ? AND c.is_archived = 0 '
          'ORDER BY COALESCE(u.uses, 0) DESC, c.sort_order',
          variables: [Variable.withString(kind.name)],
          readsFrom: {_db.categories, _db.transactions},
        )
        .watch()
        .map((rows) => [for (final r in rows) _db.categories.map(r.data)]);
  }

  /// The account to preselect: the last one used if still active,
  /// otherwise the first active account.
  Future<String?> defaultAccountId() async {
    final last = await _settings.get(SettingKeys.lastAccountId);
    final active =
        await (_db.select(_db.accounts)
              ..where((a) => a.isArchived.equals(false))
              ..orderBy([(a) => OrderingTerm(expression: a.sortOrder)]))
            .get();
    if (active.isEmpty) return null;
    return active.any((a) => a.id == last) ? last : active.first.id;
  }
}

final transactionsRepositoryProvider = Provider<TransactionsRepository>(
  (ref) => TransactionsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(settingsRepositoryProvider),
  ),
);

/// All recent transactions (Home "Recent", first-run checks).
final transactionViewsProvider = StreamProvider<List<TransactionView>>(
  (ref) => ref.watch(transactionsRepositoryProvider).watchViews(),
);

/// The Activity tab's current search and filters.
class ActivityFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => noFilter;

  void set(TransactionFilter filter) => state = filter;
  void clear() => state = noFilter;
}

final activityFilterProvider =
    NotifierProvider<ActivityFilterNotifier, TransactionFilter>(
      ActivityFilterNotifier.new,
    );

/// Activity's list: everything, or the filtered result.
final filteredViewsProvider = StreamProvider<List<TransactionView>>((ref) {
  final filter = ref.watch(activityFilterProvider);
  return ref.watch(transactionsRepositoryProvider).watchViews(filter: filter);
});

final categoriesByUsageProvider =
    StreamProvider.family<List<Category>, CategoryKind>(
      (ref, kind) => ref
          .watch(transactionsRepositoryProvider)
          .watchCategoriesByUsage(kind),
    );
