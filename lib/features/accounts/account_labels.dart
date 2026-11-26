import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';

extension AccountTypeLabel on AccountType {
  String label(AppLocalizations l10n) => switch (this) {
    AccountType.cash => l10n.accountTypeCash,
    AccountType.bank => l10n.accountTypeBank,
    AccountType.mobileWallet => l10n.accountTypeMobileWallet,
    AccountType.card => l10n.accountTypeCard,
    AccountType.other => l10n.accountTypeOther,
  };
}

/// Common Bangladeshi accounts offered as one-tap presets when adding one.
/// Brand names only; no logos (trademarks).
const accountPresets = <(String name, AccountType type, int colorIndex)>[
  ('Cash', AccountType.cash, 2),
  ('Bank', AccountType.bank, 4),
  ('bKash', AccountType.mobileWallet, 6),
  ('Nagad', AccountType.mobileWallet, 0),
  ('Rocket', AccountType.mobileWallet, 5),
  ('Card', AccountType.card, 11),
];
