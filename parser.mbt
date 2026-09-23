///|
priv enum TemplateToken {
  Text(String)
  Output(String, Int)
  Tag(String, Int)
  Verbatim(String, String)
}

///|
fn tag_parts(tag : String) -> (String, String) {
  let trimmed = tag.trim().to_owned()
  for i in 0..<trimmed.length() {
    if trimmed[i] == 32 ||
      trimmed[i] == 9 ||
      trimmed[i] == 10 ||
      trimmed[i] == 13 {
      return (trimmed[:i].to_owned(), trimmed[i:].trim().to_owned())
    }
  }
  (trimmed, "")
}

///|
fn skip_space(source : String, start : Int) -> Int {
  let mut pos = start
  while pos < source.length() &&
        (
          source[pos] == 32 ||
          source[pos] == 9 ||
          source[pos] == 10 ||
          source[pos] == 13
        ) {
    pos += 1
  }
  pos
}

///|
fn tokenize_template(
  source : String,
  diagnostics : Array[Diagnostic],
) -> Array[TemplateToken] {
  let tokens : Array[TemplateToken] = []
  let mut pos = 0
  while pos < source.length() {
    let rest = source[pos:].to_owned()
    let (offset, output) = match (rest.find("{{"), rest.find("{%")) {
      (Some(a), Some(b)) => if a < b { (a, true) } else { (b, false) }
      (Some(a), None) => (a, true)
      (None, Some(b)) => (b, false)
      (None, None) => {
        tokens.push(Text(rest))
        break
      }
    }
    let start = pos + offset
    let closing = if output { "}}" } else { "%}" }
    guard find_unquoted(source[start + 2:].to_owned(), closing)
      is Some(end_offset) else {
      diagnostics.push(
        parse_diagnostic("unclosed_tag", "Expected " + closing, start),
      )
      tokens.push(Text(rest))
      break
    }
    let end = start + 2 + end_offset
    let left = start + 2 < end && source[start + 2] == 45
    let right = end > start + 2 && source[end - 1] == 45
    let text = source[pos:start]
    let text = if left { text.trim_end() } else { text }
    if !text.is_empty() {
      tokens.push(Text(text.to_owned()))
    }
    let from = start + (if left { 3 } else { 2 })
    let to = end - (if right { 1 } else { 0 })
    let tag = if from <= to { source[from:to].trim().to_owned() } else { "" }
    pos = if right { skip_space(source, end + 2) } else { end + 2 }
    if output {
      tokens.push(Output(tag, start))
      continue
    }
    let (name, _) = tag_parts(tag)
    if name == "raw" || name == "comment" || name == "style" {
      // Verbatim bodies may contain unbalanced quotes and arbitrary Liquid syntax.
      let body_start = pos
      let mut search = pos
      let mut found = false
      while search < source.length() {
        guard source[search:].find("{%") is Some(next) else { break }
        let candidate = search + next
        guard source[candidate + 2:].find("%}") is Some(close) else { break }
        let finish = candidate + 2 + close
        let closing_tag = source[candidate + 2:finish]
          .trim(chars="- \t\r\n")
          .to_owned()
        if closing_tag == "end" + name {
          let body = source[body_start:candidate]
          let body = if source[candidate + 2] == 45 {
            body.trim_end()
          } else {
            body
          }
          tokens.push(Verbatim(name, body.to_owned()))
          pos = if source[finish - 1] == 45 {
            skip_space(source, finish + 2)
          } else {
            finish + 2
          }
          found = true
          break
        }
        search = candidate + 2
      }
      if !found {
        diagnostics.push(
          parse_diagnostic("unclosed_block", "Expected end" + name, start),
        )
        tokens.push(Verbatim(name, source[body_start:].to_owned()))
        pos = source.length()
      }
    } else {
      tokens.push(Tag(tag, start))
    }
  }
  tokens
}

