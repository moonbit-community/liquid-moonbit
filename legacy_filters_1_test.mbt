///|
test "filter upcase" {
  // Test upcase filter
  let value = string_value("hello world")
  let result = apply_filter(value, "upcase")
  assert_eq(result.to_string(), "HELLO WORLD")

  // Test upcase on non-string (should return unchanged)
  let num_value = number_value(42.0)
  let num_result = apply_filter(num_value, "upcase")
  assert_eq(num_result.to_string(), "42")
}

///|
test "filter downcase" {
  // Test downcase filter
  let value = string_value("HELLO WORLD")
  let result = apply_filter(value, "downcase")
  assert_eq(result.to_string(), "hello world")

  // Test downcase on non-string (should return unchanged)
  let bool_value = bool_value(true)
  let bool_result = apply_filter(bool_value, "downcase")
  assert_eq(bool_result.to_string(), "true")
}

///|
test "filter size" {
  // Test size filter on string
  let str_value = string_value("hello")
  let str_result = apply_filter(str_value, "size")
  assert_eq(str_result.to_string(), "5")

  // Test size filter on array
  let arr_value = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
  ])
  let arr_result = apply_filter(arr_value, "size")
  assert_eq(arr_result.to_string(), "3")

  // Test size filter on object
  let obj_map = Map([])
  obj_map.set("key1", string_value("value1"))
  obj_map.set("key2", string_value("value2"))
  let obj_value = object_value(obj_map)
  let obj_result = apply_filter(obj_value, "size")
  assert_eq(obj_result.to_string(), "2")
}

///|
test "template with filters" {
  // Test template parsing with filters
  let template = parse("Hello {{ name | upcase }}!")
  json_inspect(template, content={
    "nodes": [
      ["Text", "Hello "],
      ["Variable", "name", [{ "name": "upcase", "parameters": [] }]],
      ["Text", "!"],
    ],
  })
  let context = LiquidContext::new()
  context.set("name", string_value("world"))
  let result = template.render(context)
  assert_eq(result, "Hello WORLD!")
}

///|
test "template with multiple filters" {
  // Test template parsing with multiple filters chained
  let template = parse("{{ text | upcase | size }}")
  json_inspect(template, content={
    "nodes": [
      [
        "Variable",
        "text",
        [
          { "name": "upcase", "parameters": [] },
          { "name": "size", "parameters": [] },
        ],
      ],
    ],
  })
  let context = LiquidContext::new()
  context.set("text", string_value("hello"))
  let result = template.render(context)
  assert_eq(result, "5") // "hello" -> "HELLO" -> "5"
}

///|
test "filter trim" {
  // Test trim filter
  let value = string_value("  hello world  ")
  let result = apply_filter(value, "trim")
  assert_eq(result.to_string(), "hello world")
}

///|
test "unknown filter" {
  // Test unknown filter (should return value unchanged)
  let value = string_value("hello")
  let result = apply_filter(value, "unknown_filter")
  assert_eq(result.to_string(), "hello")
}

///|
test "edge case filter with whitespace" {
  // Test filters with various whitespace patterns
  let template = parse(
    "{{ name|upcase }} {{ name | upcase }} {{ name |upcase}}",
  )
  json_inspect(template, content={
    "nodes": [
      ["Variable", "name", [{ "name": "upcase", "parameters": [] }]],
      ["Text", " "],
      ["Variable", "name", [{ "name": "upcase", "parameters": [] }]],
      ["Text", " "],
      ["Variable", "name", [{ "name": "upcase", "parameters": [] }]],
    ],
  })
  let context = LiquidContext::new()
  context.set("name", string_value("hello"))
  let result = template.render(context)
  assert_eq(result, "HELLO HELLO HELLO")
}

// Integration tests using example templates

///|
test "integration filter chain" {
  // Test filter chaining like in examples/filters.liquid
  let template = parse(
    "Original: {{ text }}\nUppercase: {{ text | upcase }}\nSize: {{ text | size }}",
  )
  json_inspect(template, content={
    "nodes": [
      ["Text", "Original: "],
      ["Variable", "text", []],
      ["Text", "\nUppercase: "],
      ["Variable", "text", [{ "name": "upcase", "parameters": [] }]],
      ["Text", "\nSize: "],
      ["Variable", "text", [{ "name": "size", "parameters": [] }]],
    ],
  })
  let context = LiquidContext::new()
  context.set("text", string_value("hello world"))
  let result = template.render(context)
  let expected = "Original: hello world\nUppercase: HELLO WORLD\nSize: 11"
  assert_eq(result, expected)
}

