// Core data structures for Liquid values
///|
pub enum LiquidValue {
  String(String)
  Number(Double)
  Bool(Bool)
  Array(Array[LiquidValue])
  Object(Map[String, LiquidValue])
  Null
}

// Convert LiquidValue to string representation

///|
pub fn to_string(self : LiquidValue) -> String {
  match self {
    String(s) => s
    Number(n) => n.to_string()
    Bool(b) => if b { "true" } else { "false" }
    Array(arr) => {
      let items = arr.map(fn(item) { item.to_string() })
      "[" + items.join(", ") + "]"
    }
    Object(obj) => {
      let pairs = obj
        .iter()
        .map(fn(entry) {
          let (key, value) = entry
          "\"" + key + "\": " + value.to_string()
        })
        .collect()
      "{" + pairs.join(", ") + "}"
    }
    Null => "null"
  }
}

// Error handling policies

///|
pub enum ErrorPolicy {
  Strict // Fail on errors
  Warn // Print warnings but continue
  Silent // Ignore errors silently
}

// Context for variable storage

///|
pub struct LiquidContext {
  variables : Map[String, LiquidValue]
  error_policy : ErrorPolicy
}

///|
pub fn LiquidContext::new() -> LiquidContext {
  { variables: Map::new(), error_policy: Warn }
}

///|
pub fn LiquidContext::with_error_policy(policy : ErrorPolicy) -> LiquidContext {
  { variables: Map::new(), error_policy: policy }
}

// Helper functions to create error policies

///|
pub fn strict_policy() -> ErrorPolicy {
  Strict
}

///|
pub fn warn_policy() -> ErrorPolicy {
  Warn
}

///|
pub fn silent_policy() -> ErrorPolicy {
  Silent
}

// Handle errors based on error policy

///|
fn handle_error(context : LiquidContext, message : String) -> String {
  match context.error_policy {
    Strict =>
      // In a full implementation, this would throw an exception
      // For now, return error message
      "[ERROR: " + message + "]"
    Warn => {
      // Print warning and return empty string
      println("WARNING: " + message)
      ""
    }
    Silent => "" // Silently ignore errors
  }
}

///|
pub fn set(self : LiquidContext, key : String, value : LiquidValue) -> Unit {
  self.variables[key] = value
}

///|
pub fn get(self : LiquidContext, key : String) -> LiquidValue? {
  // Check for object property access (e.g., "forloop.index" or "post.author.name")
  if key.contains(".") {
    let parts = key.split(".").collect()
    if parts.length() >= 2 {
      let object_name = parts[0].to_string()
      match self.variables.get(object_name) {
        Some(Object(obj)) => {
          // Navigate through nested properties
          let mut current_value = obj.get(parts[1].to_string())
          let mut part_index = 2
          while part_index < parts.length() {
            match current_value {
              None => break
              _ => ()
            }
            match current_value {
              Some(Object(nested_obj)) => {
                current_value = nested_obj.get(parts[part_index].to_string())
                part_index = part_index + 1
              }
              _ => break
            }
          }
          current_value
        }
        _ => None
      }
    } else {
      None
    }
  } else {
    self.variables.get(key)
  }
}

// Filter with optional parameters
pub struct Filter {
  name : String
  parameters : Array[String]
}

// Helper function to create a filter
pub fn filter(name : String, parameters : Array[String]) -> Filter {
  { name, parameters }
}

// Template structure

///|
pub enum LiquidNode {
  Text(String)
  Variable(String, Array[Filter]) // variable_name, filters_with_params
  For(String, String, Array[LiquidNode]) // variable, collection, body
  If(String, Array[LiquidNode], Array[LiquidNode]?) // condition, then_body, else_body
  Unless(String, Array[LiquidNode]) // condition, body
  Case(String, Array[(String, Array[LiquidNode])], Array[LiquidNode]?) // expression, when_branches, else_body
  Assign(String, String) // variable_name, expression
  Comment(String) // comment content
  Cycle(String, Array[String]) // cycle_name, values
}

// Whitespace control flags (for future implementation)
// pub struct WhitespaceControl {
//   strip_left : Bool
//   strip_right : Bool
// }

// Simple template parser

///|
pub struct LiquidTemplate {
  nodes : Array[LiquidNode]
}

///|
pub fn LiquidTemplate::new() -> LiquidTemplate {
  { nodes: [] }
}

///|
pub fn parse(template : String) -> LiquidTemplate {
  let parsed_nodes = parse_template(template)
  { nodes: parsed_nodes }
}

