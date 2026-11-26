import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money/money.dart';
import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';
import '../../data/settings_repository.dart';

/// The fields of an expense or income entry (transfers come later).
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

  /// Newest first, with account/category joined in. [limit] keeps the list
  /// light; paging can come later if needed.
  Stream<List<TransactionView>> watchViews({int limit = 500}) {
    final toAccounts = _db.alias(_db.accounts, 'to_acc');
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

final transactionViewsProvider = StreamProvider<List<TransactionView>>(
  (ref) => ref.watch(transactionsRepositoryProvider).watchViews(),
);

final categoriesByUsageProvider =
    StreamProvider.family<List<Category>, CategoryKind>(
      (ref, kind) => ref
          .watch(transactionsRepositoryProvider)
          .watchCategoriesByUsage(kind),
    );
