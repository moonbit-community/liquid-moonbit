///|
fn render_expression(
  expression : Expr,
  context : LiquidContext,
  state : RenderState,
  report_missing : Bool,
) -> String {
  let value = expression.eval(context, state)
  match value {
    Null =>
      if report_missing && expression.missing(context) {
        render_error(
          state,
          "Variable '" + expression.label() + "' not found",
          code="missing_variable",
        )
      } else {
        ""
      }
    _ => value.to_string()
  }
}
