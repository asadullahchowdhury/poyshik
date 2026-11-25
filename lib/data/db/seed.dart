import 'package:drift/drift.dart';

import 'app_database.dart';

/// Built-in categories: (systemKey, English name, icon key, palette index).
/// Names are English for now; [Category.systemKey] lets us localize them.
const defaultExpenseCategories = [
  ('food', 'Food', 'restaurant', 0),
  ('groceries', 'Groceries', 'grocery', 2),
  ('transport', 'Transport', 'bus', 4),
  ('shopping', 'Shopping', 'shopping_bag', 6),
  ('bills', 'Bills & utilities', 'receipt', 1),
  ('rent', 'Rent', 'home', 8),
  ('health', 'Health', 'health', 7),
  ('education', 'Education', 'school', 5),
  ('entertainment', 'Entertainment', 'movie', 3),
  ('mobile', 'Mobile & internet', 'phone', 9),
  ('gifts', 'Gifts & giving', 'gift', 10),
  ('other_expense', 'Other', 'more', 11),
];

const defaultIncomeCategories = [
  ('salary', 'Salary', 'work', 2),
  ('business', 'Business', 'store', 4),
  ('gift_income', 'Gifts received', 'gift', 6),
  ('other_income', 'Other income', 'payments', 11),
];

/// Runs once, when the database file is first created.
Future<void> seedDefaults(AppDatabase db) async {
  await db.batch((b) {
    b.insert(
      db.accounts,
      AccountsCompanion.insert(
        name: 'Cash',
        type: AccountType.cash,
        icon: 'cash',
        colorIndex: const Value(2),
      ),
    );
    for (final (i, (key, name, icon, color))
        in defaultExpenseCategories.indexed) {
      b.insert(
        db.categories,
        CategoriesCompanion.insert(
          name: name,
          kind: CategoryKind.expense,
          icon: icon,
          colorIndex: Value(color),
          sortOrder: Value(i),
          systemKey: Value(key),
        ),
      );
    }
    for (final (i, (key, name, icon, color))
        in defaultIncomeCategories.indexed) {
      b.insert(
        db.categories,
        CategoriesCompanion.insert(
          name: name,
          kind: CategoryKind.income,
          icon: icon,
          colorIndex: Value(color),
          sortOrder: Value(i),
          systemKey: Value(key),
        ),
      );
    }
  });
}
