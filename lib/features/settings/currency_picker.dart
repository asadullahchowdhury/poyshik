import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../../core/money/currency.dart';
import '../../core/money/currency_provider.dart';
import '../../l10n/app_localizations.dart';

/// Localized name of a supported currency.
String currencyName(AppLocalizations l10n, AppCurrency c) => switch (c.code) {
  'BDT' => l10n.currencyBDT,
  'INR' => l10n.currencyINR,
  'PKR' => l10n.currencyPKR,
  'NPR' => l10n.currencyNPR,
  'LKR' => l10n.currencyLKR,
  'USD' => l10n.currencyUSD,
  'EUR' => l10n.currencyEUR,
  'GBP' => l10n.currencyGBP,
  'AED' => l10n.currencyAED,
  'SAR' => l10n.currencySAR,
  'MYR' => l10n.currencyMYR,
  'SGD' => l10n.currencySGD,
  _ => c.code,
};

/// Lets the user pick the app currency; saves on tap.
Future<void> showCurrencyPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _CurrencySheet(),
  );
}

class _CurrencySheet extends ConsumerWidget {
  const _CurrencySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final current = ref.watch(currencyProvider);
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, Space.xxl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            0,
            Space.screen,
            Space.md,
          ),
          child: Text(
            l10n.currencyPickTitle,
            style: AppType.titleLarge.copyWith(color: c.ink),
          ),
        ),
        for (final cur in supportedCurrencies)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Space.screen,
            ),
            leading: SizedBox(
              width: 44,
              child: Text(
                cur.symbol,
                textAlign: TextAlign.center,
                style: AppType.titleMedium.copyWith(color: c.ink),
              ),
            ),
            title: Text(
              currencyName(l10n, cur),
              style: AppType.bodyStrong.copyWith(color: c.ink),
            ),
            subtitle: Text(
              cur.code,
              style: AppType.caption.copyWith(color: c.inkMuted),
            ),
            trailing: cur == current
                ? Icon(Icons.check_rounded, color: c.brand)
                : null,
            selected: cur == current,
            onTap: () {
              Navigator.of(context).pop();
              if (cur != current) {
                ref.read(currencyProvider.notifier).set(cur);
              }
            },
          ),
      ],
    );
  }
}
