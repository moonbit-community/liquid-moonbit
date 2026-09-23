///|
priv enum RenderFlow {
  Next
  Break
  Continue
} derive(Eq)

///|
priv struct RenderState {
  mut flow : RenderFlow
  mut loops : Int
  mut depth : Int
  counters : Map[String, Int]
  cycles : Map[String, Int]
  mut previous : String?
  mut diagnostics : Array[Diagnostic]?
  mut template_name : String?
  partials : Map[String, Array[RenderNode]]
}

///|
fn new_render_state() -> RenderState {
  {
    flow: Next,
    loops: 0,
    depth: 0,
    counters: Map([]),
    cycles: Map([]),
    previous: None,
    diagnostics: None,
    template_name: None,
    partials: Map([]),
  }
}

///|
fn restore_variable(
  context : LiquidContext,
  key : String,
  value : LiquidValue?,
) -> Unit {
  match value {
    Some(value) => context.set(key, value)
    None => context.variables.remove(key)
  }
}

///|
/// Register a caller-supplied template for include/render. No filesystem access is performed.
pub fn LiquidContext::register_template(
  self : LiquidContext,
  name : String,
  source : String,
) -> Unit {
  self.templates[name] = source
}

///|
fn render_partial(
  call : PartialCall,
  context : LiquidContext,
  state : RenderState,
  isolated : Bool,
) -> String {
  let name = call.name
  guard context.templates.get(name) is Some(source) else {
    return render_error(
      context,
      state,
      "Template '" + name + "' not found",
      code="missing_template",
    )
  }
  if state.depth >= 64 {
    return render_error(
      context,
      state,
      "Template nesting limit exceeded",
      code="nesting_limit",
    )
  }
  let child = if isolated {
    {
      variables: Map([]),
      error_policy: context.error_policy,
      templates: context.templates,
    }
  } else {
    context
  }
  let saved : Map[String, LiquidValue?] = Map([])
  // Evaluate all arguments in the caller before binding any of them.
  let arguments = call.arguments.map(fn(arg) {
    (arg.0, arg.1.eval(context, state))
  })
  for (key, value) in arguments {
    if !saved.contains(key) {
      saved[key] = child.variables.get(key)
    }
    child.set(key, value)
  }
  let child_state = if isolated {
    {
      ..new_render_state(),
      depth: state.depth + 1,
      diagnostics: state.diagnostics,
      partials: state.partials,
    }
  } else {
    state
  }
  if !isolated {
    state.depth += 1
  }
  let previous_template = child_state.template_name
  child_state.template_name = Some(name)
  let nodes = match state.partials.get(source) {
    Some(nodes) => nodes
    None => {
      let diagnostics : Array[Diagnostic] = []
      let parsed = parse_template(source, diagnostics~)
      if state.diagnostics is Some(errors) {
        for diagnostic in diagnostics {
          errors.push({ ..diagnostic, template: Some(name), })
        }
      }
      let nodes = compile_nodes(parsed)
      state.partials[source] = nodes
      nodes
    }
  }
  let mut output = ""
  for node in nodes {
    output += render_node_inner(node, child, child_state)
  }
  child_state.template_name = previous_template
  if !isolated {
    state.depth -= 1
  }
  for key, value in saved {
    restore_variable(child, key, value)
  }
  output
}

///|
fn render_nodes(
  nodes : Array[RenderNode],
  context : LiquidContext,
  state : RenderState,
) -> String {
  let mut output = ""
  for node in nodes {
    output += render_node_inner(node, context, state)
  }
  output
}

///|
fn render_for(
  loop_var : String,
  collection : Expr,
  body : Array[RenderNode],
  modifiers : ForLoopModifiers,
  otherwise : Array[RenderNode],
  context : LiquidContext,
  state : RenderState,
) -> String {
  match collection.eval(context, state) {
    Array(items) => {
      // Apply modifiers to create the actual items to iterate
      let mut processed_items = items

      // Apply offset
      match modifiers.offset {
        Some(offset_count) => {
          let offset_items : Array[LiquidValue] = []
          for i in offset_count.max(0)..<processed_items.length() {
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
      if processed_items.is_empty() {
        return render_nodes(otherwise, context, state)
      }
      let mut output = ""
      let mut index = 0
      let saved_item = context.variables.get(loop_var)
      let saved_loop = context.variables.get("forloop")
      state.loops += 1
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
        forloop_obj.set("parentloop", saved_loop.unwrap_or(Null)) // Parent loop (for nested loops)
        forloop_obj.set("name", string_value(collection.label())) // Collection name

        // Add cycle functionality to forloop
        let cycle_odd_even = if index % 2 == 0 { "even" } else { "odd" }
        forloop_obj.set("cycle", string_value(cycle_odd_even))
        loop_context.set("forloop", object_value(forloop_obj))
        for body_node in body {
          output = output + render_node_inner(body_node, loop_context, state)
        }
        let flow = state.flow
        state.flow = Next
        if flow == Break {
          break
        }
        index = index + 1
      }
      state.loops -= 1
      restore_variable(context, loop_var, saved_item)
      restore_variable(context, "forloop", saved_loop)
      output
    }
    _ => render_nodes(otherwise, context, state)
  }
}

///|
fn render_error(
  context : LiquidContext,
  state : RenderState,
  message : String,
  code? : String = "evaluation_error",
) -> String {
  report_diagnostic(context, state, filter_diagnostic(code, message))
}

///|
fn report_diagnostic(
  context : LiquidContext,
  state : RenderState,
  diagnostic : Diagnostic,
) -> String {
  match state.diagnostics {
    Some(errors) => {
      errors.push({ ..diagnostic, template: state.template_name, })
      ""
    }
    None => handle_error(context, diagnostic.message)
  }
}
