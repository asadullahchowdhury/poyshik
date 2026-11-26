import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings_repository.dart';
import 'periods.dart';

/// First day of the week ([DateTime.saturday] … [DateTime.sunday]).
/// Saturday by default; saved in app settings.
final weekStartProvider = NotifierProvider<WeekStartNotifier, int>(
  WeekStartNotifier.new,
);

class WeekStartNotifier extends Notifier<int> {
  @override
  int build() {
    final saved = int.tryParse(
      ref.read(initialSettingsProvider)[SettingKeys.weekStart] ?? '',
    );
    return saved != null && saved >= 1 && saved <= 7 ? saved : kWeekStartDay;
  }

  void set(int day) {
    state = day;
    unawaited(
      ref.read(settingsRepositoryProvider).set(SettingKeys.weekStart, '$day'),
    );
  }
}
