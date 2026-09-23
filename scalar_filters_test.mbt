///|
test "filter size" {
  // Test size filter on string
  let str_value = string_value("hello")
  let str_result = apply_filter(str_value, "size", []).unwrap()
  assert_eq(str_result.to_string(), "5")

  // Test size filter on array
  let arr_value = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
  ])
  let arr_result = apply_filter(arr_value, "size", []).unwrap()
  assert_eq(arr_result.to_string(), "3")

  // Test size filter on object
  let obj_map = Map([])
  obj_map.set("key1", string_value("value1"))
  obj_map.set("key2", string_value("value2"))
  let obj_value = object_value(obj_map)
  let obj_result = apply_filter(obj_value, "size", []).unwrap()
  assert_eq(obj_result.to_string(), "2")
}

///|
test "filter default" {
  // Test default filter
  let null_value = null_value()
  let result1 = apply_filter(null_value, "default", []).unwrap()
  assert_eq(result1.to_string(), "")
  let empty_string = string_value("")
  let result2 = apply_filter(empty_string, "default", []).unwrap()
  assert_eq(result2.to_string(), "")
  let normal_string = string_value("hello")
  let result3 = apply_filter(normal_string, "default", []).unwrap()
  assert_eq(result3.to_string(), "hello")
}

///|
test "filter length alias" {
  // Test length filter (alias for size)
  let value = string_value("hello")
  let result = apply_filter(value, "length", []).unwrap()
  assert_eq(result.to_string(), "5")
}

///|
test "filter money" {
  // Test money filter
  let num_value = number_value(19.99)
  let num_result = apply_filter(num_value, "money", []).unwrap()
  assert_eq(num_result.to_string(), "$19.99")
  let str_value = string_value("25.50")
  let str_result = apply_filter(str_value, "money", []).unwrap()
  assert_eq(str_result.to_string(), "$25.50")
}

///|
test "filter money_with_currency" {
  // Test money_with_currency filter
  let num_value = number_value(100.0)
  let num_result = apply_filter(num_value, "money_with_currency", []).unwrap()
  assert_eq(num_result.to_string(), "$100 USD")
  let str_value = string_value("50.25")
  let str_result = apply_filter(str_value, "money_with_currency", []).unwrap()
  assert_eq(str_result.to_string(), "$50.25 USD")
}

///|
test "filter money_without_currency" {
  // Test money_without_currency filter
  let num_value = number_value(75.0)
  let num_result = apply_filter(num_value, "money_without_currency", []).unwrap()
  assert_eq(num_result.to_string(), "75")
  let str_value = string_value("$30.99")
  let str_result = apply_filter(str_value, "money_without_currency", []).unwrap()
  assert_eq(str_result.to_string(), "30.99")
}

///|
test "filter money_without_trailing_zeros" {
  // Test money_without_trailing_zeros filter
  let num_value = number_value(20.0)
  let num_result = apply_filter(num_value, "money_without_trailing_zeros", []).unwrap()
  assert_eq(num_result.to_string(), "$20")
  let num_value2 = number_value(19.99)
  let num_result2 = apply_filter(num_value2, "money_without_trailing_zeros", []).unwrap()
  assert_eq(num_result2.to_string(), "$19.99")
}

///|
test "filter edge cases money filters non-number" {
  // Test money filters with non-number/string inputs
  let arr_val = array_value([string_value("test")])
  let bool_val = bool_value(true)
  let null_val = null_value()
  assert_eq(apply_filter(arr_val, "money", []).unwrap().to_string(), "[test]")
  assert_eq(
    apply_filter(bool_val, "money_with_currency", []).unwrap().to_string(),
    "true",
  )
  assert_eq(
    apply_filter(null_val, "money_without_currency", []).unwrap().to_string(),
    "null",
  )
  assert_eq(
    apply_filter(arr_val, "money_without_trailing_zeros", [])
    .unwrap()
    .to_string(),
    "[test]",
  )
}

