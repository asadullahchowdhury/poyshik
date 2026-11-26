import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money/money.dart';
import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';
import '../../data/settings_repository.dart';
import '../accounts/accounts_repository.dart';
import '../budgets/budget_repository.dart';

/// An extra account chosen during setup.
typedef SetupAccount = ({
  String name,
  AccountType type,
  int colorIndex,
  Money opening,
});

class OnboardingService {
  OnboardingService(this._db);

  final AppDatabase _db;

  /// True for a fresh install: setup not done and nothing logged yet.
  /// Existing users (data but no flag) are marked done instead.
  Future<bool> needsOnboarding() async {
    final settings = SettingsRepository(_db);
    if (await settings.get(SettingKeys.onboardingDone) == 'true') return false;
    final count = countAll();
    final txCount = await (_db.selectOnly(
      _db.transactions,
    )..addColumns([count])).map((r) => r.read(count)!).getSingle();
    final accounts = await _db.select(_db.accounts).get();
    final fresh = txCount == 0 && accounts.length <= 1;
    if (!fresh) await settings.set(SettingKeys.onboardingDone, 'true');
    return fresh;
  }

  /// Applies the setup choices in one transaction.
  Future<void> complete({
    required Money cashOpening,
    required List<SetupAccount> extras,
    Money? monthlyBudget,
  }) {
    return _db.transaction(() async {
      final cash = await (_db.select(
        _db.accounts,
      )..where((a) => a.type.equalsValue(AccountType.cash))).getSingleOrNull();
      if (cash != null) {
        await (_db.update(_db.accounts)..where((a) => a.id.equals(cash.id)))
            .write(AccountsCompanion(openingBalance: Value(cashOpening.minor)));
      }
      final accounts = AccountsRepository(_db);
      for (final a in extras) {
        await accounts.create(
          name: a.name,
          type: a.type,
          colorIndex: a.colorIndex,
          openingBalance: a.opening,
        );
      }
      if (monthlyBudget != null && monthlyBudget.isPositive) {
        await BudgetRepository(_db).setOverall(monthlyBudget);
      }
      await SettingsRepository(_db).set(SettingKeys.onboardingDone, 'true');
    });
  }
}

final onboardingServiceProvider = Provider<OnboardingService>(
  (ref) => OnboardingService(ref.watch(appDatabaseProvider)),
);

/// Whether to show setup. Decided in main.dart before the first frame;
/// false in tests.
final startupNeedsOnboardingProvider = Provider<bool>((ref) => false);

class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(startupNeedsOnboardingProvider);

  void markDone() => state = false;
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);
