import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money/money.dart';
import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';
import '../transactions/transactions_repository.dart';

/// A favourite with its category, ready for a chip ("Rickshaw ৳50").
typedef FavouriteView = ({QuickTemplate template, Category category});

/// One-tap entries for things logged again and again.
class FavouritesRepository {
  FavouritesRepository(this._db, this._transactions);

  final AppDatabase _db;
  final TransactionsRepository _transactions;

  /// Favourites of [type] whose category is still active, in their order.
  Stream<List<FavouriteView>> watch(TransactionType type) {
    final q =
        _db.select(_db.quickTemplates).join([
            innerJoin(
              _db.categories,
              _db.categories.id.equalsExp(_db.quickTemplates.categoryId),
            ),
          ])
          ..where(
            _db.quickTemplates.type.equalsValue(type) &
                _db.categories.isArchived.equals(false),
          )
          ..orderBy([
            OrderingTerm.asc(_db.quickTemplates.sortOrder),
            OrderingTerm.asc(_db.quickTemplates.createdAt),
          ]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          (
            template: r.readTable(_db.quickTemplates),
            category: r.readTable(_db.categories),
          ),
      ],
    );
  }

  /// Saves an expense or income draft as a favourite (date not kept).
  Future<void> addFrom(TransactionDraft d) async {
    assert(d.type != TransactionType.transfer && d.categoryId != null);
    final last = await (_db.selectOnly(
      _db.quickTemplates,
    )..addColumns([_db.quickTemplates.sortOrder.max()])).getSingle();
    final note = d.note?.trim();
    await _db
        .into(_db.quickTemplates)
        .insert(
          QuickTemplatesCompanion.insert(
            type: d.type,
            amount: d.amount.minor,
            categoryId: d.categoryId!,
            note: Value(note == null || note.isEmpty ? null : note),
            sortOrder: Value(
              (last.read(_db.quickTemplates.sortOrder.max()) ?? -1) + 1,
            ),
          ),
        );
  }

  /// True when a favourite with the same type, amount, category and note
  /// already exists (so the "save as favourite" option can hide).
  Future<bool> exists(TransactionDraft d) async {
    final note = d.note?.trim();
    final rows =
        await (_db.select(_db.quickTemplates)..where(
              (t) =>
                  t.type.equalsValue(d.type) &
                  t.amount.equals(d.amount.minor) &
                  t.categoryId.equals(d.categoryId ?? ''),
            ))
            .get();
    return rows.any((r) => (r.note ?? '') == (note ?? ''));
  }

  /// Logs the favourite now, in [accountId] unless it has its own account.
  Future<String> log(QuickTemplate t, {required String accountId}) {
    return _transactions.add((
      type: t.type,
      amount: Money(t.amount),
      accountId: t.accountId ?? accountId,
      categoryId: t.categoryId,
      toAccountId: null,
      occurredAt: DateTime.now(),
      note: t.note,
    ));
  }

  Future<void> remove(String id) =>
      (_db.delete(_db.quickTemplates)..where((t) => t.id.equals(id))).go();
}

final favouritesRepositoryProvider = Provider<FavouritesRepository>(
  (ref) => FavouritesRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(transactionsRepositoryProvider),
  ),
);

final favouritesProvider =
    StreamProvider.family<List<FavouriteView>, TransactionType>(
      (ref, type) => ref.watch(favouritesRepositoryProvider).watch(type),
    );
