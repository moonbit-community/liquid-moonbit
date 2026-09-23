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
    Ok({ nodes: compile_nodes(nodes), })
  } else {
    Err(diagnostics)
  }
}

///|
/// Render without logging or embedding errors in output. Context ErrorPolicy
/// only applies to the legacy String-returning interfaces.
pub fn Template::render(
  self : Template,
  context : LiquidContext,
) -> Result[String, Array[Diagnostic]] {
  let diagnostics : Array[Diagnostic] = []
  let state = new_render_state()
  state.diagnostics = Some(diagnostics)
  let output = render_nodes(self.nodes, context, state)
  if diagnostics.is_empty() {
    Ok(output)
  } else {
    Err(diagnostics)
  }
}
