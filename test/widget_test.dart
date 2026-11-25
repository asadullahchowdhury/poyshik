import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/app/app.dart';

void main() {
  testWidgets('App starts and shows localized title and tagline', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: PoyshikApp()));
    await tester.pumpAndSettle();

    expect(find.text('Poyshik'), findsOneWidget);
    expect(find.text('Know where your money goes.'), findsOneWidget);
  });
}
