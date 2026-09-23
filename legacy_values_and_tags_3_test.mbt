///|
test "array size edge cases" {
  // Test slice filter with array that needs limit calculation
  let small_arr = array_value([string_value("a"), string_value("b")])
  let result_slice_small = apply_filter(small_arr, "slice")
  match result_slice_small {
    Array(sliced) => assert_eq(sliced.length(), 2) // all elements since array < 3
    _ => fail("Expected Array result")
  }

  // Test limit filter with array that needs limit calculation
  let result_limit_small = apply_filter(small_arr, "limit")
  match result_limit_small {
    Array(limited) => assert_eq(limited.length(), 2) // all elements since array < 2 is false
    _ => fail("Expected Array result")
  }
}

///|
test "increment tag basic functionality" {
  let context = LiquidContext::new()
  let node = increment_node("counter")
  // Standalone render calls have independent registers.
  assert_eq(render_node(node, context), "0")
  assert_eq(render_node(node, context), "0")
  assert_true(context.get("counter") is None)
}

///|
test "decrement tag basic functionality" {
  let context = LiquidContext::new()
  context.set("counter", number_value(5))
  let node = decrement_node("counter")
  assert_eq(render_node(node, context), "-1")
  assert_eq(render_node(node, context), "-1")
  assert_eq(context.get("counter").unwrap().to_string(), "5")
}

///|
test "increment decrement with non-number values" {
  // Test increment/decrement with non-number values
  let context = LiquidContext::new()
  context.set("string_var", string_value("hello"))

  // Test increment with string value (must not be overwritten)
  let increment_test = increment_node("string_var")
  let result = render_node(increment_test, context)
  assert_eq(result, "0")
  assert_eq(context.get("string_var").unwrap().to_string(), "hello")

  // Test decrement with boolean value
  context.set("bool_var", bool_value(true))
  let decrement_test = decrement_node("bool_var")
  let result_dec = render_node(decrement_test, context)
  assert_eq(result_dec, "-1") // Registers are separate from the boolean variable.
  assert_eq(context.get("bool_var").unwrap().to_string(), "true")
}

///|
test "echo tag basic functionality" {
  // Test echo tag functionality
  let context = LiquidContext::new()
  context.set("name", string_value("World"))

  // Test echo without filters
  let echo_test = echo_node("name", [])
  let result = render_node(echo_test, context)
  assert_eq(result, "World")

  // Test echo with filters
  let echo_with_filter = echo_node("name", [filter("upcase", [])])
  let result_filtered = render_node(echo_with_filter, context)
  assert_eq(result_filtered, "WORLD")

  // Test echo with missing variable (should output empty string, not error)
  let echo_missing = echo_node("missing_var", [])
  let result_missing = render_node(echo_missing, context)
  assert_eq(result_missing, "") // Echo outputs empty string for missing vars
}

///|
test "ifchanged tag basic functionality" {
  // Test ifchanged tag functionality
  let context = LiquidContext::new()

  // Test ifchanged with simple content
  let ifchanged_test = ifchanged_node([text_node("Content that changed")])
  let result = render_node(ifchanged_test, context)
  assert_eq(result, "Content that changed")

  // Test ifchanged with variable content
  context.set("value", string_value("test"))
  let ifchanged_var = ifchanged_node([variable_node("value", [])])
  let result_var = render_node(ifchanged_var, context)
  assert_eq(result_var, "test")
}

///|
test "content placeholder functionality" {
  // Test content placeholder
  let context = LiquidContext::new()
  let content_test = content_node()

  // Without content set
  let result_empty = render_node(content_test, context)
  assert_eq(result_empty, "<!-- Main content will be inserted here -->")

  // With content set
  context.set("__content__", string_value("Main page content"))
  let result_with_content = render_node(content_test, context)
  assert_eq(result_with_content, "Main page content")
}

///|
test "enhanced liquid drops comprehensive" {
  // Test all enhanced forloop properties
  let context = LiquidContext::new()
  let items = array_value([string_value("first"), string_value("second")])
  context.set("test_items", items)
  let for_test = for_node("item", "test_items", [
    text_node("Index: "),
    variable_node("forloop.index", []),
    text_node(", Cycle: "),
    variable_node("forloop.cycle", []),
    text_node(", Name: "),
    variable_node("forloop.name", []),
    text_node(", ParentLoop: "),
    variable_node("forloop.parentloop", []),
    text_node(" | "),
  ])
  let result = render_node(for_test, context)
  assert_eq(result.contains("Index: 1"), true)
  assert_eq(result.contains("Cycle: odd"), true)
  assert_eq(result.contains("Name: test_items"), true)
  assert_eq(result.contains("ParentLoop:  | "), true)
  assert_eq(result.contains("Index: 2"), true)
  assert_eq(result.contains("Cycle: even"), true)
}

