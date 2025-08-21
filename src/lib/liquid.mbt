// Core data structures for Liquid values
pub enum LiquidValue {
  String(String)
  Number(Double)
  Bool(Bool)
  Array(Array[LiquidValue])
  Object(Map[String, LiquidValue])
  Null
}

// Convert LiquidValue to string representation
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
      let pairs = obj.iter().map(fn(entry) { 
        let (key, value) = entry
        "\"" + key + "\": " + value.to_string() 
      }).collect()
      "{" + pairs.join(", ") + "}"
    }
    Null => "null"
  }
}

// Context for variable storage
pub struct LiquidContext {
  variables : Map[String, LiquidValue]
}

pub fn LiquidContext::new() -> LiquidContext {
  { variables: Map::new() }
}

pub fn set(self : LiquidContext, key : String, value : LiquidValue) -> Unit {
  self.variables[key] = value
}

pub fn get(self : LiquidContext, key : String) -> LiquidValue? {
  self.variables.get(key)
}

// Template structure
pub enum LiquidNode {
  Text(String)
  Variable(String, Array[String])  // variable_name, filters
  For(String, String, Array[LiquidNode])  // variable, collection, body
  If(String, Array[LiquidNode], Array[LiquidNode]?)  // condition, then_body, else_body
}

// Simple template parser
pub struct LiquidTemplate {
  nodes : Array[LiquidNode]
}

pub fn LiquidTemplate::new() -> LiquidTemplate {
  { nodes: [] }
}

pub fn parse(template : String) -> LiquidTemplate {
  let parsed_nodes = parse_template(template)
  { nodes: parsed_nodes }
}

fn parse_template(template : String) -> Array[LiquidNode] {
  let nodes : Array[LiquidNode] = []
  let mut current = 0
  let len = template.length()
  
  while current < len {
    // Find next liquid tag from current position
    let remaining = template.substring(start=current)
    match remaining.find("{{") {
      Some(relative_start) => {
        let start = current + relative_start
        
        // Add text before tag
        if start > current {
          let text = template.substring(start=current, end=start)
          nodes.push(Text(text))
        }
        
        // Find end of tag
        let search_start = start + 2
        let tag_remaining = template.substring(start=search_start)
        match tag_remaining.find("}}") {
          Some(relative_end) => {
            let end = search_start + relative_end
            let tag_content = template.substring(start=start + 2, end=end)
            let trimmed_content = tag_content.to_string()
            
            // Parse variable and filters
            let parts = trimmed_content.split("|").collect()
            let variable_name = parts[0].to_string().trim(" \t").to_string()
            let filters = if parts.length() > 1 {
              let filter_parts : Array[String] = []
              for i in 1..<parts.length() {
                filter_parts.push(parts[i].to_string().trim(" \t").to_string())
              }
              filter_parts
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
      None => {
        // No more tags, add remaining text
        if current < len {
          nodes.push(Text(template.substring(start=current)))
        }
        break
      }
    }
  }
  
  nodes
}

// Template renderer
pub fn render(self : LiquidTemplate, context : LiquidContext) -> String {
  let mut result = ""
  for node in self.nodes {
    result = result + render_node(node, context)
  }
  result
}

fn render_node(node : LiquidNode, context : LiquidContext) -> String {
  match node {
    Text(text) => text
    Variable(var_name, filters) => {
      match context.get(var_name) {
        Some(value) => {
          let mut result = value
          for filter in filters {
            result = apply_filter(result, filter)
          }
          result.to_string()
        }
        None => ""
      }
    }
    For(loop_var, collection, body) => {
      match context.get(collection) {
        Some(Array(items)) => {
          let mut output = ""
          for item in items {
            let loop_context = context
            loop_context.set(loop_var, item)
            for body_node in body {
              output = output + render_node(body_node, loop_context)
            }
          }
          output
        }
        _ => ""
      }
    }
    If(condition, then_body, else_body) => {
      let condition_result = evaluate_condition(condition, context)
      let body_to_render = if condition_result { then_body } else {
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
  }
}

pub fn evaluate_condition(condition : String, context : LiquidContext) -> Bool {
  // Simple condition evaluation - just check if variable is truthy
  let trimmed_condition = condition.to_string()
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

// Built-in filters
pub fn apply_filter(value : LiquidValue, filter : String) -> LiquidValue {
  let trimmed_filter = filter.to_string()
  match trimmed_filter {
    "upcase" => {
      match value {
        String(s) => String(s.to_upper())
        _ => value
      }
    }
    "downcase" => {
      match value {
        String(s) => String(s.to_lower())
        _ => value
      }
    }
    "trim" => {
      match value {
        String(s) => String(s.to_string())
        _ => value
      }
    }
    "size" => {
      match value {
        String(s) => Number(s.length().to_double())
        Array(arr) => Number(arr.length().to_double())
        Object(obj) => Number(obj.size().to_double())
        _ => Number(0.0)
      }
    }
    _ => value
  }
}

// Helper function to create common liquid values
pub fn string_value(s : String) -> LiquidValue {
  String(s)
}

pub fn number_value(n : Double) -> LiquidValue {
  Number(n)
}

pub fn bool_value(b : Bool) -> LiquidValue {
  Bool(b)
}

pub fn array_value(arr : Array[LiquidValue]) -> LiquidValue {
  Array(arr)
}

pub fn object_value(obj : Map[String, LiquidValue]) -> LiquidValue {
  Object(obj)
}

pub fn null_value() -> LiquidValue {
  Null
}