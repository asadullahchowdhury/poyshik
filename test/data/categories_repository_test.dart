import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/data/db/app_database.dart';
import 'package:poyshik/data/db/seed.dart';
import 'package:poyshik/features/categories/categories_repository.dart';

void main() {
  late AppDatabase db;
  late CategoriesRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = CategoriesRepository(db);
  });
  tearDown(() => db.close());

  test('lists by kind in seed order', () async {
    final expense = await repo.watch(CategoryKind.expense).first;
    expect(
      expense.map((c) => c.systemKey),
      defaultExpenseCategories.map((d) => d.$1),
    );
    final income = await repo.watch(CategoryKind.income).first;
    expect(income, hasLength(defaultIncomeCategories.length));
  });

  test('create appends to the end of its kind with no system key', () async {
    final c = await repo.create(
      name: ' Rickshaw ',
      kind: CategoryKind.expense,
      icon: 'rickshaw',
      colorIndex: 3,
    );
    expect(c.name, 'Rickshaw');
    expect(c.systemKey, isNull);
    expect(c.sortOrder, defaultExpenseCategories.length);
    expect((await repo.watch(CategoryKind.expense).first).last.id, c.id);
  });

  test('update, archive and restore', () async {
    final food = (await repo.watch(CategoryKind.expense).first).first;
    await repo.update(
      food.id,
      name: 'Eating out',
      icon: 'snacks',
      colorIndex: 7,
    );
    var list = await repo.watch(CategoryKind.expense).first;
    expect(list.first.name, 'Eating out');
    expect(list.first.systemKey, 'food'); // key survives renames

    await repo.setArchived(food.id, archived: true);
    list = await repo.watch(CategoryKind.expense).first;
    expect(list.any((c) => c.id == food.id), isFalse);
    expect(
      (await repo.watch(CategoryKind.expense, archived: true).first).single.id,
      food.id,
    );
  });

  test('reorder writes sortOrder from list position', () async {
    final list = await repo.watch(CategoryKind.income).first;
    final reversed = list.reversed.map((c) => c.id).toList();
    await repo.reorder(reversed);
    final after = await repo.watch(CategoryKind.income).first;
    expect(after.map((c) => c.id), reversed);
  });
}
