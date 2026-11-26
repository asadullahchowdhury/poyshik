import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme/theme.dart';
import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/poyshik_logo.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../accounts/account_labels.dart';
import '../accounts/accounts_repository.dart';
import 'onboarding_service.dart';

/// First launch: welcome → accounts with balances → optional budget → Home.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _AccountChoice {
  _AccountChoice(this.name, this.type, this.colorIndex, {this.on = false});

  final String name;
  final AccountType type;
  final int colorIndex;
  bool on;
  final balance = TextEditingController();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  bool _saving = false;
  final _budget = TextEditingController();

  // Cash is always on (it's the seeded account); the rest are presets.
  late final _choices = [
    for (final (name, type, color) in accountPresets)
      if (type != AccountType.card)
        _AccountChoice(name, type, color, on: type == AccountType.cash),
  ];

  @override
  void dispose() {
    _pages.dispose();
    _budget.dispose();
    for (final c in _choices) {
      c.balance.dispose();
    }
    super.dispose();
  }

  Money _parse(TextEditingController c) => Money.tryParse(c.text) ?? Money.zero;

  void _go(int page) {
    FocusScope.of(context).unfocus();
    setState(() => _page = page);
    unawaited(
      _pages.animateToPage(
        page,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Future<void> _finish({bool withBudget = true}) async {
    if (_saving) return;
    setState(() => _saving = true);
    final cash = _choices.firstWhere((c) => c.type == AccountType.cash);
    await ref
        .read(onboardingServiceProvider)
        .complete(
          cashOpening: _parse(cash.balance),
          extras: [
            for (final c in _choices)
              if (c.on && c.type != AccountType.cash)
                (
                  name: c.name,
                  type: c.type,
                  colorIndex: c.colorIndex,
                  opening: _parse(c.balance),
                ),
          ],
          monthlyBudget: withBudget ? Money.tryParse(_budget.text) : null,
        );
    ref.read(onboardingProvider.notifier).markDone();
    if (mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.screen,
                Space.lg,
                Space.screen,
                0,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 4,
                        margin: const EdgeInsets.symmetric(
                          horizontal: Space.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: i <= _page
                              ? context.colors.brand
                              : context.colors.hairline,
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomePage(onNext: () => _go(1)),
                  _AccountsPage(
                    choices: _choices,
                    onChanged: () => setState(() {}),
                    onNext: () => _go(2),
                    onBack: () => _go(0),
                  ),
                  _BudgetPage(
                    controller: _budget,
                    saving: _saving,
                    onFinish: () => unawaited(_finish()),
                    onSkip: () => unawaited(_finish(withBudget: false)),
                    onBack: () => _go(1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({required this.children, required this.actions});

  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.screen,
              Space.huge,
              Space.screen,
              Space.xl,
            ),
            children: children,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            0,
            Space.screen,
            Space.lg,
          ),
          child: Column(children: actions),
        ),
      ],
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    Widget line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.surfaceRaised,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Icon(icon, size: 20, color: c.brand),
          ),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Text(text, style: AppType.body.copyWith(color: c.ink)),
          ),
        ],
      ),
    );

    return _PageFrame(
      actions: [
        PrimaryButton(
          label: l10n.welcomeStart,
          tone: ButtonTone.accent,
          onPressed: onNext,
        ),
      ],
      children: [
        // ListView stretches children to full width; Align keeps the mark's size.
        const Reveal(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: PoyshikSymbol(height: 84),
          ),
        ),
        const SizedBox(height: Space.xxl),
        Reveal(
          index: 1,
          child: Text(
            l10n.appTitle,
            style: AppType.display.copyWith(fontSize: 64, color: c.brand),
          ),
        ),
        const SizedBox(height: Space.xs),
        Reveal(
          index: 2,
          child: Text(
            l10n.welcomeTitle,
            style: AppType.displaySmall.copyWith(color: c.inkMuted),
          ),
        ),
        const SizedBox(height: Space.huge),
        Reveal(index: 3, child: line(Icons.bolt_rounded, l10n.welcomeLine1)),
        Reveal(
          index: 4,
          child: line(Icons.donut_large_rounded, l10n.welcomeLine2),
        ),
        Reveal(
          index: 5,
          child: line(Icons.lock_outline_rounded, l10n.welcomeLine3),
        ),
      ],
    );
  }
}

class _AccountsPage extends StatelessWidget {
  const _AccountsPage({
    required this.choices,
    required this.onChanged,
    required this.onNext,
    required this.onBack,
  });

  final List<_AccountChoice> choices;
  final VoidCallback onChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return _PageFrame(
      actions: [
        PrimaryButton(label: l10n.setupContinue, onPressed: onNext),
        TextButton(onPressed: onBack, child: Text(l10n.setupBack)),
      ],
      children: [
        Text(
          l10n.setupAccountsTitle,
          style: AppType.titleLarge.copyWith(color: c.ink),
        ),
        const SizedBox(height: Space.sm),
        Text(
          l10n.setupAccountsHint,
          style: AppType.body.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: Space.xl),
        for (final choice in choices)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(Space.lg),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(Radii.lg),
                border: Border.all(
                  color: choice.on ? c.brand : c.hairline,
                  width: choice.on ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CategoryIcon(
                        icon: AppIcons.of(iconForAccountType(choice.type)),
                        color: PoyshikColors.categoryPalette[choice.colorIndex],
                        size: 40,
                      ),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Text(
                          choice.name,
                          style: AppType.bodyStrong.copyWith(color: c.ink),
                        ),
                      ),
                      Switch(
                        value: choice.on,
                        onChanged: choice.type == AccountType.cash
                            ? null
                            : (v) {
                                choice.on = v;
                                onChanged();
                              },
                      ),
                    ],
                  ),
                  if (choice.on) ...[
                    const SizedBox(height: Space.md),
                    TextField(
                      controller: choice.balance,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.setupBalance,
                        prefixText: '${MoneyFormat.symbol} ',
                        hintText: '0',
                      ),
                      style: AppType.amountMedium.copyWith(color: c.ink),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _BudgetPage extends StatelessWidget {
  const _BudgetPage({
    required this.controller,
    required this.saving,
    required this.onFinish,
    required this.onSkip,
    required this.onBack,
  });

  final TextEditingController controller;
  final bool saving;
  final VoidCallback onFinish;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return _PageFrame(
      actions: [
        PrimaryButton(
          label: l10n.setupFinish,
          tone: ButtonTone.accent,
          icon: Icons.check_rounded,
          onPressed: saving ? null : onFinish,
        ),
        TextButton(
          onPressed: saving ? null : onSkip,
          child: Text(l10n.setupSkip),
        ),
        TextButton(onPressed: onBack, child: Text(l10n.setupBack)),
      ],
      children: [
        Text(
          l10n.setupBudgetTitle,
          style: AppType.titleLarge.copyWith(color: c.ink),
        ),
        const SizedBox(height: Space.sm),
        Text(
          l10n.setupBudgetHint,
          style: AppType.body.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: Space.xl),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.budgetAmount,
            prefixText: '${MoneyFormat.symbol} ',
            hintText: '20000',
          ),
          style: AppType.amountMedium.copyWith(color: c.ink),
        ),
      ],
    );
  }
}
