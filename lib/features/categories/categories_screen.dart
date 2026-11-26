import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';
import 'categories_repository.dart';
import 'category_form_sheet.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  CategoryKind _kind = CategoryKind.expense;

  /// Local copy while dragging, so the list doesn't jump before the
  /// database write comes back.
  List<Category>? _dragOrder;

  Future<void> _onReorder(List<Category> list, int from, int to) async {
    final items = [...list];
    final moved = items.removeAt(from);
    items.insert(to, moved); // onReorderItem already adjusts `to`
    setState(() => _dragOrder = items);
    unawaited(HapticFeedback.selectionClick());
    await ref.read(categoriesRepositoryProvider).reorder([
      for (final c in items) c.id,
    ]);
    if (mounted) setState(() => _dragOrder = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final active =
        _dragOrder ??
        ref.watch(categoryListProvider((kind: _kind, archived: false))).value ??
        const <Category>[];
    final archived =
        ref.watch(categoryListProvider((kind: _kind, archived: true))).value ??
        const <Category>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.categoriesTitle)),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Space.screen,
              Space.sm,
              Space.screen,
              Space.md,
            ),
            sliver: SliverToBoxAdapter(
              child: SegmentedButton<CategoryKind>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: CategoryKind.expense,
                    label: Text(l10n.txExpense),
                  ),
                  ButtonSegment(
                    value: CategoryKind.income,
                    label: Text(l10n.txIncome),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Space.screen),
            sliver: SliverReorderableList(
              itemCount: active.length,
              onReorderItem: (from, to) =>
                  unawaited(_onReorder(active, from, to)),
              itemBuilder: (context, i) => ReorderableDelayedDragStartListener(
                key: ValueKey(active[i].id),
                index: i,
                child: _CategoryRow(category: active[i], kind: _kind),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Space.screen,
              Space.md,
              Space.screen,
              Space.huge,
            ),
            sliver: SliverList.list(
              children: [
                Text(
                  l10n.categoriesReorderHint,
                  style: AppType.caption.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: Space.xl),
                PrimaryButton(
                  label: l10n.categoriesAdd,
                  icon: Icons.add_rounded,
                  onPressed: () =>
                      unawaited(showCategoryFormSheet(context, kind: _kind)),
                ),
                if (archived.isNotEmpty) ...[
                  const SizedBox(height: Space.xxxl),
                  Text(
                    l10n.accountsArchived.toUpperCase(),
                    style: AppType.overline.copyWith(color: c.inkMuted),
                  ),
                  const SizedBox(height: Space.sm),
                  for (final cat in archived)
                    Opacity(
                      opacity: 0.6,
                      child: _CategoryRow(category: cat, kind: _kind),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.kind});

  final Category category;
  final CategoryKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.background,
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: () => unawaited(
          showCategoryFormSheet(context, kind: kind, category: category),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.sm),
          child: Row(
            children: [
              CategoryIcon(
                icon: AppIcons.of(category.icon),
                color: PoyshikColors.categoryPalette[category.colorIndex],
                size: 40,
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(
                  category.name,
                  style: AppType.bodyStrong.copyWith(color: c.ink),
                ),
              ),
              Icon(Icons.drag_indicator_rounded, color: c.inkSubtle),
            ],
          ),
        ),
      ),
    );
  }
}
