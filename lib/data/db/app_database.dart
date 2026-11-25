import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'seed.dart';
import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Accounts, Categories, Transactions, Budgets, AppSettings],
)
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database, or [executor] in tests
  /// (e.g. `NativeDatabase.memory()`).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'poyshik'));

  /// Bump on every schema change, add a migration step, and run
  /// `dart run drift_dev make-migrations` to snapshot the new schema.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedDefaults(this);
    },
    beforeOpen: (details) async {
      // SQLite leaves foreign keys off unless asked, per connection.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
