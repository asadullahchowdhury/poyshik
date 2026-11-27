import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';
import '../../data/settings_repository.dart';
import 'currency.dart';
import 'money_format.dart';

/// The app currency (a setting). Taka unless the user picked another.
final currencyProvider = NotifierProvider<CurrencyNotifier, AppCurrency>(
  CurrencyNotifier.new,
);

class CurrencyNotifier extends Notifier<AppCurrency> {
  @override
  AppCurrency build() {
    final saved = currencyFor(
      ref.read(initialSettingsProvider)[SettingKeys.currency],
    );
    MoneyFormat.currency = saved;
    return saved;
  }

  /// Switches the display currency. Amounts are not converted.
  void set(AppCurrency currency) {
    MoneyFormat.currency = currency;
    state = currency;
    unawaited(_save(currency));
  }

  Future<void> _save(AppCurrency currency) async {
    await ref
        .read(settingsRepositoryProvider)
        .set(SettingKeys.currency, currency.code);
    // Accounts carry a currency column for future per-account currencies;
    // keep it truthful while the app uses one currency for everything.
    final db = ref.read(appDatabaseProvider);
    await db
        .update(db.accounts)
        .write(AccountsCompanion(currency: Value(currency.code)));
  }
}
