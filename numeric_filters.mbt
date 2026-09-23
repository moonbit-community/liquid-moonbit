///|
fn unquote_argument(text : String) -> String {
  let text = text.trim().to_owned()
  if text.length() >= 2 &&
    (text[0] == 39 || text[0] == 34) &&
    text[text.length() - 1] == text[0] {
    text[1:text.length() - 1].to_owned()
  } else {
    text
  }
}

///|
fn numeric_filter(
  value : LiquidValue,
  name : String,
  parameters : Array[String],
) -> LiquidValue {
  if parameters.is_empty() {
    return apply_filter(value, name)
  }
  typed_numeric_filter(value, name, String(unquote_argument(parameters[0])))
}

///|
fn numeric_parts(value : LiquidValue) -> (Double, Bool)? {
  match value {
    Number(n) => Some((n, n != n.trunc()))
    Float(n) => Some((n, true))
    String(s) => parse_number(s).map(fn(n) { (n, s.contains(".")) })
    _ => None
  }
}

///|
fn numeric_result(n : Double, floating : Bool) -> LiquidValue {
  if floating {
    Float(n)
  } else {
    Number(n)
  }
}

///|
fn typed_numeric_filter(
  value : LiquidValue,
  name : String,
  operand : LiquidValue,
) -> LiquidValue {
  guard numeric_parts(value) is Some((n, left_float)) else { return value }
  guard numeric_parts(operand) is Some((p, right_float)) else { return value }
  let floating = left_float || right_float
  match name {
    "plus" => numeric_result(n + p, floating)
    "minus" => numeric_result(n - p, floating)
    "times" => numeric_result(n * p, floating)
    "divided_by" =>
      if p == 0 {
        Null
      } else {
        numeric_result(if floating { n / p } else { (n / p).floor() }, floating)
      }
    "modulo" => if p == 0 { Null } else { numeric_result(n % p, floating) }
    "round" => {
      if p != p.trunc() || p < -308 || p > 308 {
        return value
      }
      let mut scale = 1.0
      for _ in 0..<p.abs().to_int() {
        scale *= 10.0
      }
      numeric_result(
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

///|
fn parse_integer(text : String) -> Int? {
  Some(@string.parse_int(unquote_argument(text.trim().to_owned()))) catch {
    _ => None
  }
}
