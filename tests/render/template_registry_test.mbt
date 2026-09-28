///|
test "include renders registered templates in shared context" {
  let context = LiquidContext::new()
  context.set("name", string_value("Alice"))
  context.register_template(
    "custom", "Hello {{ name | upcase }}{% assign seen = 'yes' %}{% include 'tail' %}",
  )
  context.register_template("tail", "!")
  assert_eq(
    @liquid.compile("{% include 'custom' %}{{ seen }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "Hello ALICE!yes",
  )
  context.register_template("custom", "Replacement")
  assert_eq(
    @liquid.compile("{% include 'custom' %}").unwrap().render(context).unwrap(),
    "Replacement",
  )
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
    @liquid.compile(
      "{% render 'card' %}|{% render 'card', name: name %}|{{ name }}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "Guest:hidden|Alice:hidden|Alice",
  )
  context.register_template("nested", "{% render 'card' %}")
  assert_eq(
    @liquid.compile("{% render 'nested' %}").unwrap().render(context).unwrap(),
    "Guest:hidden",
  )
}

///|
test "missing and recursive templates return diagnostics" {
  let context = LiquidContext::new()
  assert_true(
    @liquid.compile("{% include 'header' %}").unwrap().render(context) is Err(_),
  )
  for tag in ["render", "include"] {
    context.register_template("loop", "{% " + tag + " 'loop' %}")
    match @liquid.compile("{% " + tag + " 'loop' %}").unwrap().render(context) {
      Err(errors) =>
        assert_eq(errors[0].message, "Template nesting limit exceeded")
      Ok(_) => fail("Expected a recursion diagnostic")
    }
  }
}

///|
test "include propagates loop control while render isolates it" {
  let context = LiquidContext::new()
  context.set("items", array_value([string_value("a"), string_value("b")]))
  context.register_template("stop", "{% break %}X")
  assert_eq(
    @liquid.compile(
      "{% for item in items %}{{ item }}{% include 'stop' %}Y{% endfor %}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "a",
  )
  assert_eq(
    @liquid.compile(
      "{% for item in items %}{{ item }}{% render 'stop' %}Y{% endfor %}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "aXYbXY",
  )
}

///|
test "include tag parsing" {
  let context = LiquidContext::new()
  context.register_template("header.liquid", "<header>Custom</header>")
  assert_eq(
    @liquid.compile("{% include 'header.liquid' %}")
    .unwrap()
    .render(context)
    .unwrap(),
    "<header>Custom</header>",
  )
}

///|
test "template inclusion in context" {
  let context = LiquidContext::new()
  context.register_template("header", "H")
  context.register_template("footer", "F")
  assert_eq(
    @liquid.compile(
      "Header: {% include 'header' %} | Footer: {% render 'footer' %}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "Header: H | Footer: F",
  )
}

///|
test "multiple includes" {
  let context = LiquidContext::new()
  context.register_template("nav", "N")
  context.register_template("content", "C")
  context.register_template("footer", "F")
  assert_eq(
    @liquid.compile(
      "{% include 'nav' %}{% include 'content' %}{% include 'footer' %}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "NCF",
  )
}

///|
test "include tag with realistic content" {
  let context = LiquidContext::new()
  context.set("title", string_value("Site"))
  context.register_template("header", "<header>{{ title }}</header>")
  assert_eq(
    @liquid.compile("{% include 'header' %}").unwrap().render(context).unwrap(),
    "<header>Site</header>",
  )
}

///|
test "render tag with component content" {
  let context = LiquidContext::new()
  context.register_template("product-card", "<article>{{ title }}</article>")
  assert_eq(
    @liquid.compile("{% render 'product-card', title: 'Product' %}")
    .unwrap()
    .render(context)
    .unwrap(),
    "<article>Product</article>",
  )
}

///|
test "include multiple known templates" {
  let context = LiquidContext::new()
  context.register_template("nav", "<nav>Links</nav>")
  context.register_template("sidebar", "<aside>Sidebar</aside>")
  assert_eq(
    @liquid.compile("{% include 'nav' %}{% include 'sidebar' %}")
    .unwrap()
    .render(context)
    .unwrap(),
    "<nav>Links</nav><aside>Sidebar</aside>",
  )
}

///|
test "include unknown template" {
  let context = LiquidContext::new()
  assert_true(
    @liquid.compile("{% include 'unknown-template' %}").unwrap().render(context)
    is Err(_),
  )
}

///|
test "render with isolated context" {
  let context = LiquidContext::new()
  context.set("global_var", string_value("private"))
  context.register_template(
    "component", "{{ global_var | default: 'isolated' }}",
  )
  assert_eq(
    @liquid.compile("{% render 'component' %}")
    .unwrap()
    .render(context)
    .unwrap(),
    "isolated",
  )
}

///|
test "template composition example" {
  let context = LiquidContext::new()
  context.register_template("header", "<header>Title</header>")
  context.register_template("footer", "<footer>End</footer>")
  assert_eq(
    @liquid.compile(
      "{% include 'header' %}<main>Content</main>{% include 'footer' %}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "<header>Title</header><main>Content</main><footer>End</footer>",
  )
}
