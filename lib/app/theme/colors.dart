import 'package:material_ui/material_ui.dart';

/// Poyshik's colour tokens, available via `context.colors`.
///
/// Brand: warm paper backgrounds, deep forest ink, one marigold accent.
/// Money colours are calm, never alarming. See docs/BRAND_GUIDELINES.md.
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
    required this.brand,
    required this.onBrand,
    required this.hero,
    required this.onHero,
    required this.onHeroMuted,
    required this.accent,
    required this.onAccent,
    required this.expense,
    required this.income,
    required this.transfer,
    required this.warning,
    required this.shadow,
  });

  /// Screen background ("paper").
  final Color background;

  /// Cards and sheets ("cream").
  final Color surface;

  /// Inset elements on a surface: keypad keys, chips, progress tracks.
  final Color surfaceRaised;

  /// Primary text (green-black, never pure black).
  final Color ink;

  /// Secondary text.
  final Color inkMuted;

  /// Tertiary text, placeholders, disabled.
  final Color inkSubtle;

  /// Text and icons drawn on [ink].
  final Color onInk;

  /// 1px borders and dividers.
  final Color hairline;

  /// Primary actions and selected states (forest).
  final Color brand;
  final Color onBrand;

  /// Feature surfaces such as the dashboard hero card (deep forest).
  final Color hero;
  final Color onHero;
  final Color onHeroMuted;

  /// Marigold. The one accent: add button, focus, one highlight per view.
  final Color accent;
  final Color onAccent;

  final Color expense;
  final Color income;
  final Color transfer;

  /// Over budget and other gentle warnings.
  final Color warning;

  /// The single soft shadow used for floating elements.
  final Color shadow;

  static const light = PoyshikColors(
    background: Color(0xFFF4EEE2),
    surface: Color(0xFFFCFAF5),
    surfaceRaised: Color(0xFFEDE6D8),
    ink: Color(0xFF17201B),
    inkMuted: Color(0xFF5C665E),
    inkSubtle: Color(0xFF98A097),
    onInk: Color(0xFFFBF8F1),
    hairline: Color(0xFFE3DBCB),
    brand: Color(0xFF123D2E),
    onBrand: Color(0xFFFBF8F1),
    hero: Color(0xFF123D2E),
    onHero: Color(0xFFFBF8F1),
    onHeroMuted: Color(0xFFB7C8BD),
    accent: Color(0xFFE2A13B),
    onAccent: Color(0xFF2A1C05),
    expense: Color(0xFFC2553F),
    income: Color(0xFF2F7D5B),
    transfer: Color(0xFF5D6E8C),
    warning: Color(0xFFB8621B),
    shadow: Color(0x1F0B2A20),
  );

  static const dark = PoyshikColors(
    background: Color(0xFF0C1713),
    surface: Color(0xFF13211A),
    surfaceRaised: Color(0xFF1C2D24),
    ink: Color(0xFFF1ECE1),
    inkMuted: Color(0xFFA9B2A8),
    inkSubtle: Color(0xFF6E7A71),
    onInk: Color(0xFF0C1713),
    hairline: Color(0xFF233629),
    brand: Color(0xFFE9E1CF),
    onBrand: Color(0xFF0C1713),
    hero: Color(0xFF173F30),
    onHero: Color(0xFFF1ECE1),
    onHeroMuted: Color(0xFF9DB5A6),
    accent: Color(0xFFE9B04E),
    onAccent: Color(0xFF2A1C05),
    expense: Color(0xFFE07A63),
    income: Color(0xFF5DB08B),
    transfer: Color(0xFF8C9BBD),
    warning: Color(0xFFF0954A),
    shadow: Color(0x66000000),
  );

  /// Earthy, muted tones for categories and charts; chosen to sit with the
  /// forest/paper palette in both themes. Stored as indexes, so the order is
  /// stable: 0 apricot, 1 mustard, 2 sage, 3 teal, 4 blue, 5 lavender,
  /// 6 rose, 7 coral, 8 taupe, 9 sky, 10 olive, 11 slate.
  static const categoryPalette = <Color>[
    Color(0xFFD9895B),
    Color(0xFFD3A445),
    Color(0xFF6E9E72),
    Color(0xFF3F918A),
    Color(0xFF5B82BF),
    Color(0xFF8775C2),
    Color(0xFFC46A8B),
    Color(0xFFD2665A),
    Color(0xFF9A876B),
    Color(0xFF6A9FCB),
    Color(0xFFA2993F),
    Color(0xFF8090A6),
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
    Color? brand,
    Color? onBrand,
    Color? hero,
    Color? onHero,
    Color? onHeroMuted,
    Color? accent,
    Color? onAccent,
    Color? expense,
    Color? income,
    Color? transfer,
    Color? warning,
    Color? shadow,
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
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      hero: hero ?? this.hero,
      onHero: onHero ?? this.onHero,
      onHeroMuted: onHeroMuted ?? this.onHeroMuted,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      expense: expense ?? this.expense,
      income: income ?? this.income,
      transfer: transfer ?? this.transfer,
      warning: warning ?? this.warning,
      shadow: shadow ?? this.shadow,
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
      brand: mix(brand, other.brand),
      onBrand: mix(onBrand, other.onBrand),
      hero: mix(hero, other.hero),
      onHero: mix(onHero, other.onHero),
      onHeroMuted: mix(onHeroMuted, other.onHeroMuted),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      expense: mix(expense, other.expense),
      income: mix(income, other.income),
      transfer: mix(transfer, other.transfer),
      warning: mix(warning, other.warning),
      shadow: mix(shadow, other.shadow),
    );
  }
}