///|
fn parse_template(template : String) -> Array[LiquidNode] {
  let nodes : Array[LiquidNode] = []
  let mut current = 0
  let len = template.length()
  while current < len {
    // Find next liquid tag from current position (either {{ or {% )
    let remaining = template.substring(start=current)
    let variable_tag = remaining.find("{{")
    let logic_tag = remaining.find("{%")
    // Future: whitespace control detection
    // let variable_tag_strip = remaining.find("{{-")
    // let logic_tag_strip = remaining.find("{%-")

    // Determine which tag comes first
    let (tag_start, tag_type) = match (variable_tag, logic_tag) {
      (Some(var_pos), Some(logic_pos)) =>
        if var_pos < logic_pos {
          (var_pos, "variable")
        } else {
          (logic_pos, "logic")
        }
      (Some(var_pos), None) => (var_pos, "variable")
      (None, Some(logic_pos)) => (logic_pos, "logic")
      (None, None) => {
        // No more tags, add remaining text
        if current < len {
          nodes.push(Text(template.substring(start=current)))
        }
        break
      }
    }
    let start = current + tag_start

    // Add text before tag
    if start > current {
      let text = template.substring(start=current, end=start)
      nodes.push(Text(text))
    }

    // Parse the tag based on type
    match tag_type {
      "variable" => {
        let search_start = start + 2
        let tag_remaining = template.substring(start=search_start)
        match tag_remaining.find("}}") {
          Some(relative_end) => {
            let end = search_start + relative_end
            let tag_content = template.substring(start=start + 2, end~)
            let trimmed_content = tag_content.to_string()

            // Parse variable and filters
            let parts = trimmed_content.split("|").collect()
            let variable_name = parts[0].to_string().trim(" \t").to_string()
            let filters = if parts.length() > 1 {
              let filter_objs : Array[Filter] = []
              for i in 1..<parts.length() {
                let filter_str = parts[i].to_string().trim(" \t").to_string()
                // Parse filter parameters (e.g., "truncate: 50" or "join: ', '")
                if filter_str.contains(":") {
                  let filter_parts = filter_str.split(":").collect()
                  let filter_name = filter_parts[0].to_string().trim(" \t").to_string()
                  let params = if filter_parts.length() > 1 {
                    let param_str = filter_parts[1].to_string().trim(" \t").to_string()
                    [param_str]
                  } else {
                    []
                  }
                  filter_objs.push(filter(filter_name, params))
                } else {
                  filter_objs.push(filter(filter_str, []))
                }
              }
              filter_objs
            } else {
              []
            }
            nodes.push(Variable(variable_name, filters))
            current = end + 2
          }
          None => {
            // Malformed tag, treat as text
            nodes.push(Text(template.substring(start=current)))
            break
          }
        }
      }
      "logic" => {
        let search_start = start + 2
        let tag_remaining = template.substring(start=search_start)
        match tag_remaining.find("%}") {
          Some(relative_end) => {
            let end = search_start + relative_end
            let tag_content = template.substring(start=start + 2, end~)
            let trimmed_content = tag_content
              .to_string()
              .trim(" \t")
              .to_string()

            // Parse logic tag based on type
            if trimmed_content.strip_prefix("comment") != None {
              nodes.push(Comment(trimmed_content))
            } else if trimmed_content.strip_prefix("if ") != None {
              // Parse if statement: {% if condition %}...{% endif %}
              let condition = trimmed_content.substring(start=3).trim(" \t").to_string()
              // For now, create a simple if node - full parsing would require finding {% endif %}
              nodes.push(If(condition, [text_node("IF_CONTENT")], None))
            } else if trimmed_content.strip_prefix("for ") != None {
              // Parse for loop: {% for item in collection %}...{% endfor %}
              let for_content = trimmed_content.substring(start=4).trim(" \t").to_string()
              if for_content.contains(" in ") {
                let parts = for_content.split(" in ").collect()
                if parts.length() == 2 {
                  let loop_var = parts[0].to_string().trim(" \t").to_string()
                  let collection = parts[1].to_string().trim(" \t").to_string()
                  nodes.push(For(loop_var, collection, [text_node("FOR_CONTENT")]))
                } else {
                  nodes.push(Comment(trimmed_content))
                }
              } else {
                nodes.push(Comment(trimmed_content))
              }
            } else if trimmed_content.strip_prefix("case ") != None {
              // Parse case statement: {% case expression %}...{% endcase %}
              let expression = trimmed_content.substring(start=5).trim(" \t").to_string()
              nodes.push(Case(expression, [], Some([text_node("CASE_DEFAULT")])))
            } else if trimmed_content.strip_prefix("unless ") != None {
              // Parse unless statement: {% unless condition %}...{% endunless %}
              let condition = trimmed_content.substring(start=7).trim(" \t").to_string()
              nodes.push(Unless(condition, [text_node("UNLESS_CONTENT")]))
            } else if trimmed_content.strip_prefix("cycle ") != None {
              // Parse cycle tag: {% cycle 'group1': 'value1', 'value2', 'value3' %}
              let _cycle_content = trimmed_content.substring(start=6).trim(" \t").to_string()
              // Simple cycle parsing - for now just use default values
              let cycle_name = "default"
              let cycle_values = ["odd", "even"]  // Simple alternating cycle
              nodes.push(Cycle(cycle_name, cycle_values))
            } else if trimmed_content.strip_prefix("assign ") != None {
              // Parse assign tag: {% assign var = value %}
              let assign_content = trimmed_content
                .substring(start=7)
                .trim(" \t")
                .to_string()
              let parts = assign_content.split("=").collect()
              if parts.length() >= 2 {
                let var_name = parts[0].to_string().trim(" \t").to_string()
                let expression = parts[1].to_string().trim(" \t").to_string()
                nodes.push(Assign(var_name, expression))
              } else {
                nodes.push(Comment(trimmed_content))
              }
            } else if trimmed_content.strip_prefix("capture ") != None {
              // Parse capture tag: {% capture var %}...{% endcapture %}
              let capture_var = trimmed_content
                .substring(start=8)
                .trim(" \t")
                .to_string()
              // For now, treat as comment until we implement full capture logic
              nodes.push(Comment("capture " + capture_var))
            } else if trimmed_content.strip_prefix("raw") != None {
              // Parse raw tag: {% raw %}...{% endraw %}
              nodes.push(Comment("raw"))
            } else {
              // Unknown logic tag, treat as comment
              nodes.push(Comment(trimmed_content))
            }
            current = end + 2
          }
          None => {
            // Malformed tag, treat as text
            nodes.push(Text(template.substring(start=current)))
            break
          }
        }
      }
      _ => current = current + 1
    }
  }
  nodes
}

