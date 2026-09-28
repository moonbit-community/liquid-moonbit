///|
test "replace filter with parameters" {
  // Test replace filter with old and new parameters
  let template = @engine.compile("{{ text | replace: 'old', 'new' }}").unwrap()
  let context = LiquidContext::new()
  context.set("text", string_value("This is old text"))
  let result = template.render(context).unwrap()
  assert_eq(result, "This is new text")
}

///|
test "remove filter with parameter" {
  // Test remove filter with target parameter
  let template = @engine.compile("{{ text | remove: 'bad' }}").unwrap()
  let context = LiquidContext::new()
  context.set("text", string_value("This is bad text"))
  let result = template.render(context).unwrap()
  assert_eq(result, "This is  text")
}

///|
test "split filter with delimiter parameter" {
  // Test split filter with custom delimiter
  let template = @engine.compile("{{ text | split: '-' }}").unwrap()
  let context = LiquidContext::new()
  context.set("text", string_value("apple-banana-cherry"))
  let result = template.render(context).unwrap()
  assert_eq(result, "[apple, banana, cherry]")
}

///|
test "strip_tags filter non-string input" {
  // Test uncovered case where input is not a string for strip_tags
  let template = @engine.compile("{{ number | strip_tags }}").unwrap()
  let context = LiquidContext::new()
  context.set("number", number_value(42.0))
  let result = template.render(context).unwrap()
  assert_eq(result, "42") // Should return original value
}

///|
test "normalize_whitespace filter non-string input" {
  // Test uncovered case where input is not a string for normalize_whitespace
  let template = @engine.compile("{{ number | normalize_whitespace }}").unwrap()
  let context = LiquidContext::new()
  context.set("number", number_value(42.0))
  let result = template.render(context).unwrap()
  assert_eq(result, "42") // Should return original value
}
