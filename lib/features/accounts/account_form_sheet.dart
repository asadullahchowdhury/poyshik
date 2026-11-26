import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/palette_picker.dart';
import '../../core/widgets/pill_chip.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';
import 'account_labels.dart';
import 'accounts_repository.dart';

/// Add a new account, or edit [account] when given.
Future<void> showAccountFormSheet(BuildContext context, {Account? account}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _AccountFormSheet(account: account),
  );
}

class _AccountFormSheet extends ConsumerStatefulWidget {
  const _AccountFormSheet({this.account});

  final Account? account;

  @override
  ConsumerState<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<_AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _opening;
  late AccountType _type;
  late int _colorIndex;
  bool _saving = false;

  bool get _isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _name = TextEditingController(text: a?.name ?? '');
    _opening = TextEditingController(
      text: a == null || a.openingBalance == 0
          ? ''
          : MoneyFormat.format(
              Money(a.openingBalance),
              withSymbol: false,
            ).replaceAll(',', '').replaceAll(MoneyFormat.minus, '-'),
    );
    _type = a?.type ?? AccountType.mobileWallet;
    _colorIndex = a?.colorIndex ?? 6;
  }

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  void _applyPreset((String, AccountType, int) p) {
    setState(() {
      _name.text = p.$1;
      _type = p.$2;
      _colorIndex = p.$3;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(accountsRepositoryProvider);
    final opening = _opening.text.trim().isEmpty
        ? Money.zero
        : Money.tryParse(_opening.text)!;
    if (_isEdit) {
      await repo.update(
        widget.account!.id,
        name: _name.text,
        type: _type,
        colorIndex: _colorIndex,
        openingBalance: opening,
      );
    } else {
      await repo.create(
        name: _name.text,
        type: _type,
        colorIndex: _colorIndex,
        openingBalance: opening,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _toggleArchive() async {
    final a = widget.account!;
    await ref
        .read(accountsRepositoryProvider)
        .setArchived(a.id, archived: !a.isArchived);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final label = AppType.label.copyWith(color: c.inkMuted);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Space.screen,
          0,
          Space.screen,
          Space.xxl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? l10n.accountEdit : l10n.accountNew,
                style: AppType.titleLarge.copyWith(color: c.ink),
              ),
              if (!_isEdit) ...[
                const SizedBox(height: Space.xl),
                Text(l10n.accountQuickPick, style: label),
                const SizedBox(height: Space.sm),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    for (final p in accountPresets)
                      PillChip(
                        label: p.$1,
                        selected: _name.text == p.$1 && _type == p.$2,
                        onTap: () => _applyPreset(p),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: Space.xl),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                maxLength: 40,
                decoration: InputDecoration(
                  labelText: l10n.accountName,
                  hintText: l10n.accountNameHint,
                  counterText: '',
                ),
                style: AppType.bodyStrong.copyWith(color: c.ink),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.accountNameRequired
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Space.xl),
              Text(l10n.accountType, style: label),
              const SizedBox(height: Space.sm),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  for (final t in AccountType.values)
                    PillChip(
                      label: t.label(l10n),
                      icon: AppIcons.of(iconForAccountType(t)),
                      selected: _type == t,
                      onTap: () => setState(() => _type = t),
                    ),
                ],
              ),
              const SizedBox(height: Space.xl),
              Text(l10n.accountColor, style: label),
              const SizedBox(height: Space.sm),
              PalettePicker(
                selected: _colorIndex,
                onChanged: (i) => setState(() => _colorIndex = i),
              ),
              const SizedBox(height: Space.xl),
              TextFormField(
                controller: _opening,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.accountOpeningBalance,
                  prefixText: '${MoneyFormat.symbol} ',
                  helperText: l10n.accountOpeningBalanceHelp,
                ),
                style: AppType.amountMedium.copyWith(color: c.ink),
                validator: (v) =>
                    (v == null || v.trim().isEmpty || Money.tryParse(v) != null)
                    ? null
                    : l10n.accountOpeningBalanceInvalid,
              ),
              const SizedBox(height: Space.xxl),
              PrimaryButton(
                label: l10n.accountSave,
                icon: Icons.check_rounded,
                onPressed: _saving ? null : () => unawaited(_save()),
              ),
              if (_isEdit) ...[
                const SizedBox(height: Space.md),
                OutlinedButton.icon(
                  onPressed: () => unawaited(_toggleArchive()),
                  icon: Icon(
                    widget.account!.isArchived
                        ? Icons.unarchive_rounded
                        : Icons.archive_rounded,
                    size: 20,
                  ),
                  label: Text(
                    widget.account!.isArchived
                        ? l10n.accountUnarchive
                        : l10n.accountArchive,
                  ),
                ),
                const SizedBox(height: Space.sm),
                Text(
                  l10n.accountArchiveHint,
                  style: AppType.caption.copyWith(color: c.inkMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
