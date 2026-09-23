///|
test "concat resolves typed arrays without mutating either input" {
  let context = LiquidContext::new()
  context.set("left", array_value([string_value("a"), number_value(2)]))
  context.set("right", array_value([bool_value(false), string_value("b")]))
  context.set("empty", array_value([]))
  assert_eq(
    parse("{{ left | concat: right | join: ',' }}").render(context),
    "a,2,false,b",
  )
  assert_eq(
    parse("{{ left | concat: empty | concat: right | join: ',' }}").render(
      context,
    ),
    "a,2,false,b",
  )
  assert_eq(
    parse("{{ left | concat: left | join: ',' }}").render(context),
    "a,2,a,2",
  )
  assert_eq(
    parse("{{ left | join: ',' }}|{{ right | join: ',' }}").render(context),
    "a,2|false,b",
  )
}

///|
test "concat preserves object values and reports invalid operands" {
  let context = LiquidContext::with_error_policy(strict_policy())
  context.set("left", array_value([]))
  context.set(
    "right",
    array_value([object_value(Map([("name", string_value("Ada"))]))]),
  )
  assert_eq(
    parse("{{ left | concat: right | map: 'name' | join: ',' }}").render(
      context,
    ),
    "Ada",
  )
  assert_true(
    parse("{{ left | concat: 'invalid' }}").render(context).contains("concat"),
  )
}