///|
test "filter first" {
  // Test first filter on arrays and strings
  let arr_value = array_value([
    string_value("apple"),
    string_value("banana"),
    string_value("cherry"),
  ])
  let arr_result = apply_filter(arr_value, "first")
  assert_eq(arr_result.to_string(), "apple")
  let str_value = string_value("hello")
  let str_result = apply_filter(str_value, "first")
  assert_eq(str_result.to_string(), "h")
  let empty_arr = array_value([])
  let empty_result = apply_filter(empty_arr, "first")
  assert_eq(empty_result.to_string(), "null")
}

///|
test "filter last" {
  // Test last filter on arrays and strings
  let arr_value = array_value([
    string_value("apple"),
    string_value("banana"),
    string_value("cherry"),
  ])
  let arr_result = apply_filter(arr_value, "last")
  assert_eq(arr_result.to_string(), "cherry")
  let str_value = string_value("hello")
  let str_result = apply_filter(str_value, "last")
  assert_eq(str_result.to_string(), "o")
}

///|
test "filter reverse" {
  // Test reverse filter on arrays
  let arr_value = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
  ])
  let arr_result = apply_filter(arr_value, "reverse")
  assert_eq(arr_result.to_string(), "[c, b, a]")

  // Test reverse filter on strings
  let str_value = string_value("hello")
  let str_result = apply_filter(str_value, "reverse")
  assert_eq(str_result.to_string(), "olleh")
}

///|
test "filter sort" {
  // Test sort filter on arrays
  let arr_value = array_value([
    string_value("cherry"),
    string_value("apple"),
    string_value("banana"),
  ])
  let arr_result = apply_filter(arr_value, "sort")
  assert_eq(arr_result.to_string(), "[apple, banana, cherry]")
}

///|
test "filter join" {
  // Test join filter on arrays
  let arr_value = array_value([
    string_value("apple"),
    string_value("banana"),
    string_value("cherry"),
  ])
  let join_result = apply_filter(arr_value, "join")
  assert_eq(join_result.to_string(), "apple, banana, cherry")
}

///|
test "filter strip" {
  // Test strip filter (alias for trim)
  let value = string_value("  hello world  ")
  let result = apply_filter(value, "strip")
  assert_eq(result.to_string(), "hello world")
}

///|
test "filter escape" {
  // Test HTML escape filter
  let value = string_value("<script>alert('xss')</script>")
  let result = apply_filter(value, "escape")
  assert_eq(result.to_string(), "&lt;script&gt;alert(&#39;xss')</script>")
}

///|
test "filter truncate" {
  // Test truncate filter
  let long_text = "This is a very long text that should be truncated because it exceeds the maximum length limit"
  let value = string_value(long_text)
  let result = apply_filter(value, "truncate")
  assert_eq(
    result.to_string(),
    "This is a very long text that should be truncat...",
  )
}

///|
test "filter default" {
  // Test default filter
  let null_value = null_value()
  let result1 = apply_filter(null_value, "default")
  assert_eq(result1.to_string(), "")
  let empty_string = string_value("")
  let result2 = apply_filter(empty_string, "default")
  assert_eq(result2.to_string(), "")
  let normal_string = string_value("hello")
  let result3 = apply_filter(normal_string, "default")
  assert_eq(result3.to_string(), "hello")
}

///|
test "filter length alias" {
  // Test length filter (alias for size)
  let value = string_value("hello")
  let result = apply_filter(value, "length")
  assert_eq(result.to_string(), "5")
}

// Math filter tests

///|
test "filter plus" {
  // Test plus filter (default increment by 1)
  let num_value = number_value(5.0)
  let num_result = apply_filter(num_value, "plus")
  assert_eq(num_result.to_string(), "6")
  let str_value = string_value("10")
  let str_result = apply_filter(str_value, "plus")
  assert_eq(str_result.to_string(), "10") // String parsing not implemented yet
}

///|
test "filter minus" {
  // Test minus filter (default decrement by 1)
  let num_value = number_value(5.0)
  let num_result = apply_filter(num_value, "minus")
  assert_eq(num_result.to_string(), "4")
  let str_value = string_value("10")
  let str_result = apply_filter(str_value, "minus")
  assert_eq(str_result.to_string(), "10") // String parsing not implemented yet
}

///|
test "filter times" {
  // Test times filter (default multiply by 2)
  let num_value = number_value(5.0)
  let num_result = apply_filter(num_value, "times")
  assert_eq(num_result.to_string(), "10")
  let str_value = string_value("3")
  let str_result = apply_filter(str_value, "times")
  assert_eq(str_result.to_string(), "3") // String parsing not implemented yet
}

///|
test "filter divided_by" {
  // Test divided_by filter (default divide by 2)
  let num_value = number_value(10.0)
  let num_result = apply_filter(num_value, "divided_by")
  assert_eq(num_result.to_string(), "5")
  let str_value = string_value("8")
  let str_result = apply_filter(str_value, "divided_by")
  assert_eq(str_result.to_string(), "8") // String parsing not implemented yet
}

