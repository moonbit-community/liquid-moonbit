///|
test "quoted delimiters in output and echo filters" {
  let context = LiquidContext::new()
  context.set("items", array_value([string_value("a"), string_value("b")]))
  for separator in [", ", " | ", ":", "😀,|:"] {
    for quote in ["'", "\""] {
      let expression = "items | join: " + quote + separator + quote
      assert_eq(
        @liquid.compile("{{ " + expression + " }}")
        .unwrap()
        .render(context)
        .unwrap(),
        "a" + separator + "b",
      )
      assert_eq(
        @liquid.compile("{% echo " + expression + " %}")
        .unwrap()
        .render(context)
        .unwrap(),
        "a" + separator + "b",
      )
    }
  }
}

///|
test "quoted tag closers and assignment equals are literal content" {
  let context = LiquidContext::new()
  assert_eq(
    @liquid.compile("{% assign x = 'a=b%}c' %}{{ x }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "a=b%}c",
  )
  context.set("items", array_value([string_value("a"), string_value("b")]))
  assert_eq(
    @liquid.compile("{{ items | join: '}}' }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "a}}b",
  )
  context.set("text", string_value("a,b:c|d"))
  assert_eq(
    @liquid.compile("{{ text | replace: 'a,b:c|d', 'ok' | upcase }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "OK",
  )
}
