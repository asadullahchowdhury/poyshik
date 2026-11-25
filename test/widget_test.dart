import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/main.dart';

void main() {
  testWidgets('App starts and shows the Poyshik placeholder', (tester) async {
    await tester.pumpWidget(const PoyshikApp());

    expect(find.text('Poyshik'), findsOneWidget);
  });
}
