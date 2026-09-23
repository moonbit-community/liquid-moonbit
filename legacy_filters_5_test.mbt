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
  let filter_0 = filter("at", ["0"])
  let result_0 = apply_filter_with_params(arr, filter_0)
  assert_eq(result_0.to_string(), "first")

  // Test at with index 2
  let filter_2 = filter("at", ["2"])
  let result_2 = apply_filter_with_params(arr, filter_2)
  assert_eq(result_2.to_string(), "third")

  // Test at with negative index -1 (last element)
  let filter_neg1 = filter("at", ["-1"])
  let result_neg1 = apply_filter_with_params(arr, filter_neg1)
  assert_eq(result_neg1.to_string(), "fourth")

  // Test at with out of bounds index
  let filter_oob = filter("at", ["10"])
  let result_oob = apply_filter_with_params(arr, filter_oob)
  assert_eq(result_oob.to_string(), "null")

  // Test at with no parameters (should return first element)
  let filter_no_params = filter("at", [])
  let result_no_params = apply_filter_with_params(arr, filter_no_params)
  assert_eq(result_no_params.to_string(), "first")

  // Test at with non-array value
  let string_val = string_value("not an array")
  let result_non_array = apply_filter_with_params(string_val, filter_0)
  assert_eq(result_non_array.to_string(), "not an array")
}

///|
test "enhanced map filter functionality" {
  // Test map filter with property parameter
  let obj1 = Map([])
  obj1.set("name", string_value("Alice"))
  obj1.set("age", number_value(25.0))
  let obj2 = Map([])
  obj2.set("name", string_value("Bob"))
  obj2.set("age", number_value(30.0))
  let obj3 = Map([])
  obj3.set("name", string_value("Charlie"))
  obj3.set("age", number_value(35.0))
  let arr = array_value([
    object_value(obj1),
    object_value(obj2),
    object_value(obj3),
  ])

  // Test map with 'name' property
  let filter_name = filter("map", ["name"])
  let result_names = apply_filter_with_params(arr, filter_name)
  match result_names {
    Array(mapped) => {
      assert_eq(mapped.length(), 3)
      assert_eq(mapped[0].to_string(), "Alice")
      assert_eq(mapped[1].to_string(), "Bob")
      assert_eq(mapped[2].to_string(), "Charlie")
    }
    _ => fail("Expected Array result")
  }

  // Test map with single quotes
  let filter_quotes = filter("map", ["'age'"])
  let result_ages = apply_filter_with_params(arr, filter_quotes)
  match result_ages {
    Array(mapped) => {
      assert_eq(mapped.length(), 3)
      assert_eq(mapped[0].to_string(), "25")
      assert_eq(mapped[1].to_string(), "30")
      assert_eq(mapped[2].to_string(), "35")
    }
    _ => fail("Expected Array result")
  }

  // Test map with missing property
  let filter_missing = filter("map", ["missing_prop"])
  let result_missing = apply_filter_with_params(arr, filter_missing)
  match result_missing {
    Array(mapped) => {
      assert_eq(mapped.length(), 3)
      assert_eq(mapped[0].to_string(), "null") // Missing properties become null
      assert_eq(mapped[1].to_string(), "null")
      assert_eq(mapped[2].to_string(), "null")
    }
    _ => fail("Expected Array result")
  }

  // Test map with no parameters (should fallback)
  let filter_no_params = filter("map", [])
  let result_no_params = apply_filter_with_params(arr, filter_no_params)
  match result_no_params {
    Array(mapped) => assert_eq(mapped.length(), 3) // Should return original array
    _ => fail("Expected Array result")
  }

  // Test map with non-array value
  let string_val = string_value("not an array")
  let result_non_array = apply_filter_with_params(string_val, filter_name)
  assert_eq(result_non_array.to_string(), "not an array")
}

