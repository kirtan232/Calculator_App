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

  testWidgets('division by zero shows an error and a digit recovers', (
    tester,
  ) async {
    await tester.pumpWidget(const CalculatorApp());

    for (final key in ['key_8', 'key_divide', 'key_0', 'key_equals']) {
      await tester.tap(find.byKey(Key(key)));
      await tester.pump();
    }
    expect(displayText(tester), 'Cannot divide by 0');

    await tester.tap(find.byKey(const Key('key_add')));
    await tester.pump();
    expect(find.byKey(const Key('hint')), findsOneWidget);

    await tester.tap(find.byKey(const Key('key_4')));
    await tester.pump();
    expect(displayText(tester), '4');
    expect(find.byKey(const Key('hint')), findsNothing);
  });

  testWidgets('theme toggle switches between light and dark and keeps state', (
    tester,
  ) async {
    await tester.pumpWidget(const CalculatorApp());
    Brightness brightness() =>
        Theme.of(tester.element(find.byKey(const Key('display')))).brightness;

    // Enter part of a calculation so we can check it survives the switch.
    for (final key in ['key_7', 'key_add']) {
      await tester.tap(find.byKey(Key(key)));
      await tester.pump();
    }
    expect(brightness(), Brightness.light);
    expect(find.byTooltip('Switch to dark theme'), findsOneWidget);

    await tester.tap(find.byKey(const Key('theme_toggle')));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);
    expect(find.byTooltip('Switch to light theme'), findsOneWidget);
    expect(displayText(tester), '7');
    expect(
      tester.widget<Text>(find.byKey(const Key('expression'))).data,
      '7 +',
    );

    await tester.tap(find.byKey(const Key('theme_toggle')));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);
  });

  testWidgets('theme change animates instead of jumping', (tester) async {
    await tester.pumpWidget(const CalculatorApp());
    Color background() =>
        Theme.of(tester.element(find.byKey(const Key('display'))))
            .colorScheme
            .surface;
    final light = background();

    await tester.tap(find.byKey(const Key('theme_toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final midway = background();
    await tester.pumpAndSettle();
    final dark = background();

    expect(midway, isNot(light));
    expect(midway, isNot(dark));
  });

  testWidgets('buttons and display have screen reader labels', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const CalculatorApp());

    expect(find.bySemanticsLabel('times'), findsOneWidget);
    expect(find.bySemanticsLabel('divided by'), findsOneWidget);
    expect(find.bySemanticsLabel('minus'), findsOneWidget);
    expect(find.bySemanticsLabel('plus'), findsOneWidget);
    expect(find.bySemanticsLabel('equals'), findsOneWidget);
    expect(find.bySemanticsLabel('All clear'), findsOneWidget);

    for (final key in ['key_8', 'key_divide', 'key_0', 'key_equals']) {
      await tester.tap(find.byKey(Key(key)));
      await tester.pump();
    }
    expect(find.bySemanticsLabel('Error: Cannot divide by 0'), findsOneWidget);

    semantics.dispose();
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
