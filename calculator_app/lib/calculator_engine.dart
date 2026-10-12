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
/// Invariant: when [awaitingOperand] is true, [pendingOperator] and
/// [accumulator] are both non-null.
class CalculatorEngine {
  /// Maximum number of digits accepted for a single operand.
  static const int maxDigits = 12;

  double? _accumulator;
  String _currentOperand = '0';
  Operator? _pendingOperator;
  bool _awaitingOperand = false;
  bool _justEvaluated = false;

  double? get accumulator => _accumulator;
  Operator? get pendingOperator => _pendingOperator;
  bool get awaitingOperand => _awaitingOperand;
  bool get justEvaluated => _justEvaluated;

  /// Text for the main display: the running total while waiting for an
  /// operand or after `=`, otherwise the operand being typed.
  String get display {
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
    final key = digit.toString();

    if (_justEvaluated) {
      // A digit after `=` starts a brand-new calculation.
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
    // Apply the pending operation first, so evaluation is left to right.
    _accumulator = pending == null
        ? operand
        : pending.apply(_accumulator!, operand);
    _pendingOperator = operator;
    _awaitingOperand = true;
  }

  /// Handles the `=` key.
  void equals() {
    final pending = _pendingOperator;
    // Nothing to apply, or no new operand yet: ignore.
    if (pending == null || _awaitingOperand) return;

    _accumulator = pending.apply(_accumulator!, double.parse(_currentOperand));
    _pendingOperator = null;
    _justEvaluated = true;
  }

  /// Handles the `AC` (all clear) key: clears the operand, accumulator,
  /// pending operator and result phase, returning the display to `0`.
  void clear() => _resetState();

  void _resetState() {
    _accumulator = null;
    _currentOperand = '0';
    _pendingOperator = null;
    _awaitingOperand = false;
    _justEvaluated = false;
  }

  /// Formats [value] for display: whole numbers without a trailing `.0`, and
  /// other values rounded to 10 significant digits to hide floating-point
  /// noise (for example `0.1 + 0.2`).
  static String formatNumber(double value) {
    if (!value.isFinite) return value.toString();
    final rounded = double.parse(value.toStringAsPrecision(10));
    if (rounded == rounded.truncateToDouble() && rounded.abs() < 1e15) {
      return rounded.toInt().toString();
    }
    return rounded.toString();
  }
}