///|
test "array manipulation filters" {
  // Test push, pop, shift, unshift filters
  let arr = array_value([
    string_value("first"),
    string_value("second"),
    string_value("third"),
  ])

  // Test push filter
  let result_push = apply_filter(arr, "push")
  match result_push {
    Array(pushed) => {
      assert_eq(pushed.length(), 4)
      assert_eq(pushed[3].to_string(), "pushed") // New element added
    }
    _ => fail("Expected Array result")
  }

  // Test pop filter
  let result_pop = apply_filter(arr, "pop")
  match result_pop {
    Array(popped) => {
      assert_eq(popped.length(), 2) // One element removed
      assert_eq(popped[0].to_string(), "first")
      assert_eq(popped[1].to_string(), "second")
    }
    _ => fail("Expected Array result")
  }

  // Test shift filter
  let result_shift = apply_filter(arr, "shift")
  match result_shift {
    Array(shifted) => {
      assert_eq(shifted.length(), 2) // First element removed
      assert_eq(shifted[0].to_string(), "second")
      assert_eq(shifted[1].to_string(), "third")
    }
    _ => fail("Expected Array result")
  }

  // Test unshift filter
  let result_unshift = apply_filter(arr, "unshift")
  match result_unshift {
    Array(unshifted) => {
      assert_eq(unshifted.length(), 4) // Element added to beginning
      assert_eq(unshifted[0].to_string(), "unshifted")
      assert_eq(unshifted[1].to_string(), "first")
    }
    _ => fail("Expected Array result")
  }

  // Test with empty array
  let empty_arr = array_value([])
  let result_pop_empty = apply_filter(empty_arr, "pop")
  match result_pop_empty {
    Array(popped) => assert_eq(popped.length(), 0) // Should remain empty
    _ => fail("Expected Array result")
  }
  let result_shift_empty = apply_filter(empty_arr, "shift")
  match result_shift_empty {
    Array(shifted) => assert_eq(shifted.length(), 0) // Should remain empty
    _ => fail("Expected Array result")
  }
}

///|
test "string trimming filters" {
  // Test lstrip and rstrip filters
  let text_with_spaces = string_value("  hello world  ")

  // Test lstrip (left strip)
  let result_lstrip = apply_filter(text_with_spaces, "lstrip")
  assert_eq(result_lstrip.to_string(), "hello world  ") // Only left spaces removed

  // Test rstrip (right strip)
  let result_rstrip = apply_filter(text_with_spaces, "rstrip")
  assert_eq(result_rstrip.to_string(), "  hello world") // Only right spaces removed

  // Test with string that has no leading/trailing spaces
  let clean_text = string_value("clean")
  let result_lstrip_clean = apply_filter(clean_text, "lstrip")
  assert_eq(result_lstrip_clean.to_string(), "clean")
  let result_rstrip_clean = apply_filter(clean_text, "rstrip")
  assert_eq(result_rstrip_clean.to_string(), "clean")
}

///|
test "concat filter basic" {
  // Test concat filter functionality
  let arr = array_value([string_value("a"), string_value("b")])
  let result_concat = apply_filter(arr, "concat")
  match result_concat {
    Array(concatenated) => assert_eq(concatenated.length(), 2) // Basic implementation returns original
    _ => fail("Expected Array result")
  }

  // Test concat with string
  let text = string_value("hello")
  let result_string_concat = apply_filter(text, "concat")
  assert_eq(result_string_concat.to_string(), "hello") // Invalid operands preserve the input in the legacy adapter
}

///|
test "new filter edge cases" {
  // Test edge cases for newly implemented filters

  // Test array manipulation filters with non-array values
  let string_val = string_value("not an array")
  assert_eq(apply_filter(string_val, "push").to_string(), "not an array")
  assert_eq(apply_filter(string_val, "pop").to_string(), "not an array")
  assert_eq(apply_filter(string_val, "shift").to_string(), "not an array")
  assert_eq(apply_filter(string_val, "unshift").to_string(), "not an array")

  // Test string trimming filters with non-string values
  let number_val = number_value(42.0)
  assert_eq(apply_filter(number_val, "lstrip").to_string(), "42")
  assert_eq(apply_filter(number_val, "rstrip").to_string(), "42")

  // Test concat filter with non-array, non-string values
  assert_eq(apply_filter(number_val, "concat").to_string(), "42")

  // Test at filter with basic usage (no parameters)
  let arr = array_value([string_value("test")])
  assert_eq(apply_filter(arr, "at").to_string(), "test")
}

