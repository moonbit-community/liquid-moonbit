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
  let number = match value {
    Number(n) => Some(n)
    String(s) => parse_number(s)
    _ => None
  }
  guard number is Some(n) else { return value }
  guard parse_number(unquote_argument(parameters[0])) is Some(p) else {
    return value
  }
  match name {
    "plus" => Number(n + p)
    "minus" => Number(n - p)
    "times" => Number(n * p)
    "divided_by" =>
      if p == 0 {
        Null
      } else {
        Number(
          if unquote_argument(parameters[0]).contains(".") {
            n / p
          } else {
            (n / p).floor()
          },
        )
      }
    "modulo" => if p == 0 { Null } else { Number(n % p) }
    "round" => {
      if p != p.trunc() || p < -308 || p > 308 {
        return value
      }
      let mut scale = 1.0
      for _ in 0..<p.abs().to_int() {
        scale *= 10.0
      }
      if p < 0 {
        Number((n / scale).round() * scale)
      } else {
        Number((n * scale).round() / scale)
      }
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
