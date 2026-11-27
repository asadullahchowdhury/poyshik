import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../../core/dates/clock.dart';
import '../../core/dates/periods.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/pill_chip.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../accounts/accounts_repository.dart';
import '../categories/categories_repository.dart';
import '../categories/category_label.dart';
import 'transactions_repository.dart';

/// Search field plus Type / Account / Category / Month chips for Activity.
class ActivityFilterBar extends ConsumerStatefulWidget {
  const ActivityFilterBar({super.key});

  @override
  ConsumerState<ActivityFilterBar> createState() => _ActivityFilterBarState();
}

class _ActivityFilterBarState extends ConsumerState<ActivityFilterBar> {
  late final TextEditingController _search;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: ref.read(activityFilterProvider).query,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  TransactionFilter get _f => ref.read(activityFilterProvider);

  void _update(TransactionFilter f) =>
      ref.read(activityFilterProvider.notifier).set(f);

  void _onQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      final f = _f;
      _update((
        query: q,
        type: f.type,
        accountId: f.accountId,
        categoryId: f.categoryId,
        range: f.range,
      ));
    });
    setState(() {}); // show/hide the clear button
  }

  /// Shows a list of options; returns `(value,)` or null if dismissed, so
  /// choosing "All" (null) is distinguishable from closing the sheet.
  Future<(T?,)?> _pick<T>(
    String title,
    List<(T?, String, Widget?)> options,
    T? selected,
  ) {
    return showModalBottomSheet<(T?,)>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final c = context.colors;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.7,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.screen,
                    0,
                    Space.screen,
                    Space.sm,
                  ),
                  child: Text(
                    title,
                    style: AppType.titleMedium.copyWith(color: c.ink),
                  ),
                ),
                for (final (value, label, leading) in options)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Space.screen,
                    ),
                    leading: leading,
                    title: Text(
                      label,
                      style: AppType.bodyStrong.copyWith(color: c.ink),
                    ),
                    trailing: value == selected
                        ? Icon(Icons.check_rounded, color: c.ink)
                        : null,
                    onTap: () => Navigator.of(context).pop((value,)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final f = ref.watch(activityFilterProvider);
    final now = ref.watch(clockProvider)();
    final accounts = ref.watch(activeAccountsProvider).value ?? const [];
    List<Category> cats(CategoryKind k) =>
        ref.watch(categoryListProvider((kind: k, archived: false))).value ??
        const [];
    final categories = [
      ...cats(CategoryKind.expense),
      ...cats(CategoryKind.income),
    ];

    String typeLabel(TransactionType t) => switch (t) {
      TransactionType.expense => l10n.txExpense,
      TransactionType.income => l10n.txIncome,
      TransactionType.transfer => l10n.txTransfer,
    };
    final accountName = accounts
        .where((a) => a.account.id == f.accountId)
        .firstOrNull
        ?.account
        .name;
    final categoryName = categories
        .where((x) => x.id == f.categoryId)
        .firstOrNull
        ?.label(l10n);
    final months = [
      for (var i = 0; i < 12; i++)
        monthRange(DateTime(now.year, now.month - i)),
    ];

    Widget icon(String key, int color) => CategoryIcon(
      icon: AppIcons.of(key),
      color: PoyshikColors.categoryPalette[color],
      size: 32,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, 0),
      child: Column(
        children: [
          TextField(
            controller: _search,
            onChanged: _onQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.activitySearchHint,
              prefixIcon: Icon(Icons.search_rounded, color: c.inkMuted),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close_rounded, color: c.inkMuted),
                      onPressed: () {
                        _search.clear();
                        _onQuery('');
                      },
                    ),
            ),
            style: AppType.body.copyWith(color: c.ink),
          ),
          const SizedBox(height: Space.sm),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: f.type == null ? l10n.filterType : typeLabel(f.type!),
                  active: f.type != null,
                  onTap: () async {
                    final r = await _pick<TransactionType>(l10n.filterType, [
                      (null, l10n.filterAll, null),
                      for (final t in TransactionType.values)
                        (t, typeLabel(t), null),
                    ], f.type);
                    if (r == null) return;
                    final cur = _f;
                    _update((
                      query: cur.query,
                      type: r.$1,
                      accountId: cur.accountId,
                      categoryId: cur.categoryId,
                      range: cur.range,
                    ));
                  },
                ),
                _FilterChip(
                  label: accountName ?? l10n.filterAccount,
                  active: f.accountId != null,
                  onTap: () async {
                    final r = await _pick<String>(l10n.filterAccount, [
                      (null, l10n.filterAll, null),
                      for (final a in accounts)
                        (
                          a.account.id,
                          a.account.name,
                          icon(a.account.icon, a.account.colorIndex),
                        ),
                    ], f.accountId);
                    if (r == null) return;
                    final cur = _f;
                    _update((
                      query: cur.query,
                      type: cur.type,
                      accountId: r.$1,
                      categoryId: cur.categoryId,
                      range: cur.range,
                    ));
                  },
                ),
                _FilterChip(
                  label: categoryName ?? l10n.filterCategory,
                  active: f.categoryId != null,
                  onTap: () async {
                    final r = await _pick<String>(l10n.filterCategory, [
                      (null, l10n.filterAll, null),
                      for (final x in categories)
                        (x.id, x.label(l10n), icon(x.icon, x.colorIndex)),
                    ], f.categoryId);
                    if (r == null) return;
                    final cur = _f;
                    _update((
                      query: cur.query,
                      type: cur.type,
                      accountId: cur.accountId,
                      categoryId: r.$1,
                      range: cur.range,
                    ));
                  },
                ),
                _FilterChip(
                  label: f.range == null
                      ? l10n.filterMonth
                      : DateFormat('MMM y').format(f.range!.start),
                  active: f.range != null,
                  onTap: () async {
                    final r = await _pick<DateRange>(l10n.filterMonth, [
                      (null, l10n.filterAllTime, null),
                      for (final m in months)
                        (m, DateFormat('MMMM y').format(m.start), null),
                    ], f.range);
                    if (r == null) return;
                    final cur = _f;
                    _update((
                      query: cur.query,
                      type: cur.type,
                      accountId: cur.accountId,
                      categoryId: cur.categoryId,
                      range: r.$1,
                    ));
                  },
                ),
                if (f.isActive)
                  TextButton(
                    onPressed: () {
                      _search.clear();
                      ref.read(activityFilterProvider.notifier).clear();
                      setState(() {});
                    },
                    child: Text(l10n.filterClear),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A filter: a [PillChip] with a dropdown hint, spaced for the chip row.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: Space.sm),
      child: Center(
        child: PillChip(
          label: label,
          selected: active,
          onTap: onTap,
          trailingIcon: Icons.expand_more_rounded,
        ),
      ),
    );
  }
}
