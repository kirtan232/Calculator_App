import 'package:flutter_test/flutter_test.dart';

import 'package:calculator_app/calculator_engine.dart';

/// Feeds a key sequence such as `'2+3*4='` into [engine].
///
/// Digits map to [CalculatorEngine.inputDigit], `+ - * /` to
/// [CalculatorEngine.chooseOperator] and `=` to [CalculatorEngine.equals].
/// Spaces are ignored so sequences can be written like the assignment table.
void press(CalculatorEngine engine, String keys) {
  const operators = {
    '+': Operator.add,
    '-': Operator.subtract,
    '*': Operator.multiply,
    '/': Operator.divide,
  };
  for (final key in keys.split('')) {
    if (key == ' ') continue;
    final digit = int.tryParse(key);
    if (digit != null) {
      engine.inputDigit(digit);
    } else if (operators.containsKey(key)) {
      engine.chooseOperator(operators[key]!);
    } else if (key == '=') {
      engine.equals();
    } else {
      throw ArgumentError('Unknown key: $key');
    }
  }
}

/// Returns the display after pressing [keys] on a fresh engine.
String displayAfter(String keys) {
  final engine = CalculatorEngine();
  press(engine, keys);
  return engine.display;
}

void main() {
  group('Initial state', () {
    test('display starts at 0 with no pending state', () {
      final engine = CalculatorEngine();
      expect(engine.display, '0');
      expect(engine.accumulator, isNull);
      expect(engine.pendingOperator, isNull);
      expect(engine.awaitingOperand, isFalse);
      expect(engine.justEvaluated, isFalse);
    });
  });

  group('Digit entry', () {
    test('digits append to the current operand', () {
      expect(displayAfter('123'), '123');
    });

    test('leading zero is replaced, not appended', () {
      expect(displayAfter('007'), '7');
    });

    test('operand length is capped at maxDigits', () {
      expect(displayAfter('1' * 20), '1' * CalculatorEngine.maxDigits);
    });
  });

  // One test per row of the core state contract table.
  group('Core state contract', () {
    test('2 + 3: digit after operator starts the second operand', () {
      final engine = CalculatorEngine();
      press(engine, '2+3');
      expect(engine.display, '3');
      expect(engine.accumulator, 2);
      expect(engine.pendingOperator, Operator.add);
      expect(engine.awaitingOperand, isFalse);
    });

    test('2 + 3 ×: next operator applies the pending one and shows 5', () {
      final engine = CalculatorEngine();
      press(engine, '2+3*');
      expect(engine.display, '5');
      expect(engine.accumulator, 5);
      expect(engine.pendingOperator, Operator.multiply);
      expect(engine.awaitingOperand, isTrue);
    });

    test('2 + 3 × 4 =: left to right gives 20', () {
      expect(displayAfter('2+3*4='), '20');
    });

    test('9 + × 2 =: second operator replaces the first', () {
      final engine = CalculatorEngine();
      press(engine, '9+*');
      expect(engine.pendingOperator, Operator.multiply);
      expect(engine.display, '9');
      press(engine, '2=');
      expect(engine.display, '18');
    });

    test('7 + =: equals without a new operand is ignored', () {
      final engine = CalculatorEngine();
      press(engine, '7+=');
      expect(engine.display, '7');
      expect(engine.pendingOperator, Operator.add);
      expect(engine.awaitingOperand, isTrue);
      expect(engine.justEvaluated, isFalse);
    });

    test('digit after equals starts a fresh calculation', () {
      final engine = CalculatorEngine();
      press(engine, '1+1=');
      expect(engine.display, '2');
      press(engine, '5');
      expect(engine.display, '5');
      expect(engine.accumulator, isNull);
      expect(engine.pendingOperator, isNull);
      // The old result must not leak into the next calculation.
      press(engine, '+1=');
      expect(engine.display, '6');
    });

    test('equals with no operator is ignored', () {
      expect(displayAfter('42='), '42');
    });

    test('repeated equals does not re-apply the operation', () {
      expect(displayAfter('2+3=='), '5');
    });

    test('operator after equals continues from the result', () {
      expect(displayAfter('2+3=*4='), '20');
    });
  });

  group('Left-to-right evaluation (no precedence)', () {
    test('2 + 3 × 4 is 20, not 14', () {
      // Catches a regression to conventional precedence (2 + 12 = 14).
      expect(displayAfter('2+3*4='), isNot('14'));
      expect(displayAfter('2+3*4='), '20');
    });

    test('10 − 4 ÷ 2 is 3, not 8', () {
      expect(displayAfter('10-4/2='), '3');
    });

    test('running total is shown after each operator in a long chain', () {
      final engine = CalculatorEngine();
      press(engine, '8+2');
      press(engine, '*');
      expect(engine.display, '10');
      press(engine, '3-');
      expect(engine.display, '30');
      press(engine, '6/');
      expect(engine.display, '24');
      press(engine, '4=');
      expect(engine.display, '6');
    });
  });

  group('Four operations', () {
    test('addition', () => expect(displayAfter('12+30='), '42'));
    test('subtraction', () => expect(displayAfter('5-8='), '-3'));
    test('multiplication', () => expect(displayAfter('6*7='), '42'));
    test('division with whole result', () => expect(displayAfter('84/2='), '42'));
    test('division with fractional result', () {
      expect(displayAfter('7/2='), '3.5');
    });
    test('division result is rounded for display', () {
      expect(displayAfter('1/3='), '0.3333333333');
    });
  });

  group('formatNumber', () {
    test('drops trailing .0 on whole numbers', () {
      expect(CalculatorEngine.formatNumber(20.0), '20');
    });

    test('hides floating-point noise', () {
      expect(CalculatorEngine.formatNumber(0.1 + 0.2), '0.3');
    });
  });
}
