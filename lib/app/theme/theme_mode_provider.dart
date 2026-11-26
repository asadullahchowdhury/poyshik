import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/settings_repository.dart';

/// Light, dark or follow the phone. Saved in app settings.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = ref.read(initialSettingsProvider)[SettingKeys.themeMode];
    return ThemeMode.values.where((m) => m.name == saved).firstOrNull ??
        ThemeMode.system;
  }

  void set(ThemeMode mode) {
    state = mode;
    unawaited(
      ref
          .read(settingsRepositoryProvider)
          .set(SettingKeys.themeMode, mode.name),
    );
  }

  /// system → light → dark → system.
  void cycle() => set(switch (state) {
    ThemeMode.system => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
  });
}
