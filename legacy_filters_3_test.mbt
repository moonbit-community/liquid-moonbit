///|
test "filter group_by" {
  // Test group_by filter - groups by string length
  let arr_value = array_value([
    string_value("cat"), // short (3)
    string_value("elephant"), // long (8)
    string_value("dog"), // short (3)
    string_value("butterfly"), // long (9)
  ])
  let group_result = apply_filter(arr_value, "group_by")
  assert_eq(group_result.to_string(), "[[cat, dog], [elephant, butterfly]]")
}

///|
test "advanced array filter chaining" {
  // Test chaining advanced array filters
  let template = parse("{{ items | slice | offset | limit | join }}")
  let context = LiquidContext::new()
  let items = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
    string_value("e"),
  ])
  context.set("items", items)
  let result = template.render(context)
  // slice (first 3) -> offset (skip first) -> limit (first 2) -> join
  assert_eq(result, "b, c")
}

// Money Filter Tests

///|
test "filter money" {
  // Test money filter
  let num_value = number_value(19.99)
  let num_result = apply_filter(num_value, "money")
  assert_eq(num_result.to_string(), "$19.99")
  let str_value = string_value("25.50")
  let str_result = apply_filter(str_value, "money")
  assert_eq(str_result.to_string(), "$25.50")
}

///|
test "filter money_with_currency" {
  // Test money_with_currency filter
  let num_value = number_value(100.0)
  let num_result = apply_filter(num_value, "money_with_currency")
  assert_eq(num_result.to_string(), "$100 USD")
  let str_value = string_value("50.25")
  let str_result = apply_filter(str_value, "money_with_currency")
  assert_eq(str_result.to_string(), "$50.25 USD")
}

///|
test "filter money_without_currency" {
  // Test money_without_currency filter
  let num_value = number_value(75.0)
  let num_result = apply_filter(num_value, "money_without_currency")
  assert_eq(num_result.to_string(), "75")
  let str_value = string_value("$30.99")
  let str_result = apply_filter(str_value, "money_without_currency")
  assert_eq(str_result.to_string(), "30.99")
}

///|
test "filter money_without_trailing_zeros" {
  // Test money_without_trailing_zeros filter
  let num_value = number_value(20.0)
  let num_result = apply_filter(num_value, "money_without_trailing_zeros")
  assert_eq(num_result.to_string(), "$20")
  let num_value2 = number_value(19.99)
  let num_result2 = apply_filter(num_value2, "money_without_trailing_zeros")
  assert_eq(num_result2.to_string(), "$19.99")
}

///|
test "money filters in template" {
  // Test money filters in template context
  let template = parse(
    "Price: {{ price | money }} | Full: {{ price | money_with_currency }}",
  )
  let context = LiquidContext::new()
  context.set("price", number_value(29.99))
  let result = template.render(context)
  assert_eq(result, "Price: $29.99 | Full: $29.99 USD")
}

// Control Flow Execution Tests

///|
test "slice filter with multiple parameters" {
  // Test slice filter with start and length parameters
  let template = parse("{{ items | slice: 1, 2 }}")
  let context = LiquidContext::new()
  let items = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
    string_value("e"),
  ])
  context.set("items", items)
  let result = template.render(context)
  assert_eq(result, "[b, c]") // Start at index 1, take 2 elements
}

///|
test "slice filter with string parameters" {
  // Test slice filter on strings with parameters
  let template = parse("{{ text | slice: 2, 3 }}")
  let context = LiquidContext::new()
  context.set("text", string_value("hello world"))
  let result = template.render(context)
  assert_eq(result, "llo") // Start at index 2, take 3 characters
}

///|
test "slice filter single parameter" {
  // Test slice filter with only start parameter
  let template = parse("{{ items | slice: 2 }}")
  let context = LiquidContext::new()
  let items = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
  ])
  context.set("items", items)
  let result = template.render(context)
  assert_eq(result, "[c]") // Start at index 2, default length 3 (but only 2 remaining)
}

