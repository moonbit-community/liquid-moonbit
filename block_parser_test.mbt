///|
test "blocks consume their bodies and respect nesting" {
  let context = LiquidContext::new()
  context.set("show", bool_value(false))
  context.set("other", bool_value(true))
  context.set("items", array_value([string_value("a"), string_value("b")]))
  assert_eq(
    parse("{% if show %}SECRET{% else %}PUBLIC{% endif %}").render(context),
    "PUBLIC",
  )
  assert_eq(
    parse("{% if show %}A{% elsif other %}B{% else %}C{% endif %}").render(
      context,
    ),
    "B",
  )
  assert_eq(
    parse(
      "{% for item in items %}[{% if show %}X{% else %}{{ item }}{% endif %}]{% endfor %}!",
    ).render(context),
    "[a][b]!",
  )
  assert_eq(
    parse(
      "{% capture x %}{% for item in items %}{{ item }}{% endfor %}{% endcapture %}[{{ x }}]",
    ).render(context),
    "[ab]",
  )
  assert_eq(
    parse("{% unless show %}yes{% else %}no{% endunless %}").render(context),
    "yes",
  )
  context.set("role", string_value("editor"))
  assert_eq(
    parse(
      "{% case role %}{% when 'admin' %}A{% when 'editor' %}E{% else %}G{% endcase %}",
    ).render(context),
    "E",
  )
}

///|
test "raw and comment bodies are not interpreted" {
  let context = LiquidContext::new()
  context.set("name", string_value("Alice"))
  assert_eq(
    parse(
      "A{% comment %}SECRET {{ name }} {% assign x = 'bad' %}{% endcomment %}B",
    ).render(context),
    "AB",
  )
  assert_true(context.get("x") is None)
  assert_eq(
    parse("{% raw %}{{ name }} {% if broken %} {{ '{% endraw %}!").render(
      context,
    ),
    "{{ name }} {% if broken %} {{ '!",
  )
  assert_eq(
    parse("A{%- raw -%}  {{ name }}  {%- endraw -%} B").render(context),
    "A{{ name }}B",
  )
  assert_eq(
    parse(
      "{% capture x %}{% raw %}{{ name }}{% endraw %}{% endcapture %}{{ x }}",
    ).render(context),
    "{{ name }}",
  )
}
