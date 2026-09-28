///|
test "break and continue propagate through nested branches" {
  let context = LiquidContext::new()
  context.set(
    "items",
    array_value([string_value("a"), string_value("stop"), string_value("b")]),
  )
  assert_eq(
    @liquid.compile(
      "{% for item in items %}{{ item }}{% if item == 'stop' %}{% break %}{% endif %}X{% endfor %}!",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "aXstop!",
  )
  assert_eq(
    @liquid.compile(
      "{% for item in items %}{% if item == 'stop' %}{% continue %}{% endif %}{{ item }}X{% endfor %}!",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "aXbX!",
  )
  assert_eq(
    @liquid.compile("{% for item in items %}{{ item }}{% break %}X{% endfor %}")
    .unwrap()
    .render(context)
    .unwrap(),
    "a",
  )
}

///|
test "inner loops consume their control and restore outer scope" {
  let context = LiquidContext::new()
  context.set("items", array_value([string_value("a"), string_value("b")]))
  context.set("item", string_value("saved"))
  assert_eq(
    @liquid.compile(
      "{% for item in items %}{{ forloop.index }}{% for item in items %}{{ item }}{% break %}{% endfor %}{{ item }}{{ forloop.index }}{% endfor %}:{{ item }}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "1aa12ab2:saved",
  )
  assert_true(context.get("forloop") is None)
}
