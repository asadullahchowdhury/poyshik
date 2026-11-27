import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

// Schema v2 (v2 added favourites, recurring rules and the bazar list).
// Conventions:
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

/// How often a recurring rule repeats.
enum RecurrenceFrequency { daily, weekly, monthly, yearly }

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

  /// Set when a recurring rule created this transaction (v2).
  TextColumn get recurringId =>
      text().nullable().references(RecurringRules, #id)();

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

/// One-tap entries ("Rickshaw 50"), shown at the top of the add sheet (v2).
@DataClassName('QuickTemplate')
class QuickTemplates extends Table with _Timestamps {
  TextColumn get id => text().clientDefault(newId)();

  /// Expense or income only.
  TextColumn get type => textEnum<TransactionType>()();
  IntColumn get amount => integer()();
  TextColumn get categoryId => text().references(Categories, #id)();

  /// Null uses the sheet's current account.
  TextColumn get accountId => text().nullable().references(Accounts, #id)();
  TextColumn get note => text().nullable().withLength(max: 500)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (amount > 0)',
    "CHECK (type IN ('expense', 'income'))",
  ];
}

/// Rent, salary, subscriptions: a transaction that repeats (v2).
/// With [autoLog] the app records it when due; otherwise it shows as a bill
/// to confirm with "Mark paid".
@DataClassName('RecurringRule')
class RecurringRules extends Table with _Timestamps {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get type => textEnum<TransactionType>()();
  IntColumn get amount => integer()();
  TextColumn get accountId => text().references(Accounts, #id)();
  @ReferenceName('recurringTransfersIn')
  TextColumn get toAccountId => text().nullable().references(Accounts, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get note => text().nullable().withLength(max: 500)();
  TextColumn get frequency => textEnum<RecurrenceFrequency>()();

  /// Every [interval] units of [frequency] (1 = every month, 3 = quarterly).
  IntColumn get interval => integer().withDefault(const Constant(1))();

  /// Day the schedule is anchored to (keeps "the 31st" stable across months).
  DateTimeColumn get startDate => dateTime()();

  /// The next occurrence not yet logged or paid.
  DateTimeColumn get nextDue => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get autoLog => boolean().withDefault(const Constant(true))();
  BoolColumn get isPaused => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (amount > 0)',
    'CHECK (interval >= 1)',
    "CHECK ((type = 'transfer' AND to_account_id IS NOT NULL "
        'AND category_id IS NULL AND to_account_id <> account_id) '
        "OR (type IN ('expense', 'income') AND category_id IS NOT NULL "
        'AND to_account_id IS NULL))',
  ];
}

/// The shopping list: things to buy, ticked off as you go (v2).
@DataClassName('BazarItem')
class BazarItems extends Table with _Timestamps {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get name => text().withLength(min: 1, max: 80)();

  /// Free text like "2 kg" or "1 dozen".
  TextColumn get quantity => text().nullable().withLength(max: 30)();

  /// Expected price in poisha, if the user noted one.
  IntColumn get estimate => integer().nullable()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (estimate IS NULL OR estimate > 0)',
  ];
}
