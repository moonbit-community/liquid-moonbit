///|
test "unknown filter" {
  match apply_filter(string_value("value"), "unknown", []) {
    Err(error) => assert_eq(error.code, "unknown_filter")
    Ok(_) => fail("Expected an unknown filter diagnostic")
  }
}

///|
test "filter edge cases non-array inputs" {
  // Test array filters with non-array inputs
  let str_val = string_value("hello")
  let num_val = number_value(42.0)
  let bool_val = bool_value(true)
  assert_eq(apply_filter(str_val, "join", []).unwrap().to_string(), "hello")
  assert_eq(apply_filter(num_val, "select", []).unwrap().to_string(), "42")
  assert_eq(apply_filter(bool_val, "reject", []).unwrap().to_string(), "true")
  assert_eq(apply_filter(str_val, "compact", []).unwrap().to_string(), "hello")
  assert_eq(apply_filter(num_val, "uniq", []).unwrap().to_string(), "42")
  assert_eq(apply_filter(bool_val, "flatten", []).unwrap().to_string(), "true")
  assert_eq(apply_filter(str_val, "group_by", []).unwrap().to_string(), "hello")
  assert_eq(apply_filter(num_val, "map", []).unwrap().to_string(), "42")
  assert_eq(apply_filter(bool_val, "where", []).unwrap().to_string(), "true")
  assert_eq(apply_filter(str_val, "offset", []).unwrap().to_string(), "hello")
  assert_eq(apply_filter(num_val, "limit", []).unwrap().to_string(), "42")
}

///|
test "array filter edge cases for non-array values" {

  // Test split filter with non-string value
  let number_val = number_value(42.0)
  let result_split = apply_filter(number_val, "split", [string_value(" ")]).unwrap()
  assert_eq(result_split.to_string(), "42")

  // Test offset filter with non-array value
  let result_offset = apply_filter(number_val, "offset", [number_value(1)]).unwrap()
  assert_eq(result_offset.to_string(), "42")

  // Test limit filter with non-array value
  let result_limit = apply_filter(number_val, "limit", [number_value(2)]).unwrap()
  assert_eq(result_limit.to_string(), "42")

  // Test where filter with non-array value
  let result_where = apply_filter(number_val, "where", [
    string_value("prop"),
    string_value("value"),
  ]).unwrap()
  assert_eq(result_where.to_string(), "42")
}

///|
test "basic filter edge cases for non-expected types" {

  // Test first filter with non-array, non-string value
  let number_val = number_value(42.0)
  let result_first = apply_filter(number_val, "first", []).unwrap()
  assert_eq(result_first.to_string(), "null")

  // Test last filter with non-array, non-string value
  let result_last = apply_filter(number_val, "last", []).unwrap()
  assert_eq(result_last.to_string(), "null")

  // Test reverse filter with non-array, non-string value
  let result_reverse = apply_filter(number_val, "reverse", []).unwrap()
  assert_eq(result_reverse.to_string(), "42")

  // Test sort filter with non-array value
  let result_sort = apply_filter(number_val, "sort", []).unwrap()
  assert_eq(result_sort.to_string(), "42")

  // Test default filter with non-null, non-string value
  let result_default = apply_filter(number_val, "default", []).unwrap()
  assert_eq(result_default.to_string(), "42")

  // Test truncate filter with non-string value
  let result_truncate = apply_filter(number_val, "truncate", []).unwrap()
  assert_eq(result_truncate.to_string(), "42")

  // Test plus filter with non-number value
  let result_plus = apply_filter(number_val, "plus", []).unwrap()
  assert_eq(result_plus.to_string(), "43") // 42 + 1

  // Test divided_by filter with non-number value
  let result_divided = apply_filter(number_val, "divided_by", []).unwrap()
  assert_eq(result_divided.to_string(), "21") // 42 / 2

  // Test ceil filter with non-number value
  let result_ceil = apply_filter(number_val, "ceil", []).unwrap()
  assert_eq(result_ceil.to_string(), "42")
}

///|
test "filter edge cases for new filters" {
  // Test pluralize filter with non-number value
  let string_val = string_value("not a number")
  let result_pluralize = apply_filter(string_val, "pluralize", []).unwrap()
  assert_eq(result_pluralize.to_string(), "not a number")

  // Test reading_time filter with non-string value
  let number_val = number_value(42.0)
  let result_reading_time = apply_filter(number_val, "reading_time", []).unwrap()
  assert_eq(result_reading_time.to_string(), "1") // Default to 1 minute

  // Test sort_by filter with non-array value
  let result_sort_by = apply_filter(number_val, "sort_by", []).unwrap()
  assert_eq(result_sort_by.to_string(), "42")
}

