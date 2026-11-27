import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../../core/dates/clock.dart';
import '../../core/dates/periods.dart';
import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../../core/widgets/amount_text.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/poyshik_card.dart';
import '../../core/widgets/section_header.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../categories/category_label.dart';
import '../home/summary_repository.dart';
import '../reminders/reminders.dart';
import 'recurring_repository.dart';

// ---------------------------------------------------------------- labels --

String repeatLabel(AppLocalizations l10n, RecurrenceFrequency f) => switch (f) {
  RecurrenceFrequency.daily => l10n.repeatDaily,
  RecurrenceFrequency.weekly => l10n.repeatWeekly,
  RecurrenceFrequency.monthly => l10n.repeatMonthly,
  RecurrenceFrequency.yearly => l10n.repeatYearly,
};

String _title(AppLocalizations l10n, RecurringView v) =>
    v.rule.note ??
    (v.rule.type == TransactionType.transfer
        ? v.account.name
        : v.category?.label(l10n) ?? '?');

/// "Due today", "Due 5 Dec", "Overdue since 1 Dec", "Logs automatically …".
String dueLabel(AppLocalizations l10n, RecurringRule r, DateTime now) {
  final date = DateFormat.MMMd().format(r.nextDue);
  if (r.autoLog) return l10n.dueAuto(date);
  final days = calendarDaysBetween(now, r.nextDue);
  if (days == 0) return l10n.dueToday;
  if (days < 0) return l10n.dueOverdue(date);
  return l10n.dueOn(date);
}

// ---------------------------------------------------- repeat picker sheet --

/// Asks how an entry repeats. Returns null for "doesn't repeat"; returns
/// [current] unchanged if the sheet is dismissed.
Future<RepeatChoice?> showRepeatSheet(
  BuildContext context, {
  required RepeatChoice? current,
  required TransactionType type,
}) async {
  final result = await showModalBottomSheet<(RepeatChoice?,)>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _RepeatSheet(current: current, type: type),
  );
  return result == null ? current : result.$1;
}

class _RepeatSheet extends StatefulWidget {
  const _RepeatSheet({required this.current, required this.type});

  final RepeatChoice? current;
  final TransactionType type;

  @override
  State<_RepeatSheet> createState() => _RepeatSheetState();
}

