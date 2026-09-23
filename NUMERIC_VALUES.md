# Numeric values

Integer literals such as `4` evaluate to `LiquidValue::Number`; decimal literals such as `4.0` evaluate to `LiquidValue::Float`. Assignments, arrays, objects, and arithmetic filters retain the floating-point distinction, even when the resulting value is integral.

Use `float_value(4.0)` when supplying an explicitly floating-point divisor from MoonBit. The existing `number_value(Double)` helper remains available: integral values retain integer arithmetic semantics, and fractional values use floating-point arithmetic.

For example, `10 | divided_by: 4` yields `2`, while `10 | divided_by: 4.0` yields `2.5`. Assigning the divisor to a variable does not change this result. Integer and floating-point numbers compare by numeric value; neither equals a string containing the same digits. Existing number-to-string formatting is retained.

Code that exhaustively matches `LiquidValue` must handle the new `Float(Double)` variant. Its derived JSON representation uses the `Float` tag. The `floor`, `ceil`, and zero-precision `round` filters return integer-valued `Number` results.