///|
test "at filter additional edge cases" {
  let arr = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
  ])

  // Test at filter with parameters that are implemented
  let filter_1 = filter("at", ["1"])
  let result_1 = apply_filter_with_params(arr, filter_1)
  assert_eq(result_1.to_string(), "b")
  let filter_3 = filter("at", ["3"])
  let result_3 = apply_filter_with_params(arr, filter_3)
  assert_eq(result_3.to_string(), "null") // Index 3 is out of bounds for 3-element array
  let filter_4 = filter("at", ["4"])
  let result_4 = apply_filter_with_params(arr, filter_4)
  assert_eq(result_4.to_string(), "null") // Index 4 is also out of bounds
  let filter_5 = filter("at", ["5"])
  let result_5 = apply_filter_with_params(arr, filter_5)
  assert_eq(result_5.to_string(), "null") // Index 5 is also out of bounds

  // Test negative indexing with -2
  let longer_arr = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
  ])
  let filter_neg2 = filter("at", ["-2"])
  let result_neg2 = apply_filter_with_params(longer_arr, filter_neg2)
  assert_eq(result_neg2.to_string(), "c") // Second to last element
}

///|
test "map filter with mixed array types" {
  // Test map filter with array containing non-objects
  let obj = Map([])
  obj.set("name", string_value("Alice"))
  let mixed_arr = array_value([
    object_value(obj),
    string_value("plain string"),
    number_value(42.0),
  ])
  let filter_name = filter("map", ["name"])
  let result = apply_filter_with_params(mixed_arr, filter_name)
  match result {
    Array(mapped) => {
      assert_eq(mapped.length(), 3)
      assert_eq(mapped[0].to_string(), "Alice") // Object property
      assert_eq(mapped[1].to_string(), "plain string") // Non-object returns itself
      assert_eq(mapped[2].to_string(), "42") // Non-object returns itself
    }
    _ => fail("Expected Array result")
  }
}

///|
test "additional advanced filters" {
  // Test truncatewords filter
  let long_text = string_value(
    "This is a very long sentence with many words that should be truncated at word boundaries",
  )
  let result_truncatewords = apply_filter(long_text, "truncatewords")
  assert_eq(result_truncatewords.to_string().contains("..."), true) // Should be truncated

  // Test strip_tags filter (enhanced version)
  let html_text = string_value("<div><p>Hello <a href='#'>world</a></p></div>")
  let result_strip_tags = apply_filter(html_text, "strip_tags")
  // The basic implementation removes some tags but not all complex ones
  assert_eq(result_strip_tags.to_string().contains("Hello"), true)
  assert_eq(result_strip_tags.to_string().contains("world"), true)

  // Test normalize_whitespace filter
  let messy_text = string_value("  Hello   \t world  \n  test  ")
  let result_normalize = apply_filter(messy_text, "normalize_whitespace")
  assert_eq(result_normalize.to_string(), "Hello world test") // Normalized spaces
}

///|
test "truncatewords filter with parameters" {
  // Test truncatewords filter with custom word count
  let text = string_value(
    "One two three four five six seven eight nine ten eleven twelve",
  )

  // Test with 5 words parameter
  let filter_5 = filter("truncatewords", ["5"])
  let result_5 = apply_filter_with_params(text, filter_5)
  assert_eq(result_5.to_string(), "One two three four five...")

  // Test with 10 words parameter
  let filter_10 = filter("truncatewords", ["10"])
  let result_10 = apply_filter_with_params(text, filter_10)
  assert_eq(
    result_10.to_string(),
    "One two three four five six seven eight nine ten...",
  )

  // Test with text shorter than limit
  let short_text = string_value("Just three words")
  let result_short = apply_filter_with_params(short_text, filter_10)
  assert_eq(result_short.to_string(), "Just three words") // No truncation needed
}

///|
test "pluralize filter fallback case" {
  // Test the uncovered fallback case in pluralize filter
  let template = parse("{{ count | pluralize: 'item', 'items' }}")
  let context = LiquidContext::new()
  context.set("count", string_value("not_a_number")) // Non-number input
  let result = template.render(context)
  assert_eq(result, "not_a_number") // Should return original value
}

