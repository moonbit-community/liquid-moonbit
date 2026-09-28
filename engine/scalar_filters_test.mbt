///|
test "money filters in template" {
  // Test money filters in template context
  let template = @engine.compile(
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
  let template = @engine.compile("{{ count | pluralize: 'item', 'items' }}").unwrap()
  let context = LiquidContext::new()
  context.set("count", string_value("not_a_number")) // Non-number input
  let result = template.render(context).unwrap()
  assert_eq(result, "not_a_number") // Should return original value
}

///|
test "pluralize filter parameter variations" {
  // Test different parameter count cases for pluralize
  let template1 = @engine.compile("{{ count | pluralize: 'item' }}").unwrap() // Only one parameter
  let context1 = LiquidContext::new()
  context1.set("count", number_value(1.0))
  let result1 = template1.render(context1).unwrap()
  assert_eq(result1, "1 item") // Should use basic pluralize logic

  // Test with different word counts
  let template2 = @engine.compile("{{ count | pluralize: 'cat', 'cats' }}").unwrap()
  let context2 = LiquidContext::new()
  context2.set("count", number_value(2.5))
  let result2 = template2.render(context2).unwrap()
  assert_eq(result2, "2.5 cats")
}

///|
test "money_without_trailing_zeros filter edge case" {
  // Test uncovered case for money_without_trailing_zeros
  let template = @engine.compile("{{ price | money_without_trailing_zeros }}").unwrap()
  let context = LiquidContext::new()
  context.set("price", number_value(10.0)) // Number ending in .0
  let result = template.render(context).unwrap()
  assert_eq(result, "$10") // Should remove .0
}
