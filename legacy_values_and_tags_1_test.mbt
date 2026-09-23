///|
test "liquid value creation and conversion" {
  // Test LiquidValue creation and string conversion
  let str_val = string_value("hello")
  let num_val = number_value(42.0)
  let bool_val = bool_value(true)
  let null_val = null_value()
  assert_eq(str_val.to_string(), "hello")
  assert_eq(num_val.to_string(), "42")
  assert_eq(bool_val.to_string(), "true")
  assert_eq(null_val.to_string(), "null")
}

///|
test "liquid array and object values" {
  // Test array values
  let arr = array_value([string_value("apple"), string_value("banana")])
  assert_eq(arr.to_string(), "[apple, banana]")

  // Test object values
  let obj_map = Map([])
  obj_map.set("name", string_value("John"))
  obj_map.set("age", number_value(30.0))
  let obj = object_value(obj_map)
  let obj_str = obj.to_string()
  assert_eq(obj_str.contains("name"), true)
  assert_eq(obj_str.contains("John"), true)
}

///|
test "liquid context operations" {
  // Test LiquidContext creation and variable management
  let context = LiquidContext::new()

  // Set and get string value
  context.set("name", string_value("World"))
  match context.get("name") {
    Some(value) => assert_eq(value.to_string(), "World")
    None => fail("Expected name to be found")
  }

  // Set and get number value
  context.set("count", number_value(42.0))
  match context.get("count") {
    Some(value) => assert_eq(value.to_string(), "42")
    None => fail("Expected count to be found")
  }

  // Test non-existent key
  match context.get("nonexistent") {
    Some(_) => fail("Expected None for nonexistent key")
    None => ()
  }
}

///|
test "template rendering basic" {
  // Test basic template rendering
  let template = parse("Hello {{ name }}!")
  let context = LiquidContext::new()
  context.set("name", string_value("World"))
  let result = template.render(context)
  assert_eq(result, "Hello World!")
}

///|
test "template rendering with missing variable" {
  // Test rendering with missing variable
  let template = parse("Hello {{ missing }}!")
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "Hello !")
}

///|
test "template rendering multiple variables" {
  // Test rendering with multiple variables
  let template = parse(
    "{{ greeting }} {{ name }}, you have {{ count }} messages.",
  )
  json_inspect(template, content={
    "nodes": [
      ["Variable", "greeting", []],
      ["Text", " "],
      ["Variable", "name", []],
      ["Text", ", you have "],
      ["Variable", "count", []],
      ["Text", " messages."],
    ],
  })
  let context = LiquidContext::new()
  context.set("greeting", string_value("Hello"))
  context.set("name", string_value("Alice"))
  context.set("count", number_value(5.0))
  let result = template.render(context)
  assert_eq(result, "Hello Alice, you have 5 messages.")
}

///|
test "integration basic template" {
  // Test basic template similar to examples/basic.liquid
  let template = parse(
    "Hello, {{ name }}!\nWelcome to {{ site_name }}.\nYour role: {{ user.role }}",
  )
  json_inspect(template, content={
    "nodes": [
      ["Text", "Hello, "],
      ["Variable", "name", []],
      ["Text", "!\nWelcome to "],
      ["Variable", "site_name", []],
      ["Text", ".\nYour role: "],
      ["Variable", "user.role", []],
    ],
  })
  let context = LiquidContext::new()
  context.set("name", string_value("World"))
  context.set("site_name", string_value("Liquid MoonBit"))
  let user_obj = Map([])
  user_obj.set("role", string_value("Developer"))
  context.set("user", object_value(user_obj))
  let result = template.render(context)
  let expected = "Hello, World!\nWelcome to Liquid MoonBit.\nYour role: Developer"
  assert_eq(result, expected)
}

