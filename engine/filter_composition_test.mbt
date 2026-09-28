///|
test "template with filters" {
  // Test template parsing with filters
  let template = @engine.compile("Hello {{ name | upcase }}!").unwrap()

  let context = LiquidContext::new()
  context.set("name", string_value("world"))
  let result = template.render(context).unwrap()
  assert_eq(result, "Hello WORLD!")
}

///|
test "template with multiple filters" {
  // Test template parsing with multiple filters chained
  let template = @engine.compile("{{ text | upcase | size }}").unwrap()

  let context = LiquidContext::new()
  context.set("text", string_value("hello"))
  let result = template.render(context).unwrap()
  assert_eq(result, "5") // "hello" -> "HELLO" -> "5"
}

///|
test "edge case filter with whitespace" {
  // Test filters with various whitespace patterns
  let template = @engine.compile(
    "{{ name|upcase }} {{ name | upcase }} {{ name |upcase}}",
  ).unwrap()

  let context = LiquidContext::new()
  context.set("name", string_value("hello"))
  let result = template.render(context).unwrap()
  assert_eq(result, "HELLO HELLO HELLO")
}

///|
test "integration filter chain" {
  // Test filter chaining like in examples/filters.liquid
  let template = @engine.compile(
    "Original: {{ text }}\nUppercase: {{ text | upcase }}\nSize: {{ text | size }}",
  ).unwrap()

  let context = LiquidContext::new()
  context.set("text", string_value("hello world"))
  let result = template.render(context).unwrap()
  let expected = "Original: hello world\nUppercase: HELLO WORLD\nSize: 11"
  assert_eq(result, expected)
}

///|
test "array filter chaining" {
  // Test chaining multiple array filters
  let template = @engine.compile("{{ items | compact | uniq | sort | join }}").unwrap()
  let context = LiquidContext::new()
  let messy_items = array_value([
    string_value("cherry"),
    string_value(""),
    string_value("apple"),
    null_value(),
    string_value("cherry"),
    string_value("banana"),
  ])
  context.set("items", messy_items)
  let result = template.render(context).unwrap()
  assert_eq(result, "apple, banana, cherry")
}

///|
test "filter parameters multiple" {
  // Test multiple filters with parameters
  let template = @engine.compile("{{ text | truncate: 20 | upcase }}").unwrap()
  let context = LiquidContext::new()
  context.set("text", string_value("This is a moderately long text"))
  let result = template.render(context).unwrap()
  assert_eq(result, "THIS IS A MODERAT...")
}

///|
test "filter without parameters" {
  // Test that filters without parameters still work
  let template = @engine.compile("{{ text | upcase | size }}").unwrap()
  let context = LiquidContext::new()
  context.set("text", string_value("hello"))
  let result = template.render(context).unwrap()
  assert_eq(result, "5")
}

///|
test "string filters in template" {
  // Test string filters in template context
  let template = @engine.compile(
    "{{ text | capitalize | append }} and {{ html | strip_html }}",
  ).unwrap()
  let context = LiquidContext::new()
  context.set("text", string_value("hello world"))
  context.set("html", string_value("<p>Clean text</p>"))
  let result = template.render(context).unwrap()
  assert_eq(result, "Hello worldappend and Clean text")
}

///|
test "url filters in template" {
  // Test URL filters in template context
  let template = @engine.compile(
    "Asset: {{ file | asset_url }} | Encoded: {{ query | url_encode }}",
  ).unwrap()
  let context = LiquidContext::new()
  context.set("file", string_value("app.js"))
  context.set("query", string_value("search term"))
  let result = template.render(context).unwrap()
  assert_eq(result, "Asset: /assets/app.js | Encoded: search%20term")
}

///|
test "advanced array filter chaining" {
  // Test chaining advanced array filters
  let template = @engine.compile("{{ items | slice | offset | limit | join }}").unwrap()
  let context = LiquidContext::new()
  let items = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
    string_value("e"),
  ])
  context.set("items", items)
  let result = template.render(context).unwrap()
  // slice (first 3) -> offset (skip first) -> limit (first 2) -> join
  assert_eq(result, "b, c")
}

///|
test "complex filter parameter chaining" {
  // Test complex filter parameter chaining
  let template = @engine.compile(
    "{{ text | replace: 'hello', 'hi' | split: ' ' | join: '_' | upcase }}",
  ).unwrap()
  let context = LiquidContext::new()
  context.set("text", string_value("hello world"))
  let result = template.render(context).unwrap()
  assert_eq(result, "HI_WORLD")
}

///|
test "filter parameters with quotes handling" {
  // Test filter parameters with different quote types
  let template = @engine.compile("{{ items | join: ', ' }}").unwrap()
  let context = LiquidContext::new()
  let items = array_value([
    string_value("red"),
    string_value("green"),
    string_value("blue"),
  ])
  context.set("items", items)
  let result = template.render(context).unwrap()
  assert_eq(result, "red, green, blue")
}