class _RepeatSheetState extends State<_RepeatSheet> {
  late RecurrenceFrequency? _frequency = widget.current?.frequency;
  // Salary-like income logs itself; expenses default to bills you confirm.
  late bool _autoLog =
      widget.current?.autoLog ?? widget.type != TransactionType.expense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    Widget option(RecurrenceFrequency? f, String label) {
      final selected = _frequency == f;
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: AppType.body.copyWith(color: c.ink)),
        trailing: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? c.brand : c.inkSubtle,
        ),
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          setState(() => _frequency = f);
        },
      );
    }

    Widget mode(bool auto, String title, String body) {
      final selected = _autoLog == auto;
      return Expanded(
        child: PoyshikCard(
          padding: const EdgeInsets.all(Space.md),
          color: selected ? c.brand.withValues(alpha: 0.08) : null,
          onTap: () => setState(() => _autoLog = auto),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                auto ? Icons.autorenew_rounded : Icons.receipt_long_rounded,
                color: selected ? c.brand : c.inkSubtle,
              ),
              const SizedBox(height: Space.sm),
              Text(title, style: AppType.label.copyWith(color: c.ink)),
              const SizedBox(height: Space.xxs),
              Text(body, style: AppType.caption.copyWith(color: c.inkMuted)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.sm,
        Space.screen,
        Space.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.repeatTitle,
            style: AppType.titleMedium.copyWith(color: c.ink),
          ),
          const SizedBox(height: Space.sm),
          option(null, l10n.repeatNever),
          for (final f in RecurrenceFrequency.values)
            option(f, repeatLabel(l10n, f)),
          if (_frequency != null &&
              widget.type != TransactionType.transfer) ...[
            const SizedBox(height: Space.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                mode(false, l10n.repeatBillTitle, l10n.repeatBillBody),
                const SizedBox(width: Space.md),
                mode(true, l10n.repeatAutoTitle, l10n.repeatAutoBody),
              ],
            ),
          ],
          const SizedBox(height: Space.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop<(RepeatChoice?,)>(context, (
                _frequency == null
                    ? null
                    : (
                        frequency: _frequency!,
                        interval: 1,
                        // Transfers between own accounts just happen.
                        autoLog:
                            widget.type == TransactionType.transfer || _autoLog,
                      ),
              )),
              child: Text(l10n.repeatDone),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ rows --

class _RuleTile extends StatelessWidget {
  const _RuleTile({
    required this.view,
    required this.subtitle,
    this.onTap,
    this.actions,
    this.dimmed = false,
  });

  final RecurringView view;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? actions;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final r = view.rule;
    final isTransfer = r.type == TransactionType.transfer;
    final color = isTransfer
        ? c.transfer
        : PoyshikColors.categoryPalette[view.category?.colorIndex ?? 11];
    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.md,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CategoryIcon(
                    icon: isTransfer
                        ? Icons.swap_horiz_rounded
                        : AppIcons.of(view.category?.icon ?? 'more'),
                    color: color,
                    size: 42,
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title(l10n, view),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.bodyStrong.copyWith(color: c.ink),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.caption.copyWith(color: c.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  AmountText(
                    Money(r.amount),
                    size: AmountSize.small,
                    tone: switch (r.type) {
                      TransactionType.expense => AmountTone.expense,
                      TransactionType.income => AmountTone.income,
                      TransactionType.transfer => AmountTone.transfer,
                    },
                    color: r.type == TransactionType.expense ? c.ink : null,
                  ),
                ],
              ),
              ?actions,
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------ Home: Upcoming --

/// Bills and repeating entries due within a week. Hidden when there are none.
class UpcomingSection extends ConsumerWidget {
  const UpcomingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final now = ref.watch(clockProvider)();
    final items = ref.watch(upcomingRecurringProvider);
    if (items.isEmpty) return const SizedBox.shrink();
    final repo = ref.read(recurringRepositoryProvider);

    Future<void> act(RecurringView v, {required bool paid}) async {
      unawaited(HapticFeedback.mediumImpact());
      final messenger = ScaffoldMessenger.of(context);
      final snack = successSnackBar(
        context,
        paid ? l10n.billPaidSaved : l10n.billSkipped,
      );
      if (paid) {
        await repo.markPaid(v.rule, now: DateTime.now());
      } else {
        await repo.skip(v.rule);
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(snack);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.upcomingTitle),
        PoyshikCard(
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.only(left: Space.lg + 42 + Space.md),
                    child: Divider(),
                  ),
                _RuleTile(
                  view: items[i],
                  subtitle: dueLabel(l10n, items[i].rule, now),
                  // Bills that are due get Paid / Skip right here.
                  actions:
                      items[i].rule.autoLog ||
                          calendarDaysBetween(now, items[i].rule.nextDue) > 3
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(
                            top: Space.sm,
                            left: 42 + Space.md,
                          ),
                          child: Row(
                            children: [
                              FilledButton.tonal(
                                onPressed: () =>
                                    unawaited(act(items[i], paid: true)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: c.brand,
                                  foregroundColor: c.onBrand,
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: Text(l10n.billPaid),
                              ),
                              const SizedBox(width: Space.sm),
                              TextButton(
                                onPressed: () =>
                                    unawaited(act(items[i], paid: false)),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: Text(l10n.billSkip),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------- More: Recurring & bills --

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rules = ref.watch(recurringRulesProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreRecurring)),
      body: rules.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.event_repeat_rounded,
                title: l10n.recurringEmptyTitle,
                message: l10n.recurringEmptyBody,
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.screen,
                Space.sm,
                Space.screen,
                Space.huge,
              ),
              children: [
                PoyshikCard(
                  padding: const EdgeInsets.symmetric(vertical: Space.xs),
                  child: Column(
                    children: [
                      for (var i = 0; i < rules.length; i++) ...[
                        if (i > 0)
                          const Padding(
                            padding: EdgeInsets.only(
                              left: Space.lg + 42 + Space.md,
                            ),
                            child: Divider(),
                          ),
                        _RuleTile(
                          view: rules[i],
                          dimmed: rules[i].rule.isPaused,
                          subtitle: [
                            repeatLabel(l10n, rules[i].rule.frequency),
                            if (rules[i].rule.isPaused)
                              l10n.recurringPaused
                            else
                              l10n.recurringNext(
                                DateFormat.MMMd().format(rules[i].rule.nextDue),
                              ),
                            if (rules[i].rule.autoLog)
                              l10n.recurringAuto
                            else
                              l10n.recurringBill,
                          ].join(' · '),
                          onTap: () => unawaited(
                            showModalBottomSheet<void>(
                              context: context,
                              useSafeArea: true,
                              builder: (_) => _RuleActions(view: rules[i]),
                            ),
                          ),
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

/// Pause / resume, switch automatic vs bill, stop repeating.
class _RuleActions extends ConsumerWidget {
  const _RuleActions({required this.view});

  final RecurringView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final r = view.rule;
    final repo = ref.read(recurringRepositoryProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.sm,
        Space.screen,
        Space.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_title(l10n, view)} · ${MoneyFormat.format(Money(r.amount))}',
            style: AppType.titleMedium.copyWith(color: c.ink),
          ),
          const SizedBox(height: Space.xs),
          Text(
            repeatLabel(l10n, r.frequency),
            style: AppType.caption.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: Space.md),
          if (r.type != TransactionType.transfer)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.repeatAutoTitle),
              subtitle: Text(
                r.autoLog ? l10n.repeatAutoBody : l10n.repeatBillBody,
              ),
              value: r.autoLog,
              onChanged: (v) {
                unawaited(
                  repo.update(r.id, amount: Money(r.amount), autoLog: v),
                );
                Navigator.pop(context);
              },
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              r.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
            title: Text(
              r.isPaused ? l10n.recurringResume : l10n.recurringPause,
            ),
            onTap: () {
              unawaited(repo.setPaused(r.id, paused: !r.isPaused));
              Navigator.pop(context);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.stop_circle_outlined, color: c.expense),
            title: Text(l10n.recurringStop, style: TextStyle(color: c.expense)),
            onTap: () async {
              final navigator = Navigator.of(context);
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.recurringDeleteTitle),
                  content: Text(l10n.recurringDeleteBody),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.commonCancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.recurringStop),
                    ),
                  ],
                ),
              );
              if (ok ?? false) {
                await repo.delete(r.id);
                navigator.pop();
              }
            },
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------- launch/resume tasks --

/// Runs housekeeping when the app opens and each time it returns to the
/// foreground: logs auto-recurring entries that came due while closed, and
/// keeps reminders in step with settings, bills and today's entries.
class AppTasks extends ConsumerStatefulWidget {
  const AppTasks({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppTasks> createState() => _AppTasksState();
}

class _AppTasksState extends ConsumerState<AppTasks> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _run);
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Timer? _debounce;

  void _run() {
    final now = ref.read(clockProvider)();
    unawaited(
      ref.read(recurringRepositoryProvider).catchUp(now).then((_) {
        if (mounted) _scheduleSync();
      }),
    );
  }

  /// Coalesces bursts of changes into one reminder reschedule.
  void _scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _syncReminders);
  }

  void _syncReminders() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final now = ref.read(clockProvider)();
    final rules = ref.read(recurringRulesProvider).value ?? const [];
    final today = ref.read(expenseEntriesProvider(dayRange(now))).value;
    unawaited(
      ReminderService.instance.sync(
        settings: ref.read(remindersProvider),
        texts: (
          dailyTitle: l10n.notifDailyTitle,
          dailyBody: l10n.notifDailyBody,
          channel: l10n.notifChannel,
        ),
        bills: [
          for (final v in rules)
            if (!v.rule.isPaused && !v.rule.autoLog)
              (
                due: v.rule.nextDue,
                title: l10n.notifBillTitle(_title(l10n, v)),
                body: l10n.notifBillBody(
                  MoneyFormat.format(Money(v.rule.amount)),
                ),
              ),
        ],
        loggedToday: today?.isNotEmpty ?? false,
        now: now,
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    ref
      ..listen(remindersProvider, (_, _) => _scheduleSync())
      ..listen(recurringRulesProvider, (_, _) => _scheduleSync())
      ..listen(
        expenseEntriesProvider(dayRange(now)),
        (_, _) => _scheduleSync(),
      );
    return widget.child;
  }
}
