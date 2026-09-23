///|
test "whitespace control trims both sides without renaming variables" {
  let context = LiquidContext::new()
  context.set("name", string_value("Alice"))
  assert_eq(
    @liquid.compile("A \n\t{{- name -}} \r\nB")
    .unwrap()
    .render(context)
    .unwrap(),
    "AAliceB",
  )
  assert_eq(
    @liquid.compile("A {{ name }} B").unwrap().render(context).unwrap(),
    "A Alice B",
  )
  assert_eq(
    @liquid.compile("A {{ name -}} B").unwrap().render(context).unwrap(),
    "A AliceB",
  )
  assert_eq(
    @liquid.compile("A {{- name }} B").unwrap().render(context).unwrap(),
    "AAlice B",
  )
}

///|
test "whitespace tags preserve source order" {
  let context = LiquidContext::new()
  assert_eq(
    @liquid.compile("{% assign x = 'ok' %}{{- x -}}")
    .unwrap()
    .render(context)
    .unwrap(),
    "ok",
  )
  assert_eq(
    @liquid.compile("A \n{%- assign x = 'yes' -%}\n {{ x }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "Ayes",
  )
  assert_eq(
    @liquid.compile("{% assign x = 'a' %}{{- x }}{%- assign x = 'b' %}{{ x }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "ab",
  )
}

///|
test "edge case variable with whitespace variations" {
  // Test variables with different whitespace patterns
  let template = @liquid.compile("{{name}} {{ name }} {{  name  }}").unwrap()

  let context = LiquidContext::new()
  context.set("name", string_value("World"))
  context.set(" name ", string_value("Space"))
  context.set("  name  ", string_value("More"))
  let result = template.render(context).unwrap()
  assert_eq(result, "World World World") // All variables have same trimmed name "name"
}

///|
test "whitespace control parsing" {
  // Test that whitespace control syntax is recognized
  let template = @liquid.compile("{{- name -}}").unwrap()

  let context = LiquidContext::new()
  context.set("name", string_value("World"))
  let result = template.render(context).unwrap()
  assert_eq(result, "World")
}

///|
test "whitespace control logic tags" {
  // Test whitespace control with logic tags
  let template = @liquid.compile("{%- assign x = 'test' -%}{{ x }}").unwrap()
  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "test")
}

///|
test "whitespace control mixed" {
  // Test mixed whitespace control
  let template = @liquid.compile("Before {{- name }} After").unwrap()
  let context = LiquidContext::new()
  context.set("name", string_value("Content"))
  let result = template.render(context).unwrap()
  assert_eq(result, "BeforeContent After")
}
