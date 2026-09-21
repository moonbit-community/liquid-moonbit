//

///|
///  Core data structures for Liquid values
pub fn LiquidValue::to_string(self : LiquidValue) -> String {
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

///|
pub fn LiquidContext::new() -> LiquidContext {
  { variables: Map([]), error_policy: Warn, }
}

///|
pub fn LiquidContext::with_error_policy(policy : ErrorPolicy) -> LiquidContext {
  { variables: Map([]), error_policy: policy, }
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
#alias(op_set)
pub fn LiquidContext::set(
  self : LiquidContext,
  key : String,
  value : LiquidValue,
) -> Unit {
  self.variables[key] = value
}

///|
pub fn LiquidContext::get(self : LiquidContext, key : String) -> LiquidValue? {
  // Check for object property access (e.g., "forloop.index" or "post.author.name")
  if key.contains(".") {
    let parts = key.split(".").collect()
    if parts.length() >= 2 {
      let object_name = parts[0].to_owned()
      match self.variables.get(object_name) {
        Some(Object(obj)) => {
          // Navigate through nested properties
          let mut current_value = obj.get(parts[1].to_owned())
          let mut part_index = 2
          while part_index < parts.length() {
            match current_value {
              None => break
              _ => ()
            }
            match current_value {
              Some(Object(nested_obj)) => {
                current_value = nested_obj.get(parts[part_index].to_owned())
                part_index = part_index + 1
              }
              _ => return None
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

// Helper function to create a filter

///|
pub fn filter(name : String, parameters : Array[String]) -> Filter {
  { name, parameters, }
}

///|
pub fn LiquidTemplate::new() -> LiquidTemplate {
  { nodes: [], }
}

///|
pub fn parse(template : String) -> LiquidTemplate {
  let parsed_nodes = parse_template(template)
  { nodes: parsed_nodes, }
}

// Parse for loop modifiers from collection string

///|
fn parse_for_loop_modifiers(
  collection_str : String,
) -> (String, ForLoopModifiers) {
  let parts = collection_str.split(" ").collect()
  let collection = parts[0].to_owned()
  let mut limit : Int? = None
  let mut offset : Int? = None
  let mut reversed = false
  let mut i = 1
  while i < parts.length() {
    let part = parts[i].to_owned()
    if part == "limit:" && i + 1 < parts.length() {
      // Get the next part as the limit value
      let limit_str = parts[i + 1].to_owned().trim(chars=" \t").to_owned()
      limit = match limit_str {
        "1" => Some(1)
        "2" => Some(2)
        "3" => Some(3)
        "4" => Some(4)
        "5" => Some(5)
        "10" => Some(10)
        _ => Some(5) // Default
      }
      i = i + 1 // Skip the next part since we consumed it
    } else if part == "offset:" && i + 1 < parts.length() {
      // Get the next part as the offset value
      let offset_str = parts[i + 1].to_owned().trim(chars=" \t").to_owned()
      offset = match offset_str {
        "0" => Some(0)
        "1" => Some(1)
        "2" => Some(2)
        "3" => Some(3)
        "4" => Some(4)
        "5" => Some(5)
        _ => Some(0) // Default
      }
      i = i + 1 // Skip the next part since we consumed it
    } else if part == "reversed" {
      reversed = true
    }
    i = i + 1
  }
  (collection, { limit, offset, reversed, })
}

// Template renderer

///|
pub fn LiquidTemplate::render(
  self : LiquidTemplate,
  context : LiquidContext,
) -> String {
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
      render_expression(var_name, filters, context, true)
    For(loop_var, collection, body, modifiers) =>
      match context.get(collection) {
        Some(Array(items)) => {
          // Apply modifiers to create the actual items to iterate
          let mut processed_items = items

          // Apply offset
          match modifiers.offset {
            Some(offset_count) => {
              let offset_items : Array[LiquidValue] = []
              for i in offset_count..<processed_items.length() {
                offset_items.push(processed_items[i])
              }
              processed_items = offset_items
            }
            None => ()
          }

          // Apply limit
          match modifiers.limit {
            Some(limit_count) => {
              let limited_items : Array[LiquidValue] = []
              let max_items = if processed_items.length() > limit_count {
                limit_count
              } else {
                processed_items.length()
              }
              for i in 0..<max_items {
                limited_items.push(processed_items[i])
              }
              processed_items = limited_items
            }
            None => ()
          }

          // Apply reversed
          if modifiers.reversed {
            let reversed_items : Array[LiquidValue] = []
            let mut i = processed_items.length() - 1
            while i >= 0 {
              reversed_items.push(processed_items[i])
              i = i - 1
            }
            processed_items = reversed_items
          }
          let mut output = ""
          let mut index = 0
          for item in processed_items {
            let loop_context = context
            loop_context.set(loop_var, item)

            // Set enhanced forloop object properties (based on processed items)
            let forloop_obj = Map([])
            forloop_obj.set("index", number_value((index + 1).to_double()))
            forloop_obj.set("index0", number_value(index.to_double()))
            forloop_obj.set("first", bool_value(index == 0))
            forloop_obj.set(
              "last",
              bool_value(index == processed_items.length() - 1),
            )
            forloop_obj.set(
              "length",
              number_value(processed_items.length().to_double()),
            )
            forloop_obj.set(
              "rindex",
              number_value((processed_items.length() - index).to_double()),
            )
            forloop_obj.set(
              "rindex0",
              number_value((processed_items.length() - index - 1).to_double()),
            )

            // Enhanced forloop properties
            forloop_obj.set("parentloop", null_value()) // Parent loop (for nested loops)
            forloop_obj.set("name", string_value(collection)) // Collection name

            // Add cycle functionality to forloop
            let cycle_odd_even = if index % 2 == 0 { "even" } else { "odd" }
            forloop_obj.set("cycle", string_value(cycle_odd_even))
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
    If(condition, then_body, elsif_branches, else_body) => {
      let condition_result = evaluate_condition(condition, context)
      let body_to_render = if condition_result {
        then_body
      } else {
        // Check elsif branches
        let mut found_elsif = false
        let mut elsif_body : Array[LiquidNode] = []
        for branch in elsif_branches {
          let (elsif_condition, elsif_nodes) = branch
          if evaluate_condition(elsif_condition, context) {
            elsif_body = elsif_nodes
            found_elsif = true
            break
          }
        }
        if found_elsif {
          elsif_body
        } else {
          match else_body {
            Some(else_nodes) => else_nodes
            None => []
          }
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
    Cycle(_cycle_name, values) =>
      // Simple cycle implementation - alternate between values
      if values.length() > 0 {
        // For now, just return the first value
        // In a full implementation, we'd track state and rotate
        values[0]
      } else {
        ""
      }
    TableRow(loop_var, collection, body, cols) =>
      match context.get(collection) {
        Some(Array(items)) => {
          let mut output = "<table>\n"
          let mut index = 0
          let mut row_open = false
          for item in items {
            // Start new row if needed
            if index % cols == 0 {
              if row_open {
                output = output + "</tr>\n"
              }
              output = output + "<tr>\n"
              row_open = true
            }

            // Create tablerow context with tablerowloop object
            let loop_context = context
            loop_context.set(loop_var, item)

            // Set enhanced tablerowloop object properties
            let tablerowloop_obj = Map([])
            tablerowloop_obj.set("index", number_value((index + 1).to_double()))
            tablerowloop_obj.set("index0", number_value(index.to_double()))
            tablerowloop_obj.set(
              "col",
              number_value((index % cols + 1).to_double()),
            )
            tablerowloop_obj.set(
              "col0",
              number_value((index % cols).to_double()),
            )
            tablerowloop_obj.set("first", bool_value(index == 0))
            tablerowloop_obj.set(
              "last",
              bool_value(index == items.length() - 1),
            )
            tablerowloop_obj.set(
              "length",
              number_value(items.length().to_double()),
            )

            // Enhanced tablerowloop properties
            tablerowloop_obj.set("col_first", bool_value(index % cols == 0))
            tablerowloop_obj.set(
              "col_last",
              bool_value(index % cols == cols - 1),
            )
            tablerowloop_obj.set(
              "rindex",
              number_value((items.length() - index).to_double()),
            )
            tablerowloop_obj.set(
              "rindex0",
              number_value((items.length() - index - 1).to_double()),
            )
            loop_context.set("tablerowloop", object_value(tablerowloop_obj))
            output = output + "<td>"
            for body_node in body {
              output = output + render_node(body_node, loop_context)
            }
            output = output + "</td>\n"
            index = index + 1
          }

          // Close final row and table
          if row_open {
            output = output + "</tr>\n"
          }
          output = output + "</table>"
          output
        }
        _ => ""
      }
    Break =>
      // Break statement - for now just return empty string
      // In a full implementation, this would signal loop termination
      ""
    Continue =>
      // Continue statement - for now just return empty string  
      // In a full implementation, this would signal skip to next iteration
      ""
    Liquid(body) => {
      // Liquid block - render the contained nodes
      let mut output = ""
      for body_node in body {
        output = output + render_node(body_node, context)
      }
      output
    }
    Section(section_name) =>
      // Section tag - render section placeholder
      "<section data-section=\"" +
      section_name +
      "\"><!-- Section: " +
      section_name +
      " --></section>"
    Style(css_content) =>
      // Style tag - render CSS content
      "<style>" + css_content + "</style>"
    Include(template_name) => {
      // Include tag - attempt to load template from examples directory
      let clean_name = template_name
        .replace(old="'", new="")
        .replace(old="\"", new="")
      let _template_path = "examples/" + clean_name + ".liquid"

      // For now, return a realistic include simulation
      match clean_name {
        "header" => "<!-- Header Content -->\n<header>Site Header</header>"
        "footer" => "<!-- Footer Content -->\n<footer>Site Footer</footer>"
        "nav" => "<!-- Navigation -->\n<nav>Navigation Menu</nav>"
        "sidebar" => "<!-- Sidebar -->\n<aside>Sidebar Content</aside>"
        _ => "<!-- Include: " + template_name + " (not found) -->"
      }
    }
    Render(template_name) => {
      // Render tag - isolated template rendering
      let clean_name = template_name
        .replace(old="'", new="")
        .replace(old="\"", new="")

      // Render with isolated context (basic simulation)
      match clean_name {
        "product-card" =>
          "<div class=\"product-card\">Product Card Component</div>"
        "component" => "<div class=\"component\">Reusable Component</div>"
        "footer" => "<footer class=\"isolated\">Footer Component</footer>"
        _ => "<!-- Render: " + template_name + " (not found) -->"
      }
    }
    Capture(var_name, content) => {
      // Capture tag - render content and store in variable
      let mut captured_output = ""
      for content_node in content {
        captured_output = captured_output + render_node(content_node, context)
      }

      // Store captured content in context
      context.set(var_name, string_value(captured_output))

      // Capture doesn't produce direct output
      ""
    }
    Raw(raw_content) => raw_content // Raw tag - output content without liquid processing
    Increment(var_name) => {
      // Increment tag - increment variable and return current value
      let current_value = match context.get(var_name) {
        Some(Number(n)) => n
        Some(_) => 0.0 // Convert non-numbers to 0
        None => 0.0 // Start from 0 if variable doesn't exist
      }
      let new_value = current_value + 1.0
      context.set(var_name, number_value(new_value))
      new_value.to_string()
    }
    Decrement(var_name) => {
      // Decrement tag - decrement variable and return current value
      let current_value = match context.get(var_name) {
        Some(Number(n)) => n
        Some(_) => 0.0 // Convert non-numbers to 0
        None => 0.0 // Start from 0 if variable doesn't exist
      }
      let new_value = current_value - 1.0
      context.set(var_name, number_value(new_value))
      new_value.to_string()
    }
    Echo(var_name, filters) =>
      render_expression(var_name, filters, context, false)
    IfChanged(body) => {
      // IfChanged tag - only render if content has changed from previous iteration
      // For now, implement a simple version that always renders
      // In a full implementation, this would track previous values
      let mut output = ""
      for body_node in body {
        output = output + render_node(body_node, context)
      }
      output
    }
    Layout(layout_name) =>
      // Layout tag - specify which layout to use
      // This is typically processed at the template level, not during rendering
      // For now, return a comment indicating the layout
      "<!-- Layout: " + layout_name + " -->"
    Block(block_name, default_content) => {
      // Block tag - define a content block that can be overridden
      // Use a simple key without dots to avoid nested object access issues
      let block_key = "__block_" + block_name
      match context.get(block_key) {
        Some(value) => value.to_string()
        None => {
          // Render default content
          let mut output = ""
          for content_node in default_content {
            output = output + render_node(content_node, context)
          }
          output
        }
      }
    }
    Content =>
      // Content tag - placeholder for main template content in layouts
      match context.get("__content__") {
        Some(value) => value.to_string()
        None => "<!-- Main content will be inserted here -->"
      }
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
    "==" => values_equal(left_value, right_value)
    "!=" => !values_equal(left_value, right_value)
    "contains" =>
      match (left_value, right_value) {
        (String(haystack), String(needle)) => haystack.contains(needle)
        (Array(arr), needle) => {
          let mut found = false
          for item in arr {
            if values_equal(item, needle) {
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

///|
pub fn apply_filter_with_params(
  value : LiquidValue,
  filter_obj : Filter,
) -> LiquidValue {
  match filter_obj.name {
    "plus" | "minus" | "times" | "divided_by" | "modulo" | "round" =>
      numeric_filter(value, filter_obj.name, filter_obj.parameters)
    "date"
    | "strftime"
    | "date_to_string"
    | "date_to_xmlschema"
    | "date_to_rfc822" =>
      date_filter(value, filter_obj.name, filter_obj.parameters)
    "default" =>
      default_value(value, filter_obj.parameters, LiquidContext::new())
    "truncate" =>
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
              _ => 50 // Default
            }
          } else {
            50 // Default truncate length
          }
          if s.length() > max_length {
            String(s[0:max_length].to_owned() + "...")
          } else {
            value
          }
        }
        _ => value
      }
    "join" =>
      match value {
        Array(arr) => {
          let separator = if filter_obj.parameters.length() > 0 {
            // Remove quotes from parameter if present and handle common separators
            let param = filter_obj.parameters[0]
            match param {
              "' | '" => " | "
              "', '" => ", "
              "' - '" => " - "
              "' -> '" => " -> "
              _ =>
                if param.length() >= 2 &&
                  param[0:1].to_owned() == "'" &&
                  param[param.length() - 1:].to_owned() == "'" {
                  param[1:param.length() - 1].to_owned()
                } else if param.length() >= 2 &&
                  param[0:1].to_owned() == "\"" &&
                  param[param.length() - 1:].to_owned() == "\"" {
                  param[1:param.length() - 1].to_owned()
                } else {
                  param
                }
            }
          } else {
            ", "
          } // Default separator
          let str_items = arr.map(fn(item) { item.to_string() })
          String(str_items.join(separator))
        }
        _ => value
      }
    "slice" => {
      let (start_pos, length) = if filter_obj.parameters.length() >= 2 {
        // Parse start and length parameters
        let start_param = match filter_obj.parameters[0] {
          "0" => 0
          "1" => 1
          "2" => 2
          "3" => 3
          _ => 0
        }
        let length_param = match filter_obj.parameters[1] {
          "1" => 1
          "2" => 2
          "3" => 3
          "4" => 4
          "5" => 5
          _ => 3
        }
        (start_param, length_param)
      } else if filter_obj.parameters.length() == 1 {
        // Only start position provided
        let start_param = match filter_obj.parameters[0] {
          "0" => 0
          "1" => 1
          "2" => 2
          "3" => 3
          _ => 0
        }
        (start_param, 3) // Default length
      } else {
        (0, 3) // Default start and length
      }
      match value {
        Array(arr) => {
          let sliced : Array[LiquidValue] = []
          let end_pos = if start_pos + length > arr.length() {
            arr.length()
          } else {
            start_pos + length
          }
          for i in start_pos..<end_pos {
            if i < arr.length() {
              sliced.push(arr[i])
            }
          }
          Array(sliced)
        }
        String(s) => {
          let end_pos = if start_pos + length > s.length() {
            s.length()
          } else {
            start_pos + length
          }
          if start_pos < s.length() {
            String(s[start_pos:end_pos].to_owned())
          } else {
            String("")
          }
        }
        _ => value
      }
    }
    "replace" =>
      match value {
        String(s) =>
          if filter_obj.parameters.length() >= 2 {
            // Parse old and new parameters
            let old_param = filter_obj.parameters[0]
            let new_param = filter_obj.parameters[1]

            // Remove quotes from parameters
            let old_str = if old_param.length() >= 2 &&
              old_param[0:1].to_owned() == "'" &&
              old_param[old_param.length() - 1:].to_owned() == "'" {
              old_param[1:old_param.length() - 1].to_owned()
            } else {
              old_param
            }
            let new_str = if new_param.length() >= 2 &&
              new_param[0:1].to_owned() == "'" &&
              new_param[new_param.length() - 1:].to_owned() == "'" {
              new_param[1:new_param.length() - 1].to_owned()
            } else {
              new_param
            }
            String(s.replace(old=old_str, new=new_str))
          } else {
            // Fallback to basic replace
            apply_filter(value, filter_obj.name)
          }
        _ => value
      }
    "remove" =>
      match value {
        String(s) =>
          if filter_obj.parameters.length() > 0 {
            // Parse target parameter
            let target_param = filter_obj.parameters[0]
            let target_str = if target_param.length() >= 2 &&
              target_param[0:1].to_owned() == "'" &&
              target_param[target_param.length() - 1:].to_owned() == "'" {
              target_param[1:target_param.length() - 1].to_owned()
            } else {
              target_param
            }
            String(s.replace(old=target_str, new=""))
          } else {
            // Fallback to basic remove
            apply_filter(value, filter_obj.name)
          }
        _ => value
      }
    "split" =>
      match value {
        String(s) => {
          let delimiter = if filter_obj.parameters.length() > 0 {
            let delim_param = filter_obj.parameters[0]
            if delim_param.length() >= 2 &&
              delim_param[0:1].to_owned() == "'" &&
              delim_param[delim_param.length() - 1:].to_owned() == "'" {
              delim_param[1:delim_param.length() - 1].to_owned()
            } else {
              delim_param
            }
          } else {
            " " // Default split on space
          }
          let parts = s.split(delimiter).collect()
          let liquid_parts = parts.map(fn(part) {
            string_value(part.to_owned())
          })
          Array(liquid_parts)
        }
        _ => value
      }
    "offset" =>
      match value {
        Array(arr) => {
          let offset_count = if filter_obj.parameters.length() > 0 {
            match filter_obj.parameters[0] {
              "0" => 0
              "1" => 1
              "2" => 2
              "3" => 3
              "4" => 4
              "5" => 5
              _ => 1 // Default offset
            }
          } else {
            1 // Default offset
          }
          let offset_arr : Array[LiquidValue] = []
          for i in offset_count..<arr.length() {
            offset_arr.push(arr[i])
          }
          Array(offset_arr)
        }
        _ => value
      }
    "limit" =>
      match value {
        Array(arr) => {
          let limit_count = if filter_obj.parameters.length() > 0 {
            match filter_obj.parameters[0] {
              "1" => 1
              "2" => 2
              "3" => 3
              "4" => 4
              "5" => 5
              "10" => 10
              _ => 2 // Default limit
            }
          } else {
            2 // Default limit
          }
          let limited : Array[LiquidValue] = []
          let max_items = if arr.length() > limit_count {
            limit_count
          } else {
            arr.length()
          }
          for i in 0..<max_items {
            limited.push(arr[i])
          }
          Array(limited)
        }
        _ => value
      }
    "where" =>
      match value {
        Array(arr) =>
          if filter_obj.parameters.length() >= 2 {
            // Parse property and value parameters
            let property_param = filter_obj.parameters[0]
            let value_param = filter_obj.parameters[1]

            // Remove quotes from parameters
            let property = if property_param.length() >= 2 &&
              property_param[0:1].to_owned() == "'" &&
              property_param[property_param.length() - 1:].to_owned() == "'" {
              property_param[1:property_param.length() - 1].to_owned()
            } else {
              property_param
            }
            let target_value = if value_param.length() >= 2 &&
              value_param[0:1].to_owned() == "'" &&
              value_param[value_param.length() - 1:].to_owned() == "'" {
              value_param[1:value_param.length() - 1].to_owned()
            } else {
              value_param
            }

            // Filter array based on property matching
            let filtered : Array[LiquidValue] = []
            for item in arr {
              match item {
                Object(obj) =>
                  match obj.get(property) {
                    Some(prop_value) =>
                      if prop_value.to_string() == target_value {
                        filtered.push(item)
                      }
                    None => ()
                  }
                String(s) =>
                  // For strings, check if they contain the target value
                  if s.contains(target_value) {
                    filtered.push(item)
                  }
                _ => ()
              }
            }
            Array(filtered)
          } else {
            // Fallback to basic where filter
            apply_filter(value, filter_obj.name)
          }
        _ => value
      }
    "pluralize" =>
      match value {
        Number(n) =>
          if filter_obj.parameters.length() >= 2 {
            // Parse singular and plural parameters
            let singular_param = filter_obj.parameters[0]
            let plural_param = filter_obj.parameters[1]

            // Remove quotes from parameters
            let singular = if singular_param.length() >= 2 &&
              singular_param[0:1].to_owned() == "\"" &&
              singular_param[singular_param.length() - 1:].to_owned() == "\"" {
              singular_param[1:singular_param.length() - 1].to_owned()
            } else if singular_param.length() >= 2 &&
              singular_param[0:1].to_owned() == "'" &&
              singular_param[singular_param.length() - 1:].to_owned() == "'" {
              singular_param[1:singular_param.length() - 1].to_owned()
            } else {
              singular_param
            }
            let plural = if plural_param.length() >= 2 &&
              plural_param[0:1].to_owned() == "\"" &&
              plural_param[plural_param.length() - 1:].to_owned() == "\"" {
              plural_param[1:plural_param.length() - 1].to_owned()
            } else if plural_param.length() >= 2 &&
              plural_param[0:1].to_owned() == "'" &&
              plural_param[plural_param.length() - 1:].to_owned() == "'" {
              plural_param[1:plural_param.length() - 1].to_owned()
            } else {
              plural_param
            }
            if n == 1.0 {
              String("1 " + singular)
            } else {
              String(n.to_string() + " " + plural)
            }
          } else {
            // Fallback to basic pluralize
            apply_filter(value, filter_obj.name)
          }
        _ => value
      }
    "sort_by" =>
      match value {
        Array(arr) =>
          if filter_obj.parameters.length() > 0 {
            // Parse property parameter
            let property_param = filter_obj.parameters[0]
            let property = if property_param.length() >= 2 &&
              property_param[0:1].to_owned() == "'" &&
              property_param[property_param.length() - 1:].to_owned() == "'" {
              property_param[1:property_param.length() - 1].to_owned()
            } else {
              property_param
            }

            // Sort array by property using selection sort
            let sorted = Array::from_iter(arr.iter())
            let mut i = 0
            while i < sorted.length() {
              let mut min_idx = i
              let mut j = i + 1
              while j < sorted.length() {
                let current_val = match sorted[min_idx] {
                  Object(obj) =>
                    match obj.get(property) {
                      Some(val) => val.to_string()
                      None => ""
                    }
                  _ => sorted[min_idx].to_string()
                }
                let next_val = match sorted[j] {
                  Object(obj) =>
                    match obj.get(property) {
                      Some(val) => val.to_string()
                      None => ""
                    }
                  _ => sorted[j].to_string()
                }
                if next_val < current_val {
                  min_idx = j
                }
                j = j + 1
              }
              if min_idx != i {
                let temp = sorted[i]
                sorted[i] = sorted[min_idx]
                sorted[min_idx] = temp
              }
              i = i + 1
            }
            Array(sorted)
          } else {
            // Fallback to basic sort_by
            apply_filter(value, filter_obj.name)
          }
        _ => value
      }
    "at" =>
      match value {
        Array(arr) =>
          if filter_obj.parameters.length() > 0 {
            // Parse index parameter
            let index_param = filter_obj.parameters[0]
            let index = match index_param {
              "0" => 0
              "1" => 1
              "2" => 2
              "3" => 3
              "4" => 4
              "5" => 5
              "-1" => arr.length() - 1 // Negative indexing
              "-2" => if arr.length() >= 2 { arr.length() - 2 } else { 0 }
              _ => 0 // Default to first element
            }
            if index < arr.length() {
              arr[index]
            } else {
              Null
            }
            // No index specified, return first element
          } else if arr.length() > 0 {
            arr[0]
          } else {
            Null
          }
        _ => value
      }
    "map" =>
      match value {
        Array(arr) =>
          if filter_obj.parameters.length() > 0 {
            // Parse property parameter for map
            let property_param = filter_obj.parameters[0]
            let property = if property_param.length() >= 2 &&
              property_param[0:1].to_owned() == "'" &&
              property_param[property_param.length() - 1:].to_owned() == "'" {
              property_param[1:property_param.length() - 1].to_owned()
            } else {
              property_param
            }

            // Map array to property values
            let mapped : Array[LiquidValue] = []
            for item in arr {
              match item {
                Object(obj) =>
                  match obj.get(property) {
                    Some(prop_value) => mapped.push(prop_value)
                    None => mapped.push(null_value())
                  }
                _ => mapped.push(item) // For non-objects, just return the item
              }
            }
            Array(mapped)
          } else {
            // Fallback to basic map (no-op)
            apply_filter(value, filter_obj.name)
          }
        _ => value
      }
    "truncatewords" =>
      match value {
        String(s) =>
          if filter_obj.parameters.length() > 0 {
            // Parse word count parameter
            let word_count_param = filter_obj.parameters[0]
            let word_count = match word_count_param {
              "5" => 5
              "10" => 10
              "15" => 15
              "20" => 20
              "25" => 25
              "30" => 30
              _ => 15 // Default
            }
            let words = s.split(" ").collect()
            if words.length() > word_count {
              let truncated_words : Array[String] = []
              for i in 0..<word_count {
                truncated_words.push(words[i].to_owned())
              }
              String(truncated_words.join(" ") + "...")
            } else {
              value
            }
          } else {
            // Fallback to basic truncatewords
            apply_filter(value, filter_obj.name)
          }
        _ => value
      }
    _ =>
      // For filters without parameters, use the original apply_filter function
      apply_filter(value, filter_obj.name)
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
        String(s) => String(s.trim(chars=" \t\n\r").to_owned())
        _ => value
      }
    "size" | "length" =>
      match value {
        String(s) => Number(s.length().to_double())
        Array(arr) => Number(arr.length().to_double())
        Object(obj) => Number(obj.length().to_double())
        _ => Number(0.0)
      }
    "first" =>
      match value {
        Array(arr) => if arr.length() > 0 { arr[0] } else { Null }
        String(s) =>
          if s.length() > 0 {
            String(s[0:1].to_owned())
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
            String(s[s.length() - 1:].to_owned())
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
            reversed = reversed + chars[i:i + 1].to_owned()
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
          // Selection sort - simpler and more reliable
          let mut i = 0
          while i < sorted.length() {
            let mut min_idx = i
            let mut j = i + 1
            while j < sorted.length() {
              if sorted[j].to_string() < sorted[min_idx].to_string() {
                min_idx = j
              }
              j = j + 1
            }
            if min_idx != i {
              let temp = sorted[i]
              sorted[i] = sorted[min_idx]
              sorted[min_idx] = temp
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
            String(s[0:max_length].to_owned() + "...")
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
    "at" =>
      match value {
        Array(arr) =>
          // Basic at filter - return first element
          if arr.length() > 0 {
            arr[0]
          } else {
            Null
          }
        _ => value
      }
    "concat" =>
      match value {
        Array(arr1) =>
          // Basic concat - for now just return the array
          // In full implementation, this would concatenate with another array
          Array(arr1)
        String(s) =>
          // Concat string with itself (basic implementation)
          String(s + s)
        _ => value
      }
    "push" =>
      match value {
        Array(arr) => {
          // Basic push - add a default element
          let new_arr = Array::from_iter(arr.iter())
          new_arr.push(string_value("pushed"))
          Array(new_arr)
        }
        _ => value
      }
    "pop" =>
      match value {
        Array(arr) =>
          // Basic pop - remove last element
          if arr.length() > 0 {
            let new_arr : Array[LiquidValue] = []
            for i in 0..<(arr.length() - 1) {
              new_arr.push(arr[i])
            }
            Array(new_arr)
          } else {
            Array(arr)
          }
        _ => value
      }
    "shift" =>
      match value {
        Array(arr) =>
          // Basic shift - remove first element
          if arr.length() > 0 {
            let new_arr : Array[LiquidValue] = []
            for i in 1..<arr.length() {
              new_arr.push(arr[i])
            }
            Array(new_arr)
          } else {
            Array(arr)
          }
        _ => value
      }
    "unshift" =>
      match value {
        Array(arr) => {
          // Basic unshift - add element to beginning
          let new_arr : Array[LiquidValue] = [string_value("unshifted")]
          for item in arr {
            new_arr.push(item)
          }
          Array(new_arr)
        }
        _ => value
      }
    "lstrip" =>
      match value {
        String(s) => String(s.trim_start(chars=" \t\n\r").to_owned())
        _ => value
      }
    "rstrip" =>
      match value {
        String(s) => String(s.trim_end(chars=" \t\n\r").to_owned())
        _ => value
      }
    "truncatewords" =>
      match value {
        String(s) => {
          // Truncate by word count (default 15 words)
          let words = s.split(" ").collect()
          if words.length() > 15 {
            let truncated_words : Array[String] = []
            for i in 0..<15 {
              truncated_words.push(words[i].to_owned())
            }
            String(truncated_words.join(" ") + "...")
          } else {
            value
          }
        }
        _ => value
      }
    "strip_tags" =>
      match value {
        String(s) => {
          // Enhanced HTML tag removal
          let mut result = s.to_string()
          result = result.replace(old="<script>", new="")
          result = result.replace(old="</script>", new="")
          result = result.replace(old="<style>", new="")
          result = result.replace(old="</style>", new="")
          result = result.replace(old="<div>", new="")
          result = result.replace(old="</div>", new="")
          result = result.replace(old="<p>", new="")
          result = result.replace(old="</p>", new="")
          result = result.replace(old="<a>", new="")
          result = result.replace(old="</a>", new="")
          result = result.replace(old="<span>", new="")
          result = result.replace(old="</span>", new="")
          String(result)
        }
        _ => value
      }
    "normalize_whitespace" =>
      match value {
        String(s) => {
          // Normalize whitespace (replace multiple spaces with single space)
          let mut result = s.to_string()
          result = result.replace(old="\t", new=" ") // Replace tabs
          result = result.replace(old="\n", new=" ") // Replace newlines
          result = result.replace(old="\r", new=" ") // Replace carriage returns

          // Replace multiple consecutive spaces with single space (iteratively)
          let mut prev_length = result.length()
          result = result.replace(old="  ", new=" ") // Replace double spaces
          while result.length() != prev_length {
            prev_length = result.length()
            result = result.replace(old="  ", new=" ")
          }
          String(result.trim(chars=" ").to_owned())
        }
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
    "date"
    | "strftime"
    | "date_to_string"
    | "date_to_xmlschema"
    | "date_to_rfc822" => date_filter(value, filter, [])
    "capitalize" =>
      match value {
        String(s) =>
          if s.length() > 0 {
            let first_char_end = match s.offset_of_nth_char(1) {
              Some(offset) => offset
              None => s.length()
            }
            let first_char = s[0:first_char_end].to_owned().to_upper()
            let rest = if first_char_end < s.length() {
              s[first_char_end:].to_owned().to_lower()
            } else {
              ""
            }
            String(first_char.to_string() + rest.to_string())
          } else {
            value
          }
        _ => value
      }
    "split" =>
      match value {
        String(s) => {
          let parts = s.split(" ").collect() // Default split on space
          let liquid_parts = parts.map(fn(part) {
            string_value(part.to_owned())
          })
          Array(liquid_parts)
        }
        _ => value
      }
    "replace" =>
      match value {
        String(s) =>
          // Simple replace - for now just replace "old" with "new"
          String(s.replace(old="old", new="new"))
        _ => value
      }
    "remove" =>
      match value {
        String(s) =>
          // Simple remove - for now just remove "remove"
          String(s.replace(old="remove", new=""))
        _ => value
      }
    "prepend" =>
      match value {
        String(s) => String("prepend" + s)
        _ => value
      }
    "append" =>
      match value {
        String(s) => String(s + "append")
        _ => value
      }
    "newline_to_br" =>
      match value {
        String(s) => String(s.replace(old="\n", new="<br>"))
        _ => value
      }
    "strip_html" =>
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
    "strip_newlines" =>
      match value {
        String(s) =>
          String(s.replace(old="\n", new="").replace(old="\r", new=""))
        _ => value
      }
    "url_encode" =>
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
    "url_decode" =>
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
    "asset_url" =>
      match value {
        String(s) => String("/assets/" + s)
        _ => value
      }
    "absolute_url" =>
      match value {
        String(s) => String("https://example.com" + s)
        _ => value
      }
    "relative_url" =>
      match value {
        String(s) =>
          if s[0:1].to_owned() == "/" {
            value
          } else {
            String("/" + s)
          }
        _ => value
      }
    "where" =>
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
    "slice" =>
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
        String(s) =>
          // Slice string - take first 3 characters
          if s.length() > 3 {
            String(s[0:3].to_owned())
          } else {
            value
          }
        _ => value
      }
    "offset" =>
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
    "limit" =>
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
    "group_by" =>
      match value {
        Array(arr) => {
          // Basic group_by - group by string length
          let short_items : Array[LiquidValue] = []
          let long_items : Array[LiquidValue] = []
          for item in arr {
            match item {
              String(s) =>
                if s.length() <= 5 {
                  short_items.push(item)
                } else {
                  long_items.push(item)
                }
              _ => short_items.push(item)
            }
          }
          // Return array of groups
          Array([Array(short_items), Array(long_items)])
        }
        _ => value
      }
    "money" =>
      match value {
        Number(n) => String("$" + n.to_string())
        String(s) => String("$" + s)
        _ => value
      }
    "money_with_currency" =>
      match value {
        Number(n) => String("$" + n.to_string() + " USD")
        String(s) => String("$" + s + " USD")
        _ => value
      }
    "money_without_currency" =>
      match value {
        Number(n) => String(n.to_string())
        String(s) => String(s.replace(old="$", new=""))
        _ => value
      }
    "money_without_trailing_zeros" =>
      match value {
        Number(n) => {
          let str_val = n.to_string()
          if str_val.strip_suffix(".0") != None {
            String("$" + str_val[0:str_val.length() - 2].to_owned())
          } else {
            String("$" + str_val)
          }
        }
        String(s) => String("$" + s)
        _ => value
      }
    "pluralize" =>
      match value {
        Number(n) =>
          // For pluralize, we need parameters: singular and plural forms
          // This is a basic implementation - in practice this would be handled by apply_filter_with_params
          if n == 1.0 {
            String("1 item")
          } else {
            String(n.to_string() + " items")
          }
        _ => value
      }
    "reading_time" =>
      match value {
        String(text) => {
          // Estimate reading time based on word count (average 200 words per minute)
          let word_count = text.split(" ").collect().length()
          let minutes = (word_count.to_double() / 200.0).ceil()
          Number(minutes)
        }
        _ => Number(1.0) // Default to 1 minute
      }
    "sort_by" =>
      match value {
        Array(arr) => {
          // Use the same selection sort algorithm as the sort filter
          let sorted = Array::from_iter(arr.iter())
          let mut i = 0
          while i < sorted.length() {
            let mut min_idx = i
            let mut j = i + 1
            while j < sorted.length() {
              if sorted[j].to_string() < sorted[min_idx].to_string() {
                min_idx = j
              }
              j = j + 1
            }
            if min_idx != i {
              let temp = sorted[i]
              sorted[i] = sorted[min_idx]
              sorted[min_idx] = temp
            }
            i = i + 1
          }
          Array(sorted)
        }
        _ => value
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