///|
test "integration blog post metadata" {
  // Test blog post template metadata like examples/blog_post.liquid
  let template = parse(
    "{{ post.title }}\nby {{ post.author.name }}\nTags: {{ post.tags | size }} tags",
  )
  json_inspect(template, content={
    "nodes": [
      ["Variable", "post.title", []],
      ["Text", "\nby "],
      ["Variable", "post.author.name", []],
      ["Text", "\nTags: "],
      ["Variable", "post.tags", [{ "name": "size", "parameters": [] }]],
      ["Text", " tags"],
    ],
  })
  let context = LiquidContext::new()
  let author_obj = Map([])
  author_obj.set("name", string_value("Jane Doe"))
  let post_obj = Map([])
  post_obj.set("title", string_value("My First Post"))
  post_obj.set("author", object_value(author_obj))
  let tags = array_value([string_value("tech"), string_value("moonbit")])
  post_obj.set("tags", tags)
  context.set("post", object_value(post_obj))
  let result = template.render(context)
  let expected = "My First Post\nby Jane Doe\nTags: 2 tags"
  assert_eq(result, expected)
}

///|
test "integration complex template" {
  // Test complex template with multiple features
  let template = parse(
    "Welcome {{ name | upcase }}!\nYou have {{ count }} items.\nFirst item: {{ items | size }} total",
  )
  json_inspect(template, content={
    "nodes": [
      ["Text", "Welcome "],
      ["Variable", "name", [{ "name": "upcase", "parameters": [] }]],
      ["Text", "!\nYou have "],
      ["Variable", "count", []],
      ["Text", " items.\nFirst item: "],
      ["Variable", "items", [{ "name": "size", "parameters": [] }]],
      ["Text", " total"],
    ],
  })
  let context = LiquidContext::new()
  context.set("name", string_value("alice"))
  context.set("count", number_value(3.0))
  let items = array_value([
    string_value("apple"),
    string_value("banana"),
    string_value("cherry"),
  ])
  context.set("items", items)
  let result = template.render(context)
  let expected = "Welcome ALICE!\nYou have 3 items.\nFirst item: 3 total"
  assert_eq(result, expected)
}

// Control flow tests

///|
test "basic comment tag" {
  // Test comment tags are ignored
  let template = parse(
    "Hello {% comment %}This is ignored{% endcomment %}World!",
  )
  json_inspect(template, content={
    "nodes": [
      ["Text", "Hello "],
      ["Comment", "This is ignored"],
      ["Text", "World!"],
    ],
  })
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "Hello World!")
}

///|
test "mixed variable and logic tags" {
  // Test parsing templates with both {{ }} and {% %} tags
  let template = parse(
    "Hello {{ name }}! {% comment %}greeting{% endcomment %} Welcome!",
  )
  json_inspect(template, content={
    "nodes": [
      ["Text", "Hello "],
      ["Variable", "name", []],
      ["Text", "! "],
      ["Comment", "greeting"],
      ["Text", " Welcome!"],
    ],
  })
  let context = LiquidContext::new()
  context.set("name", string_value("World"))
  let result = template.render(context)
  assert_eq(result, "Hello World!  Welcome!")
}

///|
test "assign tag basic" {
  // Test assign tag parsing
  let template = parse("{% assign greeting = 'Hello' %}{{ greeting }}")
  json_inspect(template, content={
    "nodes": [["Assign", "greeting", "'Hello'"], ["Variable", "greeting", []]],
  })
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "Hello") // assign should now work
}

// Enhanced Liquid Tags Tests

///|
test "assign tag string literal" {
  // Test assign with string literal
  let template = parse("{% assign name = 'World' %}Hello {{ name }}!")
  json_inspect(template, content={
    "nodes": [
      ["Assign", "name", "'World'"],
      ["Text", "Hello "],
      ["Variable", "name", []],
      ["Text", "!"],
    ],
  })
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "Hello World!")
}

///|
test "assign tag double quotes" {
  // Test assign with double quotes
  let template = parse("{% assign message = \"Welcome\" %}{{ message }}")
  json_inspect(template, content={
    "nodes": [["Assign", "message", "\"Welcome\""], ["Variable", "message", []]],
  })
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "Welcome")
}

///|
test "assign tag number" {
  // Test assign with number
  let template = parse("{% assign count = 5 %}Count: {{ count }}")
  json_inspect(template, content={
    "nodes": [
      ["Assign", "count", "5"],
      ["Text", "Count: "],
      ["Variable", "count", []],
    ],
  })
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "Count: 5")
}

