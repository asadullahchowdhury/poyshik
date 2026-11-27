// Migration safety net. Every released schema is snapshotted in
// drift_schemas/app/ and turned into test helpers under generated/.
// Regenerate both with `dart run drift_dev make-migrations` (docs/DATABASE.md).
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/data/db/app_database.dart';

import 'generated/schema.dart';

/// Tables, columns, constraints and indexes as SQLite sees them, so two
/// databases can be compared regardless of how they were created.
Future<Map<String, Object>> _describe(GeneratedDatabase db) async {
  final objects = await db
      .customSelect(
        "SELECT type, name, sql FROM sqlite_master WHERE name NOT LIKE 'sqlite_%' "
        "AND name <> 'android_metadata' ORDER BY type, name",
      )
      .get();
  final out = <String, Object>{};
  for (final o in objects) {
    final name = o.read<String>('name');
    final type = o.read<String>('type');
    if (type == 'table') {
      final cols = await db.customSelect('PRAGMA table_info("$name")').get();
      out['table $name'] = [
        for (final c in cols)
          '${c.read<String>('name')} ${c.read<String>('type')} '
              'notnull=${c.read<int>('notnull')} pk=${c.read<int>('pk')} '
              'default=${c.readNullable<String>('dflt_value')}',
      ];
      // CHECK constraints live only in the CREATE statement.
      final sql = o.read<String>('sql');
      out['checks $name'] = RegExp(r'CHECK\s*\(').allMatches(sql).length;
    } else {
      out['$type $name'] = o.readNullable<String>('sql') ?? '';
    }
  }
  return out;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('schemaVersion has a snapshot', () async {
    final db = AppDatabase(NativeDatabase.memory());
    expect(GeneratedHelper.versions.last, db.schemaVersion);
    await db.close();
  });

  test('the live schema matches the latest snapshot', () async {
    // Fails when tables.dart changed without a schemaVersion bump and a new
    // snapshot: exactly the change that would break existing installs.
    final latest = GeneratedHelper.versions.last;
    final snapshot = GeneratedHelper().databaseForVersion(
      NativeDatabase.memory(),
      latest,
    );
    await snapshot.customSelect('SELECT 1').get(); // creates the tables
    final live = AppDatabase(NativeDatabase.memory());
    expect(await _describe(live), await _describe(snapshot));
    await live.close();
    await snapshot.close();
  });

  test('every snapshotted version upgrades to the current schema', () async {
    final current = GeneratedHelper.versions.last;
    for (final from in GeneratedHelper.versions) {
      final schema = await verifier.schemaAt(from);
      final migrated = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(migrated, current);
      await migrated.close();
    }
  });

  test('v1 data survives the upgrade to v2', () async {
    final schema = await verifier.schemaAt(1);
    const now = '2026-11-01T10:00:00.000';
    schema.rawDatabase
      ..execute(
        'INSERT INTO accounts (id, name, type, icon, created_at, updated_at) '
        "VALUES ('a1', 'Cash', 'cash', 'cash', '$now', '$now')",
      )
      ..execute(
        'INSERT INTO categories (id, name, kind, icon, created_at, updated_at) '
        "VALUES ('c1', 'Food', 'expense', 'food', '$now', '$now')",
      )
      ..execute(
        'INSERT INTO transactions (id, type, amount, account_id, category_id, '
        "occurred_at, note, created_at, updated_at) VALUES ('t1', 'expense', "
        "5000, 'a1', 'c1', '$now', 'Lunch', '$now', '$now')",
      );

    final db = AppDatabase(schema.newConnection());
    final tx = await db.select(db.transactions).getSingle();
    expect(tx.id, 't1');
    expect(tx.amount, 5000);
    expect(tx.note, 'Lunch');
    expect(tx.recurringId, isNull);
    // The new tables exist and are empty.
    expect(await db.select(db.recurringRules).get(), isEmpty);
    expect(await db.select(db.quickTemplates).get(), isEmpty);
    expect(await db.select(db.bazarItems).get(), isEmpty);
    await db.close();
  });
}
