import 'package:material_ui/material_ui.dart';

/// Poyshik's color tokens, available via `context.colors`.
///
/// Concept: neutral "paper" backgrounds, ink-black primary actions and a
/// marigold accent used sparingly. Money colors are calm, never alarming.
@immutable
class PoyshikColors extends ThemeExtension<PoyshikColors> {
  const PoyshikColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.ink,
    required this.inkMuted,
    required this.inkSubtle,
    required this.onInk,
    required this.hairline,
    required this.accent,
    required this.onAccent,
    required this.expense,
    required this.income,
    required this.transfer,
    required this.warning,
  });

  /// Screen background.
  final Color background;

  /// Cards and sheets.
  final Color surface;

  /// Inset elements on a surface: keypad keys, chips, progress tracks.
  final Color surfaceRaised;

  /// Primary text and primary buttons.
  final Color ink;

  /// Secondary text.
  final Color inkMuted;

  /// Tertiary text, placeholders, disabled.
  final Color inkSubtle;

  /// Text and icons drawn on [ink].
  final Color onInk;

  /// 1px borders and dividers.
  final Color hairline;

  /// Marigold. Use sparingly: the add button, focus, one chart highlight.
  final Color accent;

  /// Text and icons drawn on [accent].
  final Color onAccent;

  final Color expense;
  final Color income;
  final Color transfer;

  /// Over budget and other gentle warnings.
  final Color warning;

  static const light = PoyshikColors(
    background: Color(0xFFF7F7F4),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF1F0EC),
    ink: Color(0xFF121417),
    inkMuted: Color(0xFF5F636B),
    inkSubtle: Color(0xFF9A9DA3),
    onInk: Color(0xFFFFFFFF),
    hairline: Color(0xFFE7E5DF),
    accent: Color(0xFFF2A93B),
    onAccent: Color(0xFF1C1405),
    expense: Color(0xFFD9604A),
    income: Color(0xFF3E8E6A),
    transfer: Color(0xFF5B6B8C),
    warning: Color(0xFFC2410C),
  );

  static const dark = PoyshikColors(
    background: Color(0xFF0F1012),
    surface: Color(0xFF17191C),
    surfaceRaised: Color(0xFF212328),
    ink: Color(0xFFF3F2EE),
    inkMuted: Color(0xFFA3A6AC),
    inkSubtle: Color(0xFF6E7178),
    onInk: Color(0xFF0F1012),
    hairline: Color(0xFF272A2F),
    accent: Color(0xFFF5B451),
    onAccent: Color(0xFF1C1405),
    expense: Color(0xFFEC7A64),
    income: Color(0xFF5DB08B),
    transfer: Color(0xFF8C9BBD),
    warning: Color(0xFFFB923C),
  );

  /// Muted tones for categories and charts; chosen to sit well together in
  /// both themes. Tiles use the color at ~14% opacity behind a full icon.
  static const categoryPalette = <Color>[
    Color(0xFFE58E5A), // apricot
    Color(0xFFE0B04A), // mustard
    Color(0xFF7FB77E), // leaf
    Color(0xFF4FA3A5), // teal
    Color(0xFF5B8DD6), // cornflower
    Color(0xFF8C7AE6), // lavender
    Color(0xFFD47AA6), // orchid
    Color(0xFFE06C75), // rose
    Color(0xFF9C8A6E), // taupe
    Color(0xFF6FA8DC), // sky
    Color(0xFFB5A642), // olive
    Color(0xFF8E9AAF), // slate
  ];

  @override
  PoyshikColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? ink,
    Color? inkMuted,
    Color? inkSubtle,
    Color? onInk,
    Color? hairline,
    Color? accent,
    Color? onAccent,
    Color? expense,
    Color? income,
    Color? transfer,
    Color? warning,
  }) {
    return PoyshikColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      inkSubtle: inkSubtle ?? this.inkSubtle,
      onInk: onInk ?? this.onInk,
      hairline: hairline ?? this.hairline,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      expense: expense ?? this.expense,
      income: income ?? this.income,
      transfer: transfer ?? this.transfer,
      warning: warning ?? this.warning,
    );
  }

  @override
  PoyshikColors lerp(covariant ThemeExtension<PoyshikColors>? other, double t) {
    if (other is! PoyshikColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return PoyshikColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceRaised: mix(surfaceRaised, other.surfaceRaised),
      ink: mix(ink, other.ink),
      inkMuted: mix(inkMuted, other.inkMuted),
      inkSubtle: mix(inkSubtle, other.inkSubtle),
      onInk: mix(onInk, other.onInk),
      hairline: mix(hairline, other.hairline),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      expense: mix(expense, other.expense),
      income: mix(income, other.income),
      transfer: mix(transfer, other.transfer),
      warning: mix(warning, other.warning),
    );
  }
}
