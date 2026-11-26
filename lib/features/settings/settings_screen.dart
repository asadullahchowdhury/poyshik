import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_info.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/theme_mode_provider.dart';
import '../../core/dates/week_start_provider.dart';
import '../../core/widgets/poyshik_card.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Localized weekday name (2026-11-16 is a Monday, weekday 1).
  static String _weekday(int day) =>
      DateFormat.EEEE().format(DateTime(2026, 11, 15 + day));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final theme = ref.watch(themeModeProvider);
    final weekStart = ref.watch(weekStartProvider);

    Widget section(String title, List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xs, Space.xxl, 0, Space.md),
          child: Text(
            title.toUpperCase(),
            style: AppType.overline.copyWith(color: c.inkMuted),
          ),
        ),
        PoyshikCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Text(text, style: AppType.bodyStrong.copyWith(color: c.ink)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.screen,
          0,
          Space.screen,
          Space.huge,
        ),
        children: [
          section(l10n.settingsAppearance, [
            label(l10n.settingsTheme),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto_rounded),
                    label: Text(l10n.settingsThemeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_rounded),
                    label: Text(l10n.settingsThemeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_rounded),
                    label: Text(l10n.settingsThemeDark),
                  ),
                ],
                selected: {theme},
                onSelectionChanged: (s) =>
                    ref.read(themeModeProvider.notifier).set(s.first),
              ),
            ),
          ]),
          section(l10n.settingsCalendar, [
            label(l10n.settingsWeekStart),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [
                  for (final d in const [
                    DateTime.saturday,
                    DateTime.sunday,
                    DateTime.monday,
                  ])
                    ButtonSegment(value: d, label: Text(_weekday(d))),
                ],
                selected: {weekStart},
                onSelectionChanged: (s) =>
                    ref.read(weekStartProvider.notifier).set(s.first),
              ),
            ),
            const SizedBox(height: Space.sm),
            Text(
              l10n.settingsWeekStartHelp,
              style: AppType.caption.copyWith(color: c.inkMuted),
            ),
          ]),
          section(l10n.settingsAbout, [
            Text(
              '${l10n.appTitle} · ${l10n.settingsVersion(kAppVersion)}',
              style: AppType.bodyStrong.copyWith(color: c.ink),
            ),
            const SizedBox(height: Space.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline_rounded, size: 18, color: c.income),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    l10n.settingsPrivacy,
                    style: AppType.label.copyWith(color: c.inkMuted),
                  ),
                ),
              ],
            ),
          ]),
        ],
      ),
    );
  }
}
