///|
test "blocks consume their bodies and respect nesting" {
  let context = LiquidContext::new()
  context.set("show", bool_value(false))
  context.set("other", bool_value(true))
  context.set("items", array_value([string_value("a"), string_value("b")]))
  assert_eq(
    @engine.compile("{% if show %}SECRET{% else %}PUBLIC{% endif %}")
    .unwrap()
    .render(context)
    .unwrap(),
    "PUBLIC",
  )
  assert_eq(
    @engine.compile("{% if show %}A{% elsif other %}B{% else %}C{% endif %}")
    .unwrap()
    .render(context)
    .unwrap(),
    "B",
  )
  assert_eq(
    @engine.compile(
      "{% for item in items %}[{% if show %}X{% else %}{{ item }}{% endif %}]{% endfor %}!",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "[a][b]!",
  )
  assert_eq(
    @engine.compile(
      "{% capture x %}{% for item in items %}{{ item }}{% endfor %}{% endcapture %}[{{ x }}]",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "[ab]",
  )
  assert_eq(
    @engine.compile("{% unless show %}yes{% else %}no{% endunless %}")
    .unwrap()
    .render(context)
    .unwrap(),
    "yes",
  )
  context.set("role", string_value("editor"))
  assert_eq(
    @engine.compile(
      "{% case role %}{% when 'admin' %}A{% when 'editor' %}E{% else %}G{% endcase %}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "E",
  )
}

///|
test "raw and comment bodies are not interpreted" {
  let context = LiquidContext::new()
  context.set("name", string_value("Alice"))
  assert_eq(
    @engine.compile(
      "A{% comment %}SECRET {{ name }} {% assign x = 'bad' %}{% endcomment %}B",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "AB",
  )
  assert_true(context.get("x") is None)
  assert_eq(
    @engine.compile("{% raw %}{{ name }} {% if broken %} {{ '{% endraw %}!")
    .unwrap()
    .render(context)
    .unwrap(),
    "{{ name }} {% if broken %} {{ '!",
  )
  assert_eq(
    @engine.compile("A{%- raw -%}  {{ name }}  {%- endraw -%} B")
    .unwrap()
    .render(context)
    .unwrap(),
    "A{{ name }}B",
  )
  assert_eq(
    @engine.compile(
      "{% capture x %}{% raw %}{{ name }}{% endraw %}{% endcapture %}{{ x }}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "{{ name }}",
  )
}