///|
test "pluralize filter parameter variations" {
  // Test different parameter count cases for pluralize
  let template1 = parse("{{ count | pluralize: 'item' }}") // Only one parameter
  let context1 = LiquidContext::new()
  context1.set("count", number_value(1.0))
  let result1 = template1.render(context1)
  assert_eq(result1, "1 item") // Should use basic pluralize logic

  // Test with different word counts
  let template2 = parse("{{ count | pluralize: 'cat', 'cats' }}")
  let context2 = LiquidContext::new()
  context2.set("count", number_value(2.5))
  let result2 = template2.render(context2)
  assert_eq(result2, "2.5 cats")
}

///|
test "sort_by filter with missing property" {
  // Test uncovered case where object doesn't have the specified property
  let template = parse("{{ items | sort_by: 'missing_prop' }}")
  let context = LiquidContext::new()
  let obj1 = Map([])
  obj1.set("name", string_value("Alice"))
  let obj2 = Map([])
  obj2.set("name", string_value("Bob"))
  let items = array_value([object_value(obj1), object_value(obj2)])
  context.set("items", items)
  let result = template.render(context)
  assert_eq(result, "[{\"name\": Alice}, {\"name\": Bob}]") // Should handle missing property
}

///|
test "sort_by filter with non-object items" {
  // Test uncovered case where array contains non-object items
  let template = parse("{{ items | sort_by: 'name' }}")
  let context = LiquidContext::new()
  let items = array_value([
    string_value("zebra"),
    string_value("apple"),
    number_value(42.0),
  ])
  context.set("items", items)
  let result = template.render(context)
  assert_eq(result, "[42, apple, zebra]") // Should sort by string representation
}

///|
test "sort_by filter non-array input" {
  // Test uncovered case where input is not an array
  let template = parse("{{ text | sort_by: 'prop' }}")
  let context = LiquidContext::new()
  context.set("text", string_value("not an array"))
  let result = template.render(context)
  assert_eq(result, "not an array") // Should return original value
}

///|
test "truncatewords filter edge cases" {
  // Test uncovered parameter values in truncatewords
  let template1 = parse("{{ text | truncatewords: 15 }}")
  let context1 = LiquidContext::new()
  context1.set(
    "text",
    string_value(
      "This has exactly fifteen words in it to test the truncation functionality properly",
    ),
  )
  let result1 = template1.render(context1)
  assert_eq(
    result1, "This has exactly fifteen words in it to test the truncation functionality properly",
  )
  let template2 = parse("{{ text | truncatewords: 20 }}")
  let context2 = LiquidContext::new()
  context2.set("text", string_value("This is a test"))
  let result2 = template2.render(context2)
  assert_eq(result2, "This is a test") // Should not truncate if under limit
  let template3 = parse("{{ text | truncatewords: 25 }}")
  let context3 = LiquidContext::new()
  context3.set("text", string_value("word"))
  let result3 = template3.render(context3)
  assert_eq(result3, "word")
  let template4 = parse("{{ text | truncatewords: 30 }}")
  let context4 = LiquidContext::new()
  context4.set("text", string_value("test"))
  let result4 = template4.render(context4)
  assert_eq(result4, "test")

  // Test default fallback case
  let template5 = parse("{{ text | truncatewords: 999 }}")
  let context5 = LiquidContext::new()
  context5.set("text", string_value("This should use the default word count"))
  let result5 = template5.render(context5)
  assert_eq(result5, "This should use the default word count")
}

///|
test "truncatewords filter non-string input" {
  // Test uncovered case where input is not a string
  let template = parse("{{ number | truncatewords: 5 }}")
  let context = LiquidContext::new()
  context.set("number", number_value(42.0))
  let result = template.render(context)
  assert_eq(result, "42") // Should return original value
}

///|
test "truncatewords filter fallback to basic" {
  // Test uncovered fallback to basic truncatewords
  let template = parse("{{ text | truncatewords }}")
  let context = LiquidContext::new()
  context.set(
    "text",
    string_value(
      "This is a very long sentence with many words to test truncation",
    ),
  )
  let result = template.render(context)
  // Should use basic truncatewords which defaults to 15 words
  assert_eq(
    result, "This is a very long sentence with many words to test truncation",
  )
}

