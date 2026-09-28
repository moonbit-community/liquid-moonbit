///|
test "additional edge cases for complete coverage" {
  // Test more edge cases to increase coverage

  // Test strip_tags with non-string
  let strip_tags_result = apply_filter(number_value(123.0), "strip_tags", []).unwrap()
  assert_eq(strip_tags_result.to_string(), "123")

  // Test normalize_whitespace with non-string
  let normalize_result = apply_filter(
    bool_value(true),
    "normalize_whitespace",
    [],
  ).unwrap()
  assert_eq(normalize_result.to_string(), "true")

  // Test various filters with different input types to hit uncovered branches
  let filters_to_test = [
    "strip_tags", "normalize_whitespace", "truncatewords", "at",
  ]
  let non_string_inputs = [number_value(42.0), bool_value(false), null_value()]
  for filter_name in filters_to_test {
    for input in non_string_inputs {
      let result = apply_filter(input, filter_name, []).unwrap()
      // These should all return the original input when type doesn't match
      assert_eq(result.to_string(), input.to_string())
    }
  }
}

///|
test "comprehensive parameter parsing edge cases" {
  // Test edge cases in parameter parsing for filters

  // Test with various parameter formats
  let params = ["\"quoted\"", "'single'", "unquoted", "\"", "'", ""]
  let expected_results = params
  for i in 0..<params.length() {
    let param = params[i]
    let expected = expected_results[i]

    // Test with pluralize filter
    let result = apply_filter(number_value(1.0), "pluralize", [
      string_value(param),
      string_value("items"),
    ]).unwrap()
    assert_eq(result.to_string(), "1 " + expected)
  }
}

///|
test "empty string and array edge cases" {
  // Test edge cases with empty strings and arrays
  let empty_str = string_value("")
  let empty_arr = array_value([])

  // Test capitalize with empty string
  assert_eq(apply_filter(empty_str, "capitalize", []).unwrap().to_string(), "")

  // Test first/last with empty arrays
  assert_eq(apply_filter(empty_arr, "first", []).unwrap().to_string(), "null")
  assert_eq(apply_filter(empty_arr, "last", []).unwrap().to_string(), "null")

  // Test first/last with empty strings
  assert_eq(apply_filter(empty_str, "first", []).unwrap().to_string(), "null")
  assert_eq(apply_filter(empty_str, "last", []).unwrap().to_string(), "null")

  // Test truncate with short string
  let short_str = string_value("short")
  assert_eq(
    apply_filter(short_str, "truncate", []).unwrap().to_string(),
    "short",
  )
}

///|
test "advanced string manipulation edge cases" {
  // Test advanced string manipulation scenarios

  // Test capitalize with various edge cases
  let capitalize_cases = [
    ("", ""),
    ("a", "A"),
    ("HELLO", "Hello"),
    ("hELLO wORLD", "Hello world"),
    ("123abc", "123abc"),
  ]
  for i in 0..<capitalize_cases.length() {
    let input = capitalize_cases[i].0
    let expected = capitalize_cases[i].1
    let result = apply_filter(string_value(input), "capitalize", []).unwrap()
    assert_eq(result.to_string(), expected)
  }

  // Test unicode strings (may not support full unicode capitalization)
  let unicode_result = apply_filter(string_value("ñoño"), "capitalize", []).unwrap()
  match unicode_result {
    String(_) => () // Just verify it doesn't crash
    _ => fail("capitalize should handle unicode strings")
  }

  // Test truncate with exact boundary conditions
  let long_string_50 = "12345678901234567890123456789012345678901234567890" // Exactly 50 chars
  let long_string_51 = "123456789012345678901234567890123456789012345678901" // 51 chars
  let result_50 = apply_filter(string_value(long_string_50), "truncate", []).unwrap()
  assert_eq(result_50.to_string(), long_string_50) // Should not truncate
  let result_51 = apply_filter(string_value(long_string_51), "truncate", []).unwrap()
  assert_eq(result_51.to_string(), long_string_50[:47].to_owned() + "...") // Should truncate
}

///|
test "performance and stress edge cases" {
  // Test filters with larger inputs to ensure they handle scale

  // Large array test
  let large_array_items : Array[LiquidValue] = []
  for i in 0..<1000 {
    large_array_items.push(string_value("item" + i.to_string()))
  }
  let large_array = array_value(large_array_items)

  // Test array filters with large input
  let sort_result = apply_filter(large_array, "sort", []).unwrap()
  match sort_result {
    Array(arr) => assert_eq(arr.length(), 1000)
    _ => fail("sort should handle large arrays")
  }
  let uniq_result = apply_filter(large_array, "uniq", []).unwrap()
  match uniq_result {
    Array(arr) => assert_eq(arr.length(), 1000) // All items are unique
    _ => fail("uniq should handle large arrays")
  }

  // Large string test
  let large_string_parts : Array[String] = []
  for i in 0..<1000 {
    large_string_parts.push("word" + i.to_string())
  }
  let large_string = large_string_parts.join(" ")
  let truncate_result = apply_filter(
    string_value(large_string),
    "truncatewords",
    [],
  ).unwrap()
  match truncate_result {
    String(s) => assert_eq(s.contains("..."), true) // Should be truncated
    _ => fail("truncatewords should handle large strings")
  }
}