///|
test "complex filter parameter combinations" {
  // Test complex combinations of filter parameters
  let template = parse(
    "{{ data | compact | slice: 1, 2 | join: ' | ' | upcase }}",
  )
  json_inspect(template, content={
    "nodes": [
      [
        "Variable",
        "data",
        [
          { "name": "compact", "parameters": [] },
          { "name": "slice", "parameters": ["1", "2"] },
          { "name": "join", "parameters": ["' | '"] },
          { "name": "upcase", "parameters": [] },
        ],
      ],
    ],
  })
  let context = LiquidContext::new()
  let data = array_value([
    string_value("first"),
    null_value(),
    string_value("second"),
    string_value("third"),
    string_value("fourth"),
  ])
  context.set("data", data)
  let result = template.render(context)
  assert_eq(result, "SECOND | THIRD") // compact -> slice(1,2) -> join(' | ') -> upcase
}

// Actual Control Flow Execution Tests

///|
test "replace filter with parameters" {
  // Test replace filter with old and new parameters
  let template = parse("{{ text | replace: 'old', 'new' }}")
  let context = LiquidContext::new()
  context.set("text", string_value("This is old text"))
  let result = template.render(context)
  assert_eq(result, "This is new text")
}

///|
test "remove filter with parameter" {
  // Test remove filter with target parameter
  let template = parse("{{ text | remove: 'bad' }}")
  let context = LiquidContext::new()
  context.set("text", string_value("This is bad text"))
  let result = template.render(context)
  assert_eq(result, "This is  text")
}

///|
test "split filter with delimiter parameter" {
  // Test split filter with custom delimiter
  let template = parse("{{ text | split: '-' }}")
  let context = LiquidContext::new()
  context.set("text", string_value("apple-banana-cherry"))
  let result = template.render(context)
  assert_eq(result, "[apple, banana, cherry]")
}

///|
test "join filter with proper separator" {
  // Test join filter with proper separator handling
  let template = parse("{{ items | join: ' | ' }}")
  let context = LiquidContext::new()
  let items = array_value([
    string_value("apple"),
    string_value("banana"),
    string_value("cherry"),
  ])
  context.set("items", items)
  let result = template.render(context)
  assert_eq(result, "apple | banana | cherry")
}

///|
test "join filter with arrow separator" {
  // Test join filter with arrow separator
  let template = parse("{{ items | join: ' -> ' }}")
  let context = LiquidContext::new()
  let items = array_value([
    string_value("step1"),
    string_value("step2"),
    string_value("step3"),
  ])
  context.set("items", items)
  let result = template.render(context)
  assert_eq(result, "step1 -> step2 -> step3")
}

///|
test "complex filter parameter chaining" {
  // Test complex filter parameter chaining
  let template = parse(
    "{{ text | replace: 'hello', 'hi' | split: ' ' | join: '_' | upcase }}",
  )
  let context = LiquidContext::new()
  context.set("text", string_value("hello world"))
  let result = template.render(context)
  assert_eq(result, "HI_WORLD")
}

///|
test "filter parameters with quotes handling" {
  // Test filter parameters with different quote types
  let template = parse("{{ items | join: ', ' }}")
  let context = LiquidContext::new()
  let items = array_value([
    string_value("red"),
    string_value("green"),
    string_value("blue"),
  ])
  context.set("items", items)
  let result = template.render(context)
  assert_eq(result, "red, green, blue")
}

// Elsif Implementation Tests

///|
test "offset filter with parameter" {
  // Test offset filter with specific parameter
  let template = parse("{{ items | offset: 2 }}")
  let context = LiquidContext::new()
  let items = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
    string_value("e"),
  ])
  context.set("items", items)
  let result = template.render(context)
  assert_eq(result, "[c, d, e]") // Skip first 2 elements
}

///|
test "limit filter with parameter" {
  // Test limit filter with specific parameter
  let template = parse("{{ items | limit: 3 }}")
  let context = LiquidContext::new()
  let items = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
    string_value("e"),
  ])
  context.set("items", items)
  let result = template.render(context)
  assert_eq(result, "[a, b, c]") // Take first 3 elements
}

///|
test "date filter with format parameter" {
  // Test date filter with format string parameter
  let template = parse("{{ date | date: '%B %d, %Y' }}")
  let context = LiquidContext::new()
  context.set("date", string_value("2024-01-15"))
  let result = template.render(context)
  assert_eq(result, "January 15, 2024")
}

///|
test "date filter with ISO format" {
  // Test date filter with ISO format
  let template = parse("{{ date | date: '%Y-%m-%d' }}")
  let context = LiquidContext::new()
  context.set("date", string_value("2023-12-25"))
  let result = template.render(context)
  assert_eq(result, "2023-12-25")
}

