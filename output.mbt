///|
fn default_value(
  value : LiquidValue,
  parameters : Array[String],
  context : LiquidContext,
) -> LiquidValue {
  let allow_false = parameters
    .iter()
    .any(fn(param) {
      let parts = split_unquoted(param, ":")
      parts.length() == 2 &&
      parts[0].trim() == "allow_false" &&
      evaluate_expression(parts[1], context) is Bool(true)
    })
  let use_default = match value {
    Null => true
    Bool(false) => !allow_false
    String(s) => s.is_empty()
    Array(a) => a.is_empty()
    _ => false
  }
  if use_default {
    if parameters.is_empty() {
      String("")
    } else {
      evaluate_expression(parameters[0], context)
    }
  } else {
    value
  }
}

///|
fn apply_context_filters(
  value : LiquidValue,
  filters : Array[Filter],
  context : LiquidContext,
) -> LiquidValue {
  let mut value = value
  for filter_obj in filters {
    if filter_obj.name == "default" {
      value = default_value(value, filter_obj.parameters, context)
    } else if filter_obj.name == "concat" {
      let other = match filter_obj.parameters.get(0) {
        Some(expression) => evaluate_expression(expression, context)
        None => Null
      }
      value = match (value, other) {
        (Array(left), Array(right)) => {
          let combined = left.copy()
          for item in right {
            combined.push(item)
          }
          Array(combined)
        }
        _ => String(handle_error(context, "concat requires two arrays"))
      }
    } else {
      let parameters = filter_obj.parameters.map(fn(param) {
        let text = param.trim().to_owned()
        // Normalize string arguments for the existing filter API, without reparsing their contents.
        if text.length() >= 2 &&
          (text[0] == 39 || text[0] == 34) &&
          text[text.length() - 1] == text[0] {
          return "'" + text[1:text.length() - 1].to_owned() + "'"
        }
        match context.get(text) {
          Some(String(s)) => "'" + s + "'"
          Some(v) => v.to_string()
          None => text
        }
      })
      value = apply_filter_with_params(
        value,
        filter(filter_obj.name, parameters),
      )
    }
  }
  value
}

///|
fn render_expression(
  expression : String,
  filters : Array[Filter],
  context : LiquidContext,
  report_missing : Bool,
) -> String {
  let value = apply_context_filters(
    evaluate_expression(expression, context),
    filters,
    context,
  )
  match value {
    Null =>
      if report_missing &&
        evaluate_expression(expression, context) is Null &&
        context.get(expression) is None &&
        expression != "nil" &&
        expression != "null" {
        handle_error(context, "Variable '" + expression + "' not found")
      } else {
        ""
      }
    _ => value.to_string()
  }
}