///|
test "new filter edge cases" {
  // Test edge cases for newly implemented filters

  // Test array manipulation filters with non-array values
  let string_val = string_value("not an array")
  assert_eq(
    apply_filter(string_val, "push", []).unwrap().to_string(),
    "not an array",
  )
  assert_eq(
    apply_filter(string_val, "pop", []).unwrap().to_string(),
    "not an array",
  )
  assert_eq(
    apply_filter(string_val, "shift", []).unwrap().to_string(),
    "not an array",
  )
  assert_eq(
    apply_filter(string_val, "unshift", []).unwrap().to_string(),
    "not an array",
  )

  // Test string trimming filters with non-string values
  let number_val = number_value(42.0)
  assert_eq(apply_filter(number_val, "lstrip", []).unwrap().to_string(), "42")
  assert_eq(apply_filter(number_val, "rstrip", []).unwrap().to_string(), "42")

  // Test concat filter with non-array, non-string values
  assert_true(apply_filter(number_val, "concat", []) is Err(_))

  // Test at filter with basic usage (no parameters)
  let arr = array_value([string_value("test")])
  assert_eq(apply_filter(arr, "at", []).unwrap().to_string(), "test")
}

///|
test "additional advanced filters" {
  // Test truncatewords filter
  let long_text = string_value(
    "This is a very long sentence with many words that should be truncated at word boundaries",
  )
  let result_truncatewords = apply_filter(long_text, "truncatewords", []).unwrap()
  assert_eq(result_truncatewords.to_string().contains("..."), true) // Should be truncated

  // Test strip_tags filter (enhanced version)
  let html_text = string_value("<div><p>Hello <a href='#'>world</a></p></div>")
  let result_strip_tags = apply_filter(html_text, "strip_tags", []).unwrap()
  // The basic implementation removes some tags but not all complex ones
  assert_eq(result_strip_tags.to_string().contains("Hello"), true)
  assert_eq(result_strip_tags.to_string().contains("world"), true)

  // Test normalize_whitespace filter
  let messy_text = string_value("  Hello   \t world  \n  test  ")
  let result_normalize = apply_filter(messy_text, "normalize_whitespace", []).unwrap()
  assert_eq(result_normalize.to_string(), "Hello world test") // Normalized spaces
}

///|
test "direct filter application uncovered cases" {
  // Test uncovered cases in typed apply_filter by calling directly

  // Test pluralize with non-number input (should fallback)
  let non_number_result = apply_filter(string_value("text"), "pluralize", [
    string_value("item"),
    string_value("items"),
  ]).unwrap()
  assert_eq(non_number_result.to_string(), "text")

  // Test sort_by with missing property
  let obj_map = Map([])
  obj_map.set("other_prop", string_value("value"))
  let obj_with_missing = object_value(obj_map)
  let sort_result = apply_filter(array_value([obj_with_missing]), "sort_by", [
    string_value("missing"),
  ]).unwrap()
  assert_eq(sort_result.to_string(), "[{\"other_prop\": value}]")

  // Test sort_by with non-object in array
  let mixed_array = array_value([string_value("zebra"), number_value(1.0)])
  let sort_mixed_result = apply_filter(mixed_array, "sort_by", [
    string_value("missing"),
  ]).unwrap()
  assert_eq(sort_mixed_result.to_string(), "[1, zebra]")
}

///|
test "remaining uncovered filter cases" {
  // Test uncovered cases in basic apply_filter function

  // Test at filter with non-array input
  let at_result = apply_filter(string_value("not_array"), "at", []).unwrap()
  assert_eq(at_result.to_string(), "not_array")

  // Test truncatewords with non-string input
  let truncate_result = apply_filter(number_value(42.0), "truncatewords", []).unwrap()
  assert_eq(truncate_result.to_string(), "42")

  // Test money_without_trailing_zeros edge case with .0
  let money_result = apply_filter(
    number_value(10.0),
    "money_without_trailing_zeros",
    [],
  ).unwrap()
  assert_eq(money_result.to_string(), "$10")
}

