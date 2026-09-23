///|
test "filter truncate" {
  // Test truncate filter
  let long_text = "This is a very long text that should be truncated because it exceeds the maximum length limit"
  let value = string_value(long_text)
  let result = apply_filter(value, "truncate", []).unwrap()
  assert_eq(
    result.to_string(),
    "This is a very long text that should be truncat...",
  )
}

///|
test "filter slice array" {
  // Test slice filter on arrays - takes first 3 elements
  let arr_value = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
    string_value("e"),
  ])
  let slice_result = apply_filter(arr_value, "slice", []).unwrap()
  assert_eq(slice_result.to_string(), "[a, b, c]")
}

///|
test "filter slice string" {
  // Test slice filter on strings - takes first 3 characters
  let str_value = string_value("hello")
  let slice_result = apply_filter(str_value, "slice", []).unwrap()
  assert_eq(slice_result.to_string(), "hel")
  let short_str = string_value("hi")
  let short_result = apply_filter(short_str, "slice", []).unwrap()
  assert_eq(short_result.to_string(), "hi") // Shorter than 3 chars
}

///|
test "filter limit" {
  // Test limit filter - takes first 2 elements
  let arr_value = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
  ])
  let limit_result = apply_filter(arr_value, "limit", []).unwrap()
  assert_eq(limit_result.to_string(), "[a, b]")
}

///|
test "filter parameters edge cases truncate" {
  // Test truncate filter with various parameter values

  // Test truncate with "30" parameter
  let long_string = string_value(
    "This is a very long string that should be truncated",
  )
  let result_30 = apply_filter(long_string, "truncate", [number_value(30)]).unwrap()
  assert_eq(result_30.to_string(), "This is a very long string ...")

  // Test truncate with "50" parameter
  let result_50 = apply_filter(long_string, "truncate", [number_value(50)]).unwrap()
  assert_eq(
    result_50.to_string(),
    "This is a very long string that should be trunc...",
  )

  // Test truncate with "100" parameter
  let result_100 = apply_filter(long_string, "truncate", [number_value(100)]).unwrap()
  assert_eq(
    result_100.to_string(),
    "This is a very long string that should be truncated",
  )

  // Test truncate with large limit (should preserve the original string)
  let result_unknown = apply_filter(long_string, "truncate", [number_value(999)]).unwrap()
  assert_eq(
    result_unknown.to_string(),
    "This is a very long string that should be truncated",
  )

  // Test truncate with no parameters (should default to 50)
  let result_no_params = apply_filter(long_string, "truncate", []).unwrap()
  assert_eq(
    result_no_params.to_string(),
    "This is a very long string that should be trunc...",
  )

  // Test truncate with string shorter than max_length
  let short_string = string_value("Short")
  let result_short = apply_filter(short_string, "truncate", [number_value(30)]).unwrap()
  assert_eq(result_short.to_string(), "Short")

  // Test truncate with non-string value
  let number_val = number_value(42.0)
  let result_number = apply_filter(number_val, "truncate", [number_value(30)]).unwrap()
  assert_eq(result_number.to_string(), "42")
}

