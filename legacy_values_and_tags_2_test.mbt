///|
test "whitespace control struct creation" {
  // Test WhitespaceControl struct constructor functions
  let ws_both = whitespace_control(true, true)
  json_inspect(ws_both, content={ "strip_left": true, "strip_right": true })

  let ws_left = whitespace_control(true, false)
  json_inspect(ws_left, content={ "strip_left": true, "strip_right": false })

  let ws_right = whitespace_control(false, true)
  json_inspect(ws_right, content={ "strip_left": false, "strip_right": true })

  let ws_none = no_whitespace_control()
  json_inspect(ws_none, content={ "strip_left": false, "strip_right": false })

  // Verify properties
  assert_eq(ws_both.strip_left, true)
  assert_eq(ws_both.strip_right, true)
  assert_eq(ws_left.strip_left, true)
  assert_eq(ws_left.strip_right, false)
  assert_eq(ws_right.strip_left, false)
  assert_eq(ws_right.strip_right, true)
  assert_eq(ws_none.strip_left, false)
  assert_eq(ws_none.strip_right, false)
}

///|
test "whitespace control practical usage" {
  // Test WhitespaceControl in practical scenarios

  // Test different whitespace control configurations
  let controls = [
    whitespace_control(true, true), // Strip both sides
    whitespace_control(true, false), // Strip left only
    whitespace_control(false, true), // Strip right only
    no_whitespace_control(), // No stripping
  ]

  for i in 0..<controls.length() {
    let control = controls[i]
    // Verify the control object is properly constructed
    match i {
      0 => {
        assert_eq(control.strip_left, true)
        assert_eq(control.strip_right, true)
      }
      1 => {
        assert_eq(control.strip_left, true)
        assert_eq(control.strip_right, false)
      }
      2 => {
        assert_eq(control.strip_left, false)
        assert_eq(control.strip_right, true)
      }
      3 => {
        assert_eq(control.strip_left, false)
        assert_eq(control.strip_right, false)
      }
      _ => fail("Unexpected index")
    }
  }
}

///|
test "whitespace control edge cases" {
  // Test WhitespaceControl with edge cases
  let ws_control = whitespace_control(true, true)

  // Test with empty content
  assert_eq(ws_control.strip_left, true)
  assert_eq(ws_control.strip_right, true)

  // Test multiple instances
  let controls = []
  for i in 0..<5 {
    controls.push(whitespace_control(i % 2 == 0, i % 3 == 0))
  }

  assert_eq(controls.length(), 5)
  assert_eq(controls[0].strip_left, true) // 0 % 2 == 0
  assert_eq(controls[0].strip_right, true) // 0 % 3 == 0
  assert_eq(controls[1].strip_left, false) // 1 % 2 == 1
  assert_eq(controls[1].strip_right, false) // 1 % 3 == 1
}

// Helper function tests to eliminate unused variant warnings

///|
test "node helper functions" {
  // Test helper functions for creating nodes (eliminates unused variant warnings)
  let context = LiquidContext::new()
  context.set("test_var", bool_value(false))

  // Test unless_node helper
  let unless_node_test = unless_node("test_var", [text_node("Content")])
  let unless_result = render_node(unless_node_test, context)
  assert_eq(unless_result, "Content") // Should render since test_var is false

  // Test case_node helper
  let case_node_test = case_node("test_var", [], Some([text_node("Default")]))
  let case_result = render_node(case_node_test, context)
  assert_eq(case_result, "Default") // Should use else body

  // Test if_node helper
  let if_node_test = if_node(
    "test_var",
    [text_node("True")],
    Some([text_node("False")]),
  )
  let if_result = render_node(if_node_test, context)
  assert_eq(if_result, "False") // Should render else body since test_var is false
}

// Filter Parameters Tests

///|
test "liquid node helper" {
  // Test liquid node helper function
  let context = LiquidContext::new()
  context.set("greeting", string_value("Hello"))
  let liquid_test = liquid_node([
    variable_node("greeting", []),
    text_node(" "),
    text_node("World!"),
  ])
  let result = render_node(liquid_test, context)
  assert_eq(result, "Hello World!")
}

