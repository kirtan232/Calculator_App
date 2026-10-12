import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calculator_app/main.dart';

/// Reads the main display text.
String displayText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('display'))).data!;

void main() {
  testWidgets('App launches and shows an initial display of 0', (tester) async {
    await tester.pumpWidget(const CalculatorApp());

    expect(find.text('Calculator'), findsOneWidget);
    expect(displayText(tester), '0');
  });

  testWidgets('AC button resets the display and expression', (tester) async {
    await tester.pumpWidget(const CalculatorApp());

    for (final key in ['key_8', 'key_add', 'key_2', 'key_multiply']) {
      await tester.tap(find.byKey(Key(key)));
      await tester.pump();
    }
    expect(displayText(tester), '10');

    await tester.tap(find.byKey(const Key('key_clear')));
    await tester.pump();
    expect(displayText(tester), '0');
    expect(
      tester.widget<Text>(find.byKey(const Key('expression'))).data,
      isEmpty,
    );
  });
}
