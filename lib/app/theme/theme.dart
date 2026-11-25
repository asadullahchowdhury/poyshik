import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

export 'colors.dart';
export 'spacing.dart';
export 'typography.dart';

/// Builds Poyshik's light and dark [ThemeData] from the design tokens.
abstract final class AppTheme {
  static final light = _build(Brightness.light, PoyshikColors.light);
  static final dark = _build(Brightness.dark, PoyshikColors.dark);

  static ThemeData _build(Brightness brightness, PoyshikColors c) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.ink,
      onPrimary: c.onInk,
      secondary: c.accent,
      onSecondary: c.onAccent,
      error: c.expense,
      onError: c.onInk,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      outline: c.hairline,
      outlineVariant: c.hairline,
      surfaceTint: Colors.transparent,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.md),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppType.fontFamily,
      textTheme: AppType.textTheme(c.ink, c.inkMuted),
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      splashFactory: InkRipple.splashFactory,
      highlightColor: Colors.transparent,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppType.titleLarge.copyWith(color: c.ink),
        systemOverlayStyle: _overlay(brightness, c),
      ),
      dividerTheme: DividerThemeData(color: c.hairline, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.ink,
          foregroundColor: c.onInk,
          minimumSize: const Size.fromHeight(52),
          textStyle: AppType.button,
          shape: buttonShape,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          minimumSize: const Size.fromHeight(52),
          textStyle: AppType.button,
          shape: buttonShape,
          side: BorderSide(color: c.hairline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.ink,
          textStyle: AppType.button,
          shape: buttonShape,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.hairline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: AppType.bodyStrong.copyWith(color: c.onInk),
        actionTextColor: c.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
    );
  }
}

/// Transparent system bars with icons that contrast the theme.
SystemUiOverlayStyle _overlay(Brightness brightness, PoyshikColors c) {
  final isLight = brightness == Brightness.light;
  final icons = isLight ? Brightness.dark : Brightness.light;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: icons,
    statusBarBrightness: brightness,
    systemNavigationBarColor: c.surface,
    systemNavigationBarIconBrightness: icons,
    systemNavigationBarDividerColor: c.hairline,
    systemNavigationBarContrastEnforced: false,
  );
}

/// Short access to Poyshik tokens: `context.colors.accent`.
extension PoyshikThemeContext on BuildContext {
  PoyshikColors get colors => Theme.of(this).extension<PoyshikColors>()!;
}
