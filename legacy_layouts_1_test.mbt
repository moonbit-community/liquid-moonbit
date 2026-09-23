///|
test "layout system basic functionality" {
  // Test layout tag parsing and rendering
  let layout_test = layout_node("base")
  let context = LiquidContext::new()
  let result = render_node(layout_test, context)
  assert_eq(result, "<!-- Layout: base -->")
}

// TemplateWithLayout Struct Tests

///|
test "template with layout struct creation" {
  // Test TemplateWithLayout struct constructor functions
  let nodes = [text_node("Hello"), variable_node("name", []), text_node("!")]
  let blocks = Map([])
  blocks.set("header", [text_node("Header Content")])
  blocks.set("footer", [text_node("Footer Content")])

  // Test with layout
  let template_with = template_with_layout(nodes, Some("base"), blocks)
  json_inspect(template_with, content={
    "nodes": [["Text", "Hello"], ["Variable", "name", []], ["Text", "!"]],
    "layout": "base",
    "blocks": {
      "header": [["Text", "Header Content"]],
      "footer": [["Text", "Footer Content"]],
    },
  })

  // Test without layout
  let template_simple = simple_template_with_layout(nodes)
  json_inspect(template_simple, content={
    "nodes": [["Text", "Hello"], ["Variable", "name", []], ["Text", "!"]],
    "blocks": {},
  })

  // Verify properties
  assert_eq(template_with.nodes.length(), 3)
  match template_with.layout {
    Some(layout) => assert_eq(layout, "base")
    None => fail("Expected layout to be Some")
  }
  assert_eq(template_with.blocks.length(), 2)

  assert_eq(template_simple.nodes.length(), 3)
  match template_simple.layout {
    Some(_) => fail("Expected layout to be None")
    None => ()
  }
  assert_eq(template_simple.blocks.length(), 0)
}

///|
test "template with layout complex scenarios" {
  // Test TemplateWithLayout with complex template structures
  let main_nodes = [
    text_node("Main content: "),
    variable_node("content", [filter("upcase", [])]),
    text_node("."),
  ]

  let blocks = Map([])
  blocks.set("sidebar", [
    text_node("Sidebar: "),
    variable_node("sidebar_content", []),
    text_node(" | "),
    variable_node("user.name", []),
  ])
  blocks.set("navigation", [
    text_node("<nav>"),
    variable_node("nav_items", [filter("join", [" | "])]),
    text_node("</nav>"),
  ])

  let template = template_with_layout(
    main_nodes,
    Some("complex_layout"),
    blocks,
  )

  // Verify structure
  assert_eq(template.nodes.length(), 3)
  assert_eq(template.blocks.length(), 2)
  match template.layout {
    Some(layout) => assert_eq(layout, "complex_layout")
    None => fail("Expected layout")
  }

  // Verify block contents
  match template.blocks.get("sidebar") {
    Some(sidebar_nodes) => assert_eq(sidebar_nodes.length(), 4)
    None => fail("Expected sidebar block")
  }
  match template.blocks.get("navigation") {
    Some(nav_nodes) => assert_eq(nav_nodes.length(), 3)
    None => fail("Expected navigation block")
  }
}

///|
test "template with layout edge cases" {
  // Test TemplateWithLayout with edge cases

  // Empty template
  let empty_template = simple_template_with_layout([])
  assert_eq(empty_template.nodes.length(), 0)
  assert_eq(empty_template.blocks.length(), 0)

  // Template with empty blocks map
  let empty_blocks = Map([])
  let template_empty_blocks = template_with_layout(
    [text_node("content")],
    Some("layout"),
    empty_blocks,
  )
  assert_eq(template_empty_blocks.blocks.length(), 0)

  // Template with multiple identical block names (should overwrite)
  let blocks = Map([])
  blocks.set("content", [text_node("First")])
  blocks.set("content", [text_node("Second")]) // Overwrites first

  let template = template_with_layout([text_node("main")], None, blocks)
  assert_eq(template.blocks.length(), 1)
  match template.blocks.get("content") {
    Some(nodes) => {
      assert_eq(nodes.length(), 1)
      match nodes[0] {
        Text(content) => assert_eq(content, "Second")
        _ => fail("Expected Text node")
      }
    }
    None => fail("Expected content block")
  }
}

