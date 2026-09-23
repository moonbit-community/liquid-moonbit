///|
pub fn LiquidContext::new() -> LiquidContext {
  { variables: Map([]), error_policy: Warn, templates: Map([]), }
}

///|
pub fn LiquidContext::with_error_policy(policy : ErrorPolicy) -> LiquidContext {
  { variables: Map([]), error_policy: policy, templates: Map([]), }
}

// Helper functions to create error policies

///|
pub fn strict_policy() -> ErrorPolicy {
  Strict
}

///|
pub fn warn_policy() -> ErrorPolicy {
  Warn
}

///|
pub fn silent_policy() -> ErrorPolicy {
  Silent
}

// Handle errors based on error policy

///|
fn handle_error(context : LiquidContext, message : String) -> String {
  match context.error_policy {
    Strict =>
      // In a full implementation, this would throw an exception
      // For now, return error message
      "[ERROR: " + message + "]"
    Warn => {
      // Print warning and return empty string
      println("WARNING: " + message)
      ""
    }
    Silent => "" // Silently ignore errors
  }
}

///|
#alias(op_set)
pub fn LiquidContext::set(
  self : LiquidContext,
  key : String,
  value : LiquidValue,
) -> Unit {
  self.variables[key] = value
}

///|
pub fn LiquidContext::get(self : LiquidContext, key : String) -> LiquidValue? {
  lookup_path(self, key.split(".").map(fn(p) { p.to_owned() }).collect())
}

///|
fn lookup_path(context : LiquidContext, path : Array[String]) -> LiquidValue? {
  guard path is [first, .. rest] else { return None }
  let mut value = context.variables.get(first)
  for key in rest {
    value = match value {
      Some(Object(fields)) => fields.get(key)
      _ => return None
    }
  }
  value
}