///|
test "date filter with US format" {
  // Test date filter with US format
  let template = parse("{{ date | date: '%m/%d/%Y' }}")
  let context = LiquidContext::new()
  context.set("date", string_value("2024-06-15"))
  let result = template.render(context)
  assert_eq(result, "06/15/2024")
}

///|
test "date filter with custom format" {
  // Test date filter with custom format
  let template = parse("{{ date | date: '%A, %B %d' }}")
  let context = LiquidContext::new()
  context.set("date", string_value("2024-03-10"))
  let result = template.render(context)
  assert_eq(result, "Sunday, March 10")
}

///|
test "date filter without parameter" {
  // Test date filter without parameter (uses default)
  let template = parse("{{ date | date }}")
  let context = LiquidContext::new()
  context.set("date", string_value("2024-05-20"))
  let result = template.render(context)
  assert_eq(result, "2024-05-20") // Uses default format
}

///|
test "date filter chaining with parameters" {
  // Test date filter chaining with other filters
  let template = parse("{{ date | date: '%B %d, %Y' | upcase }}")
  let context = LiquidContext::new()
  context.set("date", string_value("2023-11-30"))
  let result = template.render(context)
  assert_eq(result, "NOVEMBER 30, 2023") // Parameter parsing issue
}

// Where Filter with Parameters Tests

///|
test "where filter with property and value" {
  // Test where filter with property and value parameters
  let template = parse("{{ products | where: 'featured', 'true' }}")
  let context = LiquidContext::new()

  // Create products with featured property
  let product1 = Map([])
  product1.set("name", string_value("Product 1"))
  product1.set("featured", string_value("true"))
  let product2 = Map([])
  product2.set("name", string_value("Product 2"))
  product2.set("featured", string_value("false"))
  let product3 = Map([])
  product3.set("name", string_value("Product 3"))
  product3.set("featured", string_value("true"))
  let products = array_value([
    object_value(product1),
    object_value(product2),
    object_value(product3),
  ])
  context.set("products", products)
  let result = template.render(context)
  // Should contain only featured products
  assert_eq(result.contains("Product 1"), true)
  assert_eq(result.contains("Product 2"), false)
  assert_eq(result.contains("Product 3"), true)
}

///|
test "where filter with string array" {
  // Test where filter with string array
  let template = parse("{{ items | where: 'category', 'tech' }}")
  let context = LiquidContext::new()
  let items = array_value([
    string_value("tech-article"),
    string_value("sports-news"),
    string_value("tech-review"),
    string_value("health-tips"),
  ])
  context.set("items", items)
  let result = template.render(context)
  assert_eq(result, "[tech-article, tech-review]") // Should filter strings containing 'tech'
}

///|
test "where filter with no matches" {
  // Test where filter with no matching items
  let template = parse("{{ products | where: 'sale', 'true' }}")
  let context = LiquidContext::new()
  let product1 = Map([])
  product1.set("name", string_value("Product 1"))
  product1.set("sale", string_value("false"))
  let product2 = Map([])
  product2.set("name", string_value("Product 2"))
  product2.set("sale", string_value("false"))
  let products = array_value([object_value(product1), object_value(product2)])
  context.set("products", products)
  let result = template.render(context)
  assert_eq(result, "[]") // Should return empty array
}

///|
test "where filter with mixed object properties" {
  // Test where filter with different property types
  let template = parse("{{ items | where: 'active', 'yes' }}")
  let context = LiquidContext::new()
  let item1 = Map([])
  item1.set("name", string_value("Item 1"))
  item1.set("active", string_value("yes"))
  let item2 = Map([])
  item2.set("name", string_value("Item 2"))
  item2.set("active", string_value("no"))
  let item3 = Map([])
  item3.set("name", string_value("Item 3"))
  item3.set("active", string_value("yes"))
  let items = array_value([
    object_value(item1),
    object_value(item2),
    object_value(item3),
  ])
  context.set("items", items)
  let result = template.render(context)
  // Should contain items with active: 'yes'
  assert_eq(result.contains("Item 1"), true)
  assert_eq(result.contains("Item 2"), false)
  assert_eq(result.contains("Item 3"), true)
}

