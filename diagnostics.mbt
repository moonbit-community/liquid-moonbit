///|
/// A machine-readable parse or render failure. Offsets use UTF-16 code units.
/// Runtime failures without a source span have offset=None.
pub struct Diagnostic {
  phase : String
  code : String
  message : String
  offset : Int?
  template : String?
} derive(Debug, Eq, ToJson)

///|
fn parse_diagnostic(
  code : String,
  message : String,
  offset : Int,
) -> Diagnostic {
  { phase: "parse", code, message, offset: Some(offset), template: None, }
}

///|
pub extend Diagnostic with Debug::{to_repr}

///|
pub extend Diagnostic with Eq::{equal, not_equal}

///|
pub extend Diagnostic with ToJson::{to_json}

///|
fn filter_diagnostic(code : String, message : String) -> Diagnostic {
  { phase: "render", code, message, offset: None, template: None, }
}
