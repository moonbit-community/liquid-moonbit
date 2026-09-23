///|
test "loop modifiers accept arbitrary integers and colon spacing" {
  let context = LiquidContext::new()
  context.set(
    "items",
    array_value(["a", "b", "c", "d", "e", "f", "g", "h"].map(string_value)),
  )
  for args in ["limit:6", "limit: 6", "limit : 6", "limit:\t6"] {
    assert_eq(
      parse("{% for x in items " + args + " %}{{ x }}{% endfor %}").render(
        context,
      ),
      "abcdef",
    )
  }
  assert_eq(
    parse("{% for x in items offset:6 limit:2 reversed %}{{ x }}{% endfor %}").render(
      context,
    ),
    "hg",
  )
  for args in ["limit:0", "offset:99", "limit:-1"] {
    assert_eq(
      parse("{% for x in items " + args + " %}{{ x }}{% endfor %}").render(
        context,
      ),
      "",
    )
  }
  assert_eq(
    parse("{% for x in items offset:-1 limit:2 %}{{ x }}{% endfor %}").render(
      context,
    ),
    "ab",
  )
}
