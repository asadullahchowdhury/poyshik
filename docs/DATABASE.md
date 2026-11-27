# Database

Drift (SQLite), defined in `lib/data/db/tables.dart`. The file lives on the
phone and holds real user data, so every change must keep existing installs
and existing backup files working.

## Rules

- Money is `INTEGER` minor units (poisha, paise, cents). Never `REAL`.
- IDs are UUID v4 text; enums are stored by name. Never rename an enum value
  or a `SettingKeys` key: both live in user data and in backups.
- Account balances are computed (`BalanceQueries.balanceExpression`), never
  stored.
- Budgets: one row with `category_id IS NULL` is the overall monthly budget;
  one row per category is that category's monthly limit.
- The app currency is a setting (`currency`); amounts are never converted.
  `accounts.currency` mirrors it for future per-account currencies.
- Built-in categories carry a `system_key`; the UI shows a translated name
  until the user renames them (`category_label.dart`).

## Changing the schema

1. Edit `tables.dart` and bump `schemaVersion` in `app_database.dart`.
2. `dart run build_runner build`
3. `dart run drift_dev make-migrations`: snapshots the new schema into
   `drift_schemas/app/`, regenerates `lib/data/db/schema_versions.dart` and
   the helpers in `test/drift/app/generated/`.
4. In `app_database.dart`, pass the new `fromXToY` step to `stepByStep(...)`.
5. Add a data check to `test/drift/app/migration_test.dart` (rows written at
   the old version survive the upgrade), then run `flutter test`.
6. Backups: `BackupService` refuses files whose `schemaVersion` is newer than
   the app. If a column is renamed or removed, convert older backup rows in
   `BackupService.inspect` before they are parsed.

The migration test fails if `tables.dart` changes without steps 1 to 4.