///|
test "slice filter parameter variations" {
  let arr = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
    string_value("e"),
  ])

  // Test slice with "3" start parameter
  let result_3 = apply_filter(arr, "slice", [number_value(3)]).unwrap()
  match result_3 {
    Array(sliced) => assert_eq(sliced.length(), 1) // element d
    _ => fail("Expected Array result")
  }

  // Test slice with out-of-range start
  let result_unknown = apply_filter(arr, "slice", [number_value(999)]).unwrap()
  match result_unknown {
    Array(sliced) => assert_eq(sliced.length(), 0) // start beyond the array
    _ => fail("Expected Array result")
  }

  // Test slice with "1" length parameter
  let result_1_len = apply_filter(arr, "slice", [
    number_value(1),
    number_value(1),
  ]).unwrap()
  match result_1_len {
    Array(sliced) => assert_eq(sliced.length(), 1)
    _ => fail("Expected Array result")
  }

  // Test slice with "4" and "5" parameters
  let result_4_5 = apply_filter(arr, "slice", [number_value(2), number_value(4)]).unwrap()
  match result_4_5 {
    Array(sliced) => assert_eq(sliced.length(), 3) // elements c, d, e
    _ => fail("Expected Array result")
  }

  // Test slice with length larger than the array
  let result_unknown_len = apply_filter(arr, "slice", [
    number_value(0),
    number_value(999),
  ]).unwrap()
  match result_unknown_len {
    Array(sliced) => assert_eq(sliced.length(), 5) // length is capped by the array
    _ => fail("Expected Array result")
  }

  // Test slice with string (start at position 0 with length 5)
  let string_val = string_value("hello world")
  let result_string = apply_filter(string_val, "slice", [
    number_value(0),
    number_value(5),
  ]).unwrap()
  // "hello world" slice from position 0 with length 5 should be "hello"
  assert_eq(result_string.to_string(), "hello")

  // Test slice with string using supported parameters (start=0, length=3)
  let result_supported = apply_filter(string_val, "slice", [
    number_value(0),
    number_value(3),
  ]).unwrap()
  // "hello world" slice from position 0 with length 3 should be "hel"
  assert_eq(result_supported.to_string(), "hel")

  // Test slice with non-array, non-string value
  let number_val = number_value(42.0)
  let result_number = apply_filter(number_val, "slice", [number_value(3)]).unwrap()
  assert_eq(result_number.to_string(), "42")
}

///|
test "offset and limit filter parameter variations" {
  let arr = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
    string_value("e"),
  ])

  // Test offset with "4" parameter
  let result_offset_4 = apply_filter(arr, "offset", [number_value(4)]).unwrap()
  match result_offset_4 {
    Array(offset_arr) => assert_eq(offset_arr.length(), 1) // only element "e"
    _ => fail("Expected Array result")
  }

  // Test offset with offset beyond the array
  let result_offset_unknown = apply_filter(arr, "offset", [number_value(999)]).unwrap()
  match result_offset_unknown {
    Array(offset_arr) => assert_eq(offset_arr.length(), 0) // no elements remain
    _ => fail("Expected Array result")
  }

  // Test limit with limit larger than the array
  let result_limit_unknown = apply_filter(arr, "limit", [number_value(999)]).unwrap()
  match result_limit_unknown {
    Array(limited_arr) => assert_eq(limited_arr.length(), 5) // all elements
    _ => fail("Expected Array result")
  }
}

///|
test "basic array filter size variations" {

  // Test slice filter with array longer than limit
  let long_arr = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
    string_value("e"),
  ])
  let result_slice = apply_filter(long_arr, "slice", []).unwrap()
  match result_slice {
    Array(sliced) => assert_eq(sliced.length(), 3) // first 3 elements
    _ => fail("Expected Array result")
  }

  // Test limit filter with array longer than limit
  let result_limit = apply_filter(long_arr, "limit", []).unwrap()
  match result_limit {
    Array(limited) => assert_eq(limited.length(), 2) // first 2 elements
    _ => fail("Expected Array result")
  }

  // Test slice filter with non-array, non-string value
  let number_val = number_value(42.0)
  let result_slice_number = apply_filter(number_val, "slice", []).unwrap()
  assert_eq(result_slice_number.to_string(), "42")
}

///|
test "at filter additional edge cases" {
  let arr = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
  ])

  // Test at filter with parameters that are implemented
  let result_1 = apply_filter(arr, "at", [number_value(1)]).unwrap()
  assert_eq(result_1.to_string(), "b")
  let result_3 = apply_filter(arr, "at", [number_value(3)]).unwrap()
  assert_eq(result_3.to_string(), "null") // Index 3 is out of bounds for 3-element array
  let result_4 = apply_filter(arr, "at", [number_value(4)]).unwrap()
  assert_eq(result_4.to_string(), "null") // Index 4 is also out of bounds
  let result_5 = apply_filter(arr, "at", [number_value(5)]).unwrap()
  assert_eq(result_5.to_string(), "null") // Index 5 is also out of bounds

  // Test negative indexing with -2
  let longer_arr = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
  ])
  let result_neg2 = apply_filter(longer_arr, "at", [number_value(-2)]).unwrap()
  assert_eq(result_neg2.to_string(), "c") // Second to last element
}

