import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../../core/widgets/primary_button.dart';
import '../../l10n/app_localizations.dart';
import 'budget_repository.dart';

Future<void> showBudgetSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _BudgetSheet(),
  );
}

class _BudgetSheet extends ConsumerStatefulWidget {
  const _BudgetSheet();

  @override
  ConsumerState<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends ConsumerState<_BudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final Money? _current;

  @override
  void initState() {
    super.initState();
    _current = ref.read(overallBudgetProvider).value;
    _amount = TextEditingController(
      text: _current == null
          ? ''
          : MoneyFormat.format(_current, withSymbol: false).replaceAll(',', ''),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(budgetRepositoryProvider)
        .setOverall(Money.tryParse(_amount.text)!);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    await ref.read(budgetRepositoryProvider).clearOverall();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
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
                l10n.budgetTitle,
                style: AppType.titleLarge.copyWith(color: c.ink),
              ),
              const SizedBox(height: Space.sm),
              Text(
                l10n.budgetHelp,
                style: AppType.body.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: Space.xl),
              TextFormField(
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.budgetAmount,
                  prefixText: '${MoneyFormat.symbol} ',
                ),
                style: AppType.amountMedium.copyWith(color: c.ink),
                validator: (v) {
                  final m = Money.tryParse(v ?? '');
                  return m == null || !m.isPositive ? l10n.budgetInvalid : null;
                },
                onFieldSubmitted: (_) => unawaited(_save()),
              ),
              const SizedBox(height: Space.xxl),
              PrimaryButton(
                label: l10n.budgetSave,
                icon: Icons.check_rounded,
                onPressed: () => unawaited(_save()),
              ),
              if (_current != null) ...[
                const SizedBox(height: Space.md),
                OutlinedButton(
                  onPressed: () => unawaited(_remove()),
                  child: Text(l10n.budgetRemove),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
