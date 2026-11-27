import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/settings_repository.dart';

/// The app language: follow the phone, or a fixed one. Saved in settings.
enum AppLanguage {
  system(null),
  en('en'),
  bn('bn');

  const AppLanguage(this.code);

  /// Language code, or null to follow the phone.
  final String? code;

  Locale? get locale => code == null ? null : Locale(code!);

  static AppLanguage fromSetting(String? value) =>
      AppLanguage.values.where((l) => l.name == value).firstOrNull ??
      AppLanguage.system;
}

final languageProvider = NotifierProvider<LanguageNotifier, AppLanguage>(
  LanguageNotifier.new,
);

class LanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => AppLanguage.fromSetting(
    ref.read(initialSettingsProvider)[SettingKeys.language],
  );

  void set(AppLanguage language) {
    state = language;
    unawaited(
      ref
          .read(settingsRepositoryProvider)
          .set(SettingKeys.language, language.name),
    );
  }
}
