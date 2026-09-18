///|
test "output and echo evaluate literals and filters" {
  let context = LiquidContext::new()
  assert_eq(
    parse("{{ 'hello' | upcase }}{% echo 42 %}{{ true }}{{ nil }}").render(
      context,
    ),
    "HELLO42true",
  )
  assert_eq(
    parse("{% assign x = 'hello' | upcase %}{{ x }}").render(context),
    "HELLO",
  )
}

///|
test "default receives missing values and resolves arguments" {
  let context = LiquidContext::with_error_policy(strict_policy())
  context.set("fallback", string_value("Guest"))
  context.set("blank", string_value(""))
  context.set("empty_items", array_value([]))
  for input in ["missing", "nil", "false", "blank", "empty_items"] {
    assert_eq(
      parse("{{ " + input + " | default: fallback | upcase }}").render(context),
      "GUEST",
    )
    assert_eq(
      parse("{% echo " + input + " | default: 'Guest' %}").render(context),
      "Guest",
    )
  }
  assert_eq(
    parse("{{ false | default: 'Guest', allow_false: true }}").render(context),
    "false",
  )
  assert_eq(parse("{{ 0 | default: 'Guest' }}").render(context), "0")
  context.set("separator", string_value(" / "))
  context.set("items", array_value([string_value("a"), string_value("b")]))
  assert_eq(parse("{{ items | join: separator }}").render(context), "a / b")
  assert_eq(
    parse("{{ missing }}").render(context),
    "[ERROR: Variable 'missing' not found]",
  )
}

///|
test "string filter arguments use either quote style and context values" {
  let context = LiquidContext::new()
  context.set("text", string_value("a,b:c|d"))
  context.set("old", string_value("a,b:c|d"))
  context.set("replacement", string_value("it's \"done\""))
  assert_eq(
    parse("{{ text | replace: old, replacement }}").render(context),
    "it's \"done\"",
  )
  assert_eq(
    parse("{{ text | replace: \"a,b:c|d\", \"ok\" }}").render(context),
    "ok",
  )
}
