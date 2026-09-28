///|
test "forloop exposes all indices flags and filtered length" {
  let context = LiquidContext::new()
  context.set("items", array_value(["a", "b", "c", "d"].map(string_value)))
  let template = compile(
    "{% for item in items limit:2 offset:1 reversed %}{{ item }}:{{ forloop.index }},{{ forloop.index0 }},{{ forloop.rindex }},{{ forloop.rindex0 }},{{ forloop.first }},{{ forloop.last }},{{ forloop.length }};{% endfor %}",
  ).unwrap()
  assert_eq(
    template.render(context).unwrap(),
    "c:1,0,2,1,true,false,2;b:2,1,1,0,false,true,2;",
  )
  assert_true(context.get("item") is None)
  assert_true(context.get("forloop") is None)
  context.set("items", array_value([]))
  assert_eq(template.render(context).unwrap(), "")
}

///|
test "tablerow exposes indices column flags and length" {
  let context = LiquidContext::new()
  context.set("items", array_value(["a", "b", "c"].map(string_value)))
  context.set("item", string_value("saved"))
  context.set("tablerowloop", string_value("outer"))
  let template = compile(
    "{% tablerow item in items cols:2 %}{{ item }}:{{ tablerowloop.index }},{{ tablerowloop.index0 }},{{ tablerowloop.rindex }},{{ tablerowloop.rindex0 }},{{ tablerowloop.col }},{{ tablerowloop.col0 }},{{ tablerowloop.first }},{{ tablerowloop.last }},{{ tablerowloop.col_first }},{{ tablerowloop.col_last }},{{ tablerowloop.length }}{% endtablerow %}",
  ).unwrap()
  assert_eq(
    template.render(context).unwrap(),
    "<table>\n<tr>\n<td>a:1,0,3,2,1,0,true,false,true,false,3</td>\n<td>b:2,1,2,1,2,1,false,false,false,true,3</td>\n</tr>\n<tr>\n<td>c:3,2,1,0,1,0,false,true,true,false,3</td>\n</tr>\n</table>",
  )
  assert_eq(context.get("item").unwrap().to_string(), "saved")
  assert_eq(context.get("tablerowloop").unwrap().to_string(), "outer")
  context.set("items", array_value([]))
  assert_eq(template.render(context).unwrap(), "<table>\n</table>")
}

///|
test "tablerow honors different column counts" {
  let context = LiquidContext::new()
  context.set("items", array_value(["a", "b"].map(string_value)))
  for
    (cols, expected) in [
      (1, "<table>\n<tr>\n<td>a</td>\n</tr>\n<tr>\n<td>b</td>\n</tr>\n</table>"),
      (3, "<table>\n<tr>\n<td>a</td>\n<td>b</td>\n</tr>\n</table>"),
    ] {
    assert_eq(
      compile(
        "{% tablerow item in items cols:" +
        cols.to_string() +
        " %}{{ item }}{% endtablerow %}",
      )
      .unwrap()
      .render(context)
      .unwrap(),
      expected,
    )
  }
}

///|
test "for tag execution" {
  // Test for tag execution
  let template = @liquid.compile(
    "{% for item in items %}{{ item }}{% endfor %}",
  ).unwrap()

  let context = LiquidContext::new()
  let items = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
  ])
  context.set("items", items)
  let result = template.render(context).unwrap()
  assert_eq(result, "abc")
}

///|
test "cycle tag basic" {
  // Test basic cycle tag
  let template = @liquid.compile("{% cycle 'odd', 'even' %}").unwrap()

  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "odd") // Returns first value
}

///|
test "cycle tag parsing" {
  // Test cycle tag parsing recognition
  let template = @liquid.compile("{% cycle group1: 'red', 'green', 'blue' %}").unwrap()

  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "red")
}

///|
test "cycle in template context" {
  // Test cycle tag in template with other content
  let template = @liquid.compile(
    "Row: {% cycle 'odd', 'even' %} | Next: {% cycle 'odd', 'even' %}",
  ).unwrap()
  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "Row: odd | Next: even") // Both cycles return first value
}

///|
test "tablerow tag basic" {
  // Test basic tablerow tag
  let template = @liquid.compile(
    "{% tablerow item in items cols: 2 %}{{ item }}{% endtablerow %}",
  ).unwrap()
  let context = LiquidContext::new()
  let items = array_value([
    string_value("A"),
    string_value("B"),
    string_value("C"),
    string_value("D"),
  ])
  context.set("items", items)
  let result = template.render(context).unwrap()
  assert_eq(result.contains("<table>"), true)
  assert_eq(result.contains("<tr>"), true)
  assert_eq(result.contains("<td>"), true)
  assert_eq(
    result, "<table>\n<tr>\n<td>A</td>\n<td>B</td>\n</tr>\n<tr>\n<td>C</td>\n<td>D</td>\n</tr>\n</table>",
  )
}

///|
test "break tag parsing" {
  // Test break tag parsing
  let template = @liquid.compile("{% break %}").unwrap()

  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "") // Break produces no output
}

///|
test "continue tag parsing" {
  // Test continue tag parsing
  let template = @liquid.compile("{% continue %}").unwrap()

  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "") // Continue produces no output
}

///|
test "break and continue in template" {
  // Test break and continue in template context
  let template = @liquid.compile("Start {% break %} Middle {% continue %} End").unwrap()
  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "Start  Middle  End") // Break and continue produce no output
}

///|
test "loop control flow recognition" {
  // Test that loop control flow is recognized
  let template = @liquid.compile(
    "{% for item in items %}{{ item }}{% if item == 'stop' %}{% break %}{% endif %}{% endfor %}",
  ).unwrap()
  let context = LiquidContext::new()
  let items = array_value([
    string_value("a"),
    string_value("stop"),
    string_value("b"),
  ])
  context.set("items", items)
  let result = template.render(context).unwrap()
  assert_eq(result, "astop")
}