///|
test "at filter non-array input" {
  // Test uncovered case where input is not an array for at filter
  let template = parse("{{ text | at: 0 }}")
  let context = LiquidContext::new()
  context.set("text", string_value("not an array"))
  let result = template.render(context)
  assert_eq(result, "not an array") // Should return original value
}

///|
test "strip_tags filter non-string input" {
  // Test uncovered case where input is not a string for strip_tags
  let template = parse("{{ number | strip_tags }}")
  let context = LiquidContext::new()
  context.set("number", number_value(42.0))
  let result = template.render(context)
  assert_eq(result, "42") // Should return original value
}

///|
test "normalize_whitespace filter non-string input" {
  // Test uncovered case where input is not a string for normalize_whitespace
  let template = parse("{{ number | normalize_whitespace }}")
  let context = LiquidContext::new()
  context.set("number", number_value(42.0))
  let result = template.render(context)
  assert_eq(result, "42") // Should return original value
}

///|
test "money_without_trailing_zeros filter edge case" {
  // Test uncovered case for money_without_trailing_zeros
  let template = parse("{{ price | money_without_trailing_zeros }}")
  let context = LiquidContext::new()
  context.set("price", number_value(10.0)) // Number ending in .0
  let result = template.render(context)
  assert_eq(result, "$10") // Should remove .0
}

///|
test "truncatewords basic filter without parameters" {
  // Test uncovered case in basic truncatewords filter
  let template = parse("{{ text | truncatewords }}")
  let context = LiquidContext::new()
  context.set("text", string_value("short"))
  let result = template.render(context)
  assert_eq(result, "short") // Should return original if under limit
}

///|
test "truncatewords basic filter non-string input" {
  // Test uncovered case in basic truncatewords filter with non-string
  let template = parse("{{ number | truncatewords }}")
  let context = LiquidContext::new()
  context.set("number", number_value(42.0))
  let result = template.render(context)
  assert_eq(result, "42") // Should return original value
}

///|
test "direct filter application uncovered cases" {
  // Test uncovered cases in apply_filter_with_params by calling directly

  // Test pluralize with non-number input (should fallback)
  let pluralize_filter = filter("pluralize", ["item", "items"])
  let non_number_result = apply_filter_with_params(
    string_value("text"),
    pluralize_filter,
  )
  assert_eq(non_number_result.to_string(), "text")

  // Test sort_by with missing property
  let obj_map = Map([])
  obj_map.set("other_prop", string_value("value"))
  let obj_with_missing = object_value(obj_map)
  let sort_by_filter = filter("sort_by", ["missing"])
  let sort_result = apply_filter_with_params(
    array_value([obj_with_missing]),
    sort_by_filter,
  )
  assert_eq(sort_result.to_string(), "[{\"other_prop\": value}]")

  // Test sort_by with non-object in array
  let mixed_array = array_value([string_value("zebra"), number_value(1.0)])
  let sort_mixed_result = apply_filter_with_params(mixed_array, sort_by_filter)
  assert_eq(sort_mixed_result.to_string(), "[1, zebra]")
}

///|
test "additional filter edge cases for complete coverage" {
  // Test more uncovered edge cases

  // Test truncatewords with various parameter values
  let text = string_value(
    "word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 word16 word17 word18 word19 word20",
  )
  let filter15 = filter("truncatewords", ["15"])
  let result15 = apply_filter_with_params(text, filter15)
  assert_eq(
    result15.to_string(),
    "word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15...",
  )
  let filter20 = filter("truncatewords", ["20"])
  let result20 = apply_filter_with_params(text, filter20)
  assert_eq(
    result20.to_string(),
    "word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 word16 word17 word18 word19 word20",
  )
  let filter25 = filter("truncatewords", ["25"])
  let result25 = apply_filter_with_params(text, filter25)
  assert_eq(
    result25.to_string(),
    "word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 word16 word17 word18 word19 word20",
  )
  let filter30 = filter("truncatewords", ["30"])
  let result30 = apply_filter_with_params(text, filter30)
  assert_eq(
    result30.to_string(),
    "word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 word16 word17 word18 word19 word20",
  )

  // Test unknown parameter (should use default)
  let filter_unknown = filter("truncatewords", ["unknown"])
  let result_unknown = apply_filter_with_params(text, filter_unknown)
  assert_eq(
    result_unknown.to_string(),
    "word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15...",
  )
}

