///|
priv enum RenderNode {
  Text(String)
  Output(Expr, Bool)
  For(String, Expr, Array[RenderNode], ForLoopModifiers, Array[RenderNode])
  If(
    Condition,
    Array[RenderNode],
    Array[(Condition, Array[RenderNode])],
    Array[RenderNode]?
  )
  Unless(Condition, Array[RenderNode])
  Case(Expr, Array[(Expr, Array[RenderNode])], Array[RenderNode]?)
  Assign(String, Expr)
  Cycle(String, Array[String])
  TableRow(String, Expr, Array[RenderNode], Int)
  Break
  Continue
  Liquid(Array[RenderNode])
  Section(String)
  Style(String)
  Include(PartialCall)
  Render(PartialCall)
  Capture(String, Array[RenderNode])
  Increment(String)
  Decrement(String)
  IfChanged(Array[RenderNode])
  Layout(String)
  Block(String, Array[RenderNode])
  Content
}

///|
priv struct PartialCall {
  name : String
  arguments : Array[(String, Expr)]
}

///|
fn compile_partial(source : String) -> PartialCall {
  let parts = split_unquoted(source, ",")
  let arguments : Array[(String, Expr)] = []
  for part in parts[1:] {
    if find_unquoted(part, ":") is Some(at) {
      arguments.push(
        (
          part[:at].trim().to_owned(),
          compile_expression(part[at + 1:].to_owned()),
        ),
      )
    }
  }
  { name: unquote_argument(parts[0]), arguments, }
}

///|
fn compile_nodes(nodes : Array[LiquidNode]) -> Array[RenderNode] {
  nodes.map(compile_node)
}

///|
fn compile_node(node : LiquidNode) -> RenderNode {
  match node {
    Text(text) | Raw(text) => Text(text)
    Comment(_) => Text("")
    Variable(source, filters) => Output(compile_output(source, filters), true)
    Echo(source, filters) => Output(compile_output(source, filters), false)
    For(name, collection, body, modifiers) =>
      For(
        name,
        compile_expression(collection),
        compile_nodes(body),
        modifiers,
        [],
      )
    ForElse(name, collection, body, modifiers, otherwise) =>
      For(
        name,
        compile_expression(collection),
        compile_nodes(body),
        modifiers,
        compile_nodes(otherwise),
      )
    If(condition, body, branches, otherwise) =>
      If(
        compile_condition(condition),
        compile_nodes(body),
        branches.map(fn(branch) {
          (compile_condition(branch.0), compile_nodes(branch.1))
        }),
        otherwise.map(compile_nodes),
      )
    Unless(condition, body) =>
      Unless(compile_condition(condition), compile_nodes(body))
    Case(subject, branches, otherwise) =>
      Case(
        compile_expression(subject),
        branches.map(fn(branch) {
          (compile_expression(branch.0), compile_nodes(branch.1))
        }),
        otherwise.map(compile_nodes),
      )
    Assign(name, expression) => Assign(name, compile_expression(expression))
    Cycle(group, values) => Cycle(group, values)
    TableRow(name, collection, body, cols) =>
      TableRow(name, compile_expression(collection), compile_nodes(body), cols)
    Break => Break
    Continue => Continue
    Liquid(body) => Liquid(compile_nodes(body))
    Section(name) => Section(name)
    Style(css) => Style(css)
    Include(source) => Include(compile_partial(source))
    Render(source) => Render(compile_partial(source))
    Capture(name, body) => Capture(name, compile_nodes(body))
    Increment(name) => Increment(name)
    Decrement(name) => Decrement(name)
    IfChanged(body) => IfChanged(compile_nodes(body))
    Layout(name) => Layout(name)
    Block(name, body) => Block(name, compile_nodes(body))
    Content => Content
  }
}
