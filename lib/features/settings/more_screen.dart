import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme/theme.dart';
import '../../core/widgets/poyshik_card.dart';
import '../../l10n/app_localizations.dart';

/// Hub for less frequent destinations: accounts, categories, budget,
/// backup and settings. Developer tools appear only in debug builds.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabMore)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.screen,
          Space.sm,
          Space.screen,
          Space.huge,
        ),
        children: [
          _Group(
            children: [
              _Item(
                icon: Icons.account_balance_wallet_rounded,
                label: l10n.moreAccounts,
                onTap: () => context.go(Routes.accounts),
              ),
              _Item(icon: Icons.category_rounded, label: l10n.moreCategories),
              _Item(icon: Icons.savings_rounded, label: l10n.moreBudget),
            ],
          ),
          const SizedBox(height: Space.lg),
          _Group(
            children: [
              _Item(icon: Icons.cloud_upload_rounded, label: l10n.moreBackup),
              _Item(icon: Icons.tune_rounded, label: l10n.moreSettings),
            ],
          ),
          if (kDebugMode) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.xs,
                Space.xxl,
                0,
                Space.sm,
              ),
              child: Text(
                l10n.moreDeveloper.toUpperCase(),
                style: AppType.overline.copyWith(
                  color: context.colors.inkMuted,
                ),
              ),
            ),
            _Group(
              children: [
                _Item(
                  icon: Icons.palette_rounded,
                  label: l10n.moreDesignSystem,
                  onTap: () => context.go(Routes.gallery),
                ),
                _Item(
                  icon: Icons.storage_rounded,
                  label: l10n.moreDatabase,
                  onTap: () => context.go(Routes.database),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PoyshikCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.only(left: 56),
                child: Divider(),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.lg,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: enabled ? c.ink : c.inkSubtle),
            const SizedBox(width: Space.lg),
            Expanded(
              child: Text(
                label,
                style: AppType.bodyStrong.copyWith(
                  color: enabled ? c.ink : c.inkSubtle,
                ),
              ),
            ),
            if (enabled)
              Icon(Icons.chevron_right_rounded, color: c.inkSubtle)
            else
              Text(
                AppLocalizations.of(context).comingSoon,
                style: AppType.caption.copyWith(color: c.inkSubtle),
              ),
          ],
        ),
      ),
    );
  }
}
