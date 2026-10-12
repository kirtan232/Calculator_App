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

## Error handling

| Situation | What happens | Recovery |
| --- | --- | --- |
| `8 ÷ 0 =` (or `8 ÷ 0 +`) | Display shows "Cannot divide by 0"; all pending state is cleared. | Type a digit to start fresh, or press AC. |
| Result ≥ 1e15 | Display shows "Result too large". | Type a digit or press AC. |
| `7 + =` (incomplete) | State is unchanged (core contract); hint "Enter a number after +". | Type the missing number. |
| Operator or `=` during an error | Ignored; hint "Enter a number or press AC". | Type a digit or press AC. |

## Selected features (undergraduate pathway)

1. **Clear / AC**: resets the display and all calculator state.
2. **Error handling**: division by zero, overflow and incomplete input, with a
   clear message and a way to recover.
3. **Theme toggle**: light and dark themes with a smooth transition.
   The sun/moon button in the app bar switches every surface; colors fade over
   400 ms and the calculation in progress is kept.

## Accessibility

- Operator buttons are read as words ("plus", "minus", "times", "divided by",
  "equals", "All clear") instead of symbols.
- The display is a live region, so TalkBack announces the new value without
  moving focus off the keypad. Errors are read as "Error: …".
- Errors and hints use text and an icon, not color alone.
- Buttons are at least 48 dp tall.

## Project structure

| File | Purpose |
| --- | --- |
| `lib/main.dart` | App entry point; owns the light/dark theme. |
| `lib/calculator_screen.dart` | UI: display, keypad, theme toggle. Calls the engine inside `setState()`. |
| `lib/calculator_engine.dart` | Pure-Dart calculator state and transitions (no Flutter imports). |
| `test/calculator_engine_test.dart` | Unit tests for every state transition, error and AC case. |
| `test/widget_test.dart` | UI tests: tapping key sequences, theme, semantics, small screens. |

**Why a separate engine?** Keeping the arithmetic and state in a plain Dart
class means every transition can be unit tested without building widgets, and
the screen stays a thin layer that only forwards taps and renders derived
values. An expression parser was not needed because left-to-right evaluation
only ever combines the running total with one new operand.

## Testing

```bash
flutter analyze   # static checks
flutter test      # 59 unit + widget tests
```

Key regression tests:

- `2 + 3 × 4 = 20` (not 14) guards the left-to-right rule.
- `8 + 2 × AC 4 + 1 = 5` catches a stale accumulator after AC.
- `1 + 1 = 5 + 1 = 6` catches a stale result after equals.
- Layout tests at 320×480, 360×640, 640×360 and 800×1280 catch overflow.

## Release build

```bash
flutter build apk
# Output: build/app/outputs/flutter-apk/app-release.apk
# Rename to YourName_CalculatorApp.apk before submitting.
```
