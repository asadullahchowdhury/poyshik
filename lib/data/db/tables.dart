import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

// Schema v1. Conventions:
// - Money columns are INTEGER poisha (never REAL).
// - IDs are UUID v4 text, so data can be merged or synced later.
// - Enums are stored by name (text), so reordering an enum can't corrupt data.
// - Every row has createdAt/updatedAt for future sync.
// - Icons are stored as stable string keys and colors as palette indexes;
//   the UI maps them (see core/widgets/app_icons.dart, PoyshikColors).

const _uuid = Uuid();
String newId() => _uuid.v4();

enum AccountType { cash, bank, mobileWallet, card, other }

enum CategoryKind { expense, income }

enum TransactionType { expense, income, transfer }

mixin _Timestamps on Table {
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
}

@DataClassName('Account')
class Accounts extends Table with _Timestamps {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  TextColumn get type => textEnum<AccountType>()();
  TextColumn get icon => text()();
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();

  /// Balance before the first transaction recorded in Poyshik, in poisha.
  IntColumn get openingBalance => integer().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('BDT'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('Category')
class Categories extends Table with _Timestamps {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  TextColumn get kind => textEnum<CategoryKind>()();
  TextColumn get icon => text()();
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// Stable key for built-in categories ("food"), used to localize their
  /// names later. Null for categories the user created.
  TextColumn get systemKey => text().nullable().unique()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TransactionRecord')
@TableIndex(name: 'idx_transactions_occurred_at', columns: {#occurredAt})
@TableIndex(name: 'idx_transactions_account', columns: {#accountId})
@TableIndex(name: 'idx_transactions_category', columns: {#categoryId})
class Transactions extends Table with _Timestamps {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get type => textEnum<TransactionType>()();

  /// Always positive, in poisha. Direction comes from [type].
  IntColumn get amount => integer()();

  /// Source account (for transfers: the account money leaves).
  @ReferenceName('transactionsFrom')
  TextColumn get accountId => text().references(Accounts, #id)();

  /// Transfers only: the account money arrives in.
  @ReferenceName('transfersIn')
  TextColumn get toAccountId => text().nullable().references(Accounts, #id)();

  /// Expenses and income only.
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get note => text().nullable().withLength(max: 500)();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (amount > 0)',
    "CHECK ((type = 'transfer' AND to_account_id IS NOT NULL "
        'AND category_id IS NULL AND to_account_id <> account_id) '
        "OR (type IN ('expense', 'income') AND category_id IS NOT NULL "
        'AND to_account_id IS NULL))',
  ];
}

/// v1 uses one overall monthly budget (categoryId null); per-category
/// budgets later need no schema change.
@DataClassName('Budget')
class Budgets extends Table with _Timestamps {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  IntColumn get amount => integer()();
  TextColumn get period => text().withDefault(const Constant('monthly'))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (amount > 0)'];
}

/// Key-value settings stored in the database so backups include them.
@DataClassName('AppSetting')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
