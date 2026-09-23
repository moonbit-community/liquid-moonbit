///|
test "compiled templates reuse expressions with fresh contexts and registers" {
  let source = "{% assign d = 2.0 | times: 2 %}{% if person.active and count >= 2 %}{{ count | divided_by: d }}{% else %}no{% endif %}|{% increment x %}"
  let template = @liquid.compile(source).unwrap()
  for (count, expected) in [(2, "0.5|0"), (10, "2.5|0"), (1, "no|0")] {
    let context = LiquidContext::new()
    context.set("count", number_value(count.to_double()))
    context.set("person", object_value(Map([("active", bool_value(true))])))
    assert_eq(template.render(context).unwrap(), expected)
    assert_eq(template.render(context).unwrap(), expected)
  }
}

///|
test "compiled templates resolve typed default and array filter arguments" {
  let template = @liquid.compile(
    "{{ missing | default: fallback }}|{{ a | concat: b | join: delimiter }}",
  ).unwrap()
  let context = LiquidContext::new()
  context.set("fallback", string_value("'hello'"))
  context.set("delimiter", string_value("'"))
  context.set("a", array_value([string_value("x")]))
  context.set("b", array_value([string_value("y")]))
  assert_eq(template.render(context).unwrap(), "'hello'|x'y")
}

///|
test "checked parsing reports malformed blocks and exact opening offsets" {
  for
    (source, code) in [
      ("x{% unknown %}", "unknown_tag"),
      ("x{{ value", "unclosed_tag"),
      ("x{% raw %}unclosed", "unclosed_block"),
      ("x{{ }}", "empty_expression"),
      ("x{% if %}yes{% endif %}", "missing_argument"),
      ("x{% assign value %}", "invalid_tag"),
      ("x{% for x items %}{% endfor %}", "invalid_tag"),
    ] {
    match @liquid.compile(source) {
      Err(errors) => {
        assert_eq(errors[0].phase, "parse")
        assert_eq(errors[0].code, code)
        assert_eq(errors[0].offset, Some(1))
      }
      Ok(_) => fail("Expected parse diagnostics")
    }
  }
  assert_true(@liquid.compile("{% if true %}unclosed") is Err(_))
  assert_true(@liquid.compile("{% liquid\n unknown\n %}") is Err(_))
}

///|
test "checked rendering returns diagnostics rather than error text" {
  let context = LiquidContext::new()
  for
    source in [
      "{{ missing }}", "{{ 1 | unknown }}", "{{ 1 | concat: 2 }}", "{% include 'missing' %}",
    ] {
    let template = @liquid.compile(source).unwrap()
    match template.render(context) {
      Err(errors) => {
        assert_eq(errors[0].phase, "render")
        assert_false(errors[0].message.is_empty())
      }
      Ok(_) => fail("Expected render diagnostics")
    }
  }
  let literal = @liquid.compile("[ERROR: ordinary template text]").unwrap()
  assert_eq(literal.render(context).unwrap(), "[ERROR: ordinary template text]")
}

///|
test "partial diagnostics propagate and scoped arguments restore the caller" {
  let context = LiquidContext::new()
  context.set("name", string_value("caller"))
  context.register_template("bad", "{{ missing }}")
  let template = @liquid.compile("{% include 'bad', name: 'child' %}").unwrap()
  match template.render(context) {
    Err(errors) => assert_eq(errors[0].template, Some("bad"))
    Ok(_) => fail("Expected partial failure")
  }
  assert_eq(context.get("name").unwrap().to_string(), "caller")
  context.register_template("bad", "{% if true %}")
  assert_true(template.render(context) is Err(_))
  context.register_template("bad", "{{ name }}")
  assert_eq(template.render(context).unwrap(), "child")
}

///|
test "include arguments are evaluated before binding" {
  let context = LiquidContext::new()
  context.set("x", string_value("caller"))
  context.register_template("pair", "{{ x }}|{{ y }}")
  let template = @liquid.compile("{% include 'pair', x: 'child', y: x %}").unwrap()
  assert_eq(template.render(context).unwrap(), "child|caller")
}