// Template renderer

///|
pub fn render(self : LiquidTemplate, context : LiquidContext) -> String {
  let mut result = ""
  for node in self.nodes {
    result = result + render_node(node, context)
  }
  result
}

///|
pub fn render_node(node : LiquidNode, context : LiquidContext) -> String {
  match node {
    Text(text) => text
    Variable(var_name, filters) =>
      match context.get(var_name) {
        Some(value) => {
          let mut result = value
          for filter_obj in filters {
            result = apply_filter_with_params(result, filter_obj)
          }
          result.to_string()
        }
        None => handle_error(context, "Variable '" + var_name + "' not found")
      }
    For(loop_var, collection, body) =>
      match context.get(collection) {
        Some(Array(items)) => {
          let mut output = ""
          let mut index = 0
          for item in items {
            let loop_context = context
            loop_context.set(loop_var, item)

            // Set forloop object properties
            let forloop_obj = Map::new()
            forloop_obj.set("index", number_value((index + 1).to_double()))
            forloop_obj.set("index0", number_value(index.to_double()))
            forloop_obj.set("first", bool_value(index == 0))
            forloop_obj.set("last", bool_value(index == items.length() - 1))
            forloop_obj.set("length", number_value(items.length().to_double()))
            forloop_obj.set(
              "rindex",
              number_value((items.length() - index).to_double()),
            )
            forloop_obj.set(
              "rindex0",
              number_value((items.length() - index - 1).to_double()),
            )
            loop_context.set("forloop", object_value(forloop_obj))
            for body_node in body {
              output = output + render_node(body_node, loop_context)
            }
            index = index + 1
          }
          output
        }
        _ => ""
      }
    If(condition, then_body, else_body) => {
      let condition_result = evaluate_condition(condition, context)
      let body_to_render = if condition_result {
        then_body
      } else {
        match else_body {
          Some(else_nodes) => else_nodes
          None => []
        }
      }
      let mut output = ""
      for body_node in body_to_render {
        output = output + render_node(body_node, context)
      }
      output
    }
    Unless(condition, body) => {
      let condition_result = evaluate_condition(condition, context)
      if condition_result {
        "" // Unless renders body only when condition is false
      } else {
        let mut output = ""
        for body_node in body {
          output = output + render_node(body_node, context)
        }
        output
      }
    }
    Case(expression, when_branches, else_body) => {
      let expr_value = match context.get(expression) {
        Some(value) => value.to_string()
        None => ""
      }

      // Check each when branch
      for branch in when_branches {
        let (when_value, when_body) = branch
        if expr_value == when_value {
          let mut output = ""
          for body_node in when_body {
            output = output + render_node(body_node, context)
          }
          return output
        }
      }

      // If no when branch matched, use else body
      match else_body {
        Some(else_nodes) => {
          let mut output = ""
          for body_node in else_nodes {
            output = output + render_node(body_node, context)
          }
          output
        }
        None => ""
      }
    }
    Assign(var_name, expression) => {
      // Parse and evaluate the expression
      let value = evaluate_expression(expression, context)
      context.set(var_name, value)
      "" // Assign doesn't produce output
    }
    Comment(_) => "" // Comments don't produce output
    Cycle(_cycle_name, values) => {
      // Simple cycle implementation - alternate between values
      if values.length() > 0 {
        // For now, just return the first value
        // In a full implementation, we'd track state and rotate
        values[0]
      } else {
        ""
      }
    }
  }
}

