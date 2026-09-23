///|
/// Application variables and explicitly registered templates.
struct LiquidContext {
  variables : Map[String, LiquidValue]
  templates : Map[String, String]
}

///|
pub fn LiquidContext::new() -> LiquidContext {
  { variables: Map([]), templates: Map([]), }
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
