///|
test "whitespace control trims both sides without renaming variables" {
  let context = LiquidContext::new()
  context.set("name", string_value("Alice"))
  assert_eq(parse("A \n\t{{- name -}} \r\nB").render(context), "AAliceB")
  assert_eq(parse("A {{ name }} B").render(context), "A Alice B")
  assert_eq(parse("A {{ name -}} B").render(context), "A AliceB")
  assert_eq(parse("A {{- name }} B").render(context), "AAlice B")
}

///|
test "whitespace tags preserve source order" {
  let context = LiquidContext::new()
  assert_eq(parse("{% assign x = 'ok' %}{{- x -}}").render(context), "ok")
  assert_eq(
    parse("A \n{%- assign x = 'yes' -%}\n {{ x }}").render(context),
    "Ayes",
  )
  assert_eq(
    parse("{% assign x = 'a' %}{{- x }}{%- assign x = 'b' %}{{ x }}").render(
      context,
    ),
    "ab",
  )
}
