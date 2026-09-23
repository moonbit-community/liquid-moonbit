///|
fn render_node_inner(
  node : RenderNode,
  context : LiquidContext,
  state : RenderState,
) -> String {
  if state.flow != Next {
    return ""
  }
  match node {
    Text(text) => text
    Output(expression, report_missing) =>
      render_expression(expression, context, state, report_missing)
    For(loop_var, collection, body, modifiers, otherwise) =>
      render_for(
        loop_var, collection, body, modifiers, otherwise, context, state,
      )
    If(condition, then_body, elsif_branches, else_body) => {
      let condition_result = condition.eval(context, state)
      let body_to_render = if condition_result {
        then_body
      } else {
        // Check elsif branches
        let mut found_elsif = false
        let mut elsif_body : Array[RenderNode] = []
        for branch in elsif_branches {
          let (elsif_condition, elsif_nodes) = branch
          if elsif_condition.eval(context, state) {
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
      render_nodes(body_to_render, context, state)
    }
    Unless(condition, body) => {
      let condition_result = condition.eval(context, state)
      if condition_result {
        "" // Unless renders body only when condition is false
      } else {
        render_nodes(body, context, state)
      }
    }
    Case(expression, when_branches, else_body) => {
      let expr_value = expression.eval(context, state)

      // Check each when branch
      for branch in when_branches {
        let (when_value, when_body) = branch
        if values_equal(expr_value, when_value.eval(context, state)) {
          return render_nodes(when_body, context, state)
        }
      }

      // If no when branch matched, use else body
      match else_body {
        Some(else_nodes) => render_nodes(else_nodes, context, state)
        None => ""
      }
    }
    Assign(var_name, expression) => {
      // Parse and evaluate the expression
      let value = expression.eval(context, state)
      context.set(var_name, value)
      "" // Assign doesn't produce output
    }
    Cycle(group, values) => {
      if values.is_empty() {
        return ""
      }
      let key = if group == "default" {
        "implicit:" +
        values.map(fn(v) { v.length().to_string() + ":" + v }).join("")
      } else {
        "named:" + unquote_argument(group)
      }
      let index = state.cycles.get(key).unwrap_or(0) % values.length()
      state.cycles[key] = (index + 1) % values.length()
      values[index]
    }
    TableRow(loop_var, collection, body, cols) =>
      render_table_row(loop_var, collection, body, cols, context, state)
    Break => {
      if state.loops > 0 {
        state.flow = Break
      }
      ""
    }
    Continue => {
      if state.loops > 0 {
        state.flow = Continue
      }
      ""
    }
    Liquid(body) => render_nodes(body, context, state)
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
    Include(template_name) =>
      render_partial(template_name, context, state, false)
    Render(template_name) => render_partial(template_name, context, state, true)
    Capture(var_name, content) => {
      let captured_output = render_nodes(content, context, state)
      // Store captured content in context
      context.set(var_name, string_value(captured_output))

      // Capture doesn't produce direct output
      ""
    }
    Increment(name) => {
      let current = state.counters.get(name).unwrap_or(0)
      state.counters[name] = current + 1
      current.to_string()
    }
    Decrement(name) => {
      let current = state.counters.get(name).unwrap_or(0) - 1
      state.counters[name] = current
      current.to_string()
    }
    IfChanged(body) => {
      let output = render_nodes(body, context, state)
      if state.previous == Some(output) {
        return ""
      }
      state.previous = Some(output)
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
        None => render_nodes(default_content, context, state)
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
