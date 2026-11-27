import 'dart:async';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/widgets/motion.dart';
import '../../core/widgets/phosphor.dart';
import '../../features/recurring/recurring_ui.dart';
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
      child: AppTasks(
        child: Scaffold(
          body: shell,
          bottomNavigationBar: _BottomBar(
            currentIndex: shell.currentIndex,
            onTab: _goTab,
            onAdd: () => showAddTransactionSheet(context),
            onAddLongPress: () =>
                showAddTransactionSheet(context, startWithVoice: true),
            labels: [
              l10n.tabHome,
              l10n.tabActivity,
              l10n.tabInsights,
              l10n.tabMore,
            ],
            addLabel: l10n.addTransaction,
          ),
        ),
      ),
    );
  }
}

/// A floating bar on the page background. The active tab is a solid brand
/// pill showing its icon and label; the other tabs are icons only. Widths
/// animate together, so the pill appears to glide and stretch between tabs.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentIndex,
    required this.onTab,
    required this.onAdd,
    required this.onAddLongPress,
    required this.labels,
    required this.addLabel,
  });

  final int currentIndex;
  final ValueChanged<int> onTab;
  final VoidCallback onAdd;

  /// Long-press: add by voice.
  final VoidCallback onAddLongPress;
  final List<String> labels;
  final String addLabel;

  static const _icons = [
    (PhRegular.house, PhFill.house),
    (PhRegular.receipt, PhFill.receipt),
    (PhRegular.chartDonut, PhFill.chartDonut),
    (PhRegular.squaresFour, PhFill.squaresFour),
  ];

  static const _barHeight = 66.0;
  static const _addSlot = 64.0;
  static const _inset = 7.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final duration = Motion.reduced(context)
        ? Duration.zero
        : const Duration(milliseconds: 420);

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
              child: Padding(
                padding: const EdgeInsets.all(_inset),
                child: LayoutBuilder(
                  builder: (context, box) {
                    // Each side of the add button is always the same width,
                    // so the button never moves. On the active tab's side the
                    // pill takes most of the room and its neighbour keeps
                    // enough for an icon; the other side splits evenly.
                    final side = (box.maxWidth - _addSlot) / 2;
                    const iconRoom = 38.0;
                    double width(int i) {
                      final sameSide = (i < 2) == (currentIndex < 2);
                      if (!sameSide) return side / 2;
                      return i == currentIndex ? side - iconRoom : iconRoom;
                    }

                    Widget tab(int i) => _TabItem(
                      width: width(i),
                      duration: duration,
                      label: labels[i],
                      icon: _icons[i].$1,
                      selectedIcon: _icons[i].$2,
                      selected: i == currentIndex,
                      onTap: () => onTab(i),
                    );
                    return Row(
                      children: [
                        tab(0),
                        tab(1),
                        SizedBox(
                          width: _addSlot,
                          child: _AddButton(onAdd, onAddLongPress, addLabel),
                        ),
                        tab(2),
                        tab(3),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.width,
    required this.duration,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final Duration duration;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const curve = Curves.easeOutCubic;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        // Inactive tabs are icons only; a long press names them.
        message: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: duration,
            curve: curve,
            width: width,
            alignment: Alignment.center,
            child: Pressable(
              scale: 0.92,
              child: AnimatedContainer(
                duration: duration,
                curve: curve,
                height: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: selected ? 10 : 0),
                decoration: BoxDecoration(
                  color: selected ? c.brand : c.brand.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: Motion.fast,
                      transitionBuilder: (child, a) =>
                          ScaleTransition(scale: a, child: child),
                      child: Icon(
                        selected ? selectedIcon : icon,
                        key: ValueKey(selected),
                        color: selected ? c.onBrand : c.inkSubtle,
                        size: 24,
                      ),
                    ),
                    // The label unfolds beside the icon on the active tab only.
                    Flexible(
                      child: AnimatedSize(
                        duration: duration,
                        curve: curve,
                        child: selected
                            ? Padding(
                                padding: const EdgeInsets.only(left: 6),
                                // Shrinks a little rather than cutting a long
                                // label (Bangla words run wider).
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: AppType.caption.copyWith(
                                      fontSize: 13,
                                      color: c.onBrand,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton(this.onTap, this.onLongPress, this.label);

  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Raised above the top edge of the bar, ringed in the page colour.
    return Transform.translate(
      offset: const Offset(0, -20),
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
                  onLongPress: () {
                    unawaited(HapticFeedback.mediumImpact());
                    onLongPress();
                  },
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
