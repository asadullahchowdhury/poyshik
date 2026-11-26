// DEMO DATA for screenshots only. Never shipped in the app; never the
// user's real data. Rendered by the real widgets via provider overrides.
import 'package:poyshik/core/dates/periods.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/data/db/app_database.dart';
import 'package:poyshik/data/db/seed.dart';
import 'package:poyshik/features/accounts/accounts_repository.dart';
import 'package:poyshik/features/home/summary_repository.dart';
import 'package:poyshik/features/transactions/transactions_repository.dart';

/// "Now" for every screenshot: Thursday 26 Nov 2026, 7:30 pm.
final demoNow = DateTime(2026, 11, 26, 19, 30);

final _t0 = DateTime(2026);

Account _account(
  String id,
  String name,
  AccountType type,
  String icon,
  int color,
  int openingTaka,
  int order,
) => Account(
  id: id,
  name: name,
  type: type,
  icon: icon,
  colorIndex: color,
  openingBalance: openingTaka * 100,
  currency: 'BDT',
  sortOrder: order,
  isArchived: false,
  createdAt: _t0,
  updatedAt: _t0,
);

final demoAccounts = [
  _account('cash', 'Cash', AccountType.cash, 'cash', 2, 2500, 0),
  _account('bkash', 'bKash', AccountType.mobileWallet, 'wallet', 6, 2200, 1),
  _account('bank', 'City Bank', AccountType.bank, 'bank', 4, 58000, 2),
];

final demoCategories = [
  for (final (i, (key, name, icon, color)) in defaultExpenseCategories.indexed)
    Category(
      id: key,
      name: name,
      kind: CategoryKind.expense,
      icon: icon,
      colorIndex: color,
      sortOrder: i,
      isArchived: false,
      systemKey: key,
      createdAt: _t0,
      updatedAt: _t0,
    ),
  for (final (i, (key, name, icon, color)) in defaultIncomeCategories.indexed)
    Category(
      id: key,
      name: name,
      kind: CategoryKind.income,
      icon: icon,
      colorIndex: color,
      sortOrder: i,
      isArchived: false,
      systemKey: key,
      createdAt: _t0,
      updatedAt: _t0,
    ),
];

int _n = 0;
TransactionRecord _tx(
  TransactionType type,
  int taka,
  DateTime at, {
  String account = 'cash',
  String? category,
  String? to,
  String? note,
}) => TransactionRecord(
  id: 'demo-${_n++}',
  type: type,
  amount: taka * 100,
  accountId: account,
  toAccountId: to,
  categoryId: category,
  occurredAt: at,
  note: note,
  createdAt: at,
  updatedAt: at,
);

