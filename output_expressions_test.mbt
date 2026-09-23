///|
test "output and echo evaluate literals and filters" {
  let context = LiquidContext::new()
  assert_eq(
    @liquid.compile("{{ 'hello' | upcase }}{% echo 42 %}{{ true }}{{ nil }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "HELLO42true",
  )
  assert_eq(
    @liquid.compile("{% assign x = 'hello' | upcase %}{{ x }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "HELLO",
  )
}

///|
test "default receives missing values and resolves arguments" {
  let context = LiquidContext::new()
  context.set("fallback", string_value("Guest"))
  context.set("blank", string_value(""))
  context.set("empty_items", array_value([]))
  for input in ["missing", "nil", "false", "blank", "empty_items"] {
    assert_eq(
      @liquid.compile("{{ " + input + " | default: fallback | upcase }}")
      .unwrap()
      .render(context)
      .unwrap(),
      "GUEST",
    )
    assert_eq(
      @liquid.compile("{% echo " + input + " | default: 'Guest' %}")
      .unwrap()
      .render(context)
      .unwrap(),
      "Guest",
    )
  }
  assert_eq(
    @liquid.compile("{{ false | default: 'Guest', allow_false: true }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "false",
  )
  assert_eq(
    @liquid.compile("{{ 0 | default: 'Guest' }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "0",
  )
  context.set("separator", string_value(" / "))
  context.set("items", array_value([string_value("a"), string_value("b")]))
  assert_eq(
    @liquid.compile("{{ items | join: separator }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "a / b",
  )
  assert_true(
    @liquid.compile("{{ missing }}").unwrap().render(context) is Err(_),
  )
}

///|
test "string filter arguments use either quote style and context values" {
  let context = LiquidContext::new()
  context.set("text", string_value("a,b:c|d"))
  context.set("old", string_value("a,b:c|d"))
  context.set("replacement", string_value("it's \"done\""))
  assert_eq(
    @liquid.compile("{{ text | replace: old, replacement }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "it's \"done\"",
  )
  assert_eq(
    @liquid.compile("{{ text | replace: \"a,b:c|d\", \"ok\" }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "ok",
  )
}
