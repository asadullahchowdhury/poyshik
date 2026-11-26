import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../../core/dates/periods.dart';
import '../../core/money/amount_input.dart';
import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../../core/widgets/amount_text.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/balance_text.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/numpad.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../accounts/accounts_repository.dart';
import 'transactions_repository.dart';

/// Opens quick entry over whatever tab is showing. Pass [existing] to edit.
///
/// The 3-second flow: type the amount → tap a category → Save. Account
/// defaults to the last one used, date to now.
Future<void> showAddTransactionSheet(
  BuildContext context, {
  TransactionRecord? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _EntrySheet(existing: existing),
  );
}

class _EntrySheet extends ConsumerStatefulWidget {
  const _EntrySheet({this.existing});

  final TransactionRecord? existing;

  @override
  ConsumerState<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends ConsumerState<_EntrySheet> {
  late TransactionType _type;
  late AmountInput _input;
  String? _categoryId;
  String? _accountId;
  late DateTime _occurredAt;
  late final TextEditingController _note;
  late bool _showNote;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;
  bool get _isIncome => _type == TransactionType.income;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? TransactionType.expense;
    _input = e == null
        ? const AmountInput()
        : AmountInput(
            MoneyFormat.format(
              Money(e.amount),
              withSymbol: false,
            ).replaceAll(',', ''),
          );
    _categoryId = e?.categoryId;
    _accountId = e?.accountId;
    _occurredAt = e?.occurredAt ?? DateTime.now();
    _note = TextEditingController(text: e?.note ?? '');
    _showNote = (e?.note ?? '').isNotEmpty;
    if (_accountId == null) unawaited(_loadDefaultAccount());
  }

  Future<void> _loadDefaultAccount() async {
    final id = await ref
        .read(transactionsRepositoryProvider)
        .defaultAccountId();
    if (mounted && _accountId == null) setState(() => _accountId = id);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _canSave =>
      !_saving &&
      _input.value.isPositive &&
      _categoryId != null &&
      _accountId != null;

  void _setType(TransactionType t) {
    if (t == _type) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _type = t;
      _categoryId = null; // categories differ per kind
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked == null) return;
    final isToday = calendarDaysBetween(picked, now) == 0;
    setState(() {
      _occurredAt = isToday
          ? now
          : DateTime(
              picked.year,
              picked.month,
              picked.day,
              _occurredAt.hour,
              _occurredAt.minute,
            );
    });
  }

  Future<void> _pickAccount() async {
    final l10n = AppLocalizations.of(context);
    final id = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _AccountPicker(
        title: _isIncome ? l10n.txChooseAccountIncome : l10n.txChooseAccount,
        selectedId: _accountId,
      ),
    );
    if (id != null) setState(() => _accountId = id);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(transactionsRepositoryProvider);
    final draft = (
      type: _type,
      amount: _input.value,
      accountId: _accountId!,
      categoryId: _categoryId,
      toAccountId: null,
      occurredAt: _occurredAt,
      note: _note.text,
    );