/// A believable month in Dhaka, plus last month for comparisons.
final List<TransactionRecord> demoTransactions = () {
  const e = TransactionType.expense;
  final list = <TransactionRecord>[];
  // Deterministic "random" so screenshots are stable.
  var seed = 7;
  int rnd(int lo, int hi) {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return lo + seed % (hi - lo + 1);
  }

  for (final month in [10, 11]) {
    final lastDay = month == 11 ? 26 : 31;
    final scale = month == 10 ? 1.12 : 1.0; // spent a bit more in October
    list
      ..add(
        _tx(
          TransactionType.income,
          65000,
          DateTime(2026, month, 1, 10),
          account: 'bank',
          category: 'salary',
          note: 'Monthly salary',
        ),
      )
      ..add(
        _tx(
          e,
          18000,
          DateTime(2026, month, 2, 9),
          account: 'bank',
          category: 'rent',
          note: 'Flat rent',
        ),
      )
      ..add(
        _tx(
          TransactionType.transfer,
          14000,
          DateTime(2026, month, 3, 12),
          account: 'bank',
          to: 'bkash',
        ),
      )
      ..add(
        _tx(
          e,
          (1450 * scale).round(),
          DateTime(2026, month, 5, 20),
          account: 'bkash',
          category: 'bills',
          note: 'Electricity',
        ),
      )
      ..add(
        _tx(
          e,
          799,
          DateTime(2026, month, 7, 11),
          account: 'bkash',
          category: 'mobile',
          note: 'Internet package',
        ),
      );
    // Weekly cash from the ATM.
    for (final d in [1, 8, 15, 22]) {
      if (d <= lastDay) {
        list.add(
          _tx(
            TransactionType.transfer,
            5200,
            DateTime(2026, month, d, 9, 30),
            account: 'bank',
            to: 'cash',
          ),
        );
      }
    }
    for (var d = 1; d <= lastDay; d++) {
      list.add(
        _tx(
          e,
          (rnd(40, 160) * scale).round(),
          DateTime(2026, month, d, 8, 40),
          category: 'transport',
          note: 'Rickshaw',
        ),
      );
      list.add(
        _tx(
          e,
          (rnd(180, 420) * scale).round(),
          DateTime(2026, month, d, 13, 15),
          category: 'food',
          note: d.isEven ? 'Lunch' : null,
        ),
      );
      if (d % 4 == 0) {
        list.add(
          _tx(
            e,
            (rnd(900, 2600) * scale).round(),
            DateTime(2026, month, d, 18, 30),
            account: 'bkash',
            category: 'groceries',
            note: 'Weekly groceries',
          ),
        );
      }
      if (d % 9 == 0) {
        list.add(
          _tx(
            e,
            (rnd(600, 2400) * scale).round(),
            DateTime(2026, month, d, 17),
            category: 'shopping',
          ),
        );
      }
      if (d % 11 == 0) {
        list.add(
          _tx(
            e,
            (rnd(300, 900) * scale).round(),
            DateTime(2026, month, d, 21),
            category: 'entertainment',
            note: 'Movie night',
          ),
        );
      }
    }
    list.add(
      _tx(
        e,
        (1200 * scale).round(),
        DateTime(2026, month, 14, 16),
        account: 'bkash',
        category: 'health',
        note: 'Pharmacy',
      ),
    );
  }
  // Today's entries, so the Home "Today" tile isn't empty.
  list
    ..add(
      _tx(
        e,
        60,
        DateTime(2026, 11, 26, 17, 5),
        category: 'food',
        note: 'Tea and singara',
      ),
    )
    ..add(
      _tx(
        TransactionType.income,
        4500,
        DateTime(2026, 11, 24, 15),
        account: 'bkash',
        category: 'business',
        note: 'Design gig',
      ),
    );
  return list;
}();

const demoBudget = Money.taka(55000);

// ── Derived values (mirror the real repository queries) ────────────────────
Account _acc(String id) => demoAccounts.firstWhere((a) => a.id == id);
Category? _cat(String? id) =>
    id == null ? null : demoCategories.firstWhere((c) => c.id == id);

final List<TransactionView> demoViews = [
  for (final t in [
    ...demoTransactions,
  ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt)))
    (
      tx: t,
      account: _acc(t.accountId),
      toAccount: t.toAccountId == null ? null : _acc(t.toAccountId!),
      category: _cat(t.categoryId),
    ),
];

List<AccountWithBalance> demoAccountsWithBalances() => [
  for (final a in demoAccounts)
    (
      account: a,
      balance: Money(
        a.openingBalance +
            demoTransactions.fold<int>(0, (sum, t) {
              if (t.accountId == a.id) {
                return sum +
                    (t.type == TransactionType.income ? t.amount : -t.amount);
              }
              if (t.toAccountId == a.id) return sum + t.amount;
              return sum;
            }),
      ),
    ),
];

Iterable<TransactionRecord> _inRange(TransactionType type, DateRange r) =>
    demoTransactions.where((t) => t.type == type && r.contains(t.occurredAt));

Money demoTotal(PeriodQuery q) =>
    Money(_inRange(q.type, q.range).fold(0, (s, t) => s + t.amount));

List<CategoryTotal> demoCategoryTotals(DateRange r, {int? limit}) {
  final sums = <String, int>{};
  for (final t in _inRange(TransactionType.expense, r)) {
    sums[t.categoryId!] = (sums[t.categoryId!] ?? 0) + t.amount;
  }
  final list = [
    for (final e in sums.entries)
      (category: _cat(e.key)!, total: Money(e.value)),
  ]..sort((a, b) => b.total.compareTo(a.total));
  return limit == null ? list : list.take(limit).toList();
}

List<(DateTime, Money)> demoEntries(DateRange r) => [
  for (final t in _inRange(TransactionType.expense, r))
    (t.occurredAt, Money(t.amount)),
];

List<Category> demoCategoriesByUsage(CategoryKind kind) {
  final uses = <String, int>{};
  for (final t in demoTransactions) {
    if (t.categoryId != null) {
      uses[t.categoryId!] = (uses[t.categoryId!] ?? 0) + 1;
    }
  }
  return demoCategories.where((c) => c.kind == kind).toList()..sort((a, b) {
    final u = (uses[b.id] ?? 0).compareTo(uses[a.id] ?? 0);
    return u != 0 ? u : a.sortOrder.compareTo(b.sortOrder);
  });
}
