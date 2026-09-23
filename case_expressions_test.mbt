///|
test "case evaluates typed expressions on both sides" {
  let context = LiquidContext::new()
  context.set("n", number_value(6))
  context.set("role", string_value("admin"))
  context.set("expected", string_value("admin"))
  assert_eq(
    parse("{% case 'admin' %}{% when 'admin' %}yes{% else %}no{% endcase %}").render(
      context,
    ),
    "yes",
  )
  assert_eq(
    parse("{% case n %}{% when '6' %}string{% when 6 %}number{% endcase %}").render(
      context,
    ),
    "number",
  )
  assert_eq(
    parse("{% case role %}{% when expected %}yes{% endcase %}").render(context),
    "yes",
  )
  assert_eq(
    parse(
      "{% case false %}{% when 'false' %}bad{% when true, false %}bool{% endcase %}",
    ).render(context),
    "bool",
  )
  assert_eq(
    parse("{% case nil %}{% when nil %}null{% endcase %}").render(context),
    "null",
  )
  assert_eq(
    parse(
      "{% case 'x,y or z' %}{% when 'other' or 'x,y or z' %}quoted{% endcase %}",
    ).render(context),
    "quoted",
  )
}
