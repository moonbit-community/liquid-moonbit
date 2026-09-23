///|
test "assign tag basic" {
  // Test assign tag parsing
  let template = @liquid.compile(
    "{% assign greeting = 'Hello' %}{{ greeting }}",
  ).unwrap()

  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "Hello") // assign should now work
}

///|
test "assign tag string literal" {
  // Test assign with string literal
  let template = @liquid.compile("{% assign name = 'World' %}Hello {{ name }}!").unwrap()

  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "Hello World!")
}

///|
test "assign tag double quotes" {
  // Test assign with double quotes
  let template = @liquid.compile(
    "{% assign message = \"Welcome\" %}{{ message }}",
  ).unwrap()

  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "Welcome")
}

///|
test "assign tag number" {
  // Test assign with number
  let template = @liquid.compile("{% assign count = 5 %}Count: {{ count }}").unwrap()

  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "Count: 5")
}

///|
test "assign tag boolean" {
  // Test assign with boolean values
  let template = @liquid.compile(
    "{% assign flag = true %}{% assign flag2 = false %}{{ flag }} {{ flag2 }}",
  ).unwrap()

  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "true false")
}

///|
test "assign tag null" {
  // Test assign with null value
  let template = @liquid.compile("{% assign empty = null %}{{ empty }}").unwrap()

  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "")
}

///|
test "assign tag variable reference" {
  // Test assign referencing another variable
  let template = @liquid.compile(
    "{% assign original = 'Hello' %}{% assign copy = original %}{{ copy }}",
  ).unwrap()

  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "Hello")
}

///|
test "assign tag with whitespace" {
  // Test assign with various whitespace patterns
  let template = @liquid.compile("{%  assign   name   =   'Test'  %}{{ name }}").unwrap()

  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "Test")
}

///|
test "multiple assign tags" {
  // Test multiple assign statements
  let template = @liquid.compile(
    "{% assign a = 'A' %}{% assign b = 'B' %}{% assign c = 'C' %}{{ a }}{{ b }}{{ c }}",
  ).unwrap()

  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "ABC")
}
