import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'schema_versions.dart';
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

  /// Schema changes, in order (see docs/DATABASE.md):
  /// 1. edit tables.dart and bump this number;
  /// 2. `dart run build_runner build` and `dart run drift_dev make-migrations`
  ///    (snapshots the schema, regenerates schema_versions.dart and the
  ///    test helpers under test/drift/);
  /// 3. write the new `fromXToY` step in [migration] below;
  /// 4. extend test/drift/app/migration_test.dart and run the tests.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedDefaults(this);
    },
    // One generated step per version bump; it throws for any upgrade it
    // doesn't know, so a missing step fails loudly instead of corrupting data.
    onUpgrade: stepByStep(),
    beforeOpen: (details) async {
      // SQLite leaves foreign keys off unless asked, per connection.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
