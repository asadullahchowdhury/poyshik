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
import '../../core/widgets/feedback.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/numpad.dart';
import '../../core/widgets/pill_chip.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../accounts/accounts_repository.dart';
import '../categories/category_form_sheet.dart';
import '../categories/category_label.dart';
import '../favourites/favourites_repository.dart';
import '../recurring/recurring_repository.dart';
import '../recurring/recurring_ui.dart';
import '../voice/voice_parser.dart';
import '../voice/voice_sheet.dart';
import 'transactions_repository.dart';

/// Opens quick entry over whatever tab is showing. Pass [existing] to edit.
///
/// The 3-second flow: type the amount → tap a category → Save. Account
/// defaults to the last one used, date to now. Transfers pick From and To
/// accounts instead of a category and never count as spending.
Future<void> showAddTransactionSheet(
  BuildContext context, {
  TransactionRecord? existing,
  EntryPrefill? prefill,
  bool startWithVoice = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _EntrySheet(
      existing: existing,
      prefill: prefill,
      startWithVoice: startWithVoice,
    ),
  );
}

/// Starting values for a new entry (from voice input or the bazar list).
/// Anything null is left for the user to fill in.
typedef EntryPrefill = ({
  TransactionType? type,
  Money? amount,
  String? categoryId,
  String? note,
});

class _EntrySheet extends ConsumerStatefulWidget {
  const _EntrySheet({this.existing, this.prefill, this.startWithVoice = false});

  final TransactionRecord? existing;
  final EntryPrefill? prefill;

  /// Opens listening straight away (long-press on the add button).
  final bool startWithVoice;

