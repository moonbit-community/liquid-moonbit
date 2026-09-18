///|
test "numeric literals are parsed rather than enumerated" {
  let context = LiquidContext::new()
  for literal in ["6", "7", "42", "-6", "3.125", "123456"] {
    assert_eq(
      @liquid.evaluate_expression(literal, context).to_string(),
      literal,
    )
    assert_eq(
      parse("{% assign x = " + literal + " %}{{ x }}").render(context),
      literal,
    )
  }
  assert_false(evaluate_condition("6 == 7", context))
  assert_true(evaluate_condition("-6 < 3.125", context))
  assert_false(evaluate_condition("6 == '6'", context))
  assert_false(evaluate_condition("nil == 'null'", context))
}

///|
test "conditions evaluate literals and right associative boolean chains" {
  let context = LiquidContext::new()
  assert_true(evaluate_condition("true", context))
  assert_false(evaluate_condition("false", context))
  assert_false(evaluate_condition("nil", context))
  assert_true(evaluate_condition("0", context))
  assert_true(evaluate_condition("''", context))
  context.set("empty_array", array_value([]))
  assert_true(evaluate_condition("empty_array", context))
  assert_true(evaluate_condition("true and true and true", context))
  assert_true(evaluate_condition("true or false and false", context))
  assert_false(evaluate_condition("false and true or true", context))
  assert_true(evaluate_condition("'a and b == c' == 'a and b == c'", context))
  assert_eq(
    parse("{% if true %}yes{% else %}no{% endif %}").render(context),
    "yes",
  )
}
