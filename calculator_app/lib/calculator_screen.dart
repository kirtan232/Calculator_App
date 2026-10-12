import 'package:flutter/material.dart';

import 'calculator_engine.dart';

/// The calculator UI: a display on top and a button grid below.
///
/// All calculator state lives in [CalculatorEngine]. This widget forwards each
/// tap to the engine inside `setState()` and rebuilds from the engine's
/// derived values, so the UI never keeps its own copy of the state.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final CalculatorEngine _engine = CalculatorEngine();

  void _onDigit(int digit) => setState(() => _engine.inputDigit(digit));

  void _onOperator(Operator operator) =>
      setState(() => _engine.chooseOperator(operator));

  void _onEquals() => setState(_engine.equals);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculator')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: _Display(
                expression: _engine.expression,
                value: _engine.display,
              ),
            ),
            Expanded(flex: 5, child: _buildKeypad()),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _row([_digit(7), _digit(8), _digit(9), _operator(Operator.divide)]),
          _row([_digit(4), _digit(5), _digit(6), _operator(Operator.multiply)]),
          _row([_digit(1), _digit(2), _digit(3), _operator(Operator.subtract)]),
          _row([
            _digit(0, flex: 2),
            _CalcButton(
              label: '=',
              key: const Key('key_equals'),
              kind: _ButtonKind.equals,
              onPressed: _onEquals,
            ),
            _operator(Operator.add),
          ]),
        ],
      ),
    );
  }

  Widget _row(List<Widget> buttons) => Expanded(child: Row(children: buttons));

  Widget _digit(int digit, {int flex = 1}) => _CalcButton(
    label: '$digit',
    key: Key('key_$digit'),
    flex: flex,
    onPressed: () => _onDigit(digit),
  );

  Widget _operator(Operator operator) => _CalcButton(
    label: operator.symbol,
    key: Key('key_${operator.name}'),
    kind: _ButtonKind.operator,
    onPressed: () => _onOperator(operator),
  );
}

/// Shows the expression line (e.g. `5 ×`) above the main value.
class _Display extends StatelessWidget {
  const _Display({required this.expression, required this.value});

  final String expression;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      alignment: Alignment.bottomRight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            expression,
            key: const Key('expression'),
            style: TextStyle(fontSize: 24, color: scheme.onSurfaceVariant),
          ),
          // Flexible + FittedBox shrink long numbers or short screens instead
          // of overflowing.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                key: const Key('display'),
                maxLines: 1,
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w300,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ButtonKind { digit, operator, equals }

/// A single keypad button that fills its share of the row.
class _CalcButton extends StatelessWidget {
  const _CalcButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = _ButtonKind.digit,
    this.flex = 1,
  });

  final String label;
  final VoidCallback onPressed;
  final _ButtonKind kind;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (kind) {
      _ButtonKind.digit => (scheme.surfaceContainerHighest, scheme.onSurface),
      _ButtonKind.operator => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      _ButtonKind.equals => (scheme.primary, scheme.onPrimary),
    };

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            padding: EdgeInsets.zero,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(label, style: const TextStyle(fontSize: 28)),
        ),
      ),
    );
  }
}