  @override
  ConsumerState<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends ConsumerState<_EntrySheet> {
  late TransactionType _type;
  late AmountInput _input;
  String? _categoryId;
  String? _accountId;
  String? _toAccountId;
  late DateTime _occurredAt;
  late final TextEditingController _note;
  late bool _showNote;
  bool _saving = false;

  /// Also keep this entry as a one-tap favourite.
  bool _saveFavourite = false;

  /// How this new entry repeats; null = once.
  RepeatChoice? _repeat;

  bool get _isEdit => widget.existing != null;
  bool get _isIncome => _type == TransactionType.income;
  bool get _isTransfer => _type == TransactionType.transfer;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final pre = widget.prefill;
    _type = e?.type ?? pre?.type ?? TransactionType.expense;
    final startAmount = e != null ? Money(e.amount) : pre?.amount;
    _input = startAmount == null
        ? const AmountInput()
        : AmountInput(_plainAmount(startAmount));
    _categoryId = e?.categoryId ?? pre?.categoryId;
    _accountId = e?.accountId;
    _toAccountId = e?.toAccountId;
    _occurredAt = e?.occurredAt ?? DateTime.now();
    _note = TextEditingController(text: e?.note ?? pre?.note ?? '');
    _showNote = _note.text.isNotEmpty;
    if (_accountId == null) unawaited(_loadDefaultAccount());
    if (widget.startWithVoice) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _voice());
    }
  }

  /// Listens, then fills in whatever was understood. Nothing is saved
  /// until the user checks it and taps Save.
  Future<void> _voice() async {
    final l10n = AppLocalizations.of(context);
    final heard = await showVoiceSheet(context);
    if (heard == null || heard.isEmpty || !mounted) return;
    final repo = ref.read(transactionsRepositoryProvider);
    final categories = [
      ...await repo.categoriesByUsage(CategoryKind.expense),
      ...await repo.categoriesByUsage(CategoryKind.income),
    ];
    if (!mounted) return;
    final e = bestVoiceEntry(
      heard,
      categories: categories,
      names: (c) => c.label(l10n),
    );
    unawaited(HapticFeedback.mediumImpact());
    setState(() {
      final type = e.type ?? (_isTransfer ? TransactionType.expense : _type);
      if (type != _type) {
        _type = type;
        _categoryId = null;
      }
      if (e.amount != null) _input = AmountInput(_plainAmount(e.amount!));
      if (e.categoryId != null) _categoryId = e.categoryId;
      if (e.note != null) {
        _note.text = e.note!;
        _showNote = true;
      }
    });
  }

  /// "1250.5" for the numpad: Latin digits, no grouping, no symbol.
  static String _plainAmount(Money m) {
    final whole = m.minor ~/ 100;
    final frac = m.minor % 100;
    if (frac == 0) return '$whole';
    final f = frac.toString().padLeft(2, '0');
    return '$whole.${f.endsWith('0') ? f[0] : f}';
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

  bool get _transferReady => _toAccountId != null && _toAccountId != _accountId;

  bool get _canSave =>
      !_saving &&
      _input.value.isPositive &&
      _accountId != null &&
      (_isTransfer ? _transferReady : _categoryId != null);

  void _setType(TransactionType t) {
    if (t == _type) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _type = t;
      _categoryId = null; // categories differ per kind
      if (t == TransactionType.transfer && !_transferReady) {
        final accounts = ref.read(activeAccountsProvider).value ?? [];
        _toAccountId = accounts
            .map((a) => a.account.id)
            .where((id) => id != _accountId)
            .firstOrNull;
      }
    });
  }

  void _swapAccounts() {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      final from = _accountId;
      _accountId = _toAccountId;
      _toAccountId = from;
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

  Future<void> _pickAccount({bool target = false}) async {
    final l10n = AppLocalizations.of(context);
    final title = _isTransfer
        ? (target ? l10n.txTo : l10n.txFrom)
        : (_isIncome ? l10n.txChooseAccountIncome : l10n.txChooseAccount);
    final id = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _AccountPicker(
        title: title,
        selectedId: target ? _toAccountId : _accountId,
      ),
    );
    if (id == null) return;
    setState(() {
      if (target) {
        _toAccountId = id;
      } else {
        _accountId = id;
      }
    });
  }

  /// One tap on a favourite logs it now and closes the sheet.
  Future<void> _logFavourite(FavouriteView f) async {
    final accountId = _accountId;
    if (_saving || accountId == null) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(transactionsRepositoryProvider);
    final id = await ref
        .read(favouritesRepositoryProvider)
        .log(f.template, accountId: accountId);
    unawaited(HapticFeedback.mediumImpact());
    if (!mounted) return;
    final name = f.template.note ?? f.category.label(l10n);
    final amount = MoneyFormat.format(Money(f.template.amount));
    final snack = successSnackBar(
      context,
      '${l10n.favLogged(name)} · $amount',
      action: SnackBarAction(
        label: l10n.txUndo,
        onPressed: () => unawaited(repo.delete(id)),
      ),
    );
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(snack);
  }

  Future<void> _removeFavourite(FavouriteView f) async {
    final l10n = AppLocalizations.of(context);
    unawaited(HapticFeedback.mediumImpact());
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.favRemoveTitle),
        content: Text(l10n.favRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonRemove),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(favouritesRepositoryProvider).remove(f.template.id);
    }
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
      categoryId: _isTransfer ? null : _categoryId,
      toAccountId: _isTransfer ? _toAccountId : null,
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
      message = switch (_type) {
        TransactionType.expense => l10n.txSavedExpense,
        TransactionType.income => l10n.txSavedIncome,
        TransactionType.transfer => l10n.txSavedTransfer,
      };
      if (_repeat != null) {
        await ref
            .read(recurringRepositoryProvider)
            .createFrom(draft, _repeat!, firstId: newId);
        if (!mounted) return;
        message = '$message · ${repeatLabel(l10n, _repeat!.frequency)}';
      }
      if (_saveFavourite && !_isTransfer) {
        final favourites = ref.read(favouritesRepositoryProvider);
        if (!await favourites.exists(draft)) await favourites.addFrom(draft);
        message = '$message · ${l10n.favAdded}';
      }
    }
    unawaited(HapticFeedback.mediumImpact());
    if (!mounted) return;
    final snack = successSnackBar(
      context,
      '$message · ${MoneyFormat.format(draft.amount)}',
      action: newId == null
          ? null
          : SnackBarAction(
              label: l10n.txUndo,
              onPressed: () => unawaited(repo.delete(newId!)),
            ),
    );
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(snack);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final kind = _isIncome ? CategoryKind.income : CategoryKind.expense;
    final categories = ref.watch(categoriesByUsageProvider(kind)).value ?? [];
    final accounts = ref.watch(activeAccountsProvider).value ?? [];
    Account? find(String? id) =>
        accounts.where((a) => a.account.id == id).firstOrNull?.account;
    final account = find(_accountId);
    final toAccount = find(_toAccountId);

    final String buttonLabel;
    if (_isTransfer && accounts.length < 2) {
      buttonLabel = l10n.txTransferNeedsTwo;
    } else if (_isTransfer && _toAccountId == _accountId) {
      buttonLabel = l10n.txTransferSame;
    } else if (!_isTransfer && _categoryId == null && _input.value.isPositive) {
      buttonLabel = l10n.txPickCategory;
    } else {
      buttonLabel = l10n.txSave;
    }

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
              labels: (l10n.txExpense, l10n.txIncome, l10n.txTransfer),
            ),
            if (!_isEdit && !_isTransfer)
              _FavouritesRow(
                favourites: ref.watch(favouritesProvider(_type)).value ?? [],
                onTap: (f) => unawaited(_logFavourite(f)),
                onLongPress: (f) => unawaited(_removeFavourite(f)),
              ),
            const SizedBox(height: Space.xl),
            // Each key press gives the amount a tiny settle, like a ledger
            // figure being written; skipped when motion is reduced.
            TweenAnimationBuilder<double>(
              key: ValueKey(_input.text),
              tween: Tween(begin: Motion.reduced(context) ? 1 : 1.035, end: 1),
              duration: Motion.fast,
              curve: Motion.curve,
              builder: (context, s, child) =>
                  Transform.scale(scale: s, child: child),
              child: AmountText(
                _input.value,
                size: AmountSize.hero,
                tone: switch (_type) {
                  TransactionType.expense => AmountTone.neutral,
                  TransactionType.income => AmountTone.income,
                  TransactionType.transfer => AmountTone.transfer,
                },
                color: _input.isEmpty ? c.inkSubtle : null,
              ),
            ),
            const SizedBox(height: Space.xl),
            if (_isTransfer)
              _TransferAccounts(
                from: account,
                to: toAccount,
                fromLabel: l10n.txFrom,
                toLabel: l10n.txTo,
                onFrom: () => unawaited(_pickAccount()),
                onTo: () => unawaited(_pickAccount(target: true)),
                onSwap: _swapAccounts,
              )
            else
              _CategoryStrip(
                kind: kind,
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
                  if (!_isEdit) ...[
                    PillChip(
                      icon: Icons.mic_rounded,
                      label: l10n.voiceSpeak,
                      onTap: () => unawaited(_voice()),
                    ),
                    const SizedBox(width: Space.sm),
                  ],
                  if (!_isTransfer) ...[
                    PillChip(
                      icon: account == null
                          ? Icons.account_balance_wallet_outlined
                          : AppIcons.of(account.icon),
                      label: account?.name ?? l10n.txNoAccounts,
                      onTap: () => unawaited(_pickAccount()),
                    ),
                    const SizedBox(width: Space.sm),
                  ],
                  PillChip(
                    icon: Icons.calendar_today_rounded,
                    label: _dateLabel(l10n),
                    onTap: () => unawaited(_pickDate()),
                  ),
                  const SizedBox(width: Space.sm),
                  PillChip(
                    icon: Icons.notes_rounded,
                    label: l10n.txAddNote,
                    selected: _showNote,
                    onTap: () => setState(() => _showNote = !_showNote),
                  ),
                  if (!_isEdit) ...[
                    const SizedBox(width: Space.sm),
                    PillChip(
                      icon: Icons.event_repeat_rounded,
                      label: _repeat == null
                          ? l10n.txRepeat
                          : repeatLabel(l10n, _repeat!.frequency),
                      selected: _repeat != null,
                      onTap: () async {
                        final choice = await showRepeatSheet(
                          context,
                          current: _repeat,
                          type: _type,
                        );
                        if (mounted) setState(() => _repeat = choice);
                      },
                    ),
                  ],
                  if (!_isEdit && !_isTransfer) ...[
                    const SizedBox(width: Space.sm),
                    PillChip(
                      icon: _saveFavourite
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      label: l10n.favSaveAs,
                      selected: _saveFavourite,
                      onTap: () {
                        unawaited(HapticFeedback.selectionClick());
                        setState(() => _saveFavourite = !_saveFavourite);
                      },
                    ),
                  ],
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
              label: buttonLabel,
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

/// One-tap favourites: tap logs, long-press removes. Hidden when empty.
class _FavouritesRow extends StatelessWidget {
  const _FavouritesRow({
    required this.favourites,
    required this.onTap,
    required this.onLongPress,
  });

  final List<FavouriteView> favourites;
  final ValueChanged<FavouriteView> onTap;
  final ValueChanged<FavouriteView> onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return AnimatedSize(
      duration: Motion.fast,
      curve: Motion.curve,
      alignment: Alignment.topCenter,
      child: favourites.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: Space.md),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: favourites.length,
                  separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
                  itemBuilder: (context, i) => _FavouriteChip(
                    view: favourites[i],
                    label:
                        favourites[i].template.note ??
                        favourites[i].category.label(l10n),
                    onTap: () => onTap(favourites[i]),
                    onLongPress: () => onLongPress(favourites[i]),
                    colors: c,
                  ),
                ),
              ),
            ),
    );
  }
}