///|
test "size filter edge cases" {
  // Test size filter with different input types to cover uncovered lines
  let bool_val = bool_value(true)
  let null_val = null_value()

  // Test size with non-string/array/object
  assert_eq(apply_filter(bool_val, "size", []).unwrap().to_string(), "0")
  assert_eq(apply_filter(null_val, "length", []).unwrap().to_string(), "0")
}

///|
test "money filter trailing zeros edge case" {
  // Test money filter with trailing zeros
  let num_with_zeros = number_value(20.0)
  let result = apply_filter(num_with_zeros, "money_without_trailing_zeros", []).unwrap()
  assert_eq(result.to_string(), "$20") // Should remove .0

  // Test with string input
  let str_input = string_value("25.50")
  let str_result = apply_filter(str_input, "money_without_trailing_zeros", []).unwrap()
  assert_eq(str_result.to_string(), "$25.50") // Should handle string input
}

///|
test "money filter edge case with trailing zeros" {

  // Test money_without_trailing_zeros with number ending in .0
  let number_with_zero = number_value(25.0)
  let result_no_zeros = apply_filter(
    number_with_zero,
    "money_without_trailing_zeros",
    [],
  ).unwrap()
  assert_eq(result_no_zeros.to_string(), "$25")

  // Test money_without_trailing_zeros with number not ending in .0
  let number_decimal = number_value(25.50)
  let result_with_decimal = apply_filter(
    number_decimal,
    "money_without_trailing_zeros",
    [],
  ).unwrap()
  assert_eq(result_with_decimal.to_string(), "$25.5")
}

///|
test "money filter trailing zeros" {
  // Test money_without_trailing_zeros with number that has .0 suffix
  let number_zero = number_value(100.0)
  let result_money = apply_filter(number_zero, "money_without_trailing_zeros", []).unwrap()
  assert_eq(result_money.to_string(), "$100")
}

///|
test "pluralize filter basic" {
  // Test pluralize filter with number values
  let one_item = number_value(1.0)
  let result_one = apply_filter(one_item, "pluralize", []).unwrap()
  assert_eq(result_one.to_string(), "1 item")
  let multiple_items = number_value(5.0)
  let result_multiple = apply_filter(multiple_items, "pluralize", []).unwrap()
  assert_eq(result_multiple.to_string(), "5 items")
}

///|
test "pluralize filter with parameters" {
  // Test pluralize filter with custom singular and plural forms
  let one_item = number_value(1.0)
  let result_one = apply_filter(one_item, "pluralize", [
    string_value("person"),
    string_value("people"),
  ]).unwrap()
  assert_eq(result_one.to_string(), "1 person")
  let multiple_items = number_value(3.0)
  let result_multiple = apply_filter(multiple_items, "pluralize", [
    string_value("person"),
    string_value("people"),
  ]).unwrap()
  assert_eq(result_multiple.to_string(), "3 people")

  // Test with single quotes
  let result_cats = apply_filter(multiple_items, "pluralize", [
    string_value("cat"),
    string_value("cats"),
  ]).unwrap()
  assert_eq(result_cats.to_string(), "3 cats")
}

///|
test "reading_time filter" {
  // Test reading_time filter with text content
  let short_text = string_value(
    "This is a short text with about ten words in it.",
  )
  let result_short = apply_filter(short_text, "reading_time", []).unwrap()
  assert_eq(result_short.to_string(), "1") // Should be 1 minute for short text

  // Create a longer text (simulate ~400 words for 2 minutes)
  let long_text = string_value(
    "This is a much longer text that contains many more words to simulate a longer article. " +
    "We need to reach approximately four hundred words to get a reading time of about two minutes. " +
    "The reading time filter calculates based on an average of 200 words per minute which is standard. " +
    "This text is being extended to ensure we have enough content to test the reading time calculation properly. " +
    "Additional content is needed to reach the target word count for accurate testing of the reading time feature. " +
    "More words are being added to simulate a real article or blog post that would take longer to read completely.",
  )
  let result_long = apply_filter(long_text, "reading_time", []).unwrap()
  assert_eq(result_long.to_string(), "1") // Will be 1 due to ceiling of word_count/200
}

