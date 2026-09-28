///|
test "floating divisors survive assignment and property lookup" {
  let context = LiquidContext::new()
  assert_eq(
    @liquid.compile(
      "{{ 10 | divided_by: 4.0 }}|{% assign d = 4.0 %}{{ 10 | divided_by: d }}|{% assign e = d %}{{ 10 | divided_by: e }}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "2.5|2.5|2.5",
  )
  context.set(
    "settings",
    object_value(Map([("divisor", @liquid.float_value(4))])),
  )
  assert_eq(
    @liquid.compile(
      "{{ 10 | divided_by: settings.divisor }}|{{ 10 | divided_by: 4 }}|{{ 10.0 | divided_by: 4 }}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "2.5|2|2.5",
  )
}

///|
test "numeric filters preserve floating results through filter chains" {
  let context = LiquidContext::new()
  for
    expression in [
      "2.0 | times: 2", "5.0 | minus: 1", "3 | plus: 1.0", "-4.0 | abs", "8.0 | divided_by: 2",
      "12.0 | modulo: 8",
    ] {
    assert_eq(
      @liquid.compile(
        "{% assign d = " + expression + " %}{{ 10 | divided_by: d }}",
      )
      .unwrap()
      .render(context)
      .unwrap(),
      "2.5",
    )
  }
  assert_eq(
    @liquid.compile(
      "{% assign d = 4.9 | floor %}{{ 10 | divided_by: d }}|{% assign d = 3.1 | ceil %}{{ 10 | divided_by: d }}|{% assign d = 4.1 | round %}{{ 10 | divided_by: d }}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "2|2|2",
  )
  assert_true(
    @liquid.compile("{% if " + "4 == 4.0" + " %}true{% else %}false{% endif %}")
    .unwrap()
    .render(context)
    .unwrap() ==
    "true",
  )
  assert_true(
    @liquid.compile("{% if " + "3 < 4.0" + " %}true{% else %}false{% endif %}")
    .unwrap()
    .render(context)
    .unwrap() ==
    "true",
  )
  assert_false(
    @liquid.compile(
      "{% if " + "4.0 == '4'" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true",
  )
}

///|
test "explicit float values preserve host supplied integral floats" {
  let context = LiquidContext::new()
  context.set("d", @liquid.float_value(4))
  assert_eq(
    @liquid.compile(
      "{{ 10 | divided_by: d }}|{% case d %}{% when 4 %}equal{% endcase %}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "2.5|equal",
  )
  assert_eq(
    apply_filter(@liquid.float_value(10), "divided_by", [number_value(4)])
    .unwrap()
    .to_string(),
    "2.5",
  )
  assert_eq(
    @liquid.compile("{{ -10 | divided_by: 4 }}|{{ -10 | divided_by: 4.0 }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "-3|-2.5",
  )
  assert_eq(
    @liquid.compile("{{ 10 | divided_by: 0.0 }}|{{ 10.0 | modulo: 0 }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "|",
  )
}