///|
test "money_without_trailing_zeros specific edge case" {
  // Test the specific uncovered line in money_without_trailing_zeros
  // This tests numbers that end with .0 to trigger the strip_suffix logic
  let test_values = [10.0, 5.0, 100.0, 0.0, 1.0]
  for val in test_values {
    let result = apply_filter(number_value(val), "money_without_trailing_zeros")
    let expected = "$" + val.to_int().to_string()
    assert_eq(result.to_string(), expected)
  }
}

///|
test "money_without_trailing_zeros precise edge case" {
  // Very specific test to trigger the exact uncovered line 2576
  // This tests the strip_suffix(".0") logic specifically

  // Create numbers that specifically end with .0 in their string representation
  let precise_numbers = [
    1.0, 2.0, 3.0, 4.0, 5.0, 10.0, 20.0, 100.0, 1000.0, 0.0,
  ]
  for num in precise_numbers {
    let result = apply_filter(number_value(num), "money_without_trailing_zeros")
    let num_str = num.to_string()

    // Check if the number string representation ends with ".0"
    if num_str.strip_suffix(".0") != None {
      // This should trigger line 2576
      let expected = "$" + num.to_int().to_string()
      assert_eq(result.to_string(), expected)
    } else {
      let expected = "$" + num_str
      assert_eq(result.to_string(), expected)
    }
  }

  // Test with specific floating point values that should have .0 suffix
  let specific_test = apply_filter(
    number_value(42.0),
    "money_without_trailing_zeros",
  )
  assert_eq(specific_test.to_string(), "$42")
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
    let result = apply_filter(string_value(input), "capitalize")
    assert_eq(result.to_string(), expected)
  }

  // Test unicode strings (may not support full unicode capitalization)
  let unicode_result = apply_filter(string_value("ñoño"), "capitalize")
  match unicode_result {
    String(_) => () // Just verify it doesn't crash
    _ => fail("capitalize should handle unicode strings")
  }

  // Test truncate with exact boundary conditions
  let long_string_50 = "12345678901234567890123456789012345678901234567890" // Exactly 50 chars
  let long_string_51 = "123456789012345678901234567890123456789012345678901" // 51 chars
  let result_50 = apply_filter(string_value(long_string_50), "truncate")
  assert_eq(result_50.to_string(), long_string_50) // Should not truncate
  let result_51 = apply_filter(string_value(long_string_51), "truncate")
  assert_eq(result_51.to_string(), long_string_50[:47].to_owned() + "...") // Should truncate
}

///|
test "unicode and special character handling" {
  // Test filters with unicode and special characters

  let unicode_strings = [
    "café", "naïve", "résumé", "🚀", "αβγ", "中文", "العربية",
    "Ñoño", "jalapeño", "piñata",
  ]
  for unicode_str in unicode_strings {
    // Test string filters with unicode
    let upcase_result = apply_filter(string_value(unicode_str), "upcase")
    let downcase_result = apply_filter(string_value(unicode_str), "downcase")
    let capitalize_result = apply_filter(
      string_value(unicode_str),
      "capitalize",
    )

    // Should handle unicode without crashing
    match upcase_result {
      String(_) => ()
      _ => fail("upcase should handle unicode string: " + unicode_str)
    }
    match downcase_result {
      String(_) => ()
      _ => fail("downcase should handle unicode string: " + unicode_str)
    }
    match capitalize_result {
      String(_) => ()
      _ => fail("capitalize should handle unicode string: " + unicode_str)
    }
  }
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
  let sort_result = apply_filter(large_array, "sort")
  match sort_result {
    Array(arr) => assert_eq(arr.length(), 1000)
    _ => fail("sort should handle large arrays")
  }
  let uniq_result = apply_filter(large_array, "uniq")
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
  )
  match truncate_result {
    String(s) => assert_eq(s.contains("..."), true) // Should be truncated
    _ => fail("truncatewords should handle large strings")
  }
}
