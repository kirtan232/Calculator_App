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
}
