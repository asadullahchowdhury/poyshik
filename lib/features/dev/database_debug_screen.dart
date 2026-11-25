import 'dart:async';

import 'package:drift/drift.dart' show OrderingTerm, Value, countAll;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../../core/money/money.dart';
import '../../core/widgets/amount_text.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/poyshik_card.dart';
import '../../data/db/app_database.dart';
import '../../data/db/balance_queries.dart';
import '../../data/db/database_provider.dart';

// DEV ONLY: verifies the database on a real device. Not localized.

final _accountsProvider = StreamProvider<List<Account>>(
  (ref) => ref
      .watch(appDatabaseProvider)
      .select(ref.watch(appDatabaseProvider).accounts)
      .watch(),
);

final _categoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.categories)..orderBy([
        (c) => OrderingTerm(expression: c.kind),
        (c) => OrderingTerm(expression: c.sortOrder),
      ]))
      .watch();
});

final _txCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final count = countAll();
  return (db.selectOnly(
    db.transactions,
  )..addColumns([count])).map((row) => row.read(count) ?? 0).watchSingle();
});

final _balancesProvider = StreamProvider<Map<String, Money>>(
  (ref) => ref.watch(appDatabaseProvider).watchAccountBalances(),
);

class DatabaseDebugScreen extends ConsumerWidget {
  const DatabaseDebugScreen({super.key});

  Future<void> _addTestExpense(WidgetRef ref) async {
    final db = ref.read(appDatabaseProvider);
    final cash = await (db.select(db.accounts)..limit(1)).getSingle();
    final food = await (db.select(
      db.categories,
    )..where((c) => c.systemKey.equals('food'))).getSingle();
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: TransactionType.expense,
            amount: 10000,
            accountId: cash.id,
            categoryId: Value(food.id),
            occurredAt: DateTime.now(),
            note: const Value('Debug test expense'),
          ),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final accounts = ref.watch(_accountsProvider);
    final categories = ref.watch(_categoriesProvider);
    final txCount = ref.watch(_txCountProvider);
    final balances = ref.watch(_balancesProvider).value ?? const {};

    Widget stat(String label, AsyncValue<Object> v) => Expanded(
      child: PoyshikCard(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppType.label.copyWith(color: c.inkMuted)),
            const SizedBox(height: Space.xs),
            Text(
              v.when(
                data: (d) => d is List ? '${d.length}' : '$d',
                loading: () => '…',
                error: (e, _) => 'error',
              ),
              style: AppType.amountLarge.copyWith(color: c.ink),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Database')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.screen,
          Space.sm,
          Space.screen,
          Space.huge,
        ),
        children: [
          Row(
            children: [
              stat('Accounts', accounts),
              const SizedBox(width: Space.md),
              stat('Categories', categories),
              const SizedBox(width: Space.md),
              stat('Transactions', txCount),
            ],
          ),
          const SizedBox(height: Space.xl),
          for (final a in accounts.value ?? const <Account>[])
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: PoyshikCard(
                child: Row(
                  children: [
                    CategoryIcon(
                      icon: AppIcons.of(a.icon),
                      color: PoyshikColors.categoryPalette[a.colorIndex],
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Text(
                        a.name,
                        style: AppType.bodyStrong.copyWith(color: c.ink),
                      ),
                    ),
                    AmountText(
                      balances[a.id] ?? Money.zero,
                      size: AmountSize.medium,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: Space.sm),
          FilledButton.icon(
            onPressed: () => unawaited(_addTestExpense(ref)),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add test expense ৳100 (Food, Cash)'),
          ),
          const SizedBox(height: Space.md),
          OutlinedButton(
            onPressed: () => unawaited(
              ref
                  .read(appDatabaseProvider)
                  .delete(ref.read(appDatabaseProvider).transactions)
                  .go(),
            ),
            child: const Text('Delete all transactions'),
          ),
          const SizedBox(height: Space.xxl),
          Text(
            'CATEGORIES',
            style: AppType.overline.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: Space.md),
          for (final cat in categories.value ?? const <Category>[])
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Row(
                children: [
                  CategoryIcon(
                    icon: AppIcons.of(cat.icon),
                    color: PoyshikColors.categoryPalette[cat.colorIndex],
                    size: 36,
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Text(
                      cat.name,
                      style: AppType.body.copyWith(color: c.ink),
                    ),
                  ),
                  Text(
                    cat.kind.name,
                    style: AppType.caption.copyWith(
                      color: cat.kind == CategoryKind.income
                          ? c.income
                          : c.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