///|
test "truncatewords filter with parameters" {
  // Test truncatewords filter with custom word count
  let text = string_value(
    "One two three four five six seven eight nine ten eleven twelve",
  )

  // Test with 5 words parameter
  let result_5 = apply_filter(text, "truncatewords", [number_value(5)]).unwrap()
  assert_eq(result_5.to_string(), "One two three four five...")

  // Test with 10 words parameter
  let result_10 = apply_filter(text, "truncatewords", [number_value(10)]).unwrap()
  assert_eq(
    result_10.to_string(),
    "One two three four five six seven eight nine ten...",
  )

  // Test with text shorter than limit
  let short_text = string_value("Just three words")
  let result_short = apply_filter(short_text, "truncatewords", [
    number_value(10),
  ]).unwrap()
  assert_eq(result_short.to_string(), "Just three words") // No truncation needed
}

///|
test "additional filter edge cases for complete coverage" {
  // Test more uncovered edge cases

  // Test truncatewords with various parameter values
  let text = string_value(
    "word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 word16 word17 word18 word19 word20",
  )
  let result15 = apply_filter(text, "truncatewords", [number_value(15)]).unwrap()
  assert_eq(
    result15.to_string(),
    "word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15...",
  )
  let result20 = apply_filter(text, "truncatewords", [number_value(20)]).unwrap()
  assert_eq(
    result20.to_string(),
    "word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 word16 word17 word18 word19 word20",
  )
  let result25 = apply_filter(text, "truncatewords", [number_value(25)]).unwrap()
  assert_eq(
    result25.to_string(),
    "word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 word16 word17 word18 word19 word20",
  )
  let result30 = apply_filter(text, "truncatewords", [number_value(30)]).unwrap()
  assert_eq(
    result30.to_string(),
    "word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 word16 word17 word18 word19 word20",
  )

  // Test unknown parameter (should use default)
  let result_unknown = apply_filter(text, "truncatewords", [
    string_value("unknown"),
  ]).unwrap()
  assert_eq(
    result_unknown.to_string(),
    "word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15...",
  )
}

///|
test "array index edge cases for at filter" {
  // Test specific index values for at filter to cover all branches

  let test_array = array_value([
    string_value("zero"),
    string_value("one"),
    string_value("two"),
    string_value("three"),
    string_value("four"),
    string_value("five"),
  ])

  // Test various index parameters
  let indices = ["0", "1", "2", "3", "4", "5", "-1", "-2"]
  let expected = ["zero", "one", "two", "three", "four", "five", "five", "four"]
  for i in 0..<indices.length() {
    let result = apply_filter(test_array, "at", [string_value(indices[i])]).unwrap()
    assert_eq(result.to_string(), expected[i])
  }

  // Test out of bounds index
  let out_result = apply_filter(test_array, "at", [number_value(10)]).unwrap()
  assert_eq(out_result.to_string(), "null")

  // Test -2 with small array
  let small_array = array_value([string_value("only")])
  let small_result = apply_filter(small_array, "at", [number_value(-2)]).unwrap()
  assert_eq(small_result.to_string(), "null")
}

///|
test "filter parameters truncate" {
  // Test truncate filter with parameter
  let template = @liquid.compile("{{ text | truncate: 10 }}").unwrap()
  let context = LiquidContext::new()
  context.set("text", string_value("This is a very long text"))
  let result = template.render(context).unwrap()
  assert_eq(result, "This is...")
}

///|
test "filter offset" {
  // Test offset filter - skips first element
  let arr_value = array_value([
    string_value("first"),
    string_value("second"),
    string_value("third"),
  ])
  let offset_result = apply_filter(arr_value, "offset", []).unwrap()
  assert_eq(offset_result.to_string(), "[second, third]")
}

