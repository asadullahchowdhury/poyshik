import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../../app/theme/theme_mode_provider.dart';
import '../../core/money/amount_input.dart';
import '../../core/money/money.dart';
import '../../core/widgets/amount_text.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/numpad.dart';
import '../../core/widgets/poyshik_card.dart';
import '../../core/widgets/primary_button.dart';

// DEV ONLY: a design review screen. Text here is sample content, so it is not
// localized. Removed from the main flow once real screens exist.

class ComponentGalleryScreen extends ConsumerStatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  ConsumerState<ComponentGalleryScreen> createState() =>
      _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState
    extends ConsumerState<ComponentGalleryScreen> {
  AmountInput _entry = const AmountInput();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mode = ref.watch(themeModeProvider);
    const pal = PoyshikColors.categoryPalette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design system'),
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(themeModeProvider.notifier).cycle(),
            icon: Icon(switch (mode) {
              ThemeMode.system => Icons.brightness_auto_rounded,
              ThemeMode.light => Icons.light_mode_rounded,
              ThemeMode.dark => Icons.dark_mode_rounded,
            }, size: 20),
            label: Text(switch (mode) {
              ThemeMode.system => 'System',
              ThemeMode.light => 'Light',
              ThemeMode.dark => 'Dark',
            }),
          ),
          const SizedBox(width: Space.sm),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.screen,
          Space.sm,
          Space.screen,
          Space.huge,
        ),
        children: [
          // Hero card
          PoyshikCard(
            padding: const EdgeInsets.all(Space.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SPENT IN NOVEMBER',
                  style: AppType.overline.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: Space.sm),
                const AmountText(Money(1248000), size: AmountSize.hero),
                const SizedBox(height: Space.xs),
                Text.rich(
                  TextSpan(
                    style: AppType.label.copyWith(color: c.inkMuted),
                    children: const [
                      TextSpan(text: 'of '),
                      TextSpan(text: 'à§³20,000 budget'),
                    ],
                  ),
                ),
                const SizedBox(height: Space.lg),
                _ProgressTrack(value: 0.62, color: c.accent),
                const SizedBox(height: Space.lg),
                const Divider(),
                const SizedBox(height: Space.lg),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Safe to spend',
                            style: AppType.label.copyWith(color: c.inkMuted),
                          ),
                          const SizedBox(height: Space.xxs),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const AmountText(Money(125300)),
                              Text(
                                ' /day',
                                style: AppType.label.copyWith(
                                  color: c.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.md,
                        vertical: Space.xs + 2,
                      ),
                      decoration: BoxDecoration(
                        color: c.surfaceRaised,
                        borderRadius: BorderRadius.circular(Radii.pill),
                      ),
                      child: Text(
                        '6 days left',
                        style: AppType.caption.copyWith(color: c.ink),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),

          // Today / this week
          const Row(
            children: [
              Expanded(child: _MiniStat(label: 'Today', amountMinor: 45000)),
              SizedBox(width: Space.md),
              Expanded(
                child: _MiniStat(label: 'This week', amountMinor: 382050),
              ),
            ],
          ),

          const _Section('Accounts'),
          SizedBox(
            height: 76,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: const [
                _AccountChip(
                  name: 'Cash',
                  amountMinor: 245000,
                  icon: Icons.payments_rounded,
                  colorIndex: 2,
                ),
                _AccountChip(
                  name: 'bKash',
                  amountMinor: 832050,
                  icon: Icons.account_balance_wallet_rounded,
                  colorIndex: 6,
                ),
                _AccountChip(
                  name: 'Bank',
                  amountMinor: 4500000,
                  icon: Icons.account_balance_rounded,
                  colorIndex: 4,
                ),
              ],
            ),
          ),

          const _Section('Recent'),
          PoyshikCard(
            padding: const EdgeInsets.symmetric(vertical: Space.xs),
            child: Column(
              children: [
                _TxRow(
                  icon: Icons.restaurant_rounded,
                  color: pal[0],
                  title: 'Food',
                  subtitle: 'Cash Â· 1:24 PM',
                  amountMinor: 32000,
                  tone: AmountTone.expense,
                ),
                _TxRow(
                  icon: Icons.directions_bus_rounded,
                  color: pal[4],
                  title: 'Transport',
                  subtitle: 'bKash Â· 9:10 AM',
                  amountMinor: 6000,
                  tone: AmountTone.expense,
                ),
                _TxRow(
                  icon: Icons.work_rounded,
                  color: pal[2],
                  title: 'Salary',
                  subtitle: 'Bank Â· Yesterday',
                  amountMinor: 6500000,
                  tone: AmountTone.income,
                ),
                _TxRow(
                  icon: Icons.swap_horiz_rounded,
                  color: c.transfer,
                  title: 'Bank â†’ bKash',
                  subtitle: 'Transfer Â· Yesterday',
                  amountMinor: 500000,
                  tone: AmountTone.transfer,
                  isLast: true,
                ),
              ],
            ),
          ),

          const _Section('Category icons'),
          Wrap(
            spacing: Space.md,
            runSpacing: Space.md,
            children: [
              for (final (i, icon) in const [
                Icons.restaurant_rounded,
                Icons.coffee_rounded,
                Icons.shopping_bag_rounded,
                Icons.directions_bus_rounded,
                Icons.home_rounded,
                Icons.receipt_long_rounded,
                Icons.local_hospital_rounded,
                Icons.school_rounded,
                Icons.movie_rounded,
                Icons.phone_android_rounded,
                Icons.card_giftcard_rounded,
                Icons.more_horiz_rounded,
              ].indexed)
                CategoryIcon(icon: icon, color: pal[i % pal.length]),
            ],
          ),

          const _Section('Type'),
          PoyshikCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AmountText(Money(12500000), size: AmountSize.large),
                const SizedBox(height: Space.xs),
                const AmountText(
                  Money(48050),
                  tone: AmountTone.expense,
                  showSign: true,
                ),
                const SizedBox(height: Space.md),
                Text(
                  'Title large',
                  style: AppType.titleLarge.copyWith(color: c.ink),
                ),
                Text(
                  'Title medium',
                  style: AppType.titleMedium.copyWith(color: c.ink),
                ),
                Text(
                  'Body â€” Groceries from Shwapno, split with Rafi.',
                  style: AppType.body.copyWith(color: c.ink),
                ),
                Text(
                  'Label â€” Cash Â· 2:15 PM',
                  style: AppType.label.copyWith(color: c.inkMuted),
                ),
                Text(
                  'CAPTION / OVERLINE',
                  style: AppType.overline.copyWith(color: c.inkSubtle),
                ),
              ],
            ),
          ),

          const _Section('Buttons'),
          PrimaryButton(
            label: 'Save expense',
            icon: Icons.check_rounded,
            onPressed: () {},
          ),
          const SizedBox(height: Space.md),
          PrimaryButton(
            label: 'Add transaction',
            tone: ButtonTone.accent,
            icon: Icons.add_rounded,
            onPressed: () {},
          ),
          const SizedBox(height: Space.md),
          OutlinedButton(onPressed: () {}, child: const Text('Cancel')),
          const SizedBox(height: Space.md),
          Center(
            child: FloatingActionButton(
              onPressed: () {},
              backgroundColor: c.accent,
              foregroundColor: c.onAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.lg),
              ),
              child: const Icon(Icons.add_rounded, size: 28),
            ),
          ),

          const _Section('Entry keypad (try it)'),
          PoyshikCard(
            child: Column(
              children: [
                Text(
                  'EXPENSE',
                  style: AppType.overline.copyWith(color: c.expense),
                ),
                const SizedBox(height: Space.sm),
                AmountText(_entry.value, size: AmountSize.hero),
                const SizedBox(height: Space.xl),
                Numpad(
                  onKey: (k) => setState(() => _entry = _entry.press(k)),
                  onBackspace: () =>
                      setState(() => _entry = _entry.backspace()),
                  onClear: () => setState(() => _entry = _entry.clear()),
                ),
              ],
            ),
          ),

          const _Section('Colors'),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              _Swatch('background', c.background),
              _Swatch('surface', c.surface),
              _Swatch('raised', c.surfaceRaised),
              _Swatch('ink', c.ink),
              _Swatch('muted', c.inkMuted),
              _Swatch('hairline', c.hairline),
              _Swatch('accent', c.accent),
              _Swatch('expense', c.expense),
              _Swatch('income', c.income),
              _Swatch('transfer', c.transfer),
              _Swatch('warning', c.warning),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.xxxl, bottom: Space.md),
      child: Text(
        title.toUpperCase(),
        style: AppType.overline.copyWith(color: context.colors.inkMuted),
      ),
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.pill),
      child: SizedBox(
        height: 8,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: context.colors.surfaceRaised),
            ),
            FractionallySizedBox(
              widthFactor: value.clamp(0, 1),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.amountMinor});

  final String label;
  final int amountMinor;

  @override
  Widget build(BuildContext context) {
    return PoyshikCard(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppType.label.copyWith(color: context.colors.inkMuted),
          ),
          const SizedBox(height: Space.xs),
          AmountText(Money(amountMinor)),
        ],
      ),
    );
  }
}

