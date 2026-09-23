///|
priv enum RenderNode {
  Text(String)
  Output(Expr, Bool)
  For(String, Expr, Array[RenderNode], LoopModifiers, Array[RenderNode])
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
