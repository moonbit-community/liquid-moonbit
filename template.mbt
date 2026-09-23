///|
/// An opaque, compiled template. Use compile to construct it.
struct Template {
  nodes : Array[RenderNode]
}

///|
/// Parse and compile a template, rejecting malformed or unknown tags.
pub fn compile(source : String) -> Result[Template, Array[Diagnostic]] {
  let diagnostics : Array[Diagnostic] = []
  let nodes = parse_template(source, diagnostics~)
  if diagnostics.is_empty() {
    Ok({ nodes, })
  } else {
    Err(diagnostics)
  }
}

///|
/// Render without logging or embedding errors in output.
pub fn Template::render(
  self : Template,
  context : LiquidContext,
) -> Result[String, Array[Diagnostic]] {
  let state = new_render_state()
  let output = render_nodes(self.nodes, context, state)
  if state.diagnostics.is_empty() {
    Ok(output)
  } else {
    Err(state.diagnostics)
  }
}