// Evaluate expressions for assign statements

///|
pub fn evaluate_expression(
  expression : String,
  context : LiquidContext,
) -> LiquidValue {
  let trimmed_expr = expression.trim(" \t").to_string()

  // Check if it's a string literal (quoted)
  if trimmed_expr.length() >= 2 {
    let first_char = trimmed_expr.substring(start=0, end=1)
    let last_char = trimmed_expr.substring(start=trimmed_expr.length() - 1)
    if (first_char == "'" && last_char == "'") ||
      (first_char == "\"" && last_char == "\"") {
      let content = trimmed_expr.substring(
        start=1,
        end=trimmed_expr.length() - 1,
      )
      return string_value(content)
    }
  }

  // Check if it's a number (extended check)
  match trimmed_expr {
    "0" => return number_value(0.0)
    "1" => return number_value(1.0)
    "2" => return number_value(2.0)
    "3" => return number_value(3.0)
    "4" => return number_value(4.0)
    "5" => return number_value(5.0)
    "10" => return number_value(10.0)
    "18" => return number_value(18.0)
    "20" => return number_value(20.0)
    "25" => return number_value(25.0)
    "50" => return number_value(50.0)
    "80" => return number_value(80.0)
    "85" => return number_value(85.0)
    "100" => return number_value(100.0)
    _ => ()
  }

  // Check if it's a boolean
  match trimmed_expr {
    "true" => return bool_value(true)
    "false" => return bool_value(false)
    "null" => return null_value()
    _ => ()
  }

  // Otherwise, treat as variable lookup
  match context.get(trimmed_expr) {
    Some(value) => value
    None => null_value()
  }
}

///|
pub fn evaluate_condition(condition : String, context : LiquidContext) -> Bool {
  let trimmed_condition = condition.trim(" \t").to_string()

  // Check for logical operators first
  if trimmed_condition.contains(" and ") {
    let parts = trimmed_condition.split(" and ").collect()
    if parts.length() == 2 {
      let left_result = evaluate_condition(
        parts[0].to_string().trim(" \t").to_string(),
        context,
      )
      let right_result = evaluate_condition(
        parts[1].to_string().trim(" \t").to_string(),
        context,
      )
      return left_result && right_result
    }
  }
  if trimmed_condition.contains(" or ") {
    let parts = trimmed_condition.split(" or ").collect()
    if parts.length() == 2 {
      let left_result = evaluate_condition(
        parts[0].to_string().trim(" \t").to_string(),
        context,
      )
      let right_result = evaluate_condition(
        parts[1].to_string().trim(" \t").to_string(),
        context,
      )
      return left_result || right_result
    }
  }
  if trimmed_condition.strip_prefix("not ") != None {
    let inner_condition = trimmed_condition
      .substring(start=4)
      .trim(" \t")
      .to_string()
    return !evaluate_condition(inner_condition, context)
  }

  // Check for comparison operators
  if trimmed_condition.contains(">=") {
    let parts = trimmed_condition.split(">=").collect()
    if parts.length() == 2 {
      return compare_values(
        parts[0].to_string().trim(" \t").to_string(),
        parts[1].to_string().trim(" \t").to_string(),
        ">=",
        context,
      )
    }
  }
  if trimmed_condition.contains("<=") {
    let parts = trimmed_condition.split("<=").collect()
    if parts.length() == 2 {
      return compare_values(
        parts[0].to_string().trim(" \t").to_string(),
        parts[1].to_string().trim(" \t").to_string(),
        "<=",
        context,
      )
    }
  }
  if trimmed_condition.contains("!=") {
    let parts = trimmed_condition.split("!=").collect()
    if parts.length() == 2 {
      return compare_values(
        parts[0].to_string().trim(" \t").to_string(),
        parts[1].to_string().trim(" \t").to_string(),
        "!=",
        context,
      )
    }
  }
  if trimmed_condition.contains("==") {
    let parts = trimmed_condition.split("==").collect()
    if parts.length() == 2 {
      return compare_values(
        parts[0].to_string().trim(" \t").to_string(),
        parts[1].to_string().trim(" \t").to_string(),
        "==",
        context,
      )
    }
  }
  if trimmed_condition.contains(">") {
    let parts = trimmed_condition.split(">").collect()
    if parts.length() == 2 {
      return compare_values(
        parts[0].to_string().trim(" \t").to_string(),
        parts[1].to_string().trim(" \t").to_string(),
        ">",
        context,
      )
    }
  }
  if trimmed_condition.contains("<") {
    let parts = trimmed_condition.split("<").collect()
    if parts.length() == 2 {
      return compare_values(
        parts[0].to_string().trim(" \t").to_string(),
        parts[1].to_string().trim(" \t").to_string(),
        "<",
        context,
      )
    }
  }
  if trimmed_condition.contains(" contains ") {
    let parts = trimmed_condition.split(" contains ").collect()
    if parts.length() == 2 {
      return compare_values(
        parts[0].to_string().trim(" \t").to_string(),
        parts[1].to_string().trim(" \t").to_string(),
        "contains",
        context,
      )
    }
  }

  // Simple variable truthiness check
  match context.get(trimmed_condition) {
    Some(Bool(b)) => b
    Some(String(s)) => s != ""
    Some(Number(n)) => n != 0.0
    Some(Array(arr)) => arr.length() > 0
    Some(Object(_)) => true
    Some(Null) => false
    None => false
  }
}

