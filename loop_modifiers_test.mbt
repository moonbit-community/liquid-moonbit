///|
test "loop modifiers accept arbitrary integers and colon spacing" {
  let context = LiquidContext::new()
  context.set(
    "items",
    array_value(["a", "b", "c", "d", "e", "f", "g", "h"].map(string_value)),
  )
  for args in ["limit:6", "limit: 6", "limit : 6", "limit:\t6"] {
    assert_eq(
      @liquid.compile("{% for x in items " + args + " %}{{ x }}{% endfor %}")
      .unwrap()
      .render(context)
      .unwrap(),
      "abcdef",
    )
  }
  assert_eq(
    @liquid.compile(
      "{% for x in items offset:6 limit:2 reversed %}{{ x }}{% endfor %}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "hg",
  )
  for args in ["limit:0", "offset:99", "limit:-1"] {
    assert_eq(
      @liquid.compile("{% for x in items " + args + " %}{{ x }}{% endfor %}")
      .unwrap()
      .render(context)
      .unwrap(),
      "",
    )
  }
  assert_eq(
    @liquid.compile("{% for x in items offset:-1 limit:2 %}{{ x }}{% endfor %}")
    .unwrap()
    .render(context)
    .unwrap(),
    "ab",
  )
}