///|
test "assign tag boolean" {
  // Test assign with boolean values
  let template = parse(
    "{% assign flag = true %}{% assign flag2 = false %}{{ flag }} {{ flag2 }}",
  )
  json_inspect(template, content={
    "nodes": [
      ["Assign", "flag", "true"],
      ["Assign", "flag2", "false"],
      ["Variable", "flag", []],
      ["Text", " "],
      ["Variable", "flag2", []],
    ],
  })
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "true false")
}

///|
test "assign tag null" {
  // Test assign with null value
  let template = parse("{% assign empty = null %}{{ empty }}")
  json_inspect(template, content={
    "nodes": [["Assign", "empty", "null"], ["Variable", "empty", []]],
  })
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "")
}

///|
test "assign tag variable reference" {
  // Test assign referencing another variable
  let template = parse(
    "{% assign original = 'Hello' %}{% assign copy = original %}{{ copy }}",
  )
  json_inspect(template, content={
    "nodes": [
      ["Assign", "original", "'Hello'"],
      ["Assign", "copy", "original"],
      ["Variable", "copy", []],
    ],
  })
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "Hello")
}

///|
test "assign tag with whitespace" {
  // Test assign with various whitespace patterns
  let template = parse("{%  assign   name   =   'Test'  %}{{ name }}")
  json_inspect(template, content={
    "nodes": [["Assign", "name", "'Test'"], ["Variable", "name", []]],
  })
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "Test")
}

///|
test "multiple assign tags" {
  // Test multiple assign statements
  let template = parse(
    "{% assign a = 'A' %}{% assign b = 'B' %}{% assign c = 'C' %}{{ a }}{{ b }}{{ c }}",
  )
  json_inspect(template, content={
    "nodes": [
      ["Assign", "a", "'A'"],
      ["Assign", "b", "'B'"],
      ["Assign", "c", "'C'"],
      ["Variable", "a", []],
      ["Variable", "b", []],
      ["Variable", "c", []],
    ],
  })
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "ABC")
}

///|
test "logical operator and" {
  // Test and operator
  let context = LiquidContext::new()
  context.set("is_admin", bool_value(true))
  context.set("is_active", bool_value(true))
  context.set("is_guest", bool_value(false))
  let result1 = evaluate_condition("is_admin and is_active", context)
  assert_eq(result1, true)
  let result2 = evaluate_condition("is_admin and is_guest", context)
  assert_eq(result2, false)
  let result3 = evaluate_condition("is_guest and is_active", context)
  assert_eq(result3, false)
}

///|
test "logical operator or" {
  // Test or operator
  let context = LiquidContext::new()
  context.set("is_admin", bool_value(true))
  context.set("is_moderator", bool_value(false))
  context.set("is_guest", bool_value(false))
  let result1 = evaluate_condition("is_admin or is_moderator", context)
  assert_eq(result1, true)
  let result2 = evaluate_condition("is_moderator or is_guest", context)
  assert_eq(result2, false)
  let result3 = evaluate_condition("is_guest or is_admin", context)
  assert_eq(result3, true)
}

///|
test "logical operator not" {
  // Test not operator
  let context = LiquidContext::new()
  context.set("is_visible", bool_value(true))
  context.set("is_hidden", bool_value(false))
  let result1 = evaluate_condition("not is_visible", context)
  assert_eq(result1, false)
  let result2 = evaluate_condition("not is_hidden", context)
  assert_eq(result2, true)
}

///|
test "complex logical expressions" {
  // Test complex logical combinations
  let context = LiquidContext::new()
  context.set("age", number_value(25.0))
  context.set("is_member", bool_value(true))
  context.set("has_discount", bool_value(false))

  // Test: age >= 18 and is_member
  let result1 = evaluate_condition("age >= 18 and is_member", context)
  assert_eq(result1, true)

  // Test: has_discount or is_member
  let result2 = evaluate_condition("has_discount or is_member", context)
  assert_eq(result2, true)

  // Test: not has_discount and is_member
  let result3 = evaluate_condition("not has_discount and is_member", context)
  assert_eq(result3, true)
}

///|
test "logical operators with string contains" {
  // Test logical operators with contains
  let context = LiquidContext::new()
  context.set("title", string_value("Hello World"))
  context.set("category", string_value("tech"))
  let result1 = evaluate_condition(
    "title contains 'Hello' and category == 'tech'", context,
  )
  assert_eq(result1, true)
  let result2 = evaluate_condition(
    "title contains 'Goodbye' or category == 'tech'", context,
  )
  assert_eq(result2, true)
}