///|
test "where filter chaining" {
  // Test where filter chaining with other filters
  let template = parse(
    "{{ products | where: 'category', 'electronics' | limit: 2 | join }}",
  )
  let context = LiquidContext::new()
  let product1 = Map([])
  product1.set("name", string_value("Phone"))
  product1.set("category", string_value("electronics"))
  let product2 = Map([])
  product2.set("name", string_value("Book"))
  product2.set("category", string_value("books"))
  let product3 = Map([])
  product3.set("name", string_value("Laptop"))
  product3.set("category", string_value("electronics"))
  let products = array_value([
    object_value(product1),
    object_value(product2),
    object_value(product3),
  ])
  context.set("products", products)
  let result = template.render(context)
  // Should filter electronics, limit to 2, then join
  assert_eq(result.contains("Phone"), true)
  assert_eq(result.contains("Book"), false)
}

// Coverage Tests - Edge Cases and Error Conditions

///|
test "filter edge cases non-string inputs" {
  // Test filters with non-string inputs to improve coverage
  let num_val = number_value(42.0)
  let bool_val = bool_value(true)
  let null_val = null_value()

  // Test filters that should handle non-string gracefully
  assert_eq(apply_filter(num_val, "strip").to_string(), "42")
  assert_eq(apply_filter(bool_val, "escape").to_string(), "true")
  assert_eq(apply_filter(null_val, "upcase").to_string(), "null")
  assert_eq(apply_filter(num_val, "capitalize").to_string(), "42")
  assert_eq(apply_filter(bool_val, "split").to_string(), "true")
  assert_eq(apply_filter(null_val, "replace").to_string(), "null")
  assert_eq(apply_filter(num_val, "remove").to_string(), "42")
  assert_eq(apply_filter(bool_val, "prepend").to_string(), "true")
  assert_eq(apply_filter(null_val, "append").to_string(), "null")
  assert_eq(apply_filter(num_val, "newline_to_br").to_string(), "42")
  assert_eq(apply_filter(bool_val, "strip_html").to_string(), "true")
  assert_eq(apply_filter(null_val, "strip_newlines").to_string(), "null")
}

///|
test "filter edge cases non-array inputs" {
  // Test array filters with non-array inputs
  let str_val = string_value("hello")
  let num_val = number_value(42.0)
  let bool_val = bool_value(true)
  assert_eq(apply_filter(str_val, "join").to_string(), "hello")
  assert_eq(apply_filter(num_val, "select").to_string(), "42")
  assert_eq(apply_filter(bool_val, "reject").to_string(), "true")
  assert_eq(apply_filter(str_val, "compact").to_string(), "hello")
  assert_eq(apply_filter(num_val, "uniq").to_string(), "42")
  assert_eq(apply_filter(bool_val, "flatten").to_string(), "true")
  assert_eq(apply_filter(str_val, "group_by").to_string(), "hello")
  assert_eq(apply_filter(num_val, "map").to_string(), "42")
  assert_eq(apply_filter(bool_val, "where").to_string(), "true")
  assert_eq(apply_filter(str_val, "offset").to_string(), "hello")
  assert_eq(apply_filter(num_val, "limit").to_string(), "42")
}

///|
test "filter edge cases non-number inputs" {
  // Test math filters with non-number inputs
  let str_val = string_value("hello")
  let arr_val = array_value([string_value("test")])
  let bool_val = bool_value(true)
  assert_eq(apply_filter(str_val, "plus").to_string(), "hello")
  assert_eq(apply_filter(arr_val, "minus").to_string(), "[test]")
  assert_eq(apply_filter(bool_val, "times").to_string(), "true")
  assert_eq(apply_filter(str_val, "divided_by").to_string(), "hello")
  assert_eq(apply_filter(arr_val, "modulo").to_string(), "[test]")
  assert_eq(apply_filter(bool_val, "round").to_string(), "true")
  assert_eq(apply_filter(str_val, "ceil").to_string(), "hello")
  assert_eq(apply_filter(arr_val, "floor").to_string(), "[test]")
  assert_eq(apply_filter(bool_val, "abs").to_string(), "true")
}

///|
test "filter edge cases date filters non-string" {
  // Test date filters with non-string inputs
  let num_val = number_value(42.0)
  let bool_val = bool_value(true)
  let arr_val = array_value([string_value("test")])
  assert_eq(apply_filter(num_val, "date").to_string(), "42")
  assert_eq(apply_filter(bool_val, "date_to_string").to_string(), "true")
  assert_eq(apply_filter(arr_val, "date_to_xmlschema").to_string(), "[test]")
  assert_eq(apply_filter(num_val, "date_to_rfc822").to_string(), "42")
  assert_eq(apply_filter(bool_val, "strftime").to_string(), "true")
}