///|
test "liquid tag with variables" {
  // Test liquid tag with variable content
  let context = LiquidContext::new()
  context.set("name", string_value("Alice"))
  let liquid_test = liquid_node([
    text_node("Welcome "),
    variable_node("name", [filter("upcase", [])]),
    text_node("!"),
  ])
  let result = render_node(liquid_test, context)
  assert_eq(result, "Welcome ALICE!")
}

///|
test "liquid tag complex" {
  // Test liquid tag with complex content
  let context = LiquidContext::new()
  let items = array_value([string_value("item1"), string_value("item2")])
  context.set("items", items)
  let liquid_test = liquid_node([
    text_node("Count: "),
    variable_node("items", [filter("size", [])]),
    text_node(" | First: "),
    variable_node("items", [filter("first", [])]),
  ])
  let result = render_node(liquid_test, context)
  assert_eq(result, "Count: 2 | First: item1")
}

// Section and Style Tag Tests

///|
test "section node helper" {
  // Test section node helper function
  let context = LiquidContext::new()
  let section_test = section_node("footer")
  let result = render_node(section_test, context)
  assert_eq(
    result, "<section data-section=\"footer\"><!-- Section: footer --></section>",
  )
}

///|
test "style node helper" {
  // Test style node helper function
  let context = LiquidContext::new()
  let style_test = style_node("body { margin: 0; }")
  let result = render_node(style_test, context)
  assert_eq(result, "<style>body { margin: 0; }</style>")
}

///|
test "section and style in template" {
  // Test section and style tags in template context
  let template = parse(
    "{% section 'main' %}{% style %}h1 { color: blue; }{% endstyle %}",
  )
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result.contains("<section"), true)
  assert_eq(result.contains("<style>"), true)
}

// Template Inclusion Tests

///|
test "include node helper" {
  let context = LiquidContext::new()
  context.register_template("sidebar.liquid", "Sidebar")
  assert_eq(render_node(include_node("sidebar.liquid"), context), "Sidebar")
}

///|
test "render node helper" {
  let context = LiquidContext::new()
  context.register_template("component.liquid", "Component")
  assert_eq(
    render_node(render_node_tag("component.liquid"), context),
    "Component",
  )
}

///|
test "template inclusion in context" {
  let context = LiquidContext::new()
  context.register_template("header", "H")
  context.register_template("footer", "F")
  assert_eq(
    parse("Header: {% include 'header' %} | Footer: {% render 'footer' %}").render(
      context,
    ),
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
    parse("{% include 'nav' %}{% include 'content' %}{% include 'footer' %}").render(
      context,
    ),
    "NCF",
  )
}

// Enhanced Filter Parameters Tests

///|
test "parameter with quotes and spaces" {
  // Test parameter parsing with quotes and spaces
  let template = parse("{{ items | join: ' -> ' }}")
  json_inspect(template, content={
    "nodes": [
      ["Variable", "items", [{ "name": "join", "parameters": ["' -> '"] }]],
    ],
  })
  let context = LiquidContext::new()
  let items = array_value([
    string_value("step1"),
    string_value("step2"),
    string_value("step3"),
  ])
  context.set("items", items)
  let result = template.render(context)
  assert_eq(result, "step1 -> step2 -> step3")
}

///|
test "include tag with realistic content" {
  let context = LiquidContext::new()
  context.set("title", string_value("Site"))
  context.register_template("header", "<header>{{ title }}</header>")
  assert_eq(
    parse("{% include 'header' %}").render(context),
    "<header>Site</header>",
  )
}

///|
test "render tag with component content" {
  let context = LiquidContext::new()
  context.register_template("product-card", "<article>{{ title }}</article>")
  assert_eq(
    parse("{% render 'product-card', title: 'Product' %}").render(context),
    "<article>Product</article>",
  )
}

///|
test "include multiple known templates" {
  let context = LiquidContext::new()
  context.register_template("nav", "<nav>Links</nav>")
  context.register_template("sidebar", "<aside>Sidebar</aside>")
  assert_eq(
    parse("{% include 'nav' %}{% include 'sidebar' %}").render(context),
    "<nav>Links</nav><aside>Sidebar</aside>",
  )
}