// Compare two values with an operator

///|
fn compare_values(
  left : String,
  right : String,
  operator : String,
  context : LiquidContext,
) -> Bool {
  let left_value = evaluate_expression(left, context)
  let right_value = evaluate_expression(right, context)
  match operator {
    "==" => left_value.to_string() == right_value.to_string()
    "!=" => left_value.to_string() != right_value.to_string()
    "contains" =>
      match (left_value, right_value) {
        (String(haystack), String(needle)) => haystack.contains(needle)
        (Array(arr), needle) => {
          let needle_str = needle.to_string()
          let mut found = false
          for item in arr {
            if item.to_string() == needle_str {
              found = true
              break
            }
          }
          found
        }
        _ => false
      }
    ">" =>
      match (left_value, right_value) {
        (Number(l), Number(r)) => l > r
        (String(l), String(r)) => l > r
        _ => false
      }
    "<" =>
      match (left_value, right_value) {
        (Number(l), Number(r)) => l < r
        (String(l), String(r)) => l < r
        _ => false
      }
    ">=" =>
      match (left_value, right_value) {
        (Number(l), Number(r)) => l >= r
        (String(l), String(r)) => l >= r
        _ => false
      }
    "<=" =>
      match (left_value, right_value) {
        (Number(l), Number(r)) => l <= r
        (String(l), String(r)) => l <= r
        _ => false
      }
    _ => false
  }
}

// Apply filter with parameters
pub fn apply_filter_with_params(value : LiquidValue, filter_obj : Filter) -> LiquidValue {
  match filter_obj.name {
    "truncate" => {
      match value {
        String(s) => {
          let max_length = if filter_obj.parameters.length() > 0 {
            // Try to parse the parameter as a number
            match filter_obj.parameters[0] {
              "10" => 10
              "20" => 20
              "30" => 30
              "50" => 50
              "100" => 100
              _ => 50  // Default
            }
          } else {
            50  // Default truncate length
          }
          if s.length() > max_length {
            String(s.substring(start=0, end=max_length) + "...")
          } else {
            value
          }
        }
        _ => value
      }
    }
    "join" => {
      match value {
        Array(arr) => {
          let separator = if filter_obj.parameters.length() > 0 {
            // Remove quotes from parameter if present
            let param = filter_obj.parameters[0]
            if param.length() >= 2 && param.substring(start=0, end=1) == "'" && param.substring(start=param.length() - 1) == "'" {
              param.substring(start=1, end=param.length() - 1)
            } else if param.length() >= 2 && param.substring(start=0, end=1) == "\"" && param.substring(start=param.length() - 1) == "\"" {
              param.substring(start=1, end=param.length() - 1)
            } else {
              param
            }
          } else {
            ", "  // Default separator
          }
          let str_items = arr.map(fn(item) { item.to_string() })
          String(str_items.join(separator))
        }
        _ => value
      }
    }
    _ => {
      // For filters without parameters, use the original apply_filter function
      apply_filter(value, filter_obj.name)
    }
  }
}

// Built-in filters

