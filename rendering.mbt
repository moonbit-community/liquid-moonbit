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
}

///|
fn new_render_state() -> RenderState {
  { flow: Next, loops: 0, depth: 0, }
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
  expression : String,
  context : LiquidContext,
  state : RenderState,
  isolated : Bool,
) -> String {
  let args = split_unquoted(expression, ",")
  let name = unquote_argument(args[0])
  guard context.templates.get(name) is Some(source) else {
    return handle_error(context, "Template '" + name + "' not found")
  }
  if state.depth >= 64 {
    return handle_error(context, "Template nesting limit exceeded")
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
  for arg in args[1:] {
    if find_unquoted(arg, ":") is Some(at) {
      let key = arg[:at].trim().to_owned()
      if !saved.contains(key) {
        saved[key] = child.variables.get(key)
      }
      child.set(key, evaluate_expression(arg[at + 1:].to_owned(), context))
    }
  }
  let child_state = if isolated {
    { flow: Next, loops: 0, depth: state.depth + 1, }
  } else {
    state
  }
  if !isolated {
    state.depth += 1
  }
  let template = parse(source)
  let mut output = ""
  for node in template.nodes {
    output += render_node_inner(node, child, child_state)
  }
  if !isolated {
    state.depth -= 1
  }
  for key, value in saved {
    restore_variable(child, key, value)
  }
  output
}
