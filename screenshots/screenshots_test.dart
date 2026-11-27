// Renders real Poyshik screens with DEMO data into PNGs (for review and the
// landing page). Not part of the normal test suite.
//
//   flutter test screenshots --update-goldens
//
// Output: screenshots/out/*.png (1200×2600, 3× a 400×866 logical phone).
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:poyshik/app/app.dart';
import 'package:poyshik/core/dates/clock.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/data/db/app_database.dart';
import 'package:poyshik/data/db/database_provider.dart';
import 'package:poyshik/data/settings_repository.dart';
import 'package:poyshik/features/accounts/accounts_repository.dart';
import 'package:poyshik/features/bazar/bazar_repository.dart';
import 'package:poyshik/features/budgets/budget_repository.dart';
import 'package:poyshik/features/categories/categories_repository.dart';
import 'package:poyshik/features/favourites/favourites_repository.dart';
import 'package:poyshik/features/home/summary_repository.dart';
import 'package:poyshik/features/onboarding/onboarding_service.dart';
import 'package:poyshik/features/recurring/recurring_repository.dart';
import 'package:poyshik/features/transactions/transactions_repository.dart';

import 'demo_data.dart';

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    final bytes = File(p).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> _loadFonts() async {
  await _loadFont('Geist', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
      'assets/fonts/geist/Geist-$w.ttf',
  ]);
  await _loadFont('PoyshikTaka', ['assets/fonts/taka/PoyshikTaka.ttf']);
  await _loadFont('NotoSansBengali', [
    'assets/fonts/noto_bengali/NotoSansBengali.ttf',
  ]);
  await _loadFont('InstrumentSerif', [
    'assets/fonts/instrument_serif/InstrumentSerif-Regular.ttf',
  ]);
  for (final (family, file) in [
    ('PhosphorRegular', 'Phosphor-Regular.ttf'),
    ('PhosphorFill', 'Phosphor-Fill.ttf'),
    ('PhosphorBold', 'Phosphor-Bold.ttf'),
    ('PhosphorDuotone', 'Phosphor-Duotone.ttf'),
  ]) {
    await _loadFont(family, ['assets/fonts/phosphor/$file']);
  }
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? r'D:\dev\flutter';
  await _loadFont('MaterialIcons', [
    '$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  ]);
}

/// The entry sheet asks the repository for the default account; answer with
/// the demo Cash account instead of touching a database.
class _DemoTransactionsRepository extends TransactionsRepository {
  _DemoTransactionsRepository(AppDatabase db)
    : super(db, SettingsRepository(db));

  @override
  Future<String?> defaultAccountId() async => 'cash';

  /// Demo accounts aren't in the database, so saving only pretends.
  @override
  Future<String> add(TransactionDraft d, {String? recurringId}) async =>
      'demo-saved';
}

Widget _app({
  bool dark = false,
  bool firstLaunch = false,
  List<BazarItem> bazar = const [],
  String language = 'en',
}) => ProviderScope(
  overrides: [
    transactionsRepositoryProvider.overrideWithValue(
      _DemoTransactionsRepository(AppDatabase(NativeDatabase.memory())),
    ),
    clockProvider.overrideWithValue(() => demoNow),
    initialSettingsProvider.overrideWithValue({
      SettingKeys.themeMode: dark ? 'dark' : 'light',
      SettingKeys.language: language,
    }),
    startupNeedsOnboardingProvider.overrideWithValue(firstLaunch),
    recentViewsProvider.overrideWith(
      (ref) => Stream.value(demoViews.take(5).toList()),
    ),
    hasTransactionsProvider.overrideWith((ref) => Stream.value(true)),
    // Anything not faked above (e.g. the launch catch-up) gets an empty
    // in-memory database instead of a file.
    appDatabaseProvider.overrideWith((ref) {
      final db = AppDatabase(NativeDatabase.memory());
      ref.onDispose(db.close);
      return db;
    }),
    // v2 features: nothing scheduled, no favourites, empty bazar list.
    recurringRulesProvider.overrideWith((ref) => Stream.value(const [])),
    favouritesProvider.overrideWith((ref, type) => Stream.value(const [])),
    bazarItemsProvider.overrideWith((ref) => Stream.value(bazar)),
    filteredViewsProvider.overrideWith((ref) => Stream.value(demoViews)),
    filteredSummaryProvider.overrideWith(
      (ref) => Stream.value((
        count: demoViews.length,
        spent: demoViews
            .where((v) => v.tx.type == TransactionType.expense)
            .fold(Money.zero, (sum, v) => sum + Money(v.tx.amount)),
      )),
    ),
    activeAccountsProvider.overrideWith(
      (ref) => Stream.value(demoAccountsWithBalances()),
    ),
    archivedAccountsProvider.overrideWith((ref) => Stream.value(const [])),
    overallBudgetProvider.overrideWith((ref) => Stream.value(demoBudget)),
    categoryLimitsProvider.overrideWith((ref) => Stream.value(const {})),
    periodTotalProvider.overrideWith((ref, q) => Stream.value(demoTotal(q))),
    topCategoriesProvider.overrideWith(
      (ref, r) => Stream.value(demoCategoryTotals(r, limit: 4)),
    ),
    categoryTotalsProvider.overrideWith(
      (ref, r) => Stream.value(demoCategoryTotals(r)),
    ),
    expenseEntriesProvider.overrideWith(
      (ref, r) => Stream.value(demoEntries(r)),
    ),
    categoriesByUsageProvider.overrideWith(
      (ref, k) => Stream.value(demoCategoriesByUsage(k)),
    ),
    categoryListProvider.overrideWith(
      (ref, q) => Stream.value(
        demoCategories.where((c) => c.kind == q.kind && !q.archived).toList(),
      ),
    ),
  ],
  child: const PoyshikApp(),
);

Future<void> _phone(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1200, 2598)
    ..devicePixelRatio = 3
    ..padding = const FakeViewPadding(top: 120, bottom: 60)
    ..viewPadding = const FakeViewPadding(top: 120, bottom: 60);
  addTearDown(tester.view.reset);
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
  await expectLater(
    find.byType(PoyshikApp),
    matchesGoldenFile('out/$name.png'),
  );
}

