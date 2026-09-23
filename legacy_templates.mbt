///|
pub fn LiquidTemplate::new() -> LiquidTemplate {
  { nodes: [], }
}

///|
pub fn parse(template : String) -> LiquidTemplate {
  let parsed_nodes = parse_template(template)
  { nodes: parsed_nodes, }
}

///|
pub fn LiquidTemplate::render(
  self : LiquidTemplate,
  context : LiquidContext,
) -> String {
  let state = new_render_state()
  let mut result = ""
  for node in compile_nodes(self.nodes) {
    result = result + render_node_inner(node, context, state)
  }
  result
}

///|
pub fn render_node(node : LiquidNode, context : LiquidContext) -> String {
  render_node_inner(compile_node(node), context, new_render_state())
}

///|
pub fn render_with_layout(
  template : LiquidTemplate,
  layout_template : LiquidTemplate,
  context : LiquidContext,
) -> String {
  // Render the main template content
  let content = template.render(context)

  // Set the content in context for layout rendering
  context.set("__content__", string_value(content))

  // Render the layout template
  layout_template.render(context)
}