///|
test "filter parameter edge cases" {
  // Test various parameter edge cases to improve coverage

  // Test slice with different start positions
  let template1 = @engine.compile("{{ items | slice: 0 }}").unwrap()
  let context1 = LiquidContext::new()
  let items1 = array_value([string_value("a"), string_value("b")])
  context1.set("items", items1)
  context1.set("category", string_value("category"))
  context1.set("tech", string_value("tech"))
  let result1 = template1.render(context1).unwrap()
  assert_eq(result1, "[a]") // Start at 0

  // Test slice with position 3
  let template2 = @engine.compile("{{ items | slice: 3 }}").unwrap()
  let context2 = LiquidContext::new()
  let items2 = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
  ])
  context2.set("items", items2)
  let result2 = template2.render(context2).unwrap()
  assert_eq(result2, "[d]") // Start at 3

  // Test offset with different values
  let template3 = @engine.compile("{{ items | offset: 0 }}").unwrap()
  let context3 = LiquidContext::new()
  context3.set("items", items2)
  let result3 = template3.render(context3).unwrap()
  assert_eq(result3, "[a, b, c, d]") // No offset

  // Test offset with 3
  let template4 = @engine.compile("{{ items | offset: 3 }}").unwrap()
  let context4 = LiquidContext::new()
  context4.set("items", items2)
  let result4 = template4.render(context4).unwrap()
  assert_eq(result4, "[d]") // Skip first 3

  // Test limit with 1
  let template5 = @engine.compile("{{ items | limit: 1 }}").unwrap()
  let context5 = LiquidContext::new()
  context5.set("items", items2)
  let result5 = template5.render(context5).unwrap()
  assert_eq(result5, "[a]") // Take only 1

  // Test limit with 4
  let template6 = @engine.compile("{{ items | limit: 4 }}").unwrap()
  let context6 = LiquidContext::new()
  context6.set("items", items2)
  let result6 = template6.render(context6).unwrap()
  assert_eq(result6, "[a, b, c, d]") // Take 4
}

///|
test "filter parameter fallback cases" {
  // Test filter parameter parsing fallback cases

  // Test replace without quotes (unquoted parameters)
  let template1 = @engine.compile("{{ text | replace: old, new }}").unwrap()
  let context1 = LiquidContext::new()
  context1.set("text", string_value("This is old text"))
  context1.set("old", string_value("old"))
  context1.set("new", string_value("new"))
  let result1 = template1.render(context1).unwrap()
  assert_eq(result1, "This is new text") // Should handle unquoted params

  // Test remove without quotes
  let template2 = @engine.compile("{{ text | remove: bad }}").unwrap()
  let context2 = LiquidContext::new()
  context2.set("text", string_value("This is bad text"))
  context2.set("bad", string_value("bad"))
  let result2 = template2.render(context2).unwrap()
  assert_eq(result2, "This is  text") // Should handle unquoted param

  // Test split without quotes
  let template3 = @engine.compile("{{ text | split: '-' }}").unwrap()
  let context3 = LiquidContext::new()
  context3.set("text", string_value("apple-banana-cherry"))
  let result3 = template3.render(context3).unwrap()
  assert_eq(result3, "[apple, banana, cherry]") // Should handle quoted delimiter

  // Test split without parameters (default space)
  let template4 = @engine.compile("{{ text | split }}").unwrap()
  let context4 = LiquidContext::new()
  context4.set("text", string_value("apple banana cherry"))
  let result4 = template4.render(context4).unwrap()
  assert_eq(result4, "[apple, banana, cherry]") // Should use default space delimiter
}

///|
test "filter parameter quote handling comprehensive" {
  // Test quote handling in filter parameters - both single and double quotes

  // Test pluralize with double quotes
  let template1 = @engine.compile(
    "{{ count | pluralize: \"item\", \"items\" }}",
  ).unwrap()
  let context1 = LiquidContext::new()
  context1.set("count", number_value(2.0))
  let result1 = template1.render(context1).unwrap()
  assert_eq(result1, "2 items")

  // Test pluralize with single quotes
  let template2 = @engine.compile("{{ count | pluralize: 'item', 'items' }}").unwrap()
  let context2 = LiquidContext::new()
  context2.set("count", number_value(1.0))
  let result2 = template2.render(context2).unwrap()
  assert_eq(result2, "1 item")

  // Test sort_by with single quotes
  let template3 = @engine.compile("{{ items | sort_by: 'name' }}").unwrap()
  let context3 = LiquidContext::new()
  let obj1 = Map([])
  obj1.set("name", string_value("zebra"))
  let obj2 = Map([])
  obj2.set("name", string_value("apple"))
  context3.set("items", array_value([object_value(obj1), object_value(obj2)]))
  let result3 = template3.render(context3).unwrap()
  assert_eq(result3, "[{\"name\": apple}, {\"name\": zebra}]")

  // Test map filter with single quotes
  let template4 = @engine.compile("{{ items | map: 'name' }}").unwrap()
  let context4 = LiquidContext::new()
  context4.set("items", array_value([object_value(obj1), object_value(obj2)]))
  let result4 = template4.render(context4).unwrap()
  assert_eq(result4, "[zebra, apple]")
}

///|
test "filter chain integration edge cases" {
  // Test complex filter chains that might reveal edge cases

  // Test chaining with type transformations
  let template1 = @engine.compile("{{ text | split | first | upcase }}").unwrap()
  let context1 = LiquidContext::new()
  context1.set("text", string_value("hello world"))
  let result1 = template1.render(context1).unwrap()
  assert_eq(result1, "HELLO")

  // Test chaining with array manipulations
  let template2 = @engine.compile("{{ numbers | sort | reverse | first }}").unwrap()
  let context2 = LiquidContext::new()
  context2.set(
    "numbers",
    array_value([string_value("3"), string_value("1"), string_value("2")]),
  )
  let result2 = template2.render(context2).unwrap()
  assert_eq(result2, "3")

  // Test chaining with null/empty handling
  let template3 = @engine.compile(
    "{{ missing | default: 'fallback' | upcase }}",
  ).unwrap()
  let context3 = LiquidContext::new()
  // Don't set 'missing' variable
  let result3 = template3.render(context3).unwrap()
  assert_eq(result3, "FALLBACK")
}
