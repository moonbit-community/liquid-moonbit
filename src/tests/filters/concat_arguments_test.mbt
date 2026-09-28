///|
test "concat resolves typed arrays without mutating either input" {
  let context = LiquidContext::new()
  context.set("left", array_value([string_value("a"), number_value(2)]))
  context.set("right", array_value([bool_value(false), string_value("b")]))
  context.set("empty", array_value([]))
  assert_eq(
    @liquid.compile("{{ left | concat: right | join: ',' }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "a,2,false,b",
  )
  assert_eq(
    @liquid.compile("{{ left | concat: empty | concat: right | join: ',' }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "a,2,false,b",
  )
  assert_eq(
    @liquid.compile("{{ left | concat: left | join: ',' }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "a,2,a,2",
  )
  assert_eq(
    @liquid.compile("{{ left | join: ',' }}|{{ right | join: ',' }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "a,2|false,b",
  )
}

///|
test "concat preserves object values and reports invalid operands" {
  let context = LiquidContext::new()
  context.set("left", array_value([]))
  context.set(
    "right",
    array_value([object_value(Map([("name", string_value("Ada"))]))]),
  )
  assert_eq(
    @liquid.compile("{{ left | concat: right | map: 'name' | join: ',' }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "Ada",
  )
  assert_true(
    @liquid.compile("{{ left | concat: 'invalid' }}").unwrap().render(context)
    is Err(_),
  )
}
