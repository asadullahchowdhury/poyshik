import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/app/app.dart';

void main() {
  testWidgets('App starts on the design gallery', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PoyshikApp()));
    await tester.pumpAndSettle();

    expect(find.text('Design system'), findsOneWidget);
  });
}