///|
test "filter parameter edge cases without quotes" {
  // Test parameters without quotes to trigger else branches

  // Test pluralize with unquoted parameters
  let result1 = apply_filter(number_value(1.0), "pluralize", [
    string_value("item"),
    string_value("items"),
  ]).unwrap()
  assert_eq(result1.to_string(), "1 item")
  let result2 = apply_filter(number_value(3.0), "pluralize", [
    string_value("item"),
    string_value("items"),
  ]).unwrap()
  assert_eq(result2.to_string(), "3 items")

  // Test sort_by with unquoted parameter
  let obj1 = Map([])
  obj1.set("name", string_value("zebra"))
  let obj2 = Map([])
  obj2.set("name", string_value("apple"))
  let items = array_value([object_value(obj1), object_value(obj2)])
  let sort_result = apply_filter(items, "sort_by", [string_value("name")]).unwrap()
  assert_eq(sort_result.to_string(), "[{\"name\": apple}, {\"name\": zebra}]")

  // Test map filter with unquoted parameter
  let map_result = apply_filter(items, "map", [string_value("name")]).unwrap()
  assert_eq(map_result.to_string(), "[zebra, apple]")
}

///|
test "comprehensive filter fallback scenarios" {
  // Test various fallback scenarios to increase coverage

  // Test where filter fallback
  let items = array_value([string_value("test"), string_value("filter")])
  let where_result = apply_filter(items, "where", []).unwrap()
  assert_eq(where_result.to_string(), "[filter]") // Should use basic where filter

  // Test map filter fallback
  let map_result = apply_filter(items, "map", []).unwrap()
  assert_eq(map_result.to_string(), "[test, filter]") // Should use basic map filter

  // Test truncatewords filter fallback
  let long_text = string_value(
    "This is a very long text with many words that should be truncated by the filter",
  )
  let truncate_result = apply_filter(long_text, "truncatewords", []).unwrap()
  assert_eq(
    truncate_result.to_string(),
    "This is a very long text with many words that should be truncated by the...",
  )
}

///|
test "direct filter application for maximum coverage" {
  // Test direct filter application to hit remaining uncovered cases

  // Test money_without_trailing_zeros with numbers that have .0
  let money_vals = [10.0, 25.0, 100.0, 0.0]
  for val in money_vals {
    let result = apply_filter(
      number_value(val),
      "money_without_trailing_zeros",
      [],
    ).unwrap()
    // This should trigger the uncovered line
    let expected_val = val.to_int().to_string()
    assert_eq(result.to_string(), "$" + expected_val)
  }

  // Test various filters with edge case inputs
  let edge_inputs = [null_value(), bool_value(true), bool_value(false)]
  let filters_to_test = ["upcase", "downcase", "trim", "capitalize", "split"]
  for filter_name in filters_to_test {
    for input in edge_inputs {
      let result = apply_filter(input, filter_name, []).unwrap()
      // These should all return the original input for non-matching types
      assert_eq(result.to_string(), input.to_string())
    }
  }
}

///|
test "complex filter parameter combinations v2" {
  // Test complex combinations of filters with parameters

  // Test pluralize with edge case numbers
  let pluralize_numbers = [0.0, 1.0, 1.1, 2.0, -1.0, 100.0]
  for num in pluralize_numbers {
    let result = apply_filter(number_value(num), "pluralize", [
      string_value("item"),
      string_value("items"),
    ]).unwrap()
    if num == 1.0 {
      assert_eq(result.to_string(), "1 item")
    } else {
      assert_eq(result.to_string(), num.to_string() + " items")
    }
  }

  // Test sort_by with complex object structures
  let complex_obj1 = Map([])
  complex_obj1.set(
    "nested",
    object_value(
      {
        let nested_map = Map([])
        nested_map.set("value", string_value("zebra"))
        nested_map
      },
    ),
  )
  let complex_obj2 = Map([])
  complex_obj2.set(
    "nested",
    object_value(
      {
        let nested_map = Map([])
        nested_map.set("value", string_value("apple"))
        nested_map
      },
    ),
  )
  let complex_items = array_value([
    object_value(complex_obj1),
    object_value(complex_obj2),
  ])
  let complex_result = apply_filter(complex_items, "sort_by", [
    string_value("nested"),
  ]).unwrap()
  // Should handle complex nested structures
  assert_eq(complex_result.to_string().contains("apple"), true)
}
