///|
fn parse_number(text : String) -> Double? {
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
pub fn evaluate_expression(
  expression : String,
  context : LiquidContext,
) -> LiquidValue {
  let text = expression.trim().to_owned()
  if text.length() >= 2 &&
    (text[0] == 39 || text[0] == 34) &&
    text[text.length() - 1] == text[0] {
    return String(text[1:text.length() - 1].to_owned())
  }
  match text {
    "true" => Bool(true)
    "false" => Bool(false)
    "nil" | "null" => Null
    _ =>
      match parse_number(text) {
        Some(number) => Number(number)
        None => context.get(text).unwrap_or(Null)
      }
  }
}

///|
fn is_truthy(value : LiquidValue) -> Bool {
  match value {
    Null | Bool(false) => false
    _ => true
  }
}

///|
fn values_equal(left : LiquidValue, right : LiquidValue) -> Bool {
  match (left, right) {
    (Null, Null) => true
    (Bool(a), Bool(b)) => a == b
    (Number(a), Number(b)) => a == b
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
pub fn evaluate_condition(condition : String, context : LiquidContext) -> Bool {
  let text = condition.trim().to_owned()
  // Splitting at the first logical operator preserves Liquid's right-to-left evaluation.
  let logical = match
    (find_unquoted(text, " and "), find_unquoted(text, " or ")) {
    (Some(a), Some(b)) =>
      if a < b {
        Some((a, " and "))
      } else {
        Some((b, " or "))
      }
    (Some(a), None) => Some((a, " and "))
    (None, Some(b)) => Some((b, " or "))
    (None, None) => None
  }
  if logical is Some((at, op)) {
    let left = evaluate_condition(text[:at].to_owned(), context)
    if op == " and " {
      return left &&
        evaluate_condition(text[at + op.length():].to_owned(), context)
    }
    return left ||
      evaluate_condition(text[at + op.length():].to_owned(), context)
  }
  if text.strip_prefix("not ") is Some(rest) {
    return !evaluate_condition(rest.to_owned(), context)
  }
  for op in ["==", "!=", ">=", "<=", ">", "<", " contains "] {
    if find_unquoted(text, op) is Some(at) {
      return compare_values(
        text[:at].to_owned(),
        text[at + op.length():].to_owned(),
        op.trim().to_owned(),
        context,
      )
    }
  }
  is_truthy(evaluate_expression(text, context))
}
