import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calculator_app/main.dart';

/// Reads the main display text.
String displayText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('display'))).data!;

/// Taps each keypad button in [keys] (e.g. `'2+3*4='`), like a user would.
///
/// Digits map to `key_<digit>`, `+ - * /` to the operator buttons, `=` to
/// equals and `C` to AC.
Future<void> tapKeys(WidgetTester tester, String keys) async {
  const names = {
    '+': 'add',
    '-': 'subtract',
    '*': 'multiply',
    '/': 'divide',
    '=': 'equals',
    'C': 'clear',
  };
  for (final key in keys.split('')) {
    await tester.tap(find.byKey(Key('key_${names[key] ?? key}')));
    await tester.pump();
  }
}

void main() {
  group('Core contract through the UI', () {
    testWidgets('2 + 3 × 4 = shows 3, then 5, then 20', (tester) async {
      await tester.pumpWidget(const CalculatorApp());

      await tapKeys(tester, '2+3');
      expect(displayText(tester), '3');
      await tapKeys(tester, '*');
      expect(displayText(tester), '5');
      expect(
        tester.widget<Text>(find.byKey(const Key('expression'))).data,
        '5 ×',
      );
      await tapKeys(tester, '4=');
      expect(displayText(tester), '20');
    });

    testWidgets('9 + × 2 = replaces the operator and shows 18', (tester) async {
      await tester.pumpWidget(const CalculatorApp());
      await tapKeys(tester, '9+*2=');
      expect(displayText(tester), '18');
    });

    testWidgets('7 + = keeps 7 and shows a hint', (tester) async {
      await tester.pumpWidget(const CalculatorApp());
      await tapKeys(tester, '7+=');
      expect(displayText(tester), '7');
      expect(find.text('Enter a number after +'), findsOneWidget);
    });

    testWidgets('digit after equals starts a new calculation', (tester) async {
      await tester.pumpWidget(const CalculatorApp());
      await tapKeys(tester, '6-1=');
      expect(displayText(tester), '5');
      await tapKeys(tester, '8');
      expect(displayText(tester), '8');
    });

    testWidgets('8 + 2 × AC 4 + 1 = shows 5', (tester) async {
      await tester.pumpWidget(const CalculatorApp());
      await tapKeys(tester, '8+2*C4+1=');
      expect(displayText(tester), '5');
    });
  });

  group('Responsive layout', () {
    // A RenderFlex overflow throws during the test, so reaching the expects
    // means the layout fit. Sizes are logical pixels: small phone, typical
    // phone, landscape phone and tablet.
    const sizes = [
      Size(320, 480),
      Size(360, 640),
      Size(640, 360),
      Size(800, 1280),
    ];
    for (final size in sizes) {
      testWidgets('fits without overflow at ${size.width}x${size.height}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(const CalculatorApp());
        // A long number and an error message stress the display width.
        await tapKeys(tester, '123456789012');
        expect(displayText(tester), '123456789012');
        await tapKeys(tester, '/0=');
        expect(displayText(tester), 'Cannot divide by 0');
        expect(tester.takeException(), isNull);
      });
    }
  });

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
