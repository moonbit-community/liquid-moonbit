///|
test "filter plus" {
  // Test plus filter (default increment by 1)
  let num_value = number_value(5.0)
  let num_result = apply_filter(num_value, "plus", []).unwrap()
  assert_eq(num_result.to_string(), "6")
  let str_value = string_value("10")
  let str_result = apply_filter(str_value, "plus", []).unwrap()
  assert_eq(str_result.to_string(), "10") // String parsing not implemented yet
}

///|
test "filter minus" {
  // Test minus filter (default decrement by 1)
  let num_value = number_value(5.0)
  let num_result = apply_filter(num_value, "minus", []).unwrap()
  assert_eq(num_result.to_string(), "4")
  let str_value = string_value("10")
  let str_result = apply_filter(str_value, "minus", []).unwrap()
  assert_eq(str_result.to_string(), "10") // String parsing not implemented yet
}

///|
test "filter times" {
  // Test times filter (default multiply by 2)
  let num_value = number_value(5.0)
  let num_result = apply_filter(num_value, "times", []).unwrap()
  assert_eq(num_result.to_string(), "10")
  let str_value = string_value("3")
  let str_result = apply_filter(str_value, "times", []).unwrap()
  assert_eq(str_result.to_string(), "3") // String parsing not implemented yet
}

///|
test "filter divided_by" {
  // Test divided_by filter (default divide by 2)
  let num_value = number_value(10.0)
  let num_result = apply_filter(num_value, "divided_by", []).unwrap()
  assert_eq(num_result.to_string(), "5")
  let str_value = string_value("8")
  let str_result = apply_filter(str_value, "divided_by", []).unwrap()
  assert_eq(str_result.to_string(), "8") // String parsing not implemented yet
}

///|
test "filter modulo" {
  // Test modulo filter (default modulo 2)
  let num_value = number_value(5.0)
  let num_result = apply_filter(num_value, "modulo", []).unwrap()
  assert_eq(num_result.to_string(), "1")
  let str_value = string_value("7")
  let str_result = apply_filter(str_value, "modulo", []).unwrap()
  assert_eq(str_result.to_string(), "7") // String parsing not implemented yet
}

///|
test "filter round" {
  // Test round filter
  let num_value = number_value(3.7)
  let num_result = apply_filter(num_value, "round", []).unwrap()
  assert_eq(num_result.to_string(), "4")
  let str_value = string_value("2.3")
  let str_result = apply_filter(str_value, "round", []).unwrap()
  assert_eq(str_result.to_string(), "2.3") // String parsing not implemented yet
}

///|
test "filter ceil" {
  // Test ceil filter
  let num_value = number_value(3.2)
  let num_result = apply_filter(num_value, "ceil", []).unwrap()
  assert_eq(num_result.to_string(), "4")
  let str_value = string_value("2.1")
  let str_result = apply_filter(str_value, "ceil", []).unwrap()
  assert_eq(str_result.to_string(), "2.1") // String parsing not implemented yet
}

///|
test "filter floor" {
  // Test floor filter
  let num_value = number_value(3.8)
  let num_result = apply_filter(num_value, "floor", []).unwrap()
  assert_eq(num_result.to_string(), "3")
  let str_value = string_value("2.9")
  let str_result = apply_filter(str_value, "floor", []).unwrap()
  assert_eq(str_result.to_string(), "2.9") // String parsing not implemented yet
}

///|
test "filter abs" {
  // Test abs filter
  let neg_value = number_value(-5.0)
  let neg_result = apply_filter(neg_value, "abs", []).unwrap()
  assert_eq(neg_result.to_string(), "5")
  let pos_value = number_value(3.0)
  let pos_result = apply_filter(pos_value, "abs", []).unwrap()
  assert_eq(pos_result.to_string(), "3")
  let str_value = string_value("-7")
  let str_result = apply_filter(str_value, "abs", []).unwrap()
  assert_eq(str_result.to_string(), "-7") // String parsing not implemented yet
}

///|
test "filter edge cases non-number inputs" {
  // Test math filters with non-number inputs
  let str_val = string_value("hello")
  let arr_val = array_value([string_value("test")])
  let bool_val = bool_value(true)
  assert_eq(apply_filter(str_val, "plus", []).unwrap().to_string(), "hello")
  assert_eq(apply_filter(arr_val, "minus", []).unwrap().to_string(), "[test]")
  assert_eq(apply_filter(bool_val, "times", []).unwrap().to_string(), "true")
  assert_eq(
    apply_filter(str_val, "divided_by", []).unwrap().to_string(),
    "hello",
  )
  assert_eq(apply_filter(arr_val, "modulo", []).unwrap().to_string(), "[test]")
  assert_eq(apply_filter(bool_val, "round", []).unwrap().to_string(), "true")
  assert_eq(apply_filter(str_val, "ceil", []).unwrap().to_string(), "hello")
  assert_eq(apply_filter(arr_val, "floor", []).unwrap().to_string(), "[test]")
  assert_eq(apply_filter(bool_val, "abs", []).unwrap().to_string(), "true")
}

///|
test "math filter edge cases" {
  // Test plus filter with non-number value
  let bool_val = bool_value(true)
  let result_plus = apply_filter(bool_val, "plus", []).unwrap()
  assert_eq(result_plus.to_string(), "true")

  // Test divided_by filter with non-number value
  let result_div = apply_filter(bool_val, "divided_by", []).unwrap()
  assert_eq(result_div.to_string(), "true")

  // Test ceil filter with non-number value
  let result_ceil = apply_filter(bool_val, "ceil", []).unwrap()
  assert_eq(result_ceil.to_string(), "true")
}
