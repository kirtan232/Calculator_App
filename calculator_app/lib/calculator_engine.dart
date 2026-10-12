/// Pure-Dart calculator model with a running total evaluated left to right.
///
/// There is no operator precedence: `2 + 3 × 4` is evaluated as
/// `(2 + 3) × 4 = 20`. This class has no Flutter dependency so every state
/// transition can be unit tested directly.
library;

/// The four arithmetic operations supported by the calculator.
enum Operator {
  add('+'),
  subtract('−'),
  multiply('×'),
  divide('÷');

  const Operator(this.symbol);

  /// Symbol shown on the button and in the expression line.
  final String symbol;

  /// Applies this operator to [left] and [right].
  double apply(double left, double right) {
    switch (this) {
      case Operator.add:
        return left + right;
      case Operator.subtract:
        return left - right;
      case Operator.multiply:
        return left * right;
      case Operator.divide:
        return left / right;
    }
  }
}

/// Holds the calculator state and exposes one method per user action.
///
/// Authoritative state:
/// * [accumulator]: running total committed so far (null before the first
///   operator).
/// * `_currentOperand`: digits the user is typing right now.
/// * [pendingOperator]: operator waiting for its right-hand operand.
/// * [awaitingOperand]: true right after an operator; the next digit starts a
///   new operand.
/// * [justEvaluated]: true right after `=`; the next digit starts a fresh
///   calculation.
///
/// [display] is derived from these fields and never stored.
///
/// Error state: [errorMessage] is set after division by zero or overflow.
/// While it is set, operators and `=` are ignored; a digit starts a fresh
/// calculation and `AC` resets.
///
/// [hint] is a non-fatal message for incomplete input (for example `7 + =`).
/// It never changes calculator state and is cleared by the next key press.
///
/// Invariant: when [awaitingOperand] is true, [pendingOperator] and
/// [accumulator] are both non-null.
class CalculatorEngine {
  /// Maximum number of digits accepted for a single operand.
  static const int maxDigits = 12;

  /// Results with a magnitude at or above this are reported as overflow.
  static const double maxMagnitude = 1e15;

  static const String divideByZeroMessage = 'Cannot divide by 0';
  static const String overflowMessage = 'Result too large';
  static const String recoverHint = 'Enter a number or press AC';

  double? _accumulator;
  String _currentOperand = '0';
  Operator? _pendingOperator;
  bool _awaitingOperand = false;
  bool _justEvaluated = false;
  String? _errorMessage;
  String? _hint;

  double? get accumulator => _accumulator;
  Operator? get pendingOperator => _pendingOperator;
  bool get awaitingOperand => _awaitingOperand;
  bool get justEvaluated => _justEvaluated;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  String? get hint => _hint;

  /// Text for the main display: the error message if there is one, the
  /// running total while waiting for an operand or after `=`, otherwise the
  /// operand being typed.
  String get display {
    final error = _errorMessage;
    if (error != null) return error;
    if (_awaitingOperand || _justEvaluated) {
      return formatNumber(_accumulator!);
    }
    return _currentOperand;
  }

  /// Secondary line showing the committed total and pending operator, for
  /// example `5 ×`. Empty when no operation is pending.
  String get expression {
    final pending = _pendingOperator;
    if (pending == null) return '';
    return '${formatNumber(_accumulator!)} ${pending.symbol}';
  }

  /// Handles a digit key (0–9).
  void inputDigit(int digit) {
    assert(digit >= 0 && digit <= 9, 'digit must be 0-9');
    _hint = null;
    final key = digit.toString();

    if (_justEvaluated || hasError) {
      // A digit after `=` or an error starts a brand-new calculation.
      _resetState();
      _currentOperand = key;
    } else if (_awaitingOperand) {
      // A digit after an operator starts the next operand.
      _currentOperand = key;
      _awaitingOperand = false;
    } else if (_currentOperand == '0') {
      _currentOperand = key;
    } else if (_currentOperand.length < maxDigits) {
      _currentOperand += key;
    }
  }

  /// Handles an operator key (+, −, ×, ÷).
  void chooseOperator(Operator operator) {
    _hint = null;
    if (hasError) {
      // There is no valid number to operate on; tell the user how to recover.
      _hint = recoverHint;
      return;
    }

    if (_justEvaluated) {
      // Continue calculating from the previous result.
      _pendingOperator = operator;
      _awaitingOperand = true;
      _justEvaluated = false;
      return;
    }

    if (_awaitingOperand) {
      // Operator pressed twice in a row: replace the pending one.
      _pendingOperator = operator;
      return;
    }

    final operand = double.parse(_currentOperand);
    final pending = _pendingOperator;
    if (pending == null) {
      _accumulator = operand;
    } else if (!_applyPending(pending, operand)) {
      return;
    }
    _pendingOperator = operator;
    _awaitingOperand = true;
  }

  /// Handles the `=` key.
  void equals() {
    _hint = null;
    if (hasError) {
      _hint = recoverHint;
      return;
    }

    final pending = _pendingOperator;
    if (pending == null) return; // Nothing to calculate.
    if (_awaitingOperand) {
      // Incomplete input such as `7 + =`: keep the state, explain why.
      _hint = 'Enter a number after ${pending.symbol}';
      return;
    }

    if (!_applyPending(pending, double.parse(_currentOperand))) return;
    _pendingOperator = null;
    _justEvaluated = true;
  }

  /// Handles the `AC` (all clear) key: clears the operand, accumulator,
  /// pending operator, result phase and any error, returning the display to
  /// `0`.
  void clear() => _resetState();

  /// Applies [pending] to the accumulator and [operand], storing the result.
  ///
  /// Returns false and enters the error state on division by zero or
  /// overflow.
  bool _applyPending(Operator pending, double operand) {
    if (pending == Operator.divide && operand == 0) {
      _enterError(divideByZeroMessage);
      return false;
    }
    final result = pending.apply(_accumulator!, operand);
    if (!result.isFinite || result.abs() >= maxMagnitude) {
      _enterError(overflowMessage);
      return false;
    }
    _accumulator = result;
    return true;
  }

  void _enterError(String message) {
    _resetState();
    _errorMessage = message;
  }

  void _resetState() {
    _accumulator = null;
    _currentOperand = '0';
    _pendingOperator = null;
    _awaitingOperand = false;
    _justEvaluated = false;
    _errorMessage = null;
    _hint = null;
  }

  /// Formats [value] for display: whole numbers exactly and without a
  /// trailing `.0`, and other values rounded to 10 significant digits to hide
  /// floating-point noise (for example `0.1 + 0.2`).
  static String formatNumber(double value) {
    if (!value.isFinite) return value.toString();
    // Whole numbers are exact in a double below 2^53, so show every digit.
    if (value == value.truncateToDouble() && value.abs() < maxMagnitude) {
      return value.toInt().toString();
    }
    final rounded = double.parse(value.toStringAsPrecision(10));
    if (rounded == rounded.truncateToDouble() && rounded.abs() < maxMagnitude) {
      return rounded.toInt().toString();
    }
    return rounded.toString();
  }
}
