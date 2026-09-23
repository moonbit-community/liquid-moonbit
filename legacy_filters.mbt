///|
/// Compatibility adapter for filters without arguments.
pub fn apply_filter(value : LiquidValue, name : String) -> LiquidValue {
  apply_filter_values(value, name, []).unwrap_or(value)
}

///|
/// Compatibility adapter: unquoted arguments are literal text, not variable names.
pub fn apply_filter_with_params(
  value : LiquidValue,
  filter_obj : Filter,
) -> LiquidValue {
  let args : Array[LiquidValue] = []
  let options : Map[String, LiquidValue] = Map([])
  for text in filter_obj.parameters {
    if filter_obj.name == "default" && find_unquoted(text, ":") is Some(at) {
      options[text[:at].trim().to_owned()] = legacy_argument(
        text[at + 1:].to_owned(),
      )
    } else {
      args.push(legacy_argument(text))
    }
  }
  apply_filter_values(value, filter_obj.name, args, options~).unwrap_or(value)
}

///|
fn legacy_argument(text : String) -> LiquidValue {
  let trimmed = text.trim().to_owned()
  match trimmed {
    "true" => Bool(true)
    "false" => Bool(false)
    "nil" | "null" => Null
    _ =>
      match parse_number(trimmed) {
        Some(n) => numeric_result(n, trimmed.contains("."))
        None => String(unquote_argument(text))
      }
  }
}
