///|
pub fn filter(name : String, parameters : Array[String]) -> Filter {
  { name, parameters, }
}

///|
pub fn text_node(content : String) -> LiquidNode {
  Text(content)
}

///|
pub fn variable_node(name : String, filters : Array[Filter]) -> LiquidNode {
  Variable(name, filters)
}

// Helper for backward compatibility

///|
pub fn variable_node_simple(
  name : String,
  filter_names : Array[String],
) -> LiquidNode {
  let filters = filter_names.map(fn(name) { filter(name, []) })
  Variable(name, filters)
}

///|
pub fn for_node(
  loop_var : String,
  collection : String,
  body : Array[LiquidNode],
) -> LiquidNode {
  For(loop_var, collection, body, {
    limit: None,
    offset: None,
    reversed: false,
  })
}

///|
pub fn for_node_with_modifiers(
  loop_var : String,
  collection : String,
  body : Array[LiquidNode],
  modifiers : ForLoopModifiers,
) -> LiquidNode {
  For(loop_var, collection, body, modifiers)
}

///|
pub fn for_loop_modifiers(
  limit : Int?,
  offset : Int?,
  reversed : Bool,
) -> ForLoopModifiers {
  { limit, offset, reversed, }
}

///|
pub fn if_node(
  condition : String,
  then_body : Array[LiquidNode],
  else_body : Array[LiquidNode]?,
) -> LiquidNode {
  If(condition, then_body, [], else_body)
}

///|
pub fn if_node_with_elsif(
  condition : String,
  then_body : Array[LiquidNode],
  elsif_branches : Array[(String, Array[LiquidNode])],
  else_body : Array[LiquidNode]?,
) -> LiquidNode {
  If(condition, then_body, elsif_branches, else_body)
}

///|
pub fn unless_node(condition : String, body : Array[LiquidNode]) -> LiquidNode {
  Unless(condition, body)
}

///|
/// Both the subject and branch keys are Liquid expressions; quote string literals.
pub fn case_node(
  expression : String,
  when_branches : Array[(String, Array[LiquidNode])],
  else_body : Array[LiquidNode]?,
) -> LiquidNode {
  Case(expression, when_branches, else_body)
}

///|
pub fn cycle_node(cycle_name : String, values : Array[String]) -> LiquidNode {
  Cycle(cycle_name, values)
}

///|
pub fn tablerow_node(
  loop_var : String,
  collection : String,
  body : Array[LiquidNode],
  cols : Int,
) -> LiquidNode {
  TableRow(loop_var, collection, body, cols)
}

///|
pub fn break_node() -> LiquidNode {
  Break
}

///|
pub fn continue_node() -> LiquidNode {
  Continue
}

///|
pub fn liquid_node(body : Array[LiquidNode]) -> LiquidNode {
  Liquid(body)
}

///|
pub fn section_node(section_name : String) -> LiquidNode {
  Section(section_name)
}

///|
pub fn style_node(css_content : String) -> LiquidNode {
  Style(css_content)
}

///|
pub fn include_node(template_name : String) -> LiquidNode {
  Include(template_name)
}

///|
pub fn render_node_tag(template_name : String) -> LiquidNode {
  Render(template_name)
}

///|
pub fn capture_node(
  var_name : String,
  content : Array[LiquidNode],
) -> LiquidNode {
  Capture(var_name, content)
}

///|
pub fn raw_node(raw_content : String) -> LiquidNode {
  Raw(raw_content)
}

///|
pub fn increment_node(var_name : String) -> LiquidNode {
  Increment(var_name)
}

///|
pub fn decrement_node(var_name : String) -> LiquidNode {
  Decrement(var_name)
}

///|
pub fn echo_node(var_name : String, filters : Array[Filter]) -> LiquidNode {
  Echo(var_name, filters)
}

///|
pub fn ifchanged_node(body : Array[LiquidNode]) -> LiquidNode {
  IfChanged(body)
}

///|
pub fn layout_node(layout_name : String) -> LiquidNode {
  Layout(layout_name)
}

///|
pub fn block_node(
  block_name : String,
  default_content : Array[LiquidNode],
) -> LiquidNode {
  Block(block_name, default_content)
}

///|
pub fn content_node() -> LiquidNode {
  Content
}

// Template inheritance utilities
