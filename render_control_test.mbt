///|
test "break and continue propagate through nested branches" {
  let context = LiquidContext::new()
  context.set(
    "items",
    array_value([string_value("a"), string_value("stop"), string_value("b")]),
  )
  assert_eq(
    parse(
      "{% for item in items %}{{ item }}{% if item == 'stop' %}{% break %}{% endif %}X{% endfor %}!",
    ).render(context),
    "aXstop!",
  )
  assert_eq(
    parse(
      "{% for item in items %}{% if item == 'stop' %}{% continue %}{% endif %}{{ item }}X{% endfor %}!",
    ).render(context),
    "aXbX!",
  )
  assert_eq(
    render_node(
      for_node("item", "items", [
        variable_node("item", []),
        break_node(),
        text_node("X"),
      ]),
      context,
    ),
    "a",
  )
}

///|
test "inner loops consume their control and restore outer scope" {
  let context = LiquidContext::new()
  context.set("items", array_value([string_value("a"), string_value("b")]))
  context.set("item", string_value("saved"))
  assert_eq(
    parse(
      "{% for item in items %}{{ forloop.index }}{% for item in items %}{{ item }}{% break %}{% endfor %}{{ item }}{{ forloop.index }}{% endfor %}:{{ item }}",
    ).render(context),
    "1aa12ab2:saved",
  )
  assert_true(context.get("forloop") is None)
}
