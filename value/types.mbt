/// Core data structures for Liquid values

///|
pub enum LiquidValue {
  String(String)
  Number(Double)
  Float(Double) // Preserves floating-point semantics even for integral values.
  Bool(Bool)
  Array(Array[LiquidValue])
  Object(Map[String, LiquidValue])
  Null
} derive(ToJson)

///|
pub extend LiquidValue with ToJson::{to_json}