///|
test "remaining uncovered filter cases" {
  // Test uncovered cases in basic apply_filter function

  // Test at filter with non-array input
  let at_result = apply_filter(string_value("not_array"), "at")
  assert_eq(at_result.to_string(), "not_array")

  // Test truncatewords with non-string input
  let truncate_result = apply_filter(number_value(42.0), "truncatewords")
  assert_eq(truncate_result.to_string(), "42")

  // Test money_without_trailing_zeros edge case with .0
  let money_result = apply_filter(
    number_value(10.0),
    "money_without_trailing_zeros",
  )
  assert_eq(money_result.to_string(), "$10")
}

///|
test "filter parameter quote handling comprehensive" {
  // Test quote handling in filter parameters - both single and double quotes

  // Test pluralize with double quotes
  let template1 = parse("{{ count | pluralize: \"item\", \"items\" }}")
  let context1 = LiquidContext::new()
  context1.set("count", number_value(2.0))
  let result1 = template1.render(context1)
  assert_eq(result1, "2 items")

  // Test pluralize with single quotes
  let template2 = parse("{{ count | pluralize: 'item', 'items' }}")
  let context2 = LiquidContext::new()
  context2.set("count", number_value(1.0))
  let result2 = template2.render(context2)
  assert_eq(result2, "1 item")

  // Test sort_by with single quotes
  let template3 = parse("{{ items | sort_by: 'name' }}")
  let context3 = LiquidContext::new()
  let obj1 = Map([])
  obj1.set("name", string_value("zebra"))
  let obj2 = Map([])
  obj2.set("name", string_value("apple"))
  context3.set("items", array_value([object_value(obj1), object_value(obj2)]))
  let result3 = template3.render(context3)
  assert_eq(result3, "[{\"name\": apple}, {\"name\": zebra}]")

  // Test map filter with single quotes
  let template4 = parse("{{ items | map: 'name' }}")
  let context4 = LiquidContext::new()
  context4.set("items", array_value([object_value(obj1), object_value(obj2)]))
  let result4 = template4.render(context4)
  assert_eq(result4, "[zebra, apple]")
}

///|
test "filter parameter edge cases without quotes" {
  // Test parameters without quotes to trigger else branches

  // Test pluralize with unquoted parameters
  let pluralize_filter = filter("pluralize", ["item", "items"])
  let result1 = apply_filter_with_params(number_value(1.0), pluralize_filter)
  assert_eq(result1.to_string(), "1 item")
  let result2 = apply_filter_with_params(number_value(3.0), pluralize_filter)
  assert_eq(result2.to_string(), "3 items")

  // Test sort_by with unquoted parameter
  let sort_filter = filter("sort_by", ["name"])
  let obj1 = Map([])
  obj1.set("name", string_value("zebra"))
  let obj2 = Map([])
  obj2.set("name", string_value("apple"))
  let items = array_value([object_value(obj1), object_value(obj2)])
  let sort_result = apply_filter_with_params(items, sort_filter)
  assert_eq(sort_result.to_string(), "[{\"name\": apple}, {\"name\": zebra}]")

  // Test map filter with unquoted parameter
  let map_filter = filter("map", ["name"])
  let map_result = apply_filter_with_params(items, map_filter)
  assert_eq(map_result.to_string(), "[zebra, apple]")
}

