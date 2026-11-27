import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/data/db/app_database.dart';
import 'package:poyshik/data/db/seed.dart';
import 'package:poyshik/features/categories/category_label.dart';
import 'package:poyshik/l10n/app_localizations_en.dart';

Category _cat(String name, {String? key}) => Category(
  id: 'id',
  name: name,
  kind: CategoryKind.expense,
  icon: 'more',
  colorIndex: 0,
  sortOrder: 0,
  isArchived: false,
  systemKey: key,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  final l10n = AppLocalizationsEn();

  test('every built-in category has a localized name', () {
    for (final (key, name, _, _) in [
      ...defaultExpenseCategories,
      ...defaultIncomeCategories,
    ]) {
      expect(builtInCategoryName(l10n, key), name, reason: key);
    }
  });

  test('built-ins use the localized name until renamed', () {
    expect(_cat('Food', key: 'food').label(l10n), l10n.catFood);
    expect(_cat('Khabar', key: 'food').label(l10n), 'Khabar');
    expect(_cat('Rickshaw').label(l10n), 'Rickshaw');
  });
}
