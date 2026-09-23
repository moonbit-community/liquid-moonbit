///|
test "for else runs only for an empty effective collection" {
  let context = LiquidContext::new()
  context.set("items", array_value([string_value("a"), string_value("b")]))
  context.set("empty", array_value([]))
  for collection in ["empty", "missing", "items limit:0", "items offset:2"] {
    assert_eq(
      parse(
        "{% for x in " + collection + " %}{{ x }}{% else %}EMPTY{% endfor %}",
      ).render(context),
      "EMPTY",
    )
  }
  assert_eq(
    parse("{% for x in items %}{{ x }}{% else %}EMPTY{% endfor %}").render(
      context,
    ),
    "ab",
  )
  assert_eq(
    parse(
      "{% for x in items %}{% for y in empty %}bad{% else %}{{ x }}{% endfor %}{% else %}bad{% endfor %}",
    ).render(context),
    "ab",
  )
  assert_eq(
    parse("{% for x in items %}{% break %}{% else %}bad{% endfor %}").render(
      context,
    ),
    "",
  )
}
