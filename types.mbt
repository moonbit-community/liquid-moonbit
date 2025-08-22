/// Core data structures for Liquid values

///|
pub enum LiquidValue {
  String(String)
  Number(Double)
  Bool(Bool)
  Array(Array[LiquidValue])
  Object(Map[String, LiquidValue])
  Null
} derive(ToJson(style="flat"))

/// Error handling policies

///|
pub enum ErrorPolicy {
  Strict // Fail on errors
  Warn // Print warnings but continue
  Silent // Ignore errors silently
} derive(ToJson(style="flat"))

// Context for variable storage

///|
pub struct LiquidContext {
  variables : Map[String, LiquidValue]
  error_policy : ErrorPolicy
} derive(ToJson)

// Filter with optional parameters

///|
pub struct Filter {
  name : String
  parameters : Array[String]
} derive(ToJson)

// For loop modifiers

///|
pub struct ForLoopModifiers {
  limit : Int?
  offset : Int?
  reversed : Bool
} derive(ToJson)

// Template structure

///|
pub enum LiquidNode {
  Text(String)
  Variable(String, Array[Filter]) // variable_name, filters_with_params
  For(String, String, Array[LiquidNode], ForLoopModifiers) // variable, collection, body, modifiers
  If(
    String,
    Array[LiquidNode],
    Array[(String, Array[LiquidNode])],
    Array[LiquidNode]?
  ) // condition, then_body, elsif_branches, else_body
  Unless(String, Array[LiquidNode]) // condition, body
  Case(String, Array[(String, Array[LiquidNode])], Array[LiquidNode]?) // expression, when_branches, else_body
  Assign(String, String) // variable_name, expression
  Comment(String) // comment content
  Cycle(String, Array[String]) // cycle_name, values
  TableRow(String, String, Array[LiquidNode], Int) // loop_var, collection, body, cols
  Break // break statement
  Continue // continue statement
  Liquid(Array[LiquidNode]) // inline liquid code block
  Section(String) // section name
  Style(String) // CSS content
  Include(String) // template name to include
  Render(String) // template name to render
  Capture(String, Array[LiquidNode]) // variable_name, content_to_capture
  Raw(String) // raw content (no liquid processing)
  Increment(String) // variable_name to increment
  Decrement(String) // variable_name to decrement
  Echo(String, Array[Filter]) // variable_name and filters (like Variable but different semantics)
  IfChanged(Array[LiquidNode]) // content that only renders if changed
  Layout(String) // layout template name
  Block(String, Array[LiquidNode]) // block_name, default_content
  Content // placeholder for main content in layouts
} derive(ToJson(style="flat"))

// Whitespace control flags

///|
pub struct WhitespaceControl {
  strip_left : Bool
  strip_right : Bool
} derive(ToJson)

///|
pub fn whitespace_control(strip_left : Bool, strip_right : Bool) -> WhitespaceControl {
  { strip_left, strip_right }
}

///|
pub fn no_whitespace_control() -> WhitespaceControl {
  { strip_left: false, strip_right: false }
}

// Template with layout information

///|
pub struct TemplateWithLayout {
  nodes : Array[LiquidNode]
  layout : String?
  blocks : Map[String, Array[LiquidNode]]
} derive(ToJson)

///|
pub fn template_with_layout(
  nodes : Array[LiquidNode], 
  layout : String?, 
  blocks : Map[String, Array[LiquidNode]]
) -> TemplateWithLayout {
  { nodes, layout, blocks }
}

///|
pub fn simple_template_with_layout(nodes : Array[LiquidNode]) -> TemplateWithLayout {
  { nodes, layout: None, blocks: Map::new() }
}

// Simple template parser

///|
pub struct LiquidTemplate {
  nodes : Array[LiquidNode]
} derive(ToJson)
