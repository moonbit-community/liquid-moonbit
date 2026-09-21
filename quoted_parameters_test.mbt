///|
test "quoted delimiters in output and echo filters" {
  let context = LiquidContext::new()
  context.set("items", array_value([string_value("a"), string_value("b")]))
  for separator in [", ", " | ", ":", "😀,|:"] {
    for quote in ["'", "\""] {
      let expression = "items | join: " + quote + separator + quote
      assert_eq(
        parse("{{ " + expression + " }}").render(context),
        "a" + separator + "b",
      )
      assert_eq(
        parse("{% echo " + expression + " %}").render(context),
        "a" + separator + "b",
      )
    }
  }
}

///|
test "quoted tag closers and assignment equals are literal content" {
  let context = LiquidContext::new()
  assert_eq(parse("{% assign x = 'a=b%}c' %}{{ x }}").render(context), "a=b%}c")
  context.set("items", array_value([string_value("a"), string_value("b")]))
  assert_eq(parse("{{ items | join: '}}' }}").render(context), "a}}b")
  context.set("text", string_value("a,b:c|d"))
  assert_eq(
    parse("{{ text | replace: 'a,b:c|d', 'ok' | upcase }}").render(context),
    "OK",
  )
}
