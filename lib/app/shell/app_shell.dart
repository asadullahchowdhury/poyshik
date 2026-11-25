import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/transactions/add_transaction_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../theme/theme.dart';

/// Tab scaffold: four tabs with a central add button. Each tab keeps its own
/// navigation stack and scroll position (StatefulShellRoute.indexedStack).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _goTab(int index) {
    // Tapping the active tab again returns it to its root.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      // Back on another tab goes to Home first; back on Home exits.
      canPop: shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTab(0);
      },
      child: Scaffold(
        body: shell,
        bottomNavigationBar: _BottomBar(
          currentIndex: shell.currentIndex,
          onTab: _goTab,
          onAdd: () => showAddTransactionSheet(context),
          labels: [
            l10n.tabHome,
            l10n.tabActivity,
            l10n.tabInsights,
            l10n.tabMore,
          ],
          addLabel: l10n.addTransaction,
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentIndex,
    required this.onTab,
    required this.onAdd,
    required this.labels,
    required this.addLabel,
  });

  final int currentIndex;
  final ValueChanged<int> onTab;
  final VoidCallback onAdd;
  final List<String> labels;
  final String addLabel;

  static const _icons = [
    (Icons.home_outlined, Icons.home_rounded),
    (Icons.receipt_long_outlined, Icons.receipt_long_rounded),
    (Icons.insights_outlined, Icons.insights_rounded),
    (Icons.grid_view_outlined, Icons.grid_view_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget tab(int i) => Expanded(
      child: _TabItem(
        label: labels[i],
        icon: _icons[i].$1,
        selectedIcon: _icons[i].$2,
        selected: currentIndex == i,
        onTap: () => onTab(i),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              tab(0),
              tab(1),
              Expanded(child: Center(child: _AddButton(onAdd, addLabel))),
              tab(2),
              tab(3),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.ink : c.inkSubtle;
    return Semantics(
      selected: selected,
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(
                selected ? selectedIcon : icon,
                key: ValueKey(selected),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: Space.xs),
            Text(
              label,
              style: AppType.caption.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton(this.onTap, this.label);

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: label,
      child: Material(
        color: c.accent,
        borderRadius: BorderRadius.circular(Radii.md + 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.md + 2),
          child: SizedBox(
            width: 52,
            height: 44,
            child: Icon(Icons.add_rounded, color: c.onAccent, size: 28),
          ),
        ),
      ),
    );
  }
}
