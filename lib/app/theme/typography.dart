import 'package:material_ui/material_ui.dart';

/// Type scale. Numbers are the hero: amounts are heavy, tight and use
/// tabular figures so digits don't shift as values change.
abstract final class AppType {
  static const fontFamily = 'Geist';

  static const _tabular = [FontFeature.tabularFigures()];

  // Amounts
  static const amountHero = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    height: 1.05,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.8,
    fontFeatures: _tabular,
  );
  static const amountLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    fontFeatures: _tabular,
  );
  static const amountMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    fontFeatures: _tabular,
  );
  static const amountSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    fontFeatures: _tabular,
  );

  // Text
  static const titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );
  static const titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );
  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );
  static const bodyStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );
  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w500,
  );
  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  /// Small uppercase section headers ("THIS MONTH").
  static const overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 1,
  );

  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  /// Maps the scale onto Material's [TextTheme] so stock widgets match.
  static TextTheme textTheme(Color ink, Color muted) {
    return TextTheme(
      displayLarge: amountHero.copyWith(color: ink),
      displayMedium: amountLarge.copyWith(color: ink),
      headlineSmall: titleLarge.copyWith(color: ink),
      titleLarge: titleLarge.copyWith(color: ink),
      titleMedium: titleMedium.copyWith(color: ink),
      titleSmall: bodyStrong.copyWith(color: ink),
      bodyLarge: body.copyWith(color: ink, fontSize: 16),
      bodyMedium: body.copyWith(color: ink),
      bodySmall: label.copyWith(color: muted),
      labelLarge: button.copyWith(color: ink),
      labelMedium: label.copyWith(color: muted),
      labelSmall: caption.copyWith(color: muted),
    );
  }
}