///|
test "template with layout integration" {
  // Test TemplateWithLayout integration with existing layout system
  let main_content = [
    text_node("Welcome to "),
    variable_node("site.name", []),
    text_node("!"),
  ]

  let blocks = Map([])
  blocks.set("title", [variable_node("page.title", [filter("upcase", [])])])
  blocks.set("meta", [
    text_node("<meta name='description' content='"),
    variable_node("page.description", []),
    text_node("'>"),
  ])

  let template_layout = template_with_layout(main_content, Some("base"), blocks)

  // Test that it integrates with existing layout functionality
  let layout_node_test = layout_node("base")
  let context = LiquidContext::new()
  let layout_result = render_node(layout_node_test, context)
  assert_eq(layout_result, "<!-- Layout: base -->")

  // Verify template structure matches expected layout integration
  match template_layout.layout {
    Some(layout_name) => assert_eq(layout_name, "base")
    None => fail("Expected layout name")
  }

  assert_eq(template_layout.nodes.length(), 3)
  assert_eq(template_layout.blocks.length(), 2)
}

///|
test "block system functionality" {
  // Test block tag with default content
  let context = LiquidContext::new()
  let block_test = block_node("header", [text_node("Default Header")])
  let result = render_node(block_test, context)
  assert_eq(result, "Default Header")

  // Test block with override content
  context.set("__block_header", string_value("Custom Header"))
  let result_override = render_node(block_test, context)
  assert_eq(result_override, "Custom Header")
}

///|
test "template inheritance with layout" {
  // Test complete template inheritance workflow
  let main_template = LiquidTemplate::new()
  main_template.nodes.push(text_node("Hello World"))
  let layout_template = LiquidTemplate::new()
  layout_template.nodes.push(text_node("<html><body>"))
  layout_template.nodes.push(content_node())
  layout_template.nodes.push(text_node("</body></html>"))
  let context = LiquidContext::new()
  let result = render_with_layout(main_template, layout_template, context)
  assert_eq(result, "<html><body>Hello World</body></html>")
}

///|
test "template parsing with layout tags" {
  // Test parsing of layout-related tags
  let template_layout = parse("{% layout 'base' %}")
  json_inspect(template_layout, content={ "nodes": [["Layout", "'base'"]] })
  let template_block = parse("{% block 'header' %}")
  json_inspect(template_block, content={ "nodes": [["Block", "'header'", []]] })
  let template_content = parse("{% content %}")
  json_inspect(template_content, content={ "nodes": ["Content"] })
}

///|
test "layout and block integration" {
  // Test layout and block working together
  let context = LiquidContext::new()

  // Create a template with blocks
  let page_template = LiquidTemplate::new()
  page_template.nodes.push(text_node("Page: "))
  page_template.nodes.push(block_node("title", [text_node("Default Title")]))

  // Create layout template
  let layout_template = LiquidTemplate::new()
  layout_template.nodes.push(text_node("<html><head><title>"))
  layout_template.nodes.push(content_node())
  layout_template.nodes.push(text_node("</title></head></html>"))

  // Test with default block content
  let result_default = render_with_layout(
    page_template, layout_template, context,
  )
  assert_eq(
    result_default, "<html><head><title>Page: Default Title</title></head></html>",
  )

  // Test with custom block content
  context.set("__block_title", string_value("Custom Page Title"))
  let result_custom = render_with_layout(
    page_template, layout_template, context,
  )
  assert_eq(
    result_custom, "<html><head><title>Page: Custom Page Title</title></head></html>",
  )
}