Future<void> _tapText(WidgetTester tester, String text) async {
  // Tabs show their label only when active; otherwise find them by tooltip.
  final byText = find.text(text);
  await tester.tap(
    byText.evaluate().isNotEmpty ? byText.last : find.byTooltip(text).last,
  );
  await tester.pumpAndSettle();
}

/// A shopping trip in progress: some ticked with what was paid.
final _demoBazar = [
  for (final (i, (name, qty, price, done)) in [
    ('Rice', '5 kg', 450, false),
    ('Lentils', '2 kg', 280, false),
    ('Onion', '2 kg', null, false),
    ('Soybean oil', '1 L', 190, false),
    ('Eggs', '2 dozen', 300, true),
    ('Hilsa', '1 kg', 1250, true),
    ('Green chilli', null, null, true),
  ].indexed)
    BazarItem(
      id: 'b$i',
      name: name,
      quantity: qty,
      estimate: price == null ? null : price * 100,
      isDone: done,
      sortOrder: i,
      createdAt: demoNow,
      updatedAt: demoNow,
    ),
];

void main() {
  setUpAll(_loadFonts);

  for (final dark in [false, true]) {
    final suffix = dark ? 'dark' : 'light';

    testWidgets('home $suffix', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(_app(dark: dark));
      await _shot(tester, 'home_$suffix');
    });

    testWidgets('activity $suffix', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(_app(dark: dark));
      await tester.pumpAndSettle();
      await _tapText(tester, 'Activity');
      await _shot(tester, 'activity_$suffix');
    });

    testWidgets('insights $suffix', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(_app(dark: dark));
      await tester.pumpAndSettle();
      await _tapText(tester, 'Insights');
      await _shot(tester, 'insights_$suffix');
    });

    testWidgets('bazar $suffix', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(_app(dark: dark, bazar: _demoBazar));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('Bazar list'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.textContaining('Bazar list'));
      await tester.pumpAndSettle();
      await _shot(tester, 'bazar_$suffix');
    });

    testWidgets('add expense $suffix', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(_app(dark: dark));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add transaction'));
      await tester.pumpAndSettle();
      for (final k in ['3', '2', '0']) {
        await tester.tap(find.text(k).last);
        await tester.pump();
      }
      await tester.tap(find.text('Food').first);
      await _shot(tester, 'add_$suffix');
    });
  }

  // Frames for the website's scroll-scrubbed "How it works" scene: the
  // empty sheet, each key press, the category pick, and the saved state.
  testWidgets('add flow light', (tester) async {
    // Tests draw shadows as solid black outlines by default; the saved
    // frame shows a floating snackbar, so render real shadows here.
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = true);
    await _phone(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add transaction'));
    await _shot(tester, 'flow_0_open');
    final typed = <String>[];
    for (final k in ['3', '2', '0']) {
      await tester.tap(find.text(k).last);
      typed.add(k);
      await _shot(tester, 'flow_${typed.length}_${typed.join()}');
    }
    await tester.tap(find.text('Food').first);
    await _shot(tester, 'flow_4_food');
    await tester.tap(find.text('Save').last);
    // Hold on the confirmation instead of waiting for it to time out.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(
      find.byType(PoyshikApp),
      matchesGoldenFile('out/flow_5_saved.png'),
    );
  });

  // A tall Insights screen for the website's green section, where the
  // phone's screen scrolls through the whole page as the visitor scrolls.
  testWidgets('insights tall dark', (tester) async {
    await _phone(tester);
    tester.view.physicalSize = const Size(1200, 5400);
    await tester.pumpWidget(_app(dark: true));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Insights');
    await _shot(tester, 'insights_tall_dark');
  });

  // The opening intro mid-way: bloom open, "oyshik" sliding out of the P.
  testWidgets('intro light', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(_app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 950));
    await expectLater(
      find.byType(PoyshikApp),
      matchesGoldenFile('out/intro_light.png'),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('add income light', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add transaction'));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Income');
    await _shot(tester, 'add_income_light');
  });

  // Bangla: the UI, dates and amounts (Bangla numerals).
  testWidgets('home bangla light', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(_app(language: 'bn'));
    await _shot(tester, 'home_bn_light');
  });

  testWidgets('insights bangla light', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(_app(language: 'bn'));
    await tester.pumpAndSettle();
    await _tapText(tester, 'বিশ্লেষণ');
    await _shot(tester, 'insights_bn_light');
  });

  testWidgets('accounts light', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _tapText(tester, 'More');
    await _tapText(tester, 'Accounts');
    await _shot(tester, 'accounts_light');
  });

  testWidgets('welcome light', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(_app(firstLaunch: true));
    await _shot(tester, 'welcome_light');
  });
}
