///|
test "include renders registered templates in shared context" {
  let context = LiquidContext::new()
  context.set("name", string_value("Alice"))
  context.register_template(
    "custom", "Hello {{ name | upcase }}{% assign seen = 'yes' %}{% include 'tail' %}",
  )
  context.register_template("tail", "!")
  assert_eq(
    parse("{% include 'custom' %}{{ seen }}").render(context),
    "Hello ALICE!yes",
  )
  context.register_template("custom", "Replacement")
  assert_eq(parse("{% include 'custom' %}").render(context), "Replacement")
}

///|
test "render isolates variables and accepts explicit arguments" {
  let context = LiquidContext::new()
  context.set("name", string_value("Alice"))
  context.set("secret", string_value("private"))
  context.register_template(
    "card", "{{ name | default: 'Guest' }}:{{ secret | default: 'hidden' }}{% assign name = 'changed' %}",
  )
  assert_eq(
    parse("{% render 'card' %}|{% render 'card', name: name %}|{{ name }}").render(
      context,
    ),
    "Guest:hidden|Alice:hidden|Alice",
  )
  context.register_template("nested", "{% render 'card' %}")
  assert_eq(parse("{% render 'nested' %}").render(context), "Guest:hidden")
}

///|
test "missing and recursive templates follow error policy" {
  let context = LiquidContext::with_error_policy(strict_policy())
  assert_eq(
    parse("{% include 'header' %}").render(context),
    "[ERROR: Template 'header' not found]",
  )
  context.register_template("loop", "{% render 'loop' %}")
  assert_eq(
    parse("{% render 'loop' %}").render(context),
    "[ERROR: Template nesting limit exceeded]",
  )
  context.register_template("loop", "{% include 'loop' %}")
  assert_eq(
    parse("{% include 'loop' %}").render(context),
    "[ERROR: Template nesting limit exceeded]",
  )
  let silent = LiquidContext::with_error_policy(silent_policy())
  assert_eq(parse("{% render 'missing' %}").render(silent), "")
}

///|
test "include propagates loop control while render isolates it" {
  let context = LiquidContext::new()
  context.set("items", array_value([string_value("a"), string_value("b")]))
  context.register_template("stop", "{% break %}X")
  assert_eq(
    parse("{% for item in items %}{{ item }}{% include 'stop' %}Y{% endfor %}").render(
      context,
    ),
    "a",
  )
  assert_eq(
    parse("{% for item in items %}{{ item }}{% render 'stop' %}Y{% endfor %}").render(
      context,
    ),
    "aXYbXY",
  )
}