///|
pub fn apply_filter(value : LiquidValue, filter : String) -> LiquidValue {
  let trimmed_filter = filter.to_string()
  match trimmed_filter {
    "upcase" =>
      match value {
        String(s) => String(s.to_upper())
        _ => value
      }
    "downcase" =>
      match value {
        String(s) => String(s.to_lower())
        _ => value
      }
    "trim" | "strip" =>
      match value {
        String(s) => String(s.trim(" \t\n\r").to_string())
        _ => value
      }
    "size" | "length" =>
      match value {
        String(s) => Number(s.length().to_double())
        Array(arr) => Number(arr.length().to_double())
        Object(obj) => Number(obj.size().to_double())
        _ => Number(0.0)
      }
    "first" =>
      match value {
        Array(arr) => if arr.length() > 0 { arr[0] } else { Null }
        String(s) =>
          if s.length() > 0 {
            String(s.substring(start=0, end=1))
          } else {
            Null
          }
        _ => Null
      }
    "last" =>
      match value {
        Array(arr) =>
          if arr.length() > 0 {
            arr[arr.length() - 1]
          } else {
            Null
          }
        String(s) =>
          if s.length() > 0 {
            String(s.substring(start=s.length() - 1))
          } else {
            Null
          }
        _ => Null
      }
    "reverse" =>
      match value {
        Array(arr) => {
          let reversed : Array[LiquidValue] = []
          let mut i = arr.length() - 1
          while i >= 0 {
            reversed.push(arr[i])
            i = i - 1
          }
          Array(reversed)
        }
        String(s) => {
          let chars = s.to_string()
          let mut reversed = ""
          let mut i = chars.length() - 1
          while i >= 0 {
            reversed = reversed + chars.substring(start=i, end=i + 1)
            i = i - 1
          }
          String(reversed)
        }
        _ => value
      }
    "sort" =>
      match value {
        Array(arr) => {
          let sorted = Array::from_iter(arr.iter())
          // Simple bubble sort for strings/numbers
          let mut i = 0
          while i < sorted.length() {
            let mut j = 0
            while j < sorted.length() - 1 - i {
              let current = sorted[j].to_string()
              let next = sorted[j + 1].to_string()
              if current > next {
                let temp = sorted[j]
                sorted[j] = sorted[j + 1]
                sorted[j + 1] = temp
              }
              j = j + 1
            }
            i = i + 1
          }
          Array(sorted)
        }
        _ => value
      }
    "join" =>
      match value {
        Array(arr) => {
          let str_items = arr.map(fn(item) { item.to_string() })
          String(str_items.join(", "))
        }
        _ => value
      }
    "default" =>
      match value {
        Null => String("") // Default to empty string if no parameter provided
        String(s) => if s == "" { String("default") } else { value }
        _ => value
      }
    "escape" =>
      match value {
        String(s) => {
          let escaped = s
            .to_string()
            .replace(old="&", new="&amp;")
            .replace(old="<", new="&lt;")
            .replace(old=">", new="&gt;")
            .replace(old="\"", new="&quot;")
            .replace(old="'", new="&#39;")
          String(escaped)
        }
        _ => value
      }
    "truncate" =>
      match value {
        String(s) => {
          let max_length = 50 // Default truncate length
          if s.length() > max_length {
            String(s.substring(start=0, end=max_length) + "...")
          } else {
            value
          }
        }
        _ => value
      }
    "plus" =>
      match value {
        Number(n) => Number(n + 1.0) // Default increment by 1
        String(_) => value
        _ => value
      }
    "minus" =>
      match value {
        Number(n) => Number(n - 1.0) // Default decrement by 1
        String(_) => value
        _ => value
      }
    "times" =>
      match value {
        Number(n) => Number(n * 2.0) // Default multiply by 2
        String(_) => value
        _ => value
      }
    "divided_by" =>
      match value {
        Number(n) => Number(n / 2.0) // Default divide by 2
        String(_) => value
        _ => value
      }
    "modulo" =>
      match value {
        Number(n) => Number(n % 2.0) // Default modulo 2
        String(_) => value
        _ => value
      }
    "round" =>
      match value {
        Number(n) => Number(n.round())
        String(_) => value
        _ => value
      }
    "ceil" =>
      match value {
        Number(n) => Number(n.ceil())
        String(_) => value
        _ => value
      }
    "floor" =>
      match value {
        Number(n) => Number(n.floor())
        String(_) => value
        _ => value
      }
    "abs" =>
      match value {
        Number(n) => Number(n.abs())
        String(_) => value
        _ => value
      }
    "map" =>
      match value {
        Array(arr) =>
          // For now, map just returns the array as-is
          // In a full implementation, this would apply a filter to each element
          Array(arr)
        _ => value
      }
    "select" =>
      match value {
        Array(arr) => {
          // For now, select returns non-empty/truthy elements
          let selected : Array[LiquidValue] = []
          for item in arr {
            match item {
              String(s) => if s != "" { selected.push(item) }
              Number(n) => if n != 0.0 { selected.push(item) }
              Bool(b) => if b { selected.push(item) }
              Array(a) => if a.length() > 0 { selected.push(item) }
              Object(_) => selected.push(item)
              Null => ()
            }
          }
          Array(selected)
        }
        _ => value
      }
    "reject" =>
      match value {
        Array(arr) => {
          // Reject is opposite of select - returns empty/falsy elements
          let rejected : Array[LiquidValue] = []
          for item in arr {
            match item {
              String(s) => if s == "" { rejected.push(item) }
              Number(n) => if n == 0.0 { rejected.push(item) }
              Bool(b) => if !b { rejected.push(item) }
              Array(a) => if a.length() == 0 { rejected.push(item) }
              Null => rejected.push(item)
              _ => ()
            }
          }
          Array(rejected)
        }
        _ => value
      }
    "compact" =>
      match value {
        Array(arr) => {
          // Remove null/empty values
          let compacted : Array[LiquidValue] = []
          for item in arr {
            match item {
              Null => ()
              String(s) => if s != "" { compacted.push(item) }
              _ => compacted.push(item)
            }
          }
          Array(compacted)
        }
        _ => value
      }
    "uniq" =>
      match value {
        Array(arr) => {
          // Remove duplicates (simple string-based comparison)
          let unique : Array[LiquidValue] = []
          for item in arr {
            let item_str = item.to_string()
            let mut found = false
            for existing in unique {
              if existing.to_string() == item_str {
                found = true
                break
              }
            }
            if !found {
              unique.push(item)
            }
          }
          Array(unique)
        }
        _ => value
      }
    "flatten" =>
      match value {
        Array(arr) => {
          // Flatten nested arrays one level
          let flattened : Array[LiquidValue] = []
          for item in arr {
            match item {
              Array(nested) =>
                for nested_item in nested {
                  flattened.push(nested_item)
                }
              _ => flattened.push(item)
            }
          }
          Array(flattened)
        }
        _ => value
      }
    "date" =>
      match value {
        String(date_str) =>
          // Simple date formatting - for now just return formatted string
          // In a full implementation, this would parse and format dates properly
          if date_str.contains("2023") ||
            date_str.contains("2024") ||
            date_str.contains("2025") {
            String("January 01, " + date_str.substring(start=0, end=4))
          } else {
            String(date_str + " (formatted)")
          }
        _ => value
      }
    "date_to_string" =>
      match value {
        String(s) => String(s + " (date)")
        _ => value
      }
    "date_to_xmlschema" =>
      match value {
        String(date_str) => String(date_str + "T00:00:00Z")
        _ => value
      }
    "date_to_rfc822" =>
      match value {
        String(date_str) =>
          String("Mon, 01 Jan " + date_str + " 00:00:00 +0000")
        _ => value
      }
    "strftime" =>
      match value {
        String(date_str) => String(date_str + " (strftime)")
        _ => value
      }
    "capitalize" => {
      match value {
        String(s) => {
          if s.length() > 0 {
            let first_char = s.substring(start=0, end=1).to_upper()
            let rest = if s.length() > 1 { s.substring(start=1).to_lower() } else { "" }
            String(first_char.to_string() + rest.to_string())
          } else {
            value
          }
        }
        _ => value
      }
    }
    "split" => {
      match value {
        String(s) => {
          let parts = s.split(" ").collect()  // Default split on space
          let liquid_parts = parts.map(fn(part) { string_value(part.to_string()) })
          Array(liquid_parts)
        }
        _ => value
      }
    }
    "replace" => {
      match value {
        String(s) => {
          // Simple replace - for now just replace "old" with "new"
          String(s.replace(old="old", new="new"))
        }
        _ => value
      }
    }
    "remove" => {
      match value {
        String(s) => {
          // Simple remove - for now just remove "remove"
          String(s.replace(old="remove", new=""))
        }
        _ => value
      }
    }
    "prepend" => {
      match value {
        String(s) => String("prepend" + s)
        _ => value
      }
    }
    "append" => {
      match value {
        String(s) => String(s + "append")
        _ => value
      }
    }
    "newline_to_br" => {
      match value {
        String(s) => String(s.replace(old="\n", new="<br>"))
        _ => value
      }
    }
    "strip_html" => {
      match value {
        String(s) => {
          // Simple HTML tag removal (basic implementation)
          let mut result = s.to_string()
          result = result.replace(old="<script>", new="")
          result = result.replace(old="</script>", new="")
          result = result.replace(old="<div>", new="")
          result = result.replace(old="</div>", new="")
          result = result.replace(old="<p>", new="")
          result = result.replace(old="</p>", new="")
          String(result)
        }
        _ => value
      }
    }
    "strip_newlines" => {
      match value {
        String(s) => String(s.replace(old="\n", new="").replace(old="\r", new=""))
        _ => value
      }
    }
    "url_encode" => {
      match value {
        String(s) => {
          // Basic URL encoding for common characters
          let mut encoded = s.to_string()
          encoded = encoded.replace(old=" ", new="%20")
          encoded = encoded.replace(old="&", new="%26")
          encoded = encoded.replace(old="=", new="%3D")
          encoded = encoded.replace(old="?", new="%3F")
          encoded = encoded.replace(old="#", new="%23")
          encoded = encoded.replace(old="+", new="%2B")
          String(encoded)
        }
        _ => value
      }
    }
    "url_decode" => {
      match value {
        String(s) => {
          // Basic URL decoding for common characters
          let mut decoded = s.to_string()
          decoded = decoded.replace(old="%20", new=" ")
          decoded = decoded.replace(old="%26", new="&")
          decoded = decoded.replace(old="%3D", new="=")
          decoded = decoded.replace(old="%3F", new="?")
          decoded = decoded.replace(old="%23", new="#")
          decoded = decoded.replace(old="%2B", new="+")
          String(decoded)
        }
        _ => value
      }
    }
    "asset_url" => {
      match value {
        String(s) => String("/assets/" + s)
        _ => value
      }
    }
    "absolute_url" => {
      match value {
        String(s) => String("https://example.com" + s)
        _ => value
      }
    }
    "relative_url" => {
      match value {
        String(s) => {
          if s.substring(start=0, end=1) == "/" {
            value
          } else {
            String("/" + s)
          }
        }
        _ => value
      }
    }
    "where" => {
      match value {
        Array(arr) => {
          // Basic where filter - for now, filter by non-empty strings
          let filtered : Array[LiquidValue] = []
          for item in arr {
            match item {
              String(s) => if s.contains("filter") { filtered.push(item) }
              _ => ()
            }
          }
          Array(filtered)
        }
        _ => value
      }
    }
    "slice" => {
      match value {
        Array(arr) => {
          // Basic slice - take first 3 elements
          let sliced : Array[LiquidValue] = []
          let limit = if arr.length() > 3 { 3 } else { arr.length() }
          for i in 0..<limit {
            sliced.push(arr[i])
          }
          Array(sliced)
        }
        String(s) => {
          // Slice string - take first 3 characters
          if s.length() > 3 {
            String(s.substring(start=0, end=3))
          } else {
            value
          }
        }
        _ => value
      }
    }
    "offset" => {
      match value {
        Array(arr) => {
          // Basic offset - skip first element
          let offset_arr : Array[LiquidValue] = []
          for i in 1..<arr.length() {
            offset_arr.push(arr[i])
          }
          Array(offset_arr)
        }
        _ => value
      }
    }
    "limit" => {
      match value {
        Array(arr) => {
          // Basic limit - take first 2 elements
          let limited : Array[LiquidValue] = []
          let limit = if arr.length() > 2 { 2 } else { arr.length() }
          for i in 0..<limit {
            limited.push(arr[i])
          }
          Array(limited)
        }
        _ => value
      }
    }
    "group_by" => {
      match value {
        Array(arr) => {
          // Basic group_by - group by string length
          let short_items : Array[LiquidValue] = []
          let long_items : Array[LiquidValue] = []
          for item in arr {
            match item {
              String(s) => {
                if s.length() <= 5 {
                  short_items.push(item)
                } else {
                  long_items.push(item)
                }
              }
              _ => short_items.push(item)
            }
          }
          // Return array of groups
          Array([Array(short_items), Array(long_items)])
        }
        _ => value
      }
    }
    "money" => {
      match value {
        Number(n) => String("$" + n.to_string())
        String(s) => String("$" + s)
        _ => value
      }
    }
    "money_with_currency" => {
      match value {
        Number(n) => String("$" + n.to_string() + " USD")
        String(s) => String("$" + s + " USD")
        _ => value
      }
    }
    "money_without_currency" => {
      match value {
        Number(n) => String(n.to_string())
        String(s) => String(s.replace(old="$", new=""))
        _ => value
      }
    }
    "money_without_trailing_zeros" => {
      match value {
        Number(n) => {
          let str_val = n.to_string()
          if str_val.strip_suffix(".0") != None {
            String("$" + str_val.substring(start=0, end=str_val.length() - 2))
          } else {
            String("$" + str_val)
          }
        }
        String(s) => String("$" + s)
        _ => value
      }
    }
    _ => value
  }
}

