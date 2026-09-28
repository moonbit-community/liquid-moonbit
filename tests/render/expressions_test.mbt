///|
test "numeric literals are parsed rather than enumerated" {
  let context = LiquidContext::new()
  for literal in ["6", "7", "42", "-6", "3.125", "123456"] {
    assert_eq(
      string_value(
        @liquid.compile("{{ " + literal + " }}")
        .unwrap()
        .render(context)
        .unwrap(),
      ).to_string(),
      literal,
    )
    assert_eq(
      @liquid.compile("{% assign x = " + literal + " %}{{ x }}")
      .unwrap()
      .render(context)
      .unwrap(),
      literal,
    )
  }
  assert_false(
    @liquid.compile("{% if " + "6 == 7" + " %}true{% else %}false{% endif %}")
    .unwrap()
    .render(context)
    .unwrap() ==
    "true",
  )
  assert_true(
    @liquid.compile(
      "{% if " + "-6 < 3.125" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true",
  )
  assert_false(
    @liquid.compile("{% if " + "6 == '6'" + " %}true{% else %}false{% endif %}")
    .unwrap()
    .render(context)
    .unwrap() ==
    "true",
  )
  assert_false(
    @liquid.compile(
      "{% if " + "nil == 'null'" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true",
  )
}

///|
test "conditions evaluate literals and right associative boolean chains" {
  let context = LiquidContext::new()
  assert_true(
    @liquid.compile("{% if " + "true" + " %}true{% else %}false{% endif %}")
    .unwrap()
    .render(context)
    .unwrap() ==
    "true",
  )
  assert_false(
    @liquid.compile("{% if " + "false" + " %}true{% else %}false{% endif %}")
    .unwrap()
    .render(context)
    .unwrap() ==
    "true",
  )
  assert_false(
    @liquid.compile("{% if " + "nil" + " %}true{% else %}false{% endif %}")
    .unwrap()
    .render(context)
    .unwrap() ==
    "true",
  )
  assert_true(
    @liquid.compile("{% if " + "0" + " %}true{% else %}false{% endif %}")
    .unwrap()
    .render(context)
    .unwrap() ==
    "true",
  )
  assert_true(
    @liquid.compile("{% if " + "''" + " %}true{% else %}false{% endif %}")
    .unwrap()
    .render(context)
    .unwrap() ==
    "true",
  )
  context.set("empty_array", array_value([]))
  assert_true(
    @liquid.compile(
      "{% if " + "empty_array" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true",
  )
  assert_true(
    @liquid.compile(
      "{% if " + "true and true and true" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true",
  )
  assert_true(
    @liquid.compile(
      "{% if " + "true or false and false" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true",
  )
  assert_false(
    @liquid.compile(
      "{% if " + "false and true or true" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true",
  )
  assert_true(
    @liquid.compile(
      "{% if " +
      "'a and b == c' == 'a and b == c'" +
      " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true",
  )
  assert_eq(
    @liquid.compile("{% if true %}yes{% else %}no{% endif %}")
    .unwrap()
    .render(context)
    .unwrap(),
    "yes",
  )
}
