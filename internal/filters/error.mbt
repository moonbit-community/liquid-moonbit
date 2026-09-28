///|
pub struct FilterError {
  code : String
  message : String
}

///|
fn filter_error(code : String, message : String) -> FilterError {
  { code, message, }
}
