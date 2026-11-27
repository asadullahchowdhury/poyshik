import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:poyshik/app/intro.dart';
import 'package:poyshik/app/theme/theme.dart';
import 'package:poyshik/core/widgets/poyshik_logo.dart';

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int taps = 0;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => setState(() => taps++),
    child: Text('taps $taps'),
  );
}

Widget _host({bool reduced = false}) => MaterialApp(
  theme: AppTheme.light,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: const AppIntro(
      child: Scaffold(body: Center(child: _Counter())),
    ),
  ),
);

void main() {
  testWidgets('plays once, then leaves the app as it was', (tester) async {
    await tester.pumpWidget(_host());
    expect(find.byType(PoyshikLogo), findsOneWidget);

    // Taps go through to the app even while the intro is still fading.
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.tap(find.text('taps 0'));
    await tester.pumpAndSettle();

    expect(find.byType(PoyshikLogo), findsNothing);
    // Same state object: removing the intro did not rebuild the app.
    expect(find.text('taps 1'), findsOneWidget);
  });

  testWidgets('skipped when animations are turned off', (tester) async {
    await tester.pumpWidget(_host(reduced: true));
    expect(find.byType(PoyshikLogo), findsNothing);
    expect(find.text('taps 0'), findsOneWidget);
  });
}
