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
  Unless(String, Array[LiquidNode])  // condition, body
  Case(String, Array[(String, Array[LiquidNode])], Array[LiquidNode]?)  // expression, when_branches, else_body
  Assign(String, String)  // variable_name, expression
  Comment(String)  // comment content
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
    // Find next liquid tag from current position (either {{ or {% )
    let remaining = template.substring(start=current)
    let variable_tag = remaining.find("{{")
    let logic_tag = remaining.find("{%")
    
    // Determine which tag comes first
    let (tag_start, tag_type) = match (variable_tag, logic_tag) {
      (Some(var_pos), Some(logic_pos)) => 
        if var_pos < logic_pos { (var_pos, "variable") } else { (logic_pos, "logic") }
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
      "logic" => {
        let search_start = start + 2
        let tag_remaining = template.substring(start=search_start)
        match tag_remaining.find("%}") {
          Some(relative_end) => {
            let end = search_start + relative_end
            let tag_content = template.substring(start=start + 2, end=end)
            let trimmed_content = tag_content.to_string().trim(" \t").to_string()
            
            // Parse logic tag (for now, just treat as comment)
            if trimmed_content.strip_prefix("comment") != None {
              nodes.push(Comment(trimmed_content))
            } else {
              // For now, treat unknown logic tags as comments
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
      _ => {
        current = current + 1
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
    Unless(condition, body) => {
      let condition_result = evaluate_condition(condition, context)
      if condition_result {
        ""  // Unless renders body only when condition is false
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
      // For now, just assign the expression as a string literal
      // Later we'll parse expressions properly
      context.set(var_name, string_value(expression))
      ""  // Assign doesn't produce output
    }
    Comment(_) => ""  // Comments don't produce output
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
    "trim" | "strip" => {
      match value {
        String(s) => String(s.trim(" \t\n\r").to_string())
        _ => value
      }
    }
    "size" | "length" => {
      match value {
        String(s) => Number(s.length().to_double())
        Array(arr) => Number(arr.length().to_double())
        Object(obj) => Number(obj.size().to_double())
        _ => Number(0.0)
      }
    }
    "first" => {
      match value {
        Array(arr) => if arr.length() > 0 { arr[0] } else { Null }
        String(s) => if s.length() > 0 { String(s.substring(start=0, end=1)) } else { Null }
        _ => Null
      }
    }
    "last" => {
      match value {
        Array(arr) => if arr.length() > 0 { arr[arr.length() - 1] } else { Null }
        String(s) => if s.length() > 0 { String(s.substring(start=s.length() - 1)) } else { Null }
        _ => Null
      }
    }
    "reverse" => {
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
    }
    "sort" => {
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
    }
    "join" => {
      match value {
        Array(arr) => {
          let str_items = arr.map(fn(item) { item.to_string() })
          String(str_items.join(", "))
        }
        _ => value
      }
    }
    "default" => {
      match value {
        Null => String("") // Default to empty string if no parameter provided
        String(s) => if s == "" { String("default") } else { value }
        _ => value
      }
    }
    "escape" => {
      match value {
        String(s) => {
          let escaped = s.to_string()
            .replace(old="&", new="&amp;")
            .replace(old="<", new="&lt;")
            .replace(old=">", new="&gt;")
            .replace(old="\"", new="&quot;")
            .replace(old="'", new="&#39;")
          String(escaped)
        }
        _ => value
      }
    }
    "truncate" => {
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
    }
    "plus" => {
      match value {
        Number(n) => Number(n + 1.0) // Default increment by 1
        String(_) => value
        _ => value
      }
    }
    "minus" => {
      match value {
        Number(n) => Number(n - 1.0) // Default decrement by 1
        String(_) => value
        _ => value
      }
    }
    "times" => {
      match value {
        Number(n) => Number(n * 2.0) // Default multiply by 2
        String(_) => value
        _ => value
      }
    }
    "divided_by" => {
      match value {
        Number(n) => Number(n / 2.0) // Default divide by 2
        String(_) => value
        _ => value
      }
    }
    "modulo" => {
      match value {
        Number(n) => Number(n % 2.0) // Default modulo 2
        String(_) => value
        _ => value
      }
    }
    "round" => {
      match value {
        Number(n) => Number(n.round())
        String(_) => value
        _ => value
      }
    }
    "ceil" => {
      match value {
        Number(n) => Number(n.ceil())
        String(_) => value
        _ => value
      }
    }
    "floor" => {
      match value {
        Number(n) => Number(n.floor())
        String(_) => value
        _ => value
      }
    }
    "abs" => {
      match value {
        Number(n) => Number(n.abs())
        String(_) => value
        _ => value
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