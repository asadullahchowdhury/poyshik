import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../categories/category_label.dart';
import 'budget_repository.dart';

/// Edits the overall monthly budget, or [category]'s monthly limit.
Future<void> showBudgetSheet(BuildContext context, {Category? category}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _BudgetSheet(category: category),
  );
}

class _BudgetSheet extends ConsumerStatefulWidget {
  const _BudgetSheet({this.category});

  final Category? category;

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
    final category = widget.category;
    _current = category == null
        ? ref.read(overallBudgetProvider).value
        : ref.read(categoryLimitsProvider).value?[category.id];
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
    final amount = Money.tryParse(_amount.text)!;
    final repo = ref.read(budgetRepositoryProvider);
    final category = widget.category;
    await (category == null
        ? repo.setOverall(amount)
        : repo.setCategoryLimit(category.id, amount));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    final repo = ref.read(budgetRepositoryProvider);
    final category = widget.category;
    await (category == null
        ? repo.clearOverall()
        : repo.clearCategoryLimit(category.id));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final category = widget.category;
    final forCategory = category != null;
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
                forCategory
                    ? l10n.budgetCategoryTitle(category.label(l10n))
                    : l10n.budgetTitle,
                style: AppType.titleLarge.copyWith(color: c.ink),
              ),
              const SizedBox(height: Space.sm),
              Text(
                forCategory ? l10n.budgetCategoryHelp : l10n.budgetHelp,
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
                  labelText: forCategory
                      ? l10n.budgetCategoryAmount
                      : l10n.budgetAmount,
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
                label: forCategory ? l10n.budgetCategorySave : l10n.budgetSave,
                icon: Icons.check_rounded,
                onPressed: () => unawaited(_save()),
              ),
              if (_current != null) ...[
                const SizedBox(height: Space.md),
                OutlinedButton(
                  onPressed: () => unawaited(_remove()),
                  child: Text(
                    forCategory ? l10n.budgetCategoryRemove : l10n.budgetRemove,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
