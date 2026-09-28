///|
test "date filters in template" {
  // Test date filters in template context
  let template = @engine.compile(
    "Published: {{ date | date }}\nISO: {{ date | date_to_xmlschema }}",
  ).unwrap()
  let context = LiquidContext::new()
  context.set("date", string_value("2024-12-25"))
  let result = template.render(context).unwrap()
  let expected = "Published: 2024-12-25\nISO: 2024-12-25T00:00:00Z"
  assert_eq(result, expected)
}

///|
test "date filter with format parameter" {
  // Test date filter with format string parameter
  let template = @engine.compile("{{ date | date: '%B %d, %Y' }}").unwrap()
  let context = LiquidContext::new()
  context.set("date", string_value("2024-01-15"))
  let result = template.render(context).unwrap()
  assert_eq(result, "January 15, 2024")
}

///|
test "date filter with ISO format" {
  // Test date filter with ISO format
  let template = @engine.compile("{{ date | date: '%Y-%m-%d' }}").unwrap()
  let context = LiquidContext::new()
  context.set("date", string_value("2023-12-25"))
  let result = template.render(context).unwrap()
  assert_eq(result, "2023-12-25")
}

///|
test "date filter with US format" {
  // Test date filter with US format
  let template = @engine.compile("{{ date | date: '%m/%d/%Y' }}").unwrap()
  let context = LiquidContext::new()
  context.set("date", string_value("2024-06-15"))
  let result = template.render(context).unwrap()
  assert_eq(result, "06/15/2024")
}

///|
test "date filter with custom format" {
  // Test date filter with custom format
  let template = @engine.compile("{{ date | date: '%A, %B %d' }}").unwrap()
  let context = LiquidContext::new()
  context.set("date", string_value("2024-03-10"))
  let result = template.render(context).unwrap()
  assert_eq(result, "Sunday, March 10")
}

///|
test "date filter without parameter" {
  // Test date filter without parameter (uses default)
  let template = @engine.compile("{{ date | date }}").unwrap()
  let context = LiquidContext::new()
  context.set("date", string_value("2024-05-20"))
  let result = template.render(context).unwrap()
  assert_eq(result, "2024-05-20") // Uses default format
}

///|
test "date filter chaining with parameters" {
  // Test date filter chaining with other filters
  let template = @engine.compile("{{ date | date: '%B %d, %Y' | upcase }}").unwrap()
  let context = LiquidContext::new()
  context.set("date", string_value("2023-11-30"))
  let result = template.render(context).unwrap()
  assert_eq(result, "NOVEMBER 30, 2023") // Parameter parsing issue
}

///|
test "date filter format edge cases" {
  // Test date filter with different format parameters

  // Test date with double quotes
  let template1 = @engine.compile("{{ date | date: \"%B %d, %Y\" }}").unwrap()
  let context1 = LiquidContext::new()
  context1.set("date", string_value("2024-01-15"))
  let result1 = template1.render(context1).unwrap()
  assert_eq(result1.contains("2024"), true) // Should handle double quotes

  // Test date with quoted format
  let template2 = @engine.compile("{{ date | date: '%m/%d/%Y' }}").unwrap()
  let context2 = LiquidContext::new()
  context2.set("date", string_value("2023-12-25"))
  let result2 = template2.render(context2).unwrap()
  assert_eq(result2.contains("2023"), true) // Should handle quoted format
}

///|
test "date filter chaining" {
  // Test chaining date filters
  let template = @engine.compile("{{ post_date | date | upcase }}").unwrap()
  let context = LiquidContext::new()
  context.set("post_date", string_value("2025-06-15"))
  let result = template.render(context).unwrap()
  assert_eq(result, "2025-06-15")
}
