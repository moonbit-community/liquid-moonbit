///|
pub fn parse_number(text : String) -> Double? {
  if text.is_empty() {
    return None
  }
  let mut pos = if text[0] == 45 || text[0] == 43 { 1 } else { 0 }
  let start = pos
  while pos < text.length() && text[pos] >= 48 && text[pos] <= 57 {
    pos += 1
  }
  if pos == start {
    return None
  }
  if pos < text.length() && text[pos] == 46 {
    pos += 1
    let start = pos
    while pos < text.length() && text[pos] >= 48 && text[pos] <= 57 {
      pos += 1
    }
    if pos == start {
      return None
    }
  }
  if pos != text.length() {
    return None
  }
  Some(@string.parse_double(text)) catch {
    _ => None
  }
}

///|
pub fn is_truthy(value : LiquidValue) -> Bool {
  match value {
    Null | Bool(false) => false
    _ => true
  }
}

///|
pub fn values_equal(left : LiquidValue, right : LiquidValue) -> Bool {
  match (left, right) {
    (Null, Null) => true
    (Bool(a), Bool(b)) => a == b
    (Number(a) | Float(a), Number(b) | Float(b)) => a == b
    (String(a), String(b)) => a == b
    (Array(a), Array(b)) => {
      if a.length() != b.length() {
        return false
      }
      for i, value in a {
        if !values_equal(value, b[i]) {
          return false
        }
      }
      true
    }
    (Object(a), Object(b)) =>
      a.length() == b.length() &&
      a
      .iter()
      .all(fn(pair) {
        match b.get(pair.0) {
          Some(v) => values_equal(pair.1, v)
          None => false
        }
      })
    _ => false
  }
}

///|
pub fn compare_typed_values(
  left_value : LiquidValue,
  right_value : LiquidValue,
  operator : String,
) -> Bool {
  match operator {
    "==" => values_equal(left_value, right_value)
    "!=" => !values_equal(left_value, right_value)
    "contains" =>
      match (left_value, right_value) {
        (String(haystack), String(needle)) => haystack.contains(needle)
        (Array(arr), needle) => {
          let mut found = false
          for item in arr {
            if values_equal(item, needle) {
              found = true
              break
            }
          }
          found
        }
        _ => false
      }
    ">" =>
      match (left_value, right_value) {
        (Number(l) | Float(l), Number(r) | Float(r)) => l > r
        (String(l), String(r)) => l > r
        _ => false
      }
    "<" =>
      match (left_value, right_value) {
        (Number(l) | Float(l), Number(r) | Float(r)) => l < r
        (String(l), String(r)) => l < r
        _ => false
      }
    ">=" =>
      match (left_value, right_value) {
        (Number(l) | Float(l), Number(r) | Float(r)) => l >= r
        (String(l), String(r)) => l >= r
        _ => false
      }
    "<=" =>
      match (left_value, right_value) {
        (Number(l) | Float(l), Number(r) | Float(r)) => l <= r
        (String(l), String(r)) => l <= r
        _ => false
      }
    _ => false
  }
}

///|
pub fn unquote_argument(text : String) -> String {
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
pub fn numeric_parts(value : LiquidValue) -> (Double, Bool)? {
  match value {
    Number(n) => Some((n, n != n.trunc()))
    Float(n) => Some((n, true))
    String(s) => parse_number(s).map(fn(n) { (n, s.contains(".")) })
    _ => None
  }
}

///|
pub fn numeric_result(n : Double, floating : Bool) -> LiquidValue {
  if floating {
    @value.float_value(n)
  } else {
    @value.number_value(n)
  }
}

///|
pub fn parse_integer(text : String) -> Int? {
  Some(@string.parse_int(unquote_argument(text.trim().to_owned()))) catch {
    _ => None
  }
}