// Forloop Object Tests

///|
test "object property access" {
  // Test object property access like forloop.index
  let context = LiquidContext::new()
  let forloop_obj = Map([])
  forloop_obj.set("index", number_value(1.0))
  forloop_obj.set("first", bool_value(true))
  forloop_obj.set("last", bool_value(false))
  context.set("forloop", object_value(forloop_obj))
  let index_result = context.get("forloop.index")
  match index_result {
    Some(value) => assert_eq(value.to_string(), "1")
    None => fail("Expected forloop.index to be found")
  }
  let first_result = context.get("forloop.first")
  match first_result {
    Some(value) => assert_eq(value.to_string(), "true")
    None => fail("Expected forloop.first to be found")
  }
}

///|
test "nested object access" {
  // Test nested object property access
  let context = LiquidContext::new()
  let user_obj = Map([])
  user_obj.set("name", string_value("Alice"))
  user_obj.set("role", string_value("admin"))
  context.set("user", object_value(user_obj))
  let name_result = context.get("user.name")
  match name_result {
    Some(value) => assert_eq(value.to_string(), "Alice")
    None => fail("Expected user.name to be found")
  }
  let role_result = context.get("user.role")
  match role_result {
    Some(value) => assert_eq(value.to_string(), "admin")
    None => fail("Expected user.role to be found")
  }
}

// Date Filter Tests

///|
test "error policy strict" {
  // Test strict error policy
  let template = parse("Hello {{ missing_var }}!")
  let context = LiquidContext::with_error_policy(strict_policy())
  let result = template.render(context)
  assert_eq(result, "Hello [ERROR: Variable 'missing_var' not found]!")
}

///|
test "error policy warn" {
  // Test warn error policy (default)
  let template = parse("Hello {{ missing_var }}!")
  let context = LiquidContext::new() // Default is Warn
  let result = template.render(context)
  // Warn policy prints to console and returns empty string
  assert_eq(result, "Hello !")
}

///|
test "error policy silent" {
  // Test silent error policy
  let template = parse("Hello {{ missing_var }}!")
  let context = LiquidContext::with_error_policy(silent_policy())
  let result = template.render(context)
  assert_eq(result, "Hello !")
}

///|
test "error policy with valid variables" {
  // Test that error policies don't affect valid variables
  let template = parse("Hello {{ name }}!")
  let strict_context = LiquidContext::with_error_policy(strict_policy())
  strict_context.set("name", string_value("World"))
  let result = template.render(strict_context)
  assert_eq(result, "Hello World!")
}

///|
test "error policy with mixed variables" {
  // Test error policy with mix of valid and invalid variables
  let template = parse("{{ valid }} {{ invalid }} {{ another_valid }}")
  let strict_context = LiquidContext::with_error_policy(strict_policy())
  strict_context.set("valid", string_value("OK"))
  strict_context.set("another_valid", string_value("GOOD"))
  let result = template.render(strict_context)
  assert_eq(result, "OK [ERROR: Variable 'invalid' not found] GOOD")
}

///|
test "error policy context isolation" {
  // Test that different contexts can have different error policies
  let template = parse("{{ missing }}")
  let strict_context = LiquidContext::with_error_policy(strict_policy())
  let silent_context = LiquidContext::with_error_policy(silent_policy())
  let strict_result = template.render(strict_context)
  let silent_result = template.render(silent_context)
  assert_eq(strict_result, "[ERROR: Variable 'missing' not found]")
  assert_eq(silent_result, "")
}

// Whitespace Control Tests (Basic Recognition)

///|
test "whitespace control logic tags" {
  // Test whitespace control with logic tags
  let template = parse("{%- assign x = 'test' -%}{{ x }}")
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "test")
}

///|
test "whitespace control mixed" {
  // Test mixed whitespace control
  let template = parse("Before {{- name }} After")
  let context = LiquidContext::new()
  context.set("name", string_value("Content"))
  let result = template.render(context)
  assert_eq(result, "BeforeContent After")
}

// WhitespaceControl Struct Tests
