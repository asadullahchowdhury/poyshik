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
      primary: c.brand,
      onPrimary: c.onBrand,
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
      fontFamilyFallback: AppType.fallback,
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
        titleTextStyle: AppType.displayMedium.copyWith(color: c.ink),
        toolbarHeight: 64,
        titleSpacing: Space.screen,
        systemOverlayStyle: _overlay(brightness, c),
      ),
      // Shared-axis style "fade forwards" on Android: calm, quick, modern.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      dividerTheme: DividerThemeData(color: c.hairline, thickness: 1, space: 1),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.standard,
          minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
          textStyle: const WidgetStatePropertyAll(AppType.label),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.md),
            ),
          ),
          side: WidgetStatePropertyAll(BorderSide(color: c.hairline)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.brand : c.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.onBrand : c.inkMuted,
          ),
          iconColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.onBrand : c.inkMuted,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onBrand : c.inkSubtle,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.brand : c.surfaceRaised,
        ),
        trackOutlineColor: WidgetStatePropertyAll(c.hairline),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.brand,
        linearTrackColor: c.surfaceRaised,
        circularTrackColor: c.surfaceRaised,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
        titleTextStyle: AppType.titleLarge.copyWith(color: c.ink),
        contentTextStyle: AppType.body.copyWith(color: c.inkMuted),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.ink,
        textColor: c.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.brand,
          foregroundColor: c.onBrand,
          disabledBackgroundColor: c.surfaceRaised,
          disabledForegroundColor: c.inkSubtle,
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceRaised,
        hintStyle: AppType.body.copyWith(color: c.inkSubtle),
        labelStyle: AppType.label.copyWith(color: c.inkMuted),
        helperStyle: AppType.caption.copyWith(color: c.inkMuted),
        helperMaxLines: 2,
        errorStyle: AppType.caption.copyWith(color: c.expense),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.md + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: c.brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: c.expense),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: c.expense, width: 1.5),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.ink,
        selectionColor: c.accent.withValues(alpha: 0.35),
        selectionHandleColor: c.accent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.inkSubtle.withValues(alpha: 0.4),
        dragHandleSize: const Size(36, 4),
        modalBarrierColor: c.brand.withValues(
          alpha: brightness == Brightness.light ? 0.28 : 0.5,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.hero,
        contentTextStyle: AppType.bodyStrong.copyWith(color: c.onHero),
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
