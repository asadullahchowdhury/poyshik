import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme/theme.dart';
import '../../app/theme/theme_mode_provider.dart';
import '../../core/dates/week_start_provider.dart';
import '../../core/locale/language_provider.dart';
import '../../core/money/currency.dart';
import '../../core/money/currency_provider.dart';
import '../../core/widgets/poyshik_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/backup/backup_service.dart';
import '../../data/settings_repository.dart';
import '../../l10n/app_localizations.dart';

final _lastBackupProvider = FutureProvider<DateTime?>((ref) async {
  final raw = await ref
      .watch(settingsRepositoryProvider)
      .get(SettingKeys.lastBackupAt);
  return raw == null ? null : DateTime.tryParse(raw);
});

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  String get _stamp => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<File> _writeTemp(String name, String content) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsString(content, flush: true);
    return file;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } on BackupFormatException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.isNewer ? l10n.backupNewer : l10n.backupInvalid),
        ),
      );
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupFailed('$e'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _backup() async {
    final json = await ref.read(backupServiceProvider).exportJson();
    final file = await _writeTemp('poyshik-backup-$_stamp.json', json);
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'Poyshik backup $_stamp',
      ),
    );
    if (result.status != ShareResultStatus.dismissed) {
      await ref
          .read(settingsRepositoryProvider)
          .set(SettingKeys.lastBackupAt, DateTime.now().toIso8601String());
      ref.invalidate(_lastBackupProvider);
    }
  }

  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final picked = await FilePicker.pickFile();
    if (picked == null) return;
    final json = utf8.decode(await picked.readAsBytes());
    final service = ref.read(backupServiceProvider);
    final info = service.inspect(json).info; // validates before asking
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.backupConfirmTitle),
        content: Text(
          l10n.backupConfirmBody(
            DateFormat('d MMM y, h:mm a').format(info.createdAt),
            info.accounts,
            info.categories,
            info.transactions,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.backupCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.expense,
            ),
            child: Text(l10n.backupConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final restored = await service.restore(json);
    // Apply restored preferences now rather than on next launch.
    final settings = await ref.read(settingsRepositoryProvider).getAll();
    final theme = ThemeMode.values
        .where((m) => m.name == settings[SettingKeys.themeMode])
        .firstOrNull;
    if (theme != null) ref.read(themeModeProvider.notifier).set(theme);
    final week = int.tryParse(settings[SettingKeys.weekStart] ?? '');
    if (week != null) ref.read(weekStartProvider.notifier).set(week);
    ref
        .read(currencyProvider.notifier)
        .set(currencyFor(settings[SettingKeys.currency]));
    ref
        .read(languageProvider.notifier)
        .set(AppLanguage.fromSetting(settings[SettingKeys.language]));
    ref.invalidate(_lastBackupProvider);

    messenger.showSnackBar(
      SnackBar(content: Text(l10n.backupRestored(restored.transactions))),
    );
  }

  Future<void> _exportCsv() async {
    final csv = await ref.read(backupServiceProvider).exportCsv();
    final file = await _writeTemp('poyshik-transactions-$_stamp.csv', csv);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'text/csv')]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final last = ref.watch(_lastBackupProvider).value;

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
    Widget body(String text) => Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Text(text, style: AppType.body.copyWith(color: c.inkMuted)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            0,
            Space.screen,
            Space.huge,
          ),
          children: [
            if (_busy) const LinearProgressIndicator(),
            section(l10n.backupSectionBackup, [
              body(l10n.backupExplain),
              Row(
                children: [
                  Icon(
                    last == null
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18,
                    color: last == null ? c.warning : c.income,
                  ),
                  const SizedBox(width: Space.sm),
                  Text(
                    last == null
                        ? l10n.backupNever
                        : l10n.backupLast(
                            DateFormat('d MMM y, h:mm a').format(last),
                          ),
                    style: AppType.label.copyWith(color: c.ink),
                  ),
                ],
              ),
              const SizedBox(height: Space.lg),
              PrimaryButton(
                label: l10n.backupCreate,
                icon: Icons.cloud_upload_rounded,
                tone: ButtonTone.accent,
                onPressed: () => unawaited(_run(_backup)),
              ),
            ]),
            section(l10n.backupSectionRestore, [
              body(l10n.backupRestoreExplain),
              OutlinedButton.icon(
                onPressed: () => unawaited(_run(_restore)),
                icon: const Icon(Icons.settings_backup_restore_rounded),
                label: Text(l10n.backupRestorePick),
              ),
            ]),
            section(l10n.backupSectionExport, [
              body(l10n.backupExportExplain),
              OutlinedButton.icon(
                onPressed: () => unawaited(_run(_exportCsv)),
                icon: const Icon(Icons.table_view_rounded),
                label: Text(l10n.backupExportCsv),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