///|
test "slice filter with multiple parameters" {
  // Test slice filter with start and length parameters
  let template = @liquid.compile("{{ items | slice: 1, 2 }}").unwrap()
  let context = LiquidContext::new()
  let items = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
    string_value("e"),
  ])
  context.set("items", items)
  let result = template.render(context).unwrap()
  assert_eq(result, "[b, c]") // Start at index 1, take 2 elements
}

///|
test "slice filter with string parameters" {
  // Test slice filter on strings with parameters
  let template = @liquid.compile("{{ text | slice: 2, 3 }}").unwrap()
  let context = LiquidContext::new()
  context.set("text", string_value("hello world"))
  let result = template.render(context).unwrap()
  assert_eq(result, "llo") // Start at index 2, take 3 characters
}

///|
test "slice filter single parameter" {
  // Test slice filter with only start parameter
  let template = @liquid.compile("{{ items | slice: 2 }}").unwrap()
  let context = LiquidContext::new()
  let items = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
  ])
  context.set("items", items)
  let result = template.render(context).unwrap()
  assert_eq(result, "[c]") // Start at index 2, default length 3 (but only 2 remaining)
}

///|
test "offset filter with parameter" {
  // Test offset filter with specific parameter
  let template = @liquid.compile("{{ items | offset: 2 }}").unwrap()
  let context = LiquidContext::new()
  let items = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
    string_value("e"),
  ])
  context.set("items", items)
  let result = template.render(context).unwrap()
  assert_eq(result, "[c, d, e]") // Skip first 2 elements
}

///|
test "limit filter with parameter" {
  // Test limit filter with specific parameter
  let template = @liquid.compile("{{ items | limit: 3 }}").unwrap()
  let context = LiquidContext::new()
  let items = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
    string_value("e"),
  ])
  context.set("items", items)
  let result = template.render(context).unwrap()
  assert_eq(result, "[a, b, c]") // Take first 3 elements
}

///|
test "at filter functionality" {
  // Test at filter with various indices
  let arr = array_value([
    string_value("first"),
    string_value("second"),
    string_value("third"),
    string_value("fourth"),
  ])

  // Test at with index 0
  let result_0 = apply_filter(arr, "at", [number_value(0)]).unwrap()
  assert_eq(result_0.to_string(), "first")

  // Test at with index 2
  let result_2 = apply_filter(arr, "at", [number_value(2)]).unwrap()
  assert_eq(result_2.to_string(), "third")

  // Test at with negative index -1 (last element)
  let result_neg1 = apply_filter(arr, "at", [number_value(-1)]).unwrap()
  assert_eq(result_neg1.to_string(), "fourth")

  // Test at with out of bounds index
  let result_oob = apply_filter(arr, "at", [number_value(10)]).unwrap()
  assert_eq(result_oob.to_string(), "null")

  // Test at with no parameters (should return first element)
  let result_no_params = apply_filter(arr, "at", []).unwrap()
  assert_eq(result_no_params.to_string(), "first")

  // Test at with non-array value
  let string_val = string_value("not an array")
  let result_non_array = apply_filter(string_val, "at", [number_value(0)]).unwrap()
  assert_eq(result_non_array.to_string(), "not an array")
}

///|
test "truncatewords filter edge cases" {
  // Test uncovered parameter values in truncatewords
  let template1 = @liquid.compile("{{ text | truncatewords: 15 }}").unwrap()
  let context1 = LiquidContext::new()
  context1.set(
    "text",
    string_value(
      "This has exactly fifteen words in it to test the truncation functionality properly",
    ),
  )
  let result1 = template1.render(context1).unwrap()
  assert_eq(
    result1, "This has exactly fifteen words in it to test the truncation functionality properly",
  )
  let template2 = @liquid.compile("{{ text | truncatewords: 20 }}").unwrap()
  let context2 = LiquidContext::new()
  context2.set("text", string_value("This is a test"))
  let result2 = template2.render(context2).unwrap()
  assert_eq(result2, "This is a test") // Should not truncate if under limit
  let template3 = @liquid.compile("{{ text | truncatewords: 25 }}").unwrap()
  let context3 = LiquidContext::new()
  context3.set("text", string_value("word"))
  let result3 = template3.render(context3).unwrap()
  assert_eq(result3, "word")
  let template4 = @liquid.compile("{{ text | truncatewords: 30 }}").unwrap()
  let context4 = LiquidContext::new()
  context4.set("text", string_value("test"))
  let result4 = template4.render(context4).unwrap()
  assert_eq(result4, "test")

  // Test default fallback case
  let template5 = @liquid.compile("{{ text | truncatewords: 999 }}").unwrap()
  let context5 = LiquidContext::new()
  context5.set("text", string_value("This should use the default word count"))
  let result5 = template5.render(context5).unwrap()
  assert_eq(result5, "This should use the default word count")
}

