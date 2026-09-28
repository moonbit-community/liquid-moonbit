///|
test "complex filter parameter combinations" {
  // Test complex combinations of filter parameters
  let template = @engine.compile(
    "{{ data | compact | slice: 1, 2 | join: ' | ' | upcase }}",
  ).unwrap()

  let context = LiquidContext::new()
  let data = array_value([
    string_value("first"),
    null_value(),
    string_value("second"),
    string_value("third"),
    string_value("fourth"),
  ])
  context.set("data", data)
  let result = template.render(context).unwrap()
  assert_eq(result, "SECOND | THIRD") // compact -> slice(1,2) -> join(' | ') -> upcase
}

///|
test "where filter edge cases" {
  // Test where filter edge cases

  // Test where with unquoted parameters
  let template1 = @engine.compile("{{ items | where: category, tech }}").unwrap()
  let context1 = LiquidContext::new()
  let items1 = array_value([
    string_value("tech-article"),
    string_value("sports-news"),
  ])
  context1.set("items", items1)
  context1.set("category", string_value("category"))
  context1.set("tech", string_value("tech"))
  let result1 = template1.render(context1).unwrap()
  assert_eq(result1, "[tech-article]") // Should handle unquoted params

  // Test where with object without matching property
  let context2 = LiquidContext::new()
  let obj_without_prop = Map([])
  obj_without_prop.set("name", string_value("test"))
  // No 'category' property
  let items2 = array_value([object_value(obj_without_prop)])
  context2.set("items", items2)
  let where_test = apply_filter(items2, "where", [
    string_value("category"),
    string_value("tech"),
  ]).unwrap()
  assert_eq(where_test.to_string(), "[]") // Should return empty for no matches

  // Test where without enough parameters (fallback)
  let where_fallback = apply_filter(items1, "where", [
    string_value("only_one_param"),
  ]).unwrap()
  assert_eq(where_fallback.to_string(), "[]") // Should fallback to basic where (no matches)
}

///|
test "filter parameters join" {
  // Test join filter with custom separator
  let template = @engine.compile("{{ items | join: ' | ' }}").unwrap()
  let context = LiquidContext::new()
  let items = array_value([
    string_value("apple"),
    string_value("banana"),
    string_value("cherry"),
  ])
  context.set("items", items)
  let result = template.render(context).unwrap()
  assert_eq(result, "apple | banana | cherry")
}

