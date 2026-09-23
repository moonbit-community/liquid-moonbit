///|
test "filter chain integration edge cases" {
  // Test complex filter chains that might reveal edge cases

  // Test chaining with type transformations
  let template1 = parse("{{ text | split | first | upcase }}")
  let context1 = LiquidContext::new()
  context1.set("text", string_value("hello world"))
  let result1 = template1.render(context1)
  assert_eq(result1, "HELLO")

  // Test chaining with array manipulations
  let template2 = parse("{{ numbers | sort | reverse | first }}")
  let context2 = LiquidContext::new()
  context2.set(
    "numbers",
    array_value([string_value("3"), string_value("1"), string_value("2")]),
  )
  let result2 = template2.render(context2)
  assert_eq(result2, "3")

  // Test chaining with null/empty handling
  let template3 = parse("{{ missing | default: 'fallback' | upcase }}")
  let context3 = LiquidContext::new()
  // Don't set 'missing' variable
  let result3 = template3.render(context3)
  assert_eq(result3, "FALLBACK")
}
