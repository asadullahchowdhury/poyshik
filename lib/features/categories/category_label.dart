import '../../data/db/app_database.dart';
import '../../data/db/seed.dart';
import '../../l10n/app_localizations.dart';

/// English names the built-in categories were seeded with, by systemKey.
final Map<String, String> _seededNames = {
  for (final (key, name, _, _) in defaultExpenseCategories) key: name,
  for (final (key, name, _, _) in defaultIncomeCategories) key: name,
};

extension CategoryLabel on Category {
  /// The name to show. Built-in categories follow the app language until
  /// the user renames them; names the user typed are shown as typed.
  String label(AppLocalizations l10n) {
    final key = systemKey;
    if (key == null || _seededNames[key] != name) return name;
    return builtInCategoryName(l10n, key) ?? name;
  }
}

/// Localized name of a built-in category, or null for an unknown key.
String? builtInCategoryName(AppLocalizations l10n, String systemKey) =>
    switch (systemKey) {
      'food' => l10n.catFood,
      'groceries' => l10n.catGroceries,
      'transport' => l10n.catTransport,
      'shopping' => l10n.catShopping,
      'bills' => l10n.catBills,
      'rent' => l10n.catRent,
      'health' => l10n.catHealth,
      'education' => l10n.catEducation,
      'entertainment' => l10n.catEntertainment,
      'mobile' => l10n.catMobile,
      'gifts' => l10n.catGifts,
      'other_expense' => l10n.catOtherExpense,
      'salary' => l10n.catSalary,
      'business' => l10n.catBusiness,
      'gift_income' => l10n.catGiftIncome,
      'other_income' => l10n.catOtherIncome,
      _ => null,
    };