///|
test "filter parameters join with quotes" {
  // Test join filter with quoted separator
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
test "join filter with proper separator" {
  // Test join filter with proper separator handling
  let template = @engine.compile("{{ items | join: ' | ' }}").unwrap()
  let context = LiquidContext::new()
  let items = array_value([
    string_value("apple"),
    string_value("banana"),
    string_value("cherry"),
  ])
  context.set("items", items)
  let result = template.render(context).unwrap()
  assert_eq(result, "apple | banana | cherry")
}

///|
test "join filter with arrow separator" {
  // Test join filter with arrow separator
  let template = @engine.compile("{{ items | join: ' -> ' }}").unwrap()
  let context = LiquidContext::new()
  let items = array_value([
    string_value("step1"),
    string_value("step2"),
    string_value("step3"),
  ])
  context.set("items", items)
  let result = template.render(context).unwrap()
  assert_eq(result, "step1 -> step2 -> step3")
}

///|
test "where filter with property and value" {
  // Test where filter with property and value parameters
  let template = @engine.compile("{{ products | where: 'featured', 'true' }}").unwrap()
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
  let result = template.render(context).unwrap()
  // Should contain only featured products
  assert_eq(result.contains("Product 1"), true)
  assert_eq(result.contains("Product 2"), false)
  assert_eq(result.contains("Product 3"), true)
}

///|
test "where filter with string array" {
  // Test where filter with string array
  let template = @engine.compile("{{ items | where: 'category', 'tech' }}").unwrap()
  let context = LiquidContext::new()
  let items = array_value([
    string_value("tech-article"),
    string_value("sports-news"),
    string_value("tech-review"),
    string_value("health-tips"),
  ])
  context.set("items", items)
  let result = template.render(context).unwrap()
  assert_eq(result, "[tech-article, tech-review]") // Should filter strings containing 'tech'
}

///|
test "where filter with no matches" {
  // Test where filter with no matching items
  let template = @engine.compile("{{ products | where: 'sale', 'true' }}").unwrap()
  let context = LiquidContext::new()
  let product1 = Map([])
  product1.set("name", string_value("Product 1"))
  product1.set("sale", string_value("false"))
  let product2 = Map([])
  product2.set("name", string_value("Product 2"))
  product2.set("sale", string_value("false"))
  let products = array_value([object_value(product1), object_value(product2)])
  context.set("products", products)
  let result = template.render(context).unwrap()
  assert_eq(result, "[]") // Should return empty array
}

///|
test "where filter with mixed object properties" {
  // Test where filter with different property types
  let template = @engine.compile("{{ items | where: 'active', 'yes' }}").unwrap()
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
  let result = template.render(context).unwrap()
  // Should contain items with active: 'yes'
  assert_eq(result.contains("Item 1"), true)
  assert_eq(result.contains("Item 2"), false)
  assert_eq(result.contains("Item 3"), true)
}

///|
test "where filter chaining" {
  // Test where filter chaining with other filters
  let template = @engine.compile(
    "{{ products | where: 'category', 'electronics' | limit: 2 | join }}",
  ).unwrap()
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
  let result = template.render(context).unwrap()
  // Should filter electronics, limit to 2, then join
  assert_eq(result.contains("Phone"), true)
  assert_eq(result.contains("Book"), false)
}

///|
test "sort_by filter with missing property" {
  // Test uncovered case where object doesn't have the specified property
  let template = @engine.compile("{{ items | sort_by: 'missing_prop' }}").unwrap()
  let context = LiquidContext::new()
  let obj1 = Map([])
  obj1.set("name", string_value("Alice"))
  let obj2 = Map([])
  obj2.set("name", string_value("Bob"))
  let items = array_value([object_value(obj1), object_value(obj2)])
  context.set("items", items)
  let result = template.render(context).unwrap()
  assert_eq(result, "[{\"name\": Alice}, {\"name\": Bob}]") // Should handle missing property
}

///|
test "sort_by filter with non-object items" {
  // Test uncovered case where array contains non-object items
  let template = @engine.compile("{{ items | sort_by: 'name' }}").unwrap()
  let context = LiquidContext::new()
  let items = array_value([
    string_value("zebra"),
    string_value("apple"),
    number_value(42.0),
  ])
  context.set("items", items)
  let result = template.render(context).unwrap()
  assert_eq(result, "[42, apple, zebra]") // Should sort by string representation
}

///|
test "sort_by filter non-array input" {
  // Test uncovered case where input is not an array
  let template = @engine.compile("{{ text | sort_by: 'prop' }}").unwrap()
  let context = LiquidContext::new()
  context.set("text", string_value("not an array"))
  let result = template.render(context).unwrap()
  assert_eq(result, "not an array") // Should return original value
}

///|
test "conditional branches choose the first match and retain fallback" {
  let template = compile(
    "{% if score >= 100 %}perfect{% elsif score >= 80 %}high{% elsif score >= 60 %}pass{% else %}low{% endif %}|{% unless active %}hidden{% endunless %}",
  ).unwrap()
  for
    (score, expected) in [
      (100, "perfect|hidden"),
      (85, "high|hidden"),
      (65, "pass|hidden"),
      (50, "low|hidden"),
    ] {
    let context = LiquidContext::new()
    context.set("score", number_value(score.to_double()))
    context.set("active", bool_value(false))
    assert_eq(template.render(context).unwrap(), expected)
  }
}
