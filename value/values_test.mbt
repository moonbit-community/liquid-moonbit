///|
test "liquid value creation and conversion" {
  // Test LiquidValue creation and string conversion
  let str_val = string_value("hello")
  let num_val = number_value(42.0)
  let bool_val = bool_value(true)
  let null_val = null_value()
  assert_eq(str_val.to_string(), "hello")
  assert_eq(num_val.to_string(), "42")
  assert_eq(bool_val.to_string(), "true")
  assert_eq(null_val.to_string(), "null")
}

///|
test "liquid array and object values" {
  // Test array values
  let arr = array_value([string_value("apple"), string_value("banana")])
  assert_eq(arr.to_string(), "[apple, banana]")

  // Test object values
  let obj_map = Map([])
  obj_map.set("name", string_value("John"))
  obj_map.set("age", number_value(30.0))
  let obj = object_value(obj_map)
  let obj_str = obj.to_string()
  assert_eq(obj_str.contains("name"), true)
  assert_eq(obj_str.contains("John"), true)
}
