///|
priv enum Expr {
  Literal(LiquidValue)
  Lookup(Array[String])
  Pipeline(Expr, Array[FilterCall])
}

///|
priv struct FilterCall {
  name : String
  arguments : Array[(String?, Expr)]
}

///|
priv enum Condition {
  Truth(Expr)
  Compare(Expr, String, Expr)
  And(Condition, Condition)
  Or(Condition, Condition)
  Not(Condition)
}

///|
fn compile_expression(source : String) -> Expr {
  let (text, filters) = parse_output(source)
  let value = if text.length() >= 2 &&
    (text[0] == 39 || text[0] == 34) &&
    text[text.length() - 1] == text[0] {
    Expr::Literal(String(text[1:text.length() - 1].to_owned()))
  } else {
    match text {
      "true" => Literal(Bool(true))
      "false" => Literal(Bool(false))
      "nil" | "null" => Literal(Null)
      _ =>
        match parse_number(text) {
          Some(n) => Literal(numeric_result(n, text.contains(".")))
          None => Lookup(text.split(".").map(fn(p) { p.to_owned() }).collect())
        }
    }
  }
  if filters.is_empty() {
    value
  } else {
    Pipeline(value, filters.map(compile_filter))
  }
}

///|
fn compile_filter(filter : Filter) -> FilterCall {
  {
    name: filter.name,
    arguments: filter.parameters.map(fn(parameter) {
      if find_unquoted(parameter, ":") is Some(at) {
        (
          Some(parameter[:at].trim().to_owned()),
          compile_expression(parameter[at + 1:].to_owned()),
        )
      } else {
        (None, compile_expression(parameter))
      }
    }),
  }
}

///|
fn compile_output(source : String, filters : Array[Filter]) -> Expr {
  let expression = compile_expression(source)
  if filters.is_empty() {
    expression
  } else {
    Pipeline(expression, filters.map(compile_filter))
  }
}

///|
fn Expr::eval(
  self : Expr,
  context : LiquidContext,
  state : RenderState,
) -> LiquidValue {
  match self {
    Literal(value) => value
    Lookup(path) => lookup_path(context, path).unwrap_or(Null)
    Pipeline(expression, filters) => {
      let mut value = expression.eval(context, state)
      for filter in filters {
        let arguments : Array[LiquidValue] = []
        let options : Map[String, LiquidValue] = Map([])
        for (name, expr) in filter.arguments {
          let argument = expr.eval(context, state)
          match name {
            Some(key) => options[key] = argument
            None => arguments.push(argument)
          }
        }
        value = match
          apply_filter_values(value, filter.name, arguments, options~) {
          Ok(result) => result
          Err(diagnostic) =>
            String(report_diagnostic(context, state, diagnostic))
        }
      }
      value
    }
  }
}

///|
fn compile_condition(source : String) -> Condition {
  let text = source.trim().to_owned()
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
    _ => None
  }
  if logical is Some((at, op)) {
    let left = compile_condition(text[:at].to_owned())
    let right = compile_condition(text[at + op.length():].to_owned())
    return if op == " and " { And(left, right) } else { Or(left, right) }
  }
  if text.strip_prefix("not ") is Some(rest) {
    return Not(compile_condition(rest.to_owned()))
  }
  for op in ["==", "!=", ">=", "<=", ">", "<", " contains "] {
    if find_unquoted(text, op) is Some(at) {
      return Compare(
        compile_expression(text[:at].to_owned()),
        op.trim().to_owned(),
        compile_expression(text[at + op.length():].to_owned()),
      )
    }
  }
  Truth(compile_expression(text))
}

///|
fn Condition::eval(
  self : Condition,
  context : LiquidContext,
  state : RenderState,
) -> Bool {
  match self {
    Truth(expression) => is_truthy(expression.eval(context, state))
    Compare(left, op, right) =>
      compare_typed_values(
        left.eval(context, state),
        right.eval(context, state),
        op,
      )
    And(left, right) => left.eval(context, state) && right.eval(context, state)
    Or(left, right) => left.eval(context, state) || right.eval(context, state)
    Not(condition) => !condition.eval(context, state)
  }
}

///|
fn Expr::missing(self : Expr, context : LiquidContext) -> Bool {
  match self {
    Lookup(path) => lookup_path(context, path) is None
    Pipeline(base, _) => base.missing(context)
    _ => false
  }
}

///|
fn Expr::label(self : Expr) -> String {
  match self {
    Lookup(path) => path.join(".")
    Pipeline(base, _) => base.label()
    Literal(value) => value.to_string()
  }
}