///|
test "include unknown template" {
  let context = LiquidContext::with_error_policy(strict_policy())
  assert_eq(
    parse("{% include 'unknown-template' %}").render(context),
    "[ERROR: Template 'unknown-template' not found]",
  )
}

///|
test "render with isolated context" {
  let context = LiquidContext::new()
  context.set("global_var", string_value("private"))
  context.register_template(
    "component", "{{ global_var | default: 'isolated' }}",
  )
  assert_eq(parse("{% render 'component' %}").render(context), "isolated")
}

///|
test "template composition example" {
  let context = LiquidContext::new()
  context.register_template("header", "<header>Title</header>")
  context.register_template("footer", "<footer>End</footer>")
  assert_eq(
    parse("{% include 'header' %}<main>Content</main>{% include 'footer' %}").render(
      context,
    ),
    "<header>Title</header><main>Content</main><footer>End</footer>",
  )
}

// Enhanced Filter Parameters Implementation Tests

///|
test "offset and limit combined" {
  // Test offset and limit filters combined
  let template = parse("{{ items | offset: 1 | limit: 2 }}")
  let context = LiquidContext::new()
  let items = array_value([
    string_value("first"),
    string_value("second"),
    string_value("third"),
    string_value("fourth"),
    string_value("fifth"),
  ])
  context.set("items", items)
  let result = template.render(context)
  assert_eq(result, "[second, third]") // Skip 1, then take 2
}

///|
test "pagination example with offset and limit" {
  // Test realistic pagination example
  let template = parse("Page 2: {{ articles | offset: 5 | limit: 5 | join }}")
  let context = LiquidContext::new()
  let articles = array_value([
    string_value("art1"),
    string_value("art2"),
    string_value("art3"),
    string_value("art4"),
    string_value("art5"),
    string_value("art6"),
    string_value("art7"),
    string_value("art8"),
    string_value("art9"),
    string_value("art10"),
  ])
  context.set("articles", articles)
  let result = template.render(context)
  assert_eq(result, "Page 2: art6, art7, art8, art9, art10")
}

///|
test "limit with small array" {
  // Test limit filter with array smaller than limit
  let template = parse("{{ items | limit: 10 }}")
  let context = LiquidContext::new()
  let items = array_value([string_value("only"), string_value("two")])
  context.set("items", items)
  let result = template.render(context)
  assert_eq(result, "[only, two]") // Should return all items when limit > array size
}

// Date Filter Parameters Tests

///|
test "empty string and array edge cases" {
  // Test edge cases with empty strings and arrays
  let empty_str = string_value("")
  let empty_arr = array_value([])

  // Test capitalize with empty string
  assert_eq(apply_filter(empty_str, "capitalize").to_string(), "")

  // Test first/last with empty arrays
  assert_eq(apply_filter(empty_arr, "first").to_string(), "null")
  assert_eq(apply_filter(empty_arr, "last").to_string(), "null")

  // Test first/last with empty strings
  assert_eq(apply_filter(empty_str, "first").to_string(), "null")
  assert_eq(apply_filter(empty_str, "last").to_string(), "null")

  // Test truncate with short string
  let short_str = string_value("short")
  assert_eq(apply_filter(short_str, "truncate").to_string(), "short")
}

///|
test "helper function coverage" {
  // Test helper functions to improve coverage
  let filters = ["upcase", "downcase"]
  let var_node = variable_node_simple("test", filters)
  let context = LiquidContext::new()
  context.set("test", string_value("hello"))
  let result = render_node(var_node, context)
  assert_eq(result, "hello") // Should apply filters
}

///|
test "capture tag basic functionality" {
  // Test capture tag basic functionality
  let context = LiquidContext::new()
  context.set("greeting", string_value("Hello"))
  let capture_test = capture_node("my_var", [
    text_node("Welcome "),
    variable_node("greeting", []),
    text_node(" World!"),
  ])
  let result = render_node(capture_test, context)
  assert_eq(result, "") // Capture produces no output

  // Check that variable was captured
  match context.get("my_var") {
    Some(value) => assert_eq(value.to_string(), "Welcome Hello World!")
    None => fail("Expected my_var to be captured")
  }
}

