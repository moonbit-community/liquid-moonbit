///|
///  Core data structures for Liquid values
pub fn LiquidValue::to_string(self : LiquidValue) -> String {
  match self {
    String(s) => s
    Number(n) | Float(n) => n.to_string()
    Bool(b) => if b { "true" } else { "false" }
    Array(arr) => {
      let items = arr.map(fn(item) { item.to_string() })
      "[" + items.join(", ") + "]"
    }
    Object(obj) => {
      let pairs = obj
        .iter()
        .map(fn(entry) {
          let (key, value) = entry
          "\"" + key + "\": " + value.to_string()
        })
        .collect()
      "{" + pairs.join(", ") + "}"
    }
    Null => "null"
  }
}

///|
pub fn string_value(s : String) -> LiquidValue {
  String(s)
}

///|
pub fn number_value(n : Double) -> LiquidValue {
  Number(n)
}

///|
/// Construct an explicitly floating-point number, including integral values like 4.0.
pub fn float_value(n : Double) -> LiquidValue {
  Float(n)
}

///|
pub fn bool_value(b : Bool) -> LiquidValue {
  Bool(b)
}

///|
pub fn array_value(arr : Array[LiquidValue]) -> LiquidValue {
  Array(arr)
}

///|
pub fn object_value(obj : Map[String, LiquidValue]) -> LiquidValue {
  Object(obj)
}

///|
pub fn null_value() -> LiquidValue {
  Null
}

// Helper functions to create LiquidNode instances for testing
