///|
test "filter parameters truncate" {
  // Test truncate filter with parameter
  let template = @engine.compile("{{ text | truncate: 10 }}").unwrap()
  let context = LiquidContext::new()
  context.set("text", string_value("This is a very long text"))
  let result = template.render(context).unwrap()
  assert_eq(result, "This is...")
}

///|
test "slice filter with multiple parameters" {
  // Test slice filter with start and length parameters
  let template = @engine.compile("{{ items | slice: 1, 2 }}").unwrap()
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
  let template = @engine.compile("{{ text | slice: 2, 3 }}").unwrap()
  let context = LiquidContext::new()
  context.set("text", string_value("hello world"))
  let result = template.render(context).unwrap()
  assert_eq(result, "llo") // Start at index 2, take 3 characters
}

///|
test "slice filter single parameter" {
  // Test slice filter with only start parameter
  let template = @engine.compile("{{ items | slice: 2 }}").unwrap()
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
  let template = @engine.compile("{{ items | offset: 2 }}").unwrap()
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
  let template = @engine.compile("{{ items | limit: 3 }}").unwrap()
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
test "truncatewords filter edge cases" {
  // Test uncovered parameter values in truncatewords
  let template1 = @engine.compile("{{ text | truncatewords: 15 }}").unwrap()
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
  let template2 = @engine.compile("{{ text | truncatewords: 20 }}").unwrap()
  let context2 = LiquidContext::new()
  context2.set("text", string_value("This is a test"))
  let result2 = template2.render(context2).unwrap()
  assert_eq(result2, "This is a test") // Should not truncate if under limit
  let template3 = @engine.compile("{{ text | truncatewords: 25 }}").unwrap()
  let context3 = LiquidContext::new()
  context3.set("text", string_value("word"))
  let result3 = template3.render(context3).unwrap()
  assert_eq(result3, "word")
  let template4 = @engine.compile("{{ text | truncatewords: 30 }}").unwrap()
  let context4 = LiquidContext::new()
  context4.set("text", string_value("test"))
  let result4 = template4.render(context4).unwrap()
  assert_eq(result4, "test")

  // Test default fallback case
  let template5 = @engine.compile("{{ text | truncatewords: 999 }}").unwrap()
  let context5 = LiquidContext::new()
  context5.set("text", string_value("This should use the default word count"))
  let result5 = template5.render(context5).unwrap()
  assert_eq(result5, "This should use the default word count")
}

///|
test "truncatewords filter non-string input" {
  // Test uncovered case where input is not a string
  let template = @engine.compile("{{ number | truncatewords: 5 }}").unwrap()
  let context = LiquidContext::new()
  context.set("number", number_value(42.0))
  let result = template.render(context).unwrap()
  assert_eq(result, "42") // Should return original value
}

///|
test "truncatewords filter fallback to basic" {
  // Test uncovered fallback to basic truncatewords
  let template = @engine.compile("{{ text | truncatewords }}").unwrap()
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
  let template = @engine.compile("{{ text | at: 0 }}").unwrap()
  let context = LiquidContext::new()
  context.set("text", string_value("not an array"))
  let result = template.render(context).unwrap()
  assert_eq(result, "not an array") // Should return original value
}

///|
test "truncatewords basic filter without parameters" {
  // Test uncovered case in basic truncatewords filter
  let template = @engine.compile("{{ text | truncatewords }}").unwrap()
  let context = LiquidContext::new()
  context.set("text", string_value("short"))
  let result = template.render(context).unwrap()
  assert_eq(result, "short") // Should return original if under limit
}

///|
test "truncatewords basic filter non-string input" {
  // Test uncovered case in basic truncatewords filter with non-string
  let template = @engine.compile("{{ number | truncatewords }}").unwrap()
  let context = LiquidContext::new()
  context.set("number", number_value(42.0))
  let result = template.render(context).unwrap()
  assert_eq(result, "42") // Should return original value
}

///|
test "offset and limit combined" {
  // Test offset and limit filters combined
  let template = @engine.compile("{{ items | offset: 1 | limit: 2 }}").unwrap()
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
  let template = @engine.compile(
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
  let template = @engine.compile("{{ items | limit: 10 }}").unwrap()
  let context = LiquidContext::new()
  let items = array_value([string_value("only"), string_value("two")])
  context.set("items", items)
  let result = template.render(context).unwrap()
  assert_eq(result, "[only, two]") // Should return all items when limit > array size
}