///|
test "capture and use captured variable" {
  // Test capturing content and then using it
  let context = LiquidContext::new()
  context.set("title", string_value("My Article"))

  // First capture some content
  let capture_test = capture_node("page_title", [
    text_node("Title: "),
    variable_node("title", [filter("upcase", [])]),
    text_node(" - Blog"),
  ])
  let _capture_result = render_node(capture_test, context)

  // Then use the captured variable
  let use_test = variable_node("page_title", [])
  let use_result = render_node(use_test, context)
  assert_eq(use_result, "Title: MY ARTICLE - Blog")
}

///|
test "multiple capture operations" {
  // Test multiple capture operations
  let context = LiquidContext::new()
  context.set("first", string_value("Hello"))
  context.set("second", string_value("World"))
  let capture1 = capture_node("var1", [
    variable_node("first", []),
    text_node(" there!"),
  ])
  let capture2 = capture_node("var2", [
    variable_node("second", []),
    text_node(" peace!"),
  ])
  let _result1 = render_node(capture1, context)
  let _result2 = render_node(capture2, context)

  // Check both variables were captured
  match context.get("var1") {
    Some(value) => assert_eq(value.to_string(), "Hello there!")
    None => fail("Expected var1 to be captured")
  }
  match context.get("var2") {
    Some(value) => assert_eq(value.to_string(), "World peace!")
    None => fail("Expected var2 to be captured")
  }
}

///|
test "capture with complex content" {
  // Test capture with complex content including loops
  let context = LiquidContext::new()
  let items = array_value([string_value("item1"), string_value("item2")])
  context.set("items", items)
  let capture_test = capture_node("list_html", [
    text_node("<ul>"),
    for_node("item", "items", [
      text_node("<li>"),
      variable_node("item", []),
      text_node("</li>"),
    ]),
    text_node("</ul>"),
  ])
  let _result = render_node(capture_test, context)

  // Check captured HTML content
  match context.get("list_html") {
    Some(value) => {
      let html = value.to_string()
      assert_eq(html.contains("<ul>"), true)
      assert_eq(html.contains("<li>"), true)
      assert_eq(html.contains("item1"), true)
      assert_eq(html.contains("item2"), true)
    }
    None => fail("Expected list_html to be captured")
  }
}

// Raw Tag Functionality Tests

///|
test "raw tag basic functionality" {
  // Test raw tag basic functionality
  let context = LiquidContext::new()
  let raw_test = raw_node("{{ variable }} {% tag %} should not be processed")
  let result = render_node(raw_test, context)
  assert_eq(result, "{{ variable }} {% tag %} should not be processed")
}

///|
test "raw tag with liquid syntax" {
  // Test raw tag with liquid syntax that should not be processed
  let context = LiquidContext::new()
  context.set("name", string_value("Alice")) // This should not affect raw content
  let raw_test = raw_node(
    "Hello {{ name | upcase }}! {% if true %}Always shown{% endif %}",
  )
  let result = render_node(raw_test, context)
  assert_eq(
    result, "Hello {{ name | upcase }}! {% if true %}Always shown{% endif %}",
  )
}

///|
test "raw tag in complex template" {
  // Test raw tag in complex template context
  let template = parse("Before {% raw %}{{ variable }}{% endraw %} After")
  let context = LiquidContext::new()
  context.set("variable", string_value("should not be used"))
  let result = template.render(context)
  assert_eq(result, "Before {{ variable }} After")
}

///|
test "multiple raw tags" {
  // Test multiple raw tags
  let template = parse(
    "{% raw %}First {{ block }}{% endraw %} and {% raw %}Second {{ block }}{% endraw %}",
  )
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "First {{ block }} and Second {{ block }}")
}

///|
test "raw tag with HTML content" {
  // Test raw tag with HTML content
  let context = LiquidContext::new()
  let raw_test = raw_node("<script>var x = '{{ dynamic_value }}';</script>")
  let result = render_node(raw_test, context)
  assert_eq(result, "<script>var x = '{{ dynamic_value }}';</script>")
}

// Advanced Forloop Properties Tests