///|
priv struct TemplateParser {
  tokens : Array[TemplateToken]
  mut pos : Int
  diagnostics : Array[Diagnostic]
  end_offset : Int
}

///|
fn TemplateParser::body(
  self : TemplateParser,
  stops : Array[String],
) -> (Array[RenderNode], String) {
  let nodes : Array[RenderNode] = []
  while self.pos < self.tokens.length() {
    let token = self.tokens[self.pos]
    self.pos += 1
    match token {
      Text(text) => nodes.push(Text(text))
      Output(expression, at) => {
        if expression.is_empty() {
          self.diagnostics.push(
            parse_diagnostic(
              "empty_expression", "Expected an output expression", at,
            ),
          )
        }
        let (value, filters) = parse_output(expression)
        nodes.push(Output(compile_output(value, filters), true))
      }
      Verbatim(name, text) =>
        nodes.push(
          match name {
            "raw" => Text(text)
            "style" => Style(text)
            _ => Text("")
          },
        )
      Tag(tag, at) => {
        let (name, args) = tag_parts(tag)
        if stops.contains(name) {
          return (nodes, tag)
        }
        if args.is_empty() &&
          [
            "if", "unless", "case", "assign", "for", "tablerow", "capture", "increment",
            "decrement", "include", "render", "echo",
          ].contains(name) {
          self.diagnostics.push(
            parse_diagnostic(
              "missing_argument",
              "Expected an argument for " + name,
              at,
            ),
          )
        }
        match name {
          "if" | "unless" => {
            let end = if name == "if" { "endif" } else { "endunless" }
            let (body, stop) = self.body(["elsif", "else", end])
            let branches : Array[(Condition, Array[RenderNode])] = []
            let mut next = stop
            while tag_parts(next).0 == "elsif" {
              let condition = tag_parts(next).1
              let (branch, stop) = self.body(["elsif", "else", end])
              branches.push((compile_condition(condition), branch))
              next = stop
            }
            let otherwise = if next == "else" {
              Some(self.body([end]).0)
            } else {
              None
            }
            if name == "unless" {
              match otherwise {
                None => nodes.push(Unless(compile_condition(args), body))
                Some(other) =>
                  nodes.push(If(compile_condition(args), other, [], Some(body)))
              }
            } else {
              nodes.push(If(compile_condition(args), body, branches, otherwise))
            }
          }
          "for" | "tablerow" => {
            let (body, stop) = self.body(
              if name == "for" {
                ["else", "endfor"]
              } else {
                ["endtablerow"]
              },
            )
            let otherwise = if stop == "else" {
              Some(self.body(["endfor"]).0)
            } else {
              None
            }
            match find_unquoted(args, " in ") {
              Some(at) => {
                let variable = args[:at].trim().to_owned()
                let rest = args[at + 4:].trim().to_owned()
                if name == "for" {
                  let (collection, modifiers) = parse_for_loop_modifiers(rest)
                  match otherwise {
                    Some(other) =>
                      nodes.push(
                        For(
                          variable,
                          compile_expression(collection),
                          body,
                          modifiers,
                          other,
                        ),
                      )
                    None =>
                      nodes.push(
                        For(
                          variable,
                          compile_expression(collection),
                          body,
                          modifiers,
                          [],
                        ),
                      )
                  }
                } else {
                  let parts = rest.split(" cols:").collect()
                  let cols = if parts.length() == 2 {
                    match parts[1].trim().to_owned() {
                      "1" => 1
                      "2" => 2
                      "4" => 4
                      "5" => 5
                      _ => 3
                    }
                  } else {
                    3
                  }
                  nodes.push(
                    TableRow(
                      variable,
                      compile_expression(parts[0].trim().to_owned()),
                      body,
                      cols,
                    ),
                  )
                }
              }
              None => {
                self.diagnostics.push(
                  parse_diagnostic(
                    "invalid_tag",
                    "Invalid " + name + " syntax",
                    at,
                  ),
                )
                nodes.push(Text(""))
              }
            }
          }
          "case" => {
            let (_, first) = self.body(["when", "else", "endcase"])
            let branches : Array[(Expr, Array[RenderNode])] = []
            let mut next = first
            while tag_parts(next).0 == "when" {
              let value = tag_parts(next).1
              let (body, stop) = self.body(["when", "else", "endcase"])
              for group in split_unquoted(value, " or ") {
                for choice in split_unquoted(group, ",") {
                  branches.push(
                    (compile_expression(choice.trim().to_owned()), body),
                  )
                }
              }
              next = stop
            }
            let otherwise = if next == "else" {
              Some(self.body(["endcase"]).0)
            } else {
              None
            }
            nodes.push(Case(compile_expression(args), branches, otherwise))
          }
          "capture" => nodes.push(Capture(args, self.body(["endcapture"]).0))
          "ifchanged" => nodes.push(IfChanged(self.body(["endifchanged"]).0))
          "block" => nodes.push(Block(args, self.body(["endblock"]).0))
          "liquid" =>
            if args == "" {
              nodes.push(Liquid(self.body(["endliquid"]).0))
            } else {
              let lines = args
                .split("\n")
                .map(fn(line) { "{% " + line.trim().to_owned() + " %}" })
                .collect()
              let nested : Array[Diagnostic] = []
              nodes.push(
                Liquid(parse_template(lines.join(""), diagnostics=nested)),
              )
              for diagnostic in nested {
                self.diagnostics.push({ ..diagnostic, offset: Some(at), })
              }
            }
          "assign" =>
            match find_unquoted(args, "=") {
              Some(at) =>
                nodes.push(
                  Assign(
                    args[:at].trim().to_owned(),
                    compile_expression(args[at + 1:].trim().to_owned()),
                  ),
                )
              None => {
                self.diagnostics.push(
                  parse_diagnostic(
                    "invalid_tag",
                    "Invalid " + name + " syntax",
                    at,
                  ),
                )
                nodes.push(Text(""))
              }
            }
          "echo" => {
            let (value, filters) = parse_output(args)
            nodes.push(Output(compile_output(value, filters), false))
          }
          "break" => nodes.push(Break)
          "continue" => nodes.push(Continue)
          "include" => nodes.push(Include(compile_partial(args)))
          "render" => nodes.push(Render(compile_partial(args)))
          "section" => nodes.push(Section(args))
          "layout" => nodes.push(Layout(args))
          "content" => nodes.push(Content)
          "increment" => nodes.push(Increment(args))
          "decrement" => nodes.push(Decrement(args))
          "cycle" => {
            let (group, values) = match find_unquoted(args, ":") {
              Some(at) =>
                (args[:at].trim().to_owned(), args[at + 1:].to_owned())
              None => ("default", args)
            }
            nodes.push(
              Cycle(
                group,
                split_unquoted(values, ",").map(fn(v) {
                  v.trim().trim(chars="'\"").to_owned()
                }),
              ),
            )
          }
          _ => {
            self.diagnostics.push(
              parse_diagnostic(
                "unknown_tag",
                "Unknown or misplaced tag '" + name + "'",
                at,
              ),
            )
            nodes.push(Text(""))
          }
        }
      }
    }
  }
  if !stops.is_empty() {
    self.diagnostics.push(
      parse_diagnostic(
        "unclosed_block",
        "Expected " + stops[stops.length() - 1],
        self.end_offset,
      ),
    )
  }
  (nodes, "")
}

///|
fn parse_template(
  source : String,
  diagnostics? : Array[Diagnostic] = [],
) -> Array[RenderNode] {
  let parser : TemplateParser = {
    tokens: tokenize_template(source, diagnostics),
    pos: 0,
    diagnostics,
    end_offset: source.length(),
  }
  parser.body([]).0
}