class _FavouriteChip extends StatelessWidget {
  const _FavouriteChip({
    required this.view,
    required this.label,
    required this.onTap,
    required this.onLongPress,
    required this.colors,
  });

  final FavouriteView view;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final PoyshikColors colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Pressable(
      scale: 0.95,
      child: Material(
        color: c.surface,
        shape: StadiumBorder(side: BorderSide(color: c.hairline)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CategoryIcon(
                  icon: AppIcons.of(view.category.icon),
                  color:
                      PoyshikColors.categoryPalette[view.category.colorIndex %
                          PoyshikColors.categoryPalette.length],
                  size: 24,
                ),
                const SizedBox(width: Space.sm),
                Text(
                  label,
                  style: AppType.caption.copyWith(
                    color: c.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: Space.xs + 2),
                Text(
                  MoneyFormat.format(Money(view.template.amount)),
                  style: AppType.caption.copyWith(color: c.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({
    required this.type,
    required this.onChanged,
    required this.labels,
  });

  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;

  /// (expense, income, transfer)
  final (String, String, String) labels;

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
          seg(TransactionType.expense, labels.$1),
          seg(TransactionType.income, labels.$2),
          seg(TransactionType.transfer, labels.$3),
        ],
      ),
    );
  }
}

/// From → To account cards with a swap button, shown in place of the
/// category strip for transfers.
class _TransferAccounts extends StatelessWidget {
  const _TransferAccounts({
    required this.from,
    required this.to,
    required this.fromLabel,
    required this.toLabel,
    required this.onFrom,
    required this.onTo,
    required this.onSwap,
  });

  final Account? from;
  final Account? to;
  final String fromLabel;
  final String toLabel;
  final VoidCallback onFrom;
  final VoidCallback onTo;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget card(String label, Account? a, VoidCallback onTap) => Expanded(
      child: Material(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(Radii.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.lg),
          child: Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppType.caption.copyWith(color: c.inkMuted)),
                const SizedBox(height: Space.sm),
                Row(
                  children: [
                    CategoryIcon(
                      icon: AppIcons.of(a?.icon ?? 'wallet'),
                      color: a == null
                          ? c.inkSubtle
                          : PoyshikColors.categoryPalette[a.colorIndex],
                      size: 36,
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        a?.name ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.bodyStrong.copyWith(color: c.ink),
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

    return SizedBox(
      height: 172,
      child: Center(
        child: Row(
          children: [
            card(fromLabel, from, onFrom),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xs),
              child: IconButton(
                onPressed: onSwap,
                icon: Icon(Icons.swap_horiz_rounded, color: c.transfer),
              ),
            ),
            card(toLabel, to, onTo),
          ],
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.kind,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final CategoryKind kind;
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  static const _cell = 76.0;
  static const _height = 172.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tiles = <Widget>[
      for (final cat in categories)
        _CategoryTile(
          label: cat.label(l10n),
          icon: AppIcons.of(cat.icon),
          color: PoyshikColors.categoryPalette[cat.colorIndex],
          selected: cat.id == selectedId,
          onTap: () => onSelected(cat.id),
        ),
      // Create one without leaving the entry: it appears here once saved.
      _CategoryTile(
        label: l10n.categoryNewShort,
        icon: Icons.add_rounded,
        color: context.colors.inkMuted,
        selected: false,
        dashed: true,
        onTap: () => unawaited(showCategoryFormSheet(context, kind: kind)),
      ),
    ];

    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, box) {
          final perRow = (box.maxWidth / _cell).floor().clamp(1, 99);
          // Few categories (income): two centred rows that use the width,
          // instead of a 2x2 block in the corner of a scrolling strip.
          if (tiles.length <= perRow * 2) {
            final firstRow = (tiles.length / 2).ceil();
            final cellWidth = box.maxWidth / perRow;
            Widget row(List<Widget> items) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final t in items) SizedBox(width: cellWidth, child: t),
              ],
            );
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                row(tiles.sublist(0, firstRow)),
                if (tiles.length > firstRow) row(tiles.sublist(firstRow)),
              ],
            );
          }
          return GridView.builder(
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: _cell,
              crossAxisSpacing: Space.sm,
            ),
            itemCount: tiles.length,
            itemBuilder: (context, i) => tiles[i],
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    this.dashed = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final bool dashed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.md + 2),
              border: Border.all(
                color: selected ? c.brand : Colors.transparent,
                width: 2,
              ),
            ),
            child: dashed
                ? Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(48 * 0.32),
                      border: Border.all(color: c.hairline, width: 1.5),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  )
                : CategoryIcon(icon: icon, color: color, size: 48),
          ),
          const SizedBox(height: Space.xs),
          Text(
            label,
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
              style: AppType.titleLarge.copyWith(color: c.ink),
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
                          ? c.brand
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