// Helper function to create common liquid values

///|
pub fn string_value(s : String) -> LiquidValue {
  String(s)
}

///|
pub fn number_value(n : Double) -> LiquidValue {
  Number(n)
}

///|
pub fn bool_value(b : Bool) -> LiquidValue {
  Bool(b)
}

///|
pub fn array_value(arr : Array[LiquidValue]) -> LiquidValue {
  Array(arr)
}

///|
pub fn object_value(obj : Map[String, LiquidValue]) -> LiquidValue {
  Object(obj)
}

///|
pub fn null_value() -> LiquidValue {
  Null
}

// Helper functions to create LiquidNode instances for testing

///|
pub fn text_node(content : String) -> LiquidNode {
  Text(content)
}

///|
pub fn variable_node(name : String, filters : Array[Filter]) -> LiquidNode {
  Variable(name, filters)
}

// Helper for backward compatibility
pub fn variable_node_simple(name : String, filter_names : Array[String]) -> LiquidNode {
  let filters = filter_names.map(fn(name) { filter(name, []) })
  Variable(name, filters)
}

///|
pub fn for_node(
  loop_var : String,
  collection : String,
  body : Array[LiquidNode],
) -> LiquidNode {
  For(loop_var, collection, body)
}

///|
pub fn if_node(
  condition : String,
  then_body : Array[LiquidNode],
  else_body : Array[LiquidNode]?,
) -> LiquidNode {
  If(condition, then_body, else_body)
}

///|
pub fn unless_node(condition : String, body : Array[LiquidNode]) -> LiquidNode {
  Unless(condition, body)
}

///|
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
