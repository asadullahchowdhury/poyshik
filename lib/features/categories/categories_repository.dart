import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';

class CategoriesRepository {
  CategoriesRepository(this._db);

  final AppDatabase _db;

  /// Categories of [kind] in the user's order.
  Stream<List<Category>> watch(CategoryKind kind, {bool archived = false}) {
    return (_db.select(_db.categories)
          ..where(
            (c) => c.kind.equalsValue(kind) & c.isArchived.equals(archived),
          )
          ..orderBy([
            (c) => OrderingTerm(expression: c.sortOrder),
            (c) => OrderingTerm(expression: c.createdAt),
          ]))
        .watch();
  }

  Future<Category> create({
    required String name,
    required CategoryKind kind,
    required String icon,
    required int colorIndex,
  }) async {
    final maxOrder = _db.categories.sortOrder.max();
    final last =
        await (_db.selectOnly(_db.categories)
              ..addColumns([maxOrder])
              ..where(_db.categories.kind.equalsValue(kind)))
            .map((r) => r.read(maxOrder))
            .getSingle();
    return _db
        .into(_db.categories)
        .insertReturning(
          CategoriesCompanion.insert(
            name: name.trim(),
            kind: kind,
            icon: icon,
            colorIndex: Value(colorIndex),
            sortOrder: Value((last ?? -1) + 1),
          ),
        );
  }

  Future<void> update(
    String id, {
    required String name,
    required String icon,
    required int colorIndex,
  }) {
    return (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(name.trim()),
        icon: Value(icon),
        colorIndex: Value(colorIndex),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Archived categories keep their transactions but leave the entry sheet.
  Future<void> setArchived(String id, {required bool archived}) {
    return (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        isArchived: Value(archived),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Saves a new order: [orderedIds] index becomes each sortOrder.
  Future<void> reorder(List<String> orderedIds) {
    return _db.batch((b) {
      for (final (i, id) in orderedIds.indexed) {
        b.update(
          _db.categories,
          CategoriesCompanion(sortOrder: Value(i)),
          where: (c) => c.id.equals(id),
        );
      }
    });
  }
}

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => CategoriesRepository(ref.watch(appDatabaseProvider)),
);

typedef CategoryListQuery = ({CategoryKind kind, bool archived});

final categoryListProvider =
    StreamProvider.family<List<Category>, CategoryListQuery>(
      (ref, q) => ref
          .watch(categoriesRepositoryProvider)
          .watch(q.kind, archived: q.archived),
    );