///|
test "pluralize filter parameter edge cases" {
  // Test pluralize with parameters that don't have quotes
  let number_val = number_value(3.0)
  let result_no_quotes = apply_filter(number_val, "pluralize", [
    string_value("item"),
    string_value("items"),
  ]).unwrap()
  assert_eq(result_no_quotes.to_string(), "3 items")

  // Test pluralize with insufficient parameters (should fallback)
  let result_no_params = apply_filter(number_val, "pluralize", []).unwrap()
  assert_eq(result_no_params.to_string(), "3 items") // Uses basic pluralize
}

///|
test "money filters in template" {
  // Test money filters in template context
  let template = @liquid.compile(
    "Price: {{ price | money }} | Full: {{ price | money_with_currency }}",
  ).unwrap()
  let context = LiquidContext::new()
  context.set("price", number_value(29.99))
  let result = template.render(context).unwrap()
  assert_eq(result, "Price: $29.99 | Full: $29.99 USD")
}

///|
test "pluralize filter fallback case" {
  // Test the uncovered fallback case in pluralize filter
  let template = @liquid.compile("{{ count | pluralize: 'item', 'items' }}").unwrap()
  let context = LiquidContext::new()
  context.set("count", string_value("not_a_number")) // Non-number input
  let result = template.render(context).unwrap()
  assert_eq(result, "not_a_number") // Should return original value
}

///|
test "pluralize filter parameter variations" {
  // Test different parameter count cases for pluralize
  let template1 = @liquid.compile("{{ count | pluralize: 'item' }}").unwrap() // Only one parameter
  let context1 = LiquidContext::new()
  context1.set("count", number_value(1.0))
  let result1 = template1.render(context1).unwrap()
  assert_eq(result1, "1 item") // Should use basic pluralize logic

  // Test with different word counts
  let template2 = @liquid.compile("{{ count | pluralize: 'cat', 'cats' }}").unwrap()
  let context2 = LiquidContext::new()
  context2.set("count", number_value(2.5))
  let result2 = template2.render(context2).unwrap()
  assert_eq(result2, "2.5 cats")
}

///|
test "money_without_trailing_zeros filter edge case" {
  // Test uncovered case for money_without_trailing_zeros
  let template = @liquid.compile("{{ price | money_without_trailing_zeros }}").unwrap()
  let context = LiquidContext::new()
  context.set("price", number_value(10.0)) // Number ending in .0
  let result = template.render(context).unwrap()
  assert_eq(result, "$10") // Should remove .0
}

///|
test "array size edge cases" {
  // Test slice filter with array that needs limit calculation
  let small_arr = array_value([string_value("a"), string_value("b")])
  let result_slice_small = apply_filter(small_arr, "slice", []).unwrap()
  match result_slice_small {
    Array(sliced) => assert_eq(sliced.length(), 2) // all elements since array < 3
    _ => fail("Expected Array result")
  }

  // Test limit filter with array that needs limit calculation
  let result_limit_small = apply_filter(small_arr, "limit", []).unwrap()
  match result_limit_small {
    Array(limited) => assert_eq(limited.length(), 2) // all elements since array < 2 is false
    _ => fail("Expected Array result")
  }
}

///|
test "money_without_trailing_zeros specific edge case" {
  // Test the specific uncovered line in money_without_trailing_zeros
  // This tests numbers that end with .0 to trigger the strip_suffix logic
  let test_values = [10.0, 5.0, 100.0, 0.0, 1.0]
  for val in test_values {
    let result = apply_filter(
      number_value(val),
      "money_without_trailing_zeros",
      [],
    ).unwrap()
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
    let result = apply_filter(
      number_value(num),
      "money_without_trailing_zeros",
      [],
    ).unwrap()
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
    [],
  ).unwrap()
  assert_eq(specific_test.to_string(), "$42")
}
