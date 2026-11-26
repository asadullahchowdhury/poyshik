import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../../core/money/money.dart';
import '../../core/widgets/amount_text.dart';
import '../../core/widgets/animated_amount.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/balance_text.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/poyshik_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/app_localizations.dart';
import 'account_form_sheet.dart';
import 'account_labels.dart';
import 'accounts_repository.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final active = ref.watch(activeAccountsProvider);
    final archived = ref.watch(archivedAccountsProvider).value ?? const [];
    final total = ref.watch(totalBalanceProvider).value ?? Money.zero;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountsTitle)),
      body: active.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e),
        data: (accounts) => ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            Space.sm,
            Space.screen,
            Space.huge,
          ),
          children: [
            Reveal(
              child: PoyshikCard(
                color: c.hero,
                bordered: false,
                elevated: true,
                radius: Radii.xl,
                padding: const EdgeInsets.all(Space.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.accountsTotalBalance.toUpperCase(),
                      style: AppType.overline.copyWith(color: c.onHeroMuted),
                    ),
                    const SizedBox(height: Space.sm),
                    AnimatedAmountText(
                      total.abs(),
                      size: AmountSize.hero,
                      showSign: total.isNegative,
                      tone: total.isNegative
                          ? AmountTone.expense
                          : AmountTone.neutral,
                      color: c.onHero,
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      l10n.accountsCount(accounts.length),
                      style: AppType.label.copyWith(color: c.onHeroMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.lg),
            Reveal(index: 1, child: _AccountGroup(items: accounts)),
            const SizedBox(height: Space.xl),
            PrimaryButton(
              label: l10n.accountsAdd,
              icon: Icons.add_rounded,
              onPressed: () => unawaited(showAccountFormSheet(context)),
            ),
            if (archived.isNotEmpty) ...[
              const SizedBox(height: Space.xxxl),
              Text(
                l10n.accountsArchived.toUpperCase(),
                style: AppType.overline.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: Space.md),
              Opacity(opacity: 0.6, child: _AccountGroup(items: archived)),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountGroup extends StatelessWidget {
  const _AccountGroup({required this.items});

  final List<AccountWithBalance> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return PoyshikCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.only(left: Space.lg + 44 + Space.md),
                child: Divider(),
              ),
            _AccountRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.item});

  final AccountWithBalance item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final a = item.account;
    return InkWell(
      onTap: () => unawaited(showAccountFormSheet(context, account: a)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.md + 2,
        ),
        child: Row(
          children: [
            CategoryIcon(
              icon: AppIcons.of(a.icon),
              color: PoyshikColors.categoryPalette[a.colorIndex],
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.name,
                    style: AppType.bodyStrong.copyWith(color: c.ink),
                  ),
                  Text(
                    a.type.label(l10n),
                    style: AppType.caption.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
            ),
            BalanceText(item.balance),
          ],
        ),
      ),
    );
  }
}
