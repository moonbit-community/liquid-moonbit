///|
fn unary_filter(value : LiquidValue, name : String) -> LiquidValue? {
  if collection_filter(value, name) is Some(result) {
    return Some(result)
  }
  if string_filter(value, name) is Some(result) {
    return Some(result)
  }
  scalar_filter(value, name)
}