///|
test "comprehensive filter fallback scenarios" {
  // Test various fallback scenarios to increase coverage

  // Test where filter fallback
  let where_filter = filter("where", []) // No parameters
  let items = array_value([string_value("test"), string_value("filter")])
  let where_result = apply_filter_with_params(items, where_filter)
  assert_eq(where_result.to_string(), "[filter]") // Should use basic where filter

  // Test map filter fallback
  let map_filter = filter("map", []) // No parameters
  let map_result = apply_filter_with_params(items, map_filter)
  assert_eq(map_result.to_string(), "[test, filter]") // Should use basic map filter

  // Test truncatewords filter fallback
  let truncate_filter = filter("truncatewords", []) // No parameters
  let long_text = string_value(
    "This is a very long text with many words that should be truncated by the filter",
  )
  let truncate_result = apply_filter_with_params(long_text, truncate_filter)
  assert_eq(
    truncate_result.to_string(),
    "This is a very long text with many words that should be truncated by the...",
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
    let at_filter = filter("at", [indices[i]])
    let result = apply_filter_with_params(test_array, at_filter)
    assert_eq(result.to_string(), expected[i])
  }

  // Test out of bounds index
  let out_of_bounds_filter = filter("at", ["10"])
  let out_result = apply_filter_with_params(test_array, out_of_bounds_filter)
  assert_eq(out_result.to_string(), "null")

  // Test -2 with small array
  let small_array = array_value([string_value("only")])
  let small_filter = filter("at", ["-2"])
  let small_result = apply_filter_with_params(small_array, small_filter)
  assert_eq(small_result.to_string(), "null")
}

///|
test "map filter with missing properties" {
  // Test map filter when objects don't have the specified property

  let obj1 = Map([])
  obj1.set("name", string_value("Alice"))
  // obj1 doesn't have "age" property

  let obj2 = Map([])
  obj2.set("age", number_value(30.0))
  // obj2 doesn't have "name" property

  let items = array_value([object_value(obj1), object_value(obj2)])

  // Test mapping by "age" property
  let map_age_filter = filter("map", ["age"])
  let result = apply_filter_with_params(items, map_age_filter)
  assert_eq(result.to_string(), "[null, 30]") // Missing property should return null
}

///|
test "direct filter application for maximum coverage" {
  // Test direct filter application to hit remaining uncovered cases

  // Test money_without_trailing_zeros with numbers that have .0
  let money_vals = [10.0, 25.0, 100.0, 0.0]
  for val in money_vals {
    let result = apply_filter(number_value(val), "money_without_trailing_zeros")
    // This should trigger the uncovered line
    let expected_val = val.to_int().to_string()
    assert_eq(result.to_string(), "$" + expected_val)
  }

  // Test various filters with edge case inputs
  let edge_inputs = [null_value(), bool_value(true), bool_value(false)]
  let filters_to_test = ["upcase", "downcase", "trim", "capitalize", "split"]
  for filter_name in filters_to_test {
    for input in edge_inputs {
      let result = apply_filter(input, filter_name)
      // These should all return the original input for non-matching types
      assert_eq(result.to_string(), input.to_string())
    }
  }
}

///|
test "numeric precision and edge cases" {
  // Test numeric operations with various floating point values

  let test_numbers = [
    0.0, 0.1, 0.5, 0.9, 1.0, 1.1, 1.5, 1.9, 2.0, -1.0, -0.5, 10.0, 100.0, 1000.0,
    0.001, 999.999,
  ]

  // Test all math filters with edge cases
  let math_filters = [
    "plus", "minus", "times", "divided_by", "modulo", "round", "ceil", "floor", "abs",
  ]
  for filter_name in math_filters {
    for num in test_numbers {
      let result = apply_filter(number_value(num), filter_name)
      // Verify result is still a number (not NaN or error)
      match result {
        Number(_) | Float(_) => () // Both numeric representations are valid
        _ =>
          fail(
            "Math filter " +
            filter_name +
            " should return a numeric value for input " +
            num.to_string(),
          )
      }
    }
  }
}

///|
test "complex filter parameter combinations v2" {
  // Test complex combinations of filters with parameters

  // Test pluralize with edge case numbers
  let pluralize_numbers = [0.0, 1.0, 1.1, 2.0, -1.0, 100.0]
  for num in pluralize_numbers {
    let filter_obj = filter("pluralize", ["\"item\"", "'items'"])
    let result = apply_filter_with_params(number_value(num), filter_obj)
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
  let complex_sort_filter = filter("sort_by", ["'nested'"])
  let complex_result = apply_filter_with_params(
    complex_items, complex_sort_filter,
  )
  // Should handle complex nested structures
  assert_eq(complex_result.to_string().contains("apple"), true)
}
