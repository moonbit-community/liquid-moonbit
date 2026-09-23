///|
test "template parsing basic" {
  // Test basic template parsing with text and variables
  let template = parse("Hello {{ name }}!")
  json_inspect(template, content={
    "nodes": [["Text", "Hello "], ["Variable", "name", []], ["Text", "!"]],
  })
}

///|
test "basic logic tag parsing" {
  // Test that logic tags are parsed (even if not fully implemented yet)
  let template = parse("Start {% assign name = 'test' %} End")
  json_inspect(template, content={
    "nodes": [
      ["Text", "Start "],
      ["Assign", "name", "'test'"],
      ["Text", " End"],
    ],
  })
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "Start  End") // Assign produces no output
}

///|
test "comment tag parsing" {
  // Test comment tag is properly parsed and ignored
  let template = parse(
    "Before{% comment %}This is a comment{% endcomment %}After",
  )
  json_inspect(template, content={
    "nodes": [
      ["Text", "Before"],
      ["Comment", "This is a comment"],
      ["Text", "After"],
    ],
  })
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "BeforeAfter")
}

///|
test "capture tag parsing" {
  // Test capture tag parsing (basic recognition)
  let template = parse(
    "{% capture my_var %}content{% endcapture %}{{ my_var }}",
  )
  json_inspect(template, content={
    "nodes": [
      ["Capture", "my_var", [["Text", "content"]]],
      ["Variable", "my_var", []],
    ],
  })
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "content")
}

///|
test "raw tag parsing" {
  // Test raw tag parsing (basic recognition)
  let template = parse("{% raw %}{{ not_processed }}{% endraw %}")
  json_inspect(template, content={ "nodes": [["Raw", "{{ not_processed }}"]] })
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "{{ not_processed }}")
}

// Advanced filter tests

///|
test "whitespace control parsing" {
  // Test that whitespace control syntax is recognized
  let template = parse("{{- name -}}")
  json_inspect(template, content={ "nodes": [["Variable", "name", []]] })
  let context = LiquidContext::new()
  context.set("name", string_value("World"))
  let result = template.render(context)
  assert_eq(result, "World")
}

///|
test "liquid tag parsing" {
  // Test liquid tag parsing
  let template = parse(
    "{% liquid %}assign name = 'World'{{ name }}{% endliquid %}",
  )
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "assign name = 'World'")
}

///|
test "section tag parsing" {
  // Test section tag parsing
  let template = parse("{% section 'header' %}")
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result.contains("<section"), true)
  assert_eq(result.contains("header"), true)
}

///|
test "style tag parsing" {
  // Test style tag parsing
  let template = parse("{% style %}body { color: red; }{% endstyle %}")
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result.contains("<style>"), true)
  assert_eq(result, "<style>body { color: red; }</style>")
}

///|
test "include tag parsing" {
  let context = LiquidContext::new()
  context.register_template("header.liquid", "<header>Custom</header>")
  assert_eq(
    parse("{% include 'header.liquid' %}").render(context),
    "<header>Custom</header>",
  )
}

///|
test "render tag parsing" {
  let context = LiquidContext::new()
  context.register_template("product-card", "<article>Product</article>")
  assert_eq(
    parse("{% render 'product-card' %}").render(context),
    "<article>Product</article>",
  )
}

///|
test "multiple parameter parsing" {
  // Test parsing multiple parameters with commas
  let template = parse("{{ text | slice: 0, 5 | upcase }}")
  json_inspect(template, content={
    "nodes": [
      [
        "Variable",
        "text",
        [
          { "name": "slice", "parameters": ["0", "5"] },
          { "name": "upcase", "parameters": [] },
        ],
      ],
    ],
  })
  let context = LiquidContext::new()
  context.set("text", string_value("hello world"))
  let result = template.render(context)
  assert_eq(result, "HELLO") // Slice first 5 chars, then uppercase
}

///|
test "when tag parsing recognition" {
  // Test when tag parsing recognition
  let template = parse("{% when 'admin' %}")
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "") // When tag produces no output (it's part of case)
}

///|
test "capture tag parsing in template" {
  // Test capture tag parsing in template
  let template = parse(
    "{% capture my_content %}Hello {{ name }}!{% endcapture %}{{ my_content }}",
  )
  let context = LiquidContext::new()
  context.set("name", string_value("World"))
  let result = template.render(context)
  // Should capture content and then display it
  assert_eq(result, "Hello World!")
}

///|
test "raw tag parsing in template" {
  // Test raw tag parsing in template
  let template = parse("{% raw %}{{ not_processed }}{% endraw %}")
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "{{ not_processed }}") // Raw content without processing
}

///|
test "template parsing with new tags" {
  // Test parsing of new tags
  let template_increment = parse("{% increment counter %}")
  json_inspect(template_increment, content={
    "nodes": [["Increment", "counter"]],
  })
  let template_decrement = parse("{% decrement counter %}")
  json_inspect(template_decrement, content={
    "nodes": [["Decrement", "counter"]],
  })
  let template_echo = parse("{% echo name | upcase %}")
  json_inspect(template_echo, content={
    "nodes": [["Echo", "name", [{ "name": "upcase", "parameters": [] }]]],
  })
  let template_ifchanged = parse("{% ifchanged %}")
  json_inspect(template_ifchanged, content={ "nodes": [["IfChanged", []]] })
}

///|
test "comprehensive parameter parsing edge cases" {
  // Test edge cases in parameter parsing for filters

  // Test with various parameter formats
  let params = ["\"quoted\"", "'single'", "unquoted", "\"", "'", ""]
  let expected_results = ["quoted", "single", "unquoted", "\"", "'", ""]
  for i in 0..<params.length() {
    let param = params[i]
    let expected = expected_results[i]

    // Test with pluralize filter
    let pluralize_filter = filter("pluralize", [param, "items"])
    let result = apply_filter_with_params(number_value(1.0), pluralize_filter)
    assert_eq(result.to_string(), "1 " + expected)
  }
}