///|
test "filter modulo" {
  // Test modulo filter (default modulo 2)
  let num_value = number_value(5.0)
  let num_result = apply_filter(num_value, "modulo")
  assert_eq(num_result.to_string(), "1")
  let str_value = string_value("7")
  let str_result = apply_filter(str_value, "modulo")
  assert_eq(str_result.to_string(), "7") // String parsing not implemented yet
}

///|
test "filter round" {
  // Test round filter
  let num_value = number_value(3.7)
  let num_result = apply_filter(num_value, "round")
  assert_eq(num_result.to_string(), "4")
  let str_value = string_value("2.3")
  let str_result = apply_filter(str_value, "round")
  assert_eq(str_result.to_string(), "2.3") // String parsing not implemented yet
}

///|
test "filter ceil" {
  // Test ceil filter
  let num_value = number_value(3.2)
  let num_result = apply_filter(num_value, "ceil")
  assert_eq(num_result.to_string(), "4")
  let str_value = string_value("2.1")
  let str_result = apply_filter(str_value, "ceil")
  assert_eq(str_result.to_string(), "2.1") // String parsing not implemented yet
}

///|
test "filter floor" {
  // Test floor filter
  let num_value = number_value(3.8)
  let num_result = apply_filter(num_value, "floor")
  assert_eq(num_result.to_string(), "3")
  let str_value = string_value("2.9")
  let str_result = apply_filter(str_value, "floor")
  assert_eq(str_result.to_string(), "2.9") // String parsing not implemented yet
}

///|
test "filter abs" {
  // Test abs filter
  let neg_value = number_value(-5.0)
  let neg_result = apply_filter(neg_value, "abs")
  assert_eq(neg_result.to_string(), "5")
  let pos_value = number_value(3.0)
  let pos_result = apply_filter(pos_value, "abs")
  assert_eq(pos_result.to_string(), "3")
  let str_value = string_value("-7")
  let str_result = apply_filter(str_value, "abs")
  assert_eq(str_result.to_string(), "-7") // String parsing not implemented yet
}

// Advanced Array Filter Tests

///|
test "filter map" {
  // Test map filter (basic identity for now)
  let arr_value = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
  ])
  let map_result = apply_filter(arr_value, "map")
  assert_eq(map_result.to_string(), "[a, b, c]")
}

///|
test "filter select" {
  // Test select filter - keeps truthy values
  let mixed_array = array_value([
    string_value("hello"),
    string_value(""),
    number_value(5.0),
    number_value(0.0),
    bool_value(true),
    bool_value(false),
    null_value(),
  ])
  let select_result = apply_filter(mixed_array, "select")
  assert_eq(select_result.to_string(), "[hello, 5, true]")
}

///|
test "filter reject" {
  // Test reject filter - keeps falsy values
  let mixed_array = array_value([
    string_value("hello"),
    string_value(""),
    number_value(5.0),
    number_value(0.0),
    bool_value(true),
    bool_value(false),
    null_value(),
  ])
  let reject_result = apply_filter(mixed_array, "reject")
  assert_eq(reject_result.to_string(), "[, 0, false, null]")
}

///|
test "filter compact" {
  // Test compact filter - removes null and empty values
  let messy_array = array_value([
    string_value("hello"),
    string_value(""),
    number_value(5.0),
    null_value(),
    string_value("world"),
  ])
  let compact_result = apply_filter(messy_array, "compact")
  assert_eq(compact_result.to_string(), "[hello, 5, world]")
}

///|
test "filter uniq" {
  // Test uniq filter - removes duplicates
  let duplicate_array = array_value([
    string_value("apple"),
    string_value("banana"),
    string_value("apple"),
    string_value("cherry"),
    string_value("banana"),
  ])
  let uniq_result = apply_filter(duplicate_array, "uniq")
  assert_eq(uniq_result.to_string(), "[apple, banana, cherry]")
}

///|
test "filter flatten" {
  // Test flatten filter - flattens nested arrays one level
  let nested_array = array_value([
    string_value("single"),
    array_value([string_value("nested1"), string_value("nested2")]),
    string_value("another"),
  ])
  let flatten_result = apply_filter(nested_array, "flatten")
  assert_eq(flatten_result.to_string(), "[single, nested1, nested2, another]")
}

///|
test "array filter chaining" {
  // Test chaining multiple array filters
  let template = parse("{{ items | compact | uniq | sort | join }}")
  let context = LiquidContext::new()
  let messy_items = array_value([
    string_value("cherry"),
    string_value(""),
    string_value("apple"),
    null_value(),
    string_value("cherry"),
    string_value("banana"),
  ])
  context.set("items", messy_items)
  let result = template.render(context)
  assert_eq(result, "apple, banana, cherry")
}
