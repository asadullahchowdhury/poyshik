import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/widgets/motion.dart';
import '../../core/widgets/phosphor.dart';
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

/// A floating bar on the page background: a rounded surface with a soft
/// shadow, a pill that glides to the active tab, filled icons for the active
/// tab and outlines for the rest, and a raised marigold add button.
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
    (PhRegular.house, PhFill.house),
    (PhRegular.receipt, PhFill.receipt),
    (PhRegular.chartDonut, PhFill.chartDonut),
    (PhRegular.squaresFour, PhFill.squaresFour),
  ];

  /// Slot of each tab in the five-slot row (the add button is slot 2).
  static const _slots = [0, 1, 3, 4];

  static const _barHeight = 66.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final slot = _slots[currentIndex];

    return ColoredBox(
      color: c.background,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: Space.sm),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.lg,
            Space.md,
            Space.lg,
            Space.xs,
          ),
          child: SizedBox(
            height: _barHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // The bar surface.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(Radii.pill),
                      border: Border.all(color: c.hairline),
                      boxShadow: [
                        BoxShadow(
                          color: c.shadow,
                          blurRadius: 28,
                          offset: const Offset(0, 6),
                          spreadRadius: -12,
                        ),
                      ],
                    ),
                  ),
                ),
                // The active pill, gliding between tabs.
                Positioned.fill(
                  child: AnimatedAlign(
                    duration: Motion.reduced(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 380),
                    curve: Curves.easeOutBack,
                    alignment: Alignment(-1 + slot * 0.5, 0),
                    child: FractionallySizedBox(
                      widthFactor: 0.2,
                      child: Center(
                        child: Container(
                          width: 58,
                          height: 50,
                          decoration: BoxDecoration(
                            color: c.brand.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(Radii.pill),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var s = 0; s < 5; s++)
                      Expanded(
                        child: s == 2
                            ? _AddButton(onAdd, addLabel)
                            : _TabItem(
                                label: labels[_slots.indexOf(s)],
                                icon: _icons[_slots.indexOf(s)].$1,
                                selectedIcon: _icons[_slots.indexOf(s)].$2,
                                selected: slot == s,
                                onTap: () => onTab(_slots.indexOf(s)),
                              ),
                      ),
                  ],
                ),
              ],
            ),
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
    final color = selected ? c.brand : c.inkSubtle;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Pressable(
          scale: 0.9,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: Motion.fast,
                transitionBuilder: (child, a) =>
                    ScaleTransition(scale: a, child: child),
                child: Icon(
                  selected ? selectedIcon : icon,
                  key: ValueKey(selected),
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: Motion.fast,
                style: AppType.caption.copyWith(
                  fontSize: 11,
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(label, maxLines: 1, overflow: TextOverflow.fade),
              ),
            ],
          ),
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
    // Raised above the top edge of the bar, ringed in the page colour.
    return Transform.translate(
      offset: const Offset(0, -14),
      child: Center(
        child: Tooltip(
          message: label,
          child: Pressable(
            scale: 0.92,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.background,
                boxShadow: [
                  BoxShadow(
                    color: c.accent.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                    spreadRadius: -4,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: Material(
                color: c.accent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: Icon(PhBold.plus, color: c.onAccent, size: 24),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
