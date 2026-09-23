///|
test "cycle rotates independent implicit and named groups per render" {
  let context = LiquidContext::new()
  context.set(
    "items",
    array_value([number_value(1), number_value(2), number_value(3)]),
  )
  let template = parse(
    "{% for x in items %}{% cycle 'odd', 'even' %}/{% cycle 'x', 'y' %};{% endfor %}",
  )
  for _ in 0..<2 {
    assert_eq(template.render(context), "odd/x;even/y;odd/x;")
  }
  assert_eq(
    parse(
      "{% cycle one: 'a', 'b' %}{% cycle two: 'a', 'b' %}{% cycle one: 'a', 'b' %}{% cycle two: 'a', 'b' %}",
    ).render(context),
    "aabb",
  )
}

///|
test "ifchanged suppresses only consecutive repeated rendered output" {
  let context = LiquidContext::new()
  context.set("items", array_value(["a", "a", "b", "a"].map(string_value)))
  let template = parse(
    "{% for x in items %}{% ifchanged %}{{ x }}{% endifchanged %}{% endfor %}",
  )
  for _ in 0..<2 {
    assert_eq(template.render(context), "aba")
  }
}

///|
test "increment and decrement share registers separate from assign" {
  let context = LiquidContext::new()
  let template = parse(
    "{% assign x = 10 %}{% increment x %}|{% increment x %}|{% decrement x %}|{{ x }}|{% decrement y %}|{% increment y %}",
  )
  for _ in 0..<2 {
    assert_eq(template.render(context), "0|1|1|10|-1|-1")
  }
  assert_true(context.get("y") is None)
}

///|
test "include shares tag registers while render isolates them" {
  let context = LiquidContext::new()
  context.register_template("counter", "{% increment x %}{% cycle 'a', 'b' %}")
  assert_eq(
    parse(
      "{% increment x %}{% include 'counter' %}{% include 'counter' %}|{% render 'counter' %}{% render 'counter' %}|{% increment x %}",
    ).render(context),
    "01a2b|0a0a|3",
  )
}
