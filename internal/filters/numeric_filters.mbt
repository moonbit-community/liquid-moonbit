///|
fn typed_numeric_filter(
  value : LiquidValue,
  name : String,
  operand : LiquidValue,
) -> LiquidValue {
  guard @semantics.numeric_parts(value) is Some((n, left_float)) else {
    return value
  }
  guard @semantics.numeric_parts(operand) is Some((p, right_float)) else {
    return value
  }
  let floating = left_float || right_float
  match name {
    "plus" => @semantics.numeric_result(n + p, floating)
    "minus" => @semantics.numeric_result(n - p, floating)
    "times" => @semantics.numeric_result(n * p, floating)
    "divided_by" =>
      if p == 0 {
        @value.null_value()
      } else {
        @semantics.numeric_result(
          if floating {
            n / p
          } else {
            (n / p).floor()
          },
          floating,
        )
      }
    "modulo" =>
      if p == 0 {
        @value.null_value()
      } else {
        @semantics.numeric_result(n % p, floating)
      }
    "round" => {
      if p != p.trunc() || p < -308 || p > 308 {
        return value
      }
      let mut scale = 1.0
      for _ in 0..<p.abs().to_int() {
        scale *= 10.0
      }
      @semantics.numeric_result(
        if p < 0 {
          (n / scale).round() * scale
        } else {
          (n * scale).round() / scale
        },
        p > 0,
      )
    }
    _ => value
  }
}