///|
test "truncatewords filter non-string input" {
  // Test uncovered case where input is not a string
  let template = @liquid.compile("{{ number | truncatewords: 5 }}").unwrap()
  let context = LiquidContext::new()
  context.set("number", number_value(42.0))
  let result = template.render(context).unwrap()
  assert_eq(result, "42") // Should return original value
}

///|
test "truncatewords filter fallback to basic" {
  // Test uncovered fallback to basic truncatewords
  let template = @liquid.compile("{{ text | truncatewords }}").unwrap()
  let context = LiquidContext::new()
  context.set(
    "text",
    string_value(
      "This is a very long sentence with many words to test truncation",
    ),
  )
  let result = template.render(context).unwrap()
  // Should use basic truncatewords which defaults to 15 words
  assert_eq(
    result, "This is a very long sentence with many words to test truncation",
  )
}

///|
test "at filter non-array input" {
  // Test uncovered case where input is not an array for at filter
  let template = @liquid.compile("{{ text | at: 0 }}").unwrap()
  let context = LiquidContext::new()
  context.set("text", string_value("not an array"))
  let result = template.render(context).unwrap()
  assert_eq(result, "not an array") // Should return original value
}

///|
test "truncatewords basic filter without parameters" {
  // Test uncovered case in basic truncatewords filter
  let template = @liquid.compile("{{ text | truncatewords }}").unwrap()
  let context = LiquidContext::new()
  context.set("text", string_value("short"))
  let result = template.render(context).unwrap()
  assert_eq(result, "short") // Should return original if under limit
}

///|
test "truncatewords basic filter non-string input" {
  // Test uncovered case in basic truncatewords filter with non-string
  let template = @liquid.compile("{{ number | truncatewords }}").unwrap()
  let context = LiquidContext::new()
  context.set("number", number_value(42.0))
  let result = template.render(context).unwrap()
  assert_eq(result, "42") // Should return original value
}

///|
test "offset and limit combined" {
  // Test offset and limit filters combined
  let template = @liquid.compile("{{ items | offset: 1 | limit: 2 }}").unwrap()
  let context = LiquidContext::new()
  let items = array_value([
    string_value("first"),
    string_value("second"),
    string_value("third"),
    string_value("fourth"),
    string_value("fifth"),
  ])
  context.set("items", items)
  let result = template.render(context).unwrap()
  assert_eq(result, "[second, third]") // Skip 1, then take 2
}

///|
test "pagination example with offset and limit" {
  // Test realistic pagination example
  let template = @liquid.compile(
    "Page 2: {{ articles | offset: 5 | limit: 5 | join }}",
  ).unwrap()
  let context = LiquidContext::new()
  let articles = array_value([
    string_value("art1"),
    string_value("art2"),
    string_value("art3"),
    string_value("art4"),
    string_value("art5"),
    string_value("art6"),
    string_value("art7"),
    string_value("art8"),
    string_value("art9"),
    string_value("art10"),
  ])
  context.set("articles", articles)
  let result = template.render(context).unwrap()
  assert_eq(result, "Page 2: art6, art7, art8, art9, art10")
}

///|
test "limit with small array" {
  // Test limit filter with array smaller than limit
  let template = @liquid.compile("{{ items | limit: 10 }}").unwrap()
  let context = LiquidContext::new()
  let items = array_value([string_value("only"), string_value("two")])
  context.set("items", items)
  let result = template.render(context).unwrap()
  assert_eq(result, "[only, two]") // Should return all items when limit > array size
}
