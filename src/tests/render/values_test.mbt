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

///|
test "liquid context operations" {
  // Test LiquidContext creation and variable management
  let context = LiquidContext::new()

  // Set and get string value
  context.set("name", string_value("World"))
  match context.get("name") {
    Some(value) => assert_eq(value.to_string(), "World")
    None => fail("Expected name to be found")
  }

  // Set and get number value
  context.set("count", number_value(42.0))
  match context.get("count") {
    Some(value) => assert_eq(value.to_string(), "42")
    None => fail("Expected count to be found")
  }

  // Test non-existent key
  match context.get("nonexistent") {
    Some(_) => fail("Expected None for nonexistent key")
    None => ()
  }
}

///|
test "object property access" {
  // Test object property access like forloop.index
  let context = LiquidContext::new()
  let forloop_obj = Map([])
  forloop_obj.set("index", number_value(1.0))
  forloop_obj.set("first", bool_value(true))
  forloop_obj.set("last", bool_value(false))
  context.set("forloop", object_value(forloop_obj))
  let index_result = context.get("forloop.index")
  match index_result {
    Some(value) => assert_eq(value.to_string(), "1")
    None => fail("Expected forloop.index to be found")
  }
  let first_result = context.get("forloop.first")
  match first_result {
    Some(value) => assert_eq(value.to_string(), "true")
    None => fail("Expected forloop.first to be found")
  }
}

///|
test "nested object access" {
  // Test nested object property access
  let context = LiquidContext::new()
  let user_obj = Map([])
  user_obj.set("name", string_value("Alice"))
  user_obj.set("role", string_value("admin"))
  context.set("user", object_value(user_obj))
  let name_result = context.get("user.name")
  match name_result {
    Some(value) => assert_eq(value.to_string(), "Alice")
    None => fail("Expected user.name to be found")
  }
  let role_result = context.get("user.role")
  match role_result {
    Some(value) => assert_eq(value.to_string(), "admin")
    None => fail("Expected user.role to be found")
  }
}
