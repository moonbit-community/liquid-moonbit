///|
test "case evaluates typed expressions on both sides" {
  let context = LiquidContext::new()
  context.set("n", number_value(6))
  context.set("role", string_value("admin"))
  context.set("expected", string_value("admin"))
  assert_eq(
    @liquid.compile(
      "{% case 'admin' %}{% when 'admin' %}yes{% else %}no{% endcase %}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "yes",
  )
  assert_eq(
    @liquid.compile(
      "{% case n %}{% when '6' %}string{% when 6 %}number{% endcase %}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "number",
  )
  assert_eq(
    @liquid.compile("{% case role %}{% when expected %}yes{% endcase %}")
    .unwrap()
    .render(context)
    .unwrap(),
    "yes",
  )
  assert_eq(
    @liquid.compile(
      "{% case false %}{% when 'false' %}bad{% when true, false %}bool{% endcase %}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "bool",
  )
  assert_eq(
    @liquid.compile("{% case nil %}{% when nil %}null{% endcase %}")
    .unwrap()
    .render(context)
    .unwrap(),
    "null",
  )
  assert_eq(
    @liquid.compile(
      "{% case 'x,y or z' %}{% when 'other' or 'x,y or z' %}quoted{% endcase %}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "quoted",
  )
}
