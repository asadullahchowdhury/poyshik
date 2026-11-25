import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:poyshik/app/theme/theme.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/core/widgets/amount_text.dart';

Future<String> _render(WidgetTester tester, AmountText widget) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: widget),
    ),
  );
  final rich = tester.widget<Text>(find.byType(Text)).textSpan!;
  return rich.toPlainText();
}

void main() {
  testWidgets('uses South Asian (lakh) grouping', (tester) async {
    expect(
      await _render(tester, const AmountText(Money(12500000))),
      '৳1,25,000',
    );
    expect(await _render(tester, const AmountText(Money(99900))), '৳999');
    expect(
      await _render(tester, const AmountText(Money(123456789))),
      '৳12,34,567.89',
    );
  });

  testWidgets('hides .00 but shows real decimals', (tester) async {
    expect(await _render(tester, const AmountText(Money(100))), '৳1');
    expect(await _render(tester, const AmountText(Money(105))), '৳1.05');
  });

  testWidgets('sign follows tone when showSign is on', (tester) async {
    expect(
      await _render(
        tester,
        const AmountText(Money(500), tone: AmountTone.expense, showSign: true),
      ),
      '−৳5',
    );
    expect(
      await _render(
        tester,
        const AmountText(Money(500), tone: AmountTone.income, showSign: true),
      ),
      '+৳5',
    );
  });
}
