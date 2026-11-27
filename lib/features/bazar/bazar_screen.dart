import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme/theme.dart';
import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/poyshik_card.dart';
import '../../core/widgets/section_header.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../transactions/add_transaction_sheet.dart';
import '../transactions/transactions_repository.dart';
import '../voice/voice_sheet.dart';
import 'bazar_repository.dart';

/// The shopping list: a notepad with tick boxes. Add, tick, untick, swipe
/// to delete; clear what's bought or untick all to reuse the list.
class BazarScreen extends ConsumerStatefulWidget {
  const BazarScreen({super.key});

  @override
  ConsumerState<BazarScreen> createState() => _BazarScreenState();
}

class _BazarScreenState extends ConsumerState<BazarScreen> {
  final _input = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    unawaited(HapticFeedback.selectionClick());
    await ref.read(bazarRepositoryProvider).addFromText(text);
    _focus.requestFocus(); // keep typing the next item
  }

  /// Say the whole list at once; each item lands on its own line.
  Future<void> _speak() async {
    final l10n = AppLocalizations.of(context);
    _focus.unfocus();
    final spoken = await showVoiceSheet(context, hint: l10n.bazarVoiceHint);
    if (spoken == null || !mounted) return;
    final added = await ref.read(bazarRepositoryProvider).addFromText(spoken);
    if (!mounted) return;
    unawaited(HapticFeedback.mediumImpact());
    _snack(added == 0 ? l10n.bazarNothingHeard : l10n.bazarAdded(added));
  }

  void _snack(String message, {VoidCallback? undo}) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        successSnackBar(
          context,
          message,
          action: undo == null
              ? null
              : SnackBarAction(label: l10n.txUndo, onPressed: undo),
        ),
      );
  }

  Future<void> _delete(BazarItem item) async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(bazarRepositoryProvider);
    final row = await repo.delete(item.id);
    if (row == null || !mounted) return;
    _snack(l10n.bazarItemDeleted, undo: () => unawaited(repo.restore(row)));
  }

  Future<void> _clearDone() async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(bazarRepositoryProvider);
    final rows = await repo.clearDone();
    if (rows.isEmpty || !mounted) return;
    _snack(
      l10n.bazarCleared(rows.length),
      undo: () => unawaited(repo.restoreAll(rows)),
    );
  }

  /// Opens the add sheet as a Groceries expense, pre-filled with what the
  /// ticked items cost (the user can still correct the total).
  Future<void> _logSpend(List<BazarItem> bought) async {
    final l10n = AppLocalizations.of(context);
    final estimate = bought.fold<int>(0, (sum, b) => sum + (b.estimate ?? 0));
    final categories =
        ref.read(categoriesByUsageProvider(CategoryKind.expense)).value ??
        const [];
    final groceries = categories
        .where((c) => c.systemKey == 'groceries')
        .firstOrNull;
    await showAddTransactionSheet(
      context,
      prefill: (
        type: TransactionType.expense,
        amount: estimate > 0 ? Money(estimate) : null,
        categoryId: groceries?.id,
        note: l10n.bazarExpenseNote,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final items = ref.watch(bazarItemsProvider).value ?? const [];
    final toBuy = items.where((i) => !i.isDone).toList();
    final bought = items.where((i) => i.isDone).toList();
    final estimate = toBuy.fold<int>(0, (s, i) => s + (i.estimate ?? 0));
    final paid = bought.fold<int>(0, (s, i) => s + (i.estimate ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bazarTitle),
        actions: [
          if (items.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (v) => unawaited(
                v == 'clear'
                    ? _clearDone()
                    : ref.read(bazarRepositoryProvider).untickAll(),
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'clear',
                  enabled: bought.isNotEmpty,
                  child: Text(l10n.bazarClearDone),
                ),
                PopupMenuItem(
                  value: 'untick',
                  enabled: bought.isNotEmpty,
                  child: Text(l10n.bazarUntickAll),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.screen,
              Space.sm,
              Space.screen,
              Space.md,
            ),
            child: TextField(
              controller: _input,
              focusNode: _focus,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => unawaited(_add()),
              decoration: InputDecoration(
                hintText: l10n.bazarAddHint,
                prefixIcon: const Icon(Icons.add_rounded),
                // Mic until something is typed, then a send arrow.
                suffixIcon: ValueListenableBuilder(
                  valueListenable: _input,
                  builder: (context, value, _) => value.text.trim().isEmpty
                      ? IconButton(
                          tooltip: l10n.voiceSpeak,
                          icon: Icon(Icons.mic_rounded, color: c.brand),
                          onPressed: () => unawaited(_speak()),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.arrow_upward_rounded,
                            color: c.brand,
                          ),
                          onPressed: () => unawaited(_add()),
                        ),
                ),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: EmptyState(
                      icon: Icons.shopping_basket_outlined,
                      title: l10n.bazarEmptyTitle,
                      message: l10n.bazarEmptyBody,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      Space.screen,
                      0,
                      Space.screen,
                      Space.huge,
                    ),
                    children: [
                      if (toBuy.isNotEmpty) ...[
                        SectionHeader(
                          l10n.bazarToBuy(toBuy.length),
                          trailing: estimate > 0
                              ? Text(
                                  l10n.bazarEstimate(
                                    MoneyFormat.format(Money(estimate)),
                                  ),
                                  style: AppType.caption.copyWith(
                                    color: c.inkMuted,
                                  ),
                                )
                              : null,
                        ),
                        _ItemCard(
                          items: toBuy,
                          onDelete: (i) => unawaited(_delete(i)),
                        ),
                      ],
                      if (bought.isNotEmpty) ...[
                        const SizedBox(height: Space.xl),
                        SectionHeader(
                          paid > 0
                              ? '${l10n.bazarDone} · '
                                    '${l10n.bazarPaid(MoneyFormat.format(Money(paid)))}'
                              : l10n.bazarDone,
                          trailing: SectionAction(
                            label: l10n.bazarLogSpend,
                            onTap: () => unawaited(_logSpend(bought)),
                          ),
                        ),
                        _ItemCard(
                          items: bought,
                          onDelete: (i) => unawaited(_delete(i)),
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

class _ItemCard extends ConsumerWidget {
  const _ItemCard({required this.items, required this.onDelete});

  final List<BazarItem> items;
  final ValueChanged<BazarItem> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final repo = ref.read(bazarRepositoryProvider);
    return PoyshikCard(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.only(left: 56),
                child: Divider(),
              ),
            Dismissible(
              key: ValueKey(items[i].id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: Space.xl),
                color: c.expense.withValues(alpha: 0.12),
                child: Icon(Icons.delete_outline_rounded, color: c.expense),
              ),
              onDismissed: (_) => onDelete(items[i]),
              child: _ItemRow(
                item: items[i],
                onToggle: () {
                  unawaited(HapticFeedback.selectionClick());
                  unawaited(repo.setDone(items[i].id, done: !items[i].isDone));
                },
                onEdit: () => unawaited(
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => _EditItemSheet(item: items[i]),
                  ),
                ),
                onPrice: () => unawaited(
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => _PriceSheet(item: items[i]),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onPrice,
  });

  final BazarItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  /// The price spot: expected before buying (~৳), what was paid after.
  final VoidCallback onPrice;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final done = item.isDone;
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.xs, Space.xxs, Space.lg, 0),
        child: Row(
          children: [
            Checkbox(
              value: done,
              onChanged: (_) => onToggle(),
              activeColor: c.brand,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: Space.xs),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.md),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: AppType.body.copyWith(
                    color: done ? c.inkSubtle : c.ink,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: c.inkSubtle,
                  ),
                  child: Text(item.name),
                ),
              ),
            ),
            if (item.quantity != null)
              Text(
                item.quantity!,
                style: AppType.caption.copyWith(color: c.inkMuted),
              ),
            const SizedBox(width: Space.xs),
            // Its own tap target, so pricing never opens the edit sheet.
            InkWell(
              onTap: onPrice,
              borderRadius: BorderRadius.circular(Radii.sm),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                  child: Center(
                    widthFactor: 1,
                    child: item.estimate == null
                        ? Text(
                            '+${MoneyFormat.symbol}',
                            style: AppType.caption.copyWith(color: c.inkSubtle),
                          )
                        : Text(
                            done
                                ? MoneyFormat.format(Money(item.estimate!))
                                : '~${MoneyFormat.format(Money(item.estimate!))}',
                            style: done
                                ? AppType.label.copyWith(color: c.ink)
                                : AppType.caption.copyWith(color: c.inkMuted),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditItemSheet extends ConsumerStatefulWidget {
  const _EditItemSheet({required this.item});

  final BazarItem item;

  @override
  ConsumerState<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends ConsumerState<_EditItemSheet> {
  late final _name = TextEditingController(text: widget.item.name);
  late final _quantity = TextEditingController(text: widget.item.quantity);
  late final _price = TextEditingController(
    text: widget.item.estimate == null ? '' : '${widget.item.estimate! ~/ 100}',
  );

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.screen,
        Space.sm,
        Space.screen,
        Space.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.bazarEditTitle,
            style: AppType.titleMedium.copyWith(color: c.ink),
          ),
          const SizedBox(height: Space.lg),
          TextField(
            controller: _name,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.bazarName,
              counterText: '',
            ),
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantity,
                  maxLength: 30,
                  decoration: InputDecoration(
                    labelText: l10n.bazarQuantity,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.bazarPrice,
                    prefixText: '${MoneyFormat.symbol} ',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final name = _name.text.trim();
                if (name.isEmpty) return;
                final navigator = Navigator.of(context);
                final taka = int.tryParse(_price.text);
                await ref
                    .read(bazarRepositoryProvider)
                    .update(
                      widget.item.id,
                      name: name,
                      quantity: _quantity.text,
                      estimate: taka == null ? null : Money.taka(taka),
                    );
                navigator.pop();
              },
              child: Text(l10n.commonSave),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick price entry for one item: expected before buying, paid after.
class _PriceSheet extends ConsumerStatefulWidget {
  const _PriceSheet({required this.item});

  final BazarItem item;

  @override
  ConsumerState<_PriceSheet> createState() => _PriceSheetState();
}

class _PriceSheetState extends ConsumerState<_PriceSheet> {
  late final _price = TextEditingController(
    text: widget.item.estimate == null ? '' : '${widget.item.estimate! ~/ 100}',
  );

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  Future<void> _save(Money? price) async {
    final navigator = Navigator.of(context);
    await ref.read(bazarRepositoryProvider).setPrice(widget.item.id, price);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final item = widget.item;
    Money? parsed() {
      final taka = int.tryParse(_price.text);
      return taka == null ? null : Money.taka(taka);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.screen,
        Space.sm,
        Space.screen,
        Space.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.bazarPriceTitle(item.name),
            style: AppType.titleMedium.copyWith(color: c.ink),
          ),
          const SizedBox(height: Space.xs),
          Text(
            item.isDone ? l10n.bazarPriceHelpBought : l10n.bazarPriceHelpToBuy,
            style: AppType.caption.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: Space.lg),
          TextField(
            controller: _price,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppType.amountMedium.copyWith(color: c.ink),
            decoration: InputDecoration(
              prefixText: '${MoneyFormat.symbol} ',
              hintText: '0',
            ),
            onSubmitted: (_) => unawaited(_save(parsed())),
          ),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              if (item.estimate != null)
                TextButton(
                  onPressed: () => unawaited(_save(null)),
                  child: Text(l10n.bazarPriceClear),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () => unawaited(_save(parsed())),
                child: Text(l10n.commonSave),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Home card: what's left to buy. Shown only while the list has items to buy.
class BazarHomeCard extends ConsumerWidget {
  const BazarHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final toBuy = (ref.watch(bazarItemsProvider).value ?? const [])
        .where((i) => !i.isDone)
        .toList();
    final preview = toBuy.take(3).map((i) => i.name).join(' · ');
    final more = toBuy.length - 3;
    return PoyshikCard(
      onTap: () => context.go(Routes.bazar),
      padding: const EdgeInsets.all(Space.lg),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Icon(Icons.shopping_basket_rounded, color: c.accent),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.bazarTitle} · ${l10n.bazarToBuy(toBuy.length)}',
                  style: AppType.bodyStrong.copyWith(color: c.ink),
                ),
                Text(
                  more > 0 ? '$preview  ${l10n.homeBazarMore(more)}' : preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.caption.copyWith(color: c.inkMuted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.inkSubtle),
        ],
      ),
    );
  }
}

/// Whether Home shows the bazar card.
final hasBazarToBuyProvider = Provider<bool>(
  (ref) =>
      (ref.watch(bazarItemsProvider).value ?? const []).any((i) => !i.isDone),
);
