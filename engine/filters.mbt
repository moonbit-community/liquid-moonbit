///|
/// Apply a built-in filter to evaluated arguments.
pub fn apply_filter(
  value : LiquidValue,
  name : String,
  parameters : Array[LiquidValue],
  options? : Map[String, LiquidValue] = Map([]),
) -> Result[LiquidValue, Diagnostic] {
  match @filters.apply_filter(value, name, parameters, options~) {
    Ok(value) => Ok(value)
    Err(error) => Err(filter_diagnostic(error.code, error.message))
  }
}
