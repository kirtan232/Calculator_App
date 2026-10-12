# Calculator State Lab

A Flutter calculator for CSC 4360 Assignment 01 (alternate edition). It keeps a
**running total** and evaluates operations **left to right** with no operator
precedence, so `2 + 3 × 4 = 20`.

## Setup & run

```bash
flutter pub get
flutter run            # run on an emulator or connected device
flutter test           # run unit and widget tests
flutter build apk      # release build -> build/app/outputs/flutter-apk/app-release.apk
```

## State model

The calculator stores only these fields. The display text is derived from them
and is never stored separately.

| Field | Meaning |
| --- | --- |
| `accumulator` | Running total committed so far (null before the first operator). |
| `currentOperand` | Digits the user is typing right now. |
| `pendingOperator` | Operator waiting for its right-hand operand (+, −, ×, ÷). |
| `awaitingOperand` | True right after an operator: the next digit starts a new operand. |
| `justEvaluated` | True right after `=`: the next digit starts a fresh calculation. |

**Invariant:** if `awaitingOperand` is true, then `pendingOperator` is set and
the display shows `accumulator`.

## Core state contract

| Key sequence | State transition | Display |
| --- | --- | --- |
| `2 + 3` | Store 2 and +; start the second operand at 3. | 3 |
| `×` | Apply 2 + 3, store 5 as the accumulator, wait for the next operand. | 5 |
| `4 =` | Apply 5 × 4 and finish the calculation. | 20 |
| `9 + × 2 =` | The second operator replaces the pending +; evaluate 9 × 2. | 18 |
| `7 + =` | Equals is ignored while waiting for an operand; + stays pending. | 7 |
| Digit after `=` | Starts a new calculation instead of appending to the result. | New digit |
| `AC` | Clears operand, accumulator, pending operator and result phase. | 0 |

## Selected features (undergraduate pathway)

1. **Clear / AC**: resets the display and all calculator state.
2. **Error handling**: division by zero, overflow and incomplete input, with a
   clear message and a way to recover.
3. **Theme toggle**: light and dark themes with a smooth transition.