class _AccountChip extends StatelessWidget {
  const _AccountChip({
    required this.name,
    required this.amountMinor,
    required this.icon,
    required this.colorIndex,
  });

  final String name;
  final int amountMinor;
  final IconData icon;
  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: Space.md),
      child: PoyshikCard(
        padding: const EdgeInsets.fromLTRB(
          Space.md,
          Space.md,
          Space.lg,
          Space.md,
        ),
        child: Row(
          children: [
            CategoryIcon(
              icon: icon,
              color: PoyshikColors.categoryPalette[colorIndex],
              size: 40,
            ),
            const SizedBox(width: Space.md),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppType.label.copyWith(color: context.colors.inkMuted),
                ),
                AmountText(Money(amountMinor), size: AmountSize.small),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.amountMinor,
    required this.tone,
    this.isLast = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final int amountMinor;
  final AmountTone tone;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.lg,
              vertical: Space.md,
            ),
            child: Row(
              children: [
                CategoryIcon(icon: icon, color: color, size: 42),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppType.bodyStrong.copyWith(color: c.ink),
                      ),
                      Text(
                        subtitle,
                        style: AppType.caption.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
                AmountText(
                  Money(amountMinor),
                  size: AmountSize.small,
                  tone: tone,
                  showSign: tone != AmountTone.transfer,
                  color: tone == AmountTone.expense ? c.ink : null,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: Space.lg + 42 + Space.md),
            child: Divider(color: c.hairline),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.color);

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(Radii.sm),
              border: Border.all(color: c.hairline),
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(name, style: AppType.caption.copyWith(color: c.inkMuted)),
        ],
      ),
    );
  }
}
