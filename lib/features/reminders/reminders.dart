import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/dates/periods.dart';
import '../../data/settings_repository.dart';

/// What the user wants to be reminded of. Both off until switched on.
typedef ReminderSettings = ({
  /// Daily "log today?" nudge at this time; null = off.
  TimeOfDay? daily,

  /// A notification on the morning a bill is due.
  bool bills,
});

const _dailyKey = 'reminder_daily';
const _billsKey = 'reminder_bills';

final remindersProvider = NotifierProvider<RemindersNotifier, ReminderSettings>(
  RemindersNotifier.new,
);

class RemindersNotifier extends Notifier<ReminderSettings> {
  @override
  ReminderSettings build() {
    final saved = ref.read(initialSettingsProvider);
    return (daily: _parse(saved[_dailyKey]), bills: saved[_billsKey] == '1');
  }

  static TimeOfDay? _parse(String? v) {
    final parts = v?.split(':');
    if (parts == null || parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h > 23 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  void setDaily(TimeOfDay? time) {
    state = (daily: time, bills: state.bills);
    final v = time == null ? '' : '${time.hour}:${time.minute}';
    unawaited(ref.read(settingsRepositoryProvider).set(_dailyKey, v));
  }

  void setBills({required bool on}) {
    state = (daily: state.daily, bills: on);
    unawaited(
      ref.read(settingsRepositoryProvider).set(_billsKey, on ? '1' : '0'),
    );
  }
}

/// A bill reminder to schedule: when, and what to say.
typedef BillReminder = ({DateTime due, String title, String body});

/// Localized texts for the notifications (built where a context exists).
typedef ReminderTexts = ({String dailyTitle, String dailyBody, String channel});

/// Local notifications, scheduled on the device. Nothing leaves the phone.
///
/// Every [sync] cancels and re-creates all reminders, so they always match
/// the current settings and bills. The daily nudge is planned day by day for
/// the next two weeks (re-planned on every app open), which lets today's be
/// dropped once something has been logged.
class ReminderService {
  ReminderService._();

  static final instance = ReminderService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<bool>? _ready;

  static const _daysAhead = 14;
  static const _billHour = 10;
  static const _dailyIdBase = 1000;
  static const _billIdBase = 2000;

  Future<bool> _init() => _ready ??= () async {
    try {
      tzdata.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
        ),
      );
      return true;
    } on Object catch (e) {
      // No plugin (tests) or an unknown zone: reminders just stay off.
      debugPrint('Reminders unavailable: $e');
      return false;
    }
  }();

  /// Asks for notification permission (Android 13+). True if allowed.
  Future<bool> requestPermission() async {
    if (!await _init()) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? true;
  }

  Future<void> sync({
    required ReminderSettings settings,
    required ReminderTexts texts,
    required List<BillReminder> bills,
    required bool loggedToday,
    required DateTime now,
  }) async {
    if (settings.daily == null && !settings.bills) {
      // Never touch the plugin for users who don't use reminders.
      if (_ready != null && await _init()) await _plugin.cancelAll();
      return;
    }
    if (!await _init()) return;
    await _plugin.cancelAll();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        texts.channel,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: 'ic_notification',
        color: const Color(0xFF123D2E),
      ),
    );

    Future<void> at(int id, DateTime when, String title, String body) =>
        _plugin.zonedSchedule(
          id: id,
          scheduledDate: tz.TZDateTime.from(when, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: title,
          body: body,
        );

    final daily = settings.daily;
    if (daily != null) {
      for (var d = 0; d < _daysAhead; d++) {
        final day = dateOnly(now).add(Duration(days: d));
        final when = DateTime(
          day.year,
          day.month,
          day.day,
          daily.hour,
          daily.minute,
        );
        if (!when.isAfter(now) || (d == 0 && loggedToday)) continue;
        await at(_dailyIdBase + d, when, texts.dailyTitle, texts.dailyBody);
      }
    }
    if (settings.bills) {
      var i = 0;
      for (final b in bills) {
        final due = dateOnly(b.due);
        var when = DateTime(due.year, due.month, due.day, _billHour);
        // Due today but past 10:00: remind soon instead of never.
        if (!when.isAfter(now) && calendarDaysBetween(now, due) == 0) {
          when = now.add(const Duration(minutes: 1));
        }
        if (!when.isAfter(now)) continue;
        await at(_billIdBase + i++, when, b.title, b.body);
        if (i >= 50) break;
      }
    }
  }
}