    String message;
    String? newId;
    if (_isEdit) {
      await repo.update(widget.existing!.id, draft);
      message = l10n.txUpdated;
    } else {
      newId = await repo.add(draft);
      message = _isIncome ? l10n.txSavedIncome : l10n.txSavedExpense;
    }
    unawaited(HapticFeedback.mediumImpact());
    if (mounted) Navigator.of(context).pop();

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$message · ${MoneyFormat.format(draft.amount)}'),
          action: newId == null
              ? null
              : SnackBarAction(
                  label: l10n.txUndo,
                  onPressed: () => unawaited(repo.delete(newId!)),
                ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final kind = _isIncome ? CategoryKind.income : CategoryKind.expense;
    final categories = ref.watch(categoriesByUsageProvider(kind)).value ?? [];
    final accounts = ref.watch(activeAccountsProvider).value ?? [];
    final account = accounts
        .where((a) => a.account.id == _accountId)
        .firstOrNull
        ?.account;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Space.screen,
          0,
          Space.screen,
          Space.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TypeToggle(
              type: _type,
              onChanged: _setType,
              expenseLabel: l10n.txExpense,
              incomeLabel: l10n.txIncome,
            ),
            const SizedBox(height: Space.xl),
            AmountText(
              _input.value,
              size: AmountSize.hero,
              tone: _isIncome ? AmountTone.income : AmountTone.neutral,
              color: _input.isEmpty ? c.inkSubtle : null,
            ),
            const SizedBox(height: Space.xl),
            _CategoryStrip(
              categories: categories,
              selectedId: _categoryId,
              onSelected: (id) {
                unawaited(HapticFeedback.selectionClick());
                setState(() => _categoryId = id);
              },
            ),
            const SizedBox(height: Space.lg),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _InfoChip(
                    icon: account == null
                        ? Icons.account_balance_wallet_outlined
                        : AppIcons.of(account.icon),
                    label: account?.name ?? l10n.txNoAccounts,
                    onTap: () => unawaited(_pickAccount()),
                  ),
                  const SizedBox(width: Space.sm),
                  _InfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: _dateLabel(l10n),
                    onTap: () => unawaited(_pickDate()),
                  ),
                  const SizedBox(width: Space.sm),
                  _InfoChip(
                    icon: Icons.notes_rounded,
                    label: l10n.txAddNote,
                    active: _showNote,
                    onTap: () => setState(() => _showNote = !_showNote),
                  ),
                ],
              ),
            ),
            if (_showNote) ...[
              const SizedBox(height: Space.md),
              TextField(
                controller: _note,
                autofocus: !_isEdit,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: l10n.txNoteHint,
                  counterText: '',
                ),
                style: AppType.body.copyWith(color: c.ink),
              ),
            ],
            const SizedBox(height: Space.lg),
            Numpad(
              onKey: (k) => setState(() => _input = _input.press(k)),
              onBackspace: () => setState(() => _input = _input.backspace()),
              onClear: () => setState(() => _input = _input.clear()),
            ),
            const SizedBox(height: Space.xs),
            PrimaryButton(
              label: _categoryId == null && _input.value.isPositive
                  ? l10n.txPickCategory
                  : l10n.txSave,
              icon: Icons.check_rounded,
              tone: ButtonTone.accent,
              onPressed: _canSave ? () => unawaited(_save()) : null,
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(AppLocalizations l10n) {
    final days = calendarDaysBetween(_occurredAt, DateTime.now());
    if (days == 0) return l10n.txToday;
    if (days == 1) return l10n.txYesterday;
    return DateFormat.MMMd().format(_occurredAt);
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({
    required this.type,
    required this.onChanged,
    required this.expenseLabel,
    required this.incomeLabel,
  });

  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;
  final String expenseLabel;
  final String incomeLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget seg(TransactionType t, String label) {
      final selected = type == t;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? c.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(Radii.sm),
              border: selected ? Border.all(color: c.hairline) : null,
            ),
            child: Text(
              label,
              style: AppType.label.copyWith(
                color: selected ? c.ink : c.inkMuted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(Space.xs),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          seg(TransactionType.expense, expenseLabel),
          seg(TransactionType.income, incomeLabel),
        ],
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 172,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 76,
          crossAxisSpacing: Space.sm,
        ),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          final selected = cat.id == selectedId;
          final color = PoyshikColors.categoryPalette[cat.colorIndex];
          return GestureDetector(
            onTap: () => onSelected(cat.id),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Radii.md + 2),
                    border: Border.all(
                      color: selected ? c.ink : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: CategoryIcon(
                    icon: AppIcons.of(cat.icon),
                    color: color,
                    size: 46,
                  ),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  cat.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.caption.copyWith(
                    color: selected ? c.ink : c.inkMuted,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: active ? c.ink : c.surfaceRaised,
      borderRadius: BorderRadius.circular(Radii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md + 2,
            vertical: Space.sm + 1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: active ? c.onInk : c.ink),
              const SizedBox(width: Space.xs + 2),
              Text(
                label,
                style: AppType.label.copyWith(color: active ? c.onInk : c.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountPicker extends ConsumerWidget {
  const _AccountPicker({required this.title, required this.selectedId});

  final String title;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final accounts = ref.watch(activeAccountsProvider).value ?? [];
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.screen,
              0,
              Space.screen,
              Space.md,
            ),
            child: Text(
              title,
              style: AppType.titleMedium.copyWith(color: c.ink),
            ),
          ),
          for (final item in accounts)
            InkWell(
              onTap: () => Navigator.of(context).pop(item.account.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.screen,
                  vertical: Space.md,
                ),
                child: Row(
                  children: [
                    CategoryIcon(
                      icon: AppIcons.of(item.account.icon),
                      color: PoyshikColors
                          .categoryPalette[item.account.colorIndex],
                      size: 40,
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Text(
                        item.account.name,
                        style: AppType.bodyStrong.copyWith(color: c.ink),
                      ),
                    ),
                    BalanceText(item.balance, size: AmountSize.small),
                    const SizedBox(width: Space.md),
                    Icon(
                      item.account.id == selectedId
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: item.account.id == selectedId
                          ? c.ink
                          : c.inkSubtle,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: Space.lg),
        ],
      ),
    );
  }
}
