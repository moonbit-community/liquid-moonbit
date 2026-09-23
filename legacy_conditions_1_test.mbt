///|
test "condition evaluation truthy values" {
  // Test condition evaluation with truthy values
  let context = LiquidContext::new()

  // Boolean true
  context.set("bool_true", bool_value(true))
  let result1 = evaluate_condition("bool_true", context)
  assert_eq(result1, true)

  // Non-empty string
  context.set("non_empty_string", string_value("hello"))
  let result2 = evaluate_condition("non_empty_string", context)
  assert_eq(result2, true)

  // Non-zero number
  context.set("non_zero_number", number_value(42.0))
  let result3 = evaluate_condition("non_zero_number", context)
  assert_eq(result3, true)

  // Non-empty array
  context.set("non_empty_array", array_value([string_value("item")]))
  let result4 = evaluate_condition("non_empty_array", context)
  assert_eq(result4, true)

  // Non-empty object
  let obj_map = Map([])
  obj_map.set("key", string_value("value"))
  context.set("non_empty_object", object_value(obj_map))
  let result5 = evaluate_condition("non_empty_object", context)
  assert_eq(result5, true)
}

///|
test "condition evaluation distinguishes falsy and empty values" {
  // Only false and null are falsy in Liquid
  let context = LiquidContext::new()

  // Boolean false
  context.set("bool_false", bool_value(false))
  let result1 = evaluate_condition("bool_false", context)
  assert_eq(result1, false)

  // Empty string
  context.set("empty_string", string_value(""))
  let result2 = evaluate_condition("empty_string", context)
  assert_eq(result2, true)

  // Zero number
  context.set("zero_number", number_value(0.0))
  let result3 = evaluate_condition("zero_number", context)
  assert_eq(result3, true)

  // Empty array
  context.set("empty_array", array_value([]))
  let result4 = evaluate_condition("empty_array", context)
  assert_eq(result4, true)

  // Null value
  context.set("null_value", null_value())
  let result5 = evaluate_condition("null_value", context)
  assert_eq(result5, false)

  // Non-existent variable
  let result6 = evaluate_condition("nonexistent", context)
  assert_eq(result6, false)
}

///|
test "edge case empty template" {
  // Test parsing and rendering empty template
  let template = parse("")
  json_inspect(template, content={ "nodes": [] })
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "")
}

///|
test "edge case only text template" {
  // Test template with only text (no variables)
  let template = parse("Hello World!")
  json_inspect(template, content={ "nodes": [["Text", "Hello World!"]] })
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "Hello World!")
}

///|
test "edge case malformed liquid tags" {
  // Test malformed liquid tags (unclosed)
  let template = parse("Hello {{ name")
  json_inspect(template, content={ "nodes": [["Text", "Hello {{ name"]] })
  let context = LiquidContext::new()
  context.set("name", string_value("World"))
  let result = template.render(context)
  assert_eq(result, "Hello {{ name") // Should treat as text
}

///|
test "edge case nested liquid tags" {
  // Test nested liquid tags (should not be processed)
  let template = parse("Hello {{ {{ name }} }}!")
  json_inspect(template, content={
    "nodes": [["Text", "Hello "], ["Variable", "{{ name", []], ["Text", " }}!"]],
  })
  let context = LiquidContext::new()
  context.set("name", string_value("World"))
  let result = template.render(context)
  // This will parse as "Hello " + " }}!"
  assert_eq(result, "Hello  }}!")
}

///|
test "edge case multiple consecutive variables" {
  // Test multiple consecutive variables
  let template = parse("{{a}}{{b}}{{c}}")
  json_inspect(template, content={
    "nodes": [
      ["Variable", "a", []],
      ["Variable", "b", []],
      ["Variable", "c", []],
    ],
  })
  let context = LiquidContext::new()
  context.set("a", string_value("1"))
  context.set("b", string_value("2"))
  context.set("c", string_value("3"))
  let result = template.render(context)
  assert_eq(result, "123")
}

///|
test "edge case variable with whitespace variations" {
  // Test variables with different whitespace patterns
  let template = parse("{{name}} {{ name }} {{  name  }}")
  json_inspect(template, content={
    "nodes": [
      ["Variable", "name", []],
      ["Text", " "],
      ["Variable", "name", []],
      ["Text", " "],
      ["Variable", "name", []],
    ],
  })
  let context = LiquidContext::new()
  context.set("name", string_value("World"))
  context.set(" name ", string_value("Space"))
  context.set("  name  ", string_value("More"))
  let result = template.render(context)
  assert_eq(result, "World World World") // All variables have same trimmed name "name"
}

///|
test "unless tag basic" {
  // Test unless tag (opposite of if)
  let template = parse("{% unless show_message %}Hidden content{% endunless %}")
  json_inspect(template, content={
    "nodes": [["Unless", "show_message", [["Text", "Hidden content"]]]],
  })
  let context = LiquidContext::new()
  context.set("show_message", bool_value(false))

  let result = template.render(context)
  assert_eq(result, "Hidden content")
}

///|
test "comparison operator equals" {
  // Test == operator
  let context = LiquidContext::new()
  context.set("name", string_value("Alice"))
  context.set("age", number_value(25.0))
  let result1 = evaluate_condition("name == 'Alice'", context)
  assert_eq(result1, true)
  let result2 = evaluate_condition("name == 'Bob'", context)
  assert_eq(result2, false)
  let result3 = evaluate_condition("age == 25", context)
  assert_eq(result3, true)
}

///|
test "comparison operator not equals" {
  // Test != operator
  let context = LiquidContext::new()
  context.set("status", string_value("active"))
  let result1 = evaluate_condition("status != 'inactive'", context)
  assert_eq(result1, true)
  let result2 = evaluate_condition("status != 'active'", context)
  assert_eq(result2, false)
}

///|
test "comparison operator greater than" {
  // Test > operator
  let context = LiquidContext::new()
  context.set("score", number_value(85.0))
  context.set("threshold", number_value(80.0))
  let result1 = evaluate_condition("score > threshold", context)
  assert_eq(result1, true)
  let result2 = evaluate_condition("threshold > score", context)
  assert_eq(result2, false)
}

///|
test "comparison operator less than" {
  // Test < operator
  let context = LiquidContext::new()
  context.set("price", number_value(50.0))
  context.set("budget", number_value(100.0))
  let result1 = evaluate_condition("price < budget", context)
  assert_eq(result1, true)
  let result2 = evaluate_condition("budget < price", context)
  assert_eq(result2, false)
}

///|
test "comparison operator greater than or equal" {
  // Test >= operator
  let context = LiquidContext::new()
  context.set("level", number_value(5.0))
  let result1 = evaluate_condition("level >= 5", context)
  assert_eq(result1, true)
  let result2 = evaluate_condition("level >= 3", context)
  assert_eq(result2, true)
  let result3 = evaluate_condition("level >= 10", context)
  assert_eq(result3, false)
}

///|
test "comparison operator less than or equal" {
  // Test <= operator
  let context = LiquidContext::new()
  context.set("attempts", number_value(3.0))
  let result1 = evaluate_condition("attempts <= 3", context)
  assert_eq(result1, true)
  let result2 = evaluate_condition("attempts <= 5", context)
  assert_eq(result2, true)
  let result3 = evaluate_condition("attempts <= 1", context)
  assert_eq(result3, false)
}

///|
test "comparison operator contains string" {
  // Test contains operator with strings
  let context = LiquidContext::new()
  context.set("message", string_value("Hello World"))
  let result1 = evaluate_condition("message contains 'World'", context)
  assert_eq(result1, true)
  let result2 = evaluate_condition("message contains 'Universe'", context)
  assert_eq(result2, false)
}

///|
test "comparison operator contains array" {
  // Test contains operator with arrays
  let context = LiquidContext::new()
  let fruits = array_value([
    string_value("apple"),
    string_value("banana"),
    string_value("cherry"),
  ])
  context.set("fruits", fruits)
  let result1 = evaluate_condition("fruits contains 'banana'", context)
  assert_eq(result1, true)
  let result2 = evaluate_condition("fruits contains 'orange'", context)
  assert_eq(result2, false)
}

///|
test "string comparison ordering" {
  // Test string comparison with ordering
  let context = LiquidContext::new()
  context.set("word1", string_value("apple"))
  context.set("word2", string_value("banana"))
  let result1 = evaluate_condition("word1 < word2", context)
  assert_eq(result1, true) // "apple" < "banana"
  let result2 = evaluate_condition("word2 > word1", context)
  assert_eq(result2, true) // "banana" > "apple"
}

///|
test "comparison with whitespace" {
  // Test comparison operators with various whitespace
  let context = LiquidContext::new()
  context.set("x", number_value(10.0))
  let result1 = evaluate_condition("x   ==   10", context)
  assert_eq(result1, true)
  let result2 = evaluate_condition("x>=5", context)
  assert_eq(result2, true)
  let result3 = evaluate_condition("  x  <  20  ", context)
  assert_eq(result3, true)
}

// Logical Operators Tests

///|
test "logical operators with comparisons" {
  // Test logical operators combined with comparisons
  let context = LiquidContext::new()
  context.set("score", number_value(85.0))
  context.set("name", string_value("Alice"))

  // Test: score > 80 and name == 'Alice'
  let result1 = evaluate_condition("score > 80 and name == 'Alice'", context)
  assert_eq(result1, true)

  // Test: score < 50 or name == 'Alice'
  let result2 = evaluate_condition("score < 50 or name == 'Alice'", context)
  assert_eq(result2, true)

  // Test: not score < 80
  let result3 = evaluate_condition("not score < 80", context)
  assert_eq(result3, true)
}

///|
test "if tag execution" {
  // Test if tag execution
  let template = parse("{% if show_message %}Hello World{% endif %}")
  json_inspect(template, content={
    "nodes": [["If", "show_message", [["Text", "Hello World"]], [], null]],
  })
  let context = LiquidContext::new()
  context.set("show_message", bool_value(true))
  let result = template.render(context)
  assert_eq(result, "Hello World")
}

///|
test "unless tag execution" {
  // Test unless tag execution
  let template = parse("{% unless is_hidden %}Visible content{% endunless %}")
  let context = LiquidContext::new()
  context.set("is_hidden", bool_value(false))
  let result = template.render(context)
  assert_eq(result, "Visible content")
}

///|
test "case tag execution" {
  // Test case tag execution
  let template = parse(
    "{% case user_type %}{% when 'admin' %}Admin{% else %}User{% endcase %}",
  )
  let context = LiquidContext::new()
  context.set("user_type", string_value("guest"))
  let result = template.render(context)
  assert_eq(result, "User")
}

///|
test "nested control flow" {
  // Test nested control flow structures
  let template = parse(
    "{% if show %}{% for item in items %}{{ item }}{% endfor %}{% endif %}",
  )
  let context = LiquidContext::new()
  context.set("show", bool_value(true))
  let items = array_value([string_value("test")])
  context.set("items", items)
  let result = template.render(context)
  assert_eq(result, "test")
}

///|
test "control flow with conditions" {
  // Test control flow with complex conditions
  let template = parse("{% if age >= 18 and is_member %}Welcome{% endif %}")
  json_inspect(template, content={
    "nodes": [
      ["If", "age >= 18 and is_member", [["Text", "Welcome"]], [], null],
    ],
  })
  let context = LiquidContext::new()
  context.set("age", number_value(25.0))
  context.set("is_member", bool_value(true))
  let result = template.render(context)
  assert_eq(result, "Welcome") // Condition evaluation works
}

// Cycle Tag Tests

///|
test "if tag true condition execution" {
  // Test if tag with true condition
  let context = LiquidContext::new()
  context.set("show", bool_value(true))
  let if_test = if_node(
    "show",
    [text_node("Visible")],
    Some([text_node("Hidden")]),
  )
  let result = render_node(if_test, context)
  assert_eq(result, "Visible") // Should render true branch
}

///|
test "if tag false condition execution" {
  // Test if tag with false condition
  let context = LiquidContext::new()
  context.set("show", bool_value(false))
  let if_test = if_node(
    "show",
    [text_node("Visible")],
    Some([text_node("Hidden")]),
  )
  let result = render_node(if_test, context)
  assert_eq(result, "Hidden") // Should render false branch
}

///|
test "unless tag execution logic" {
  // Test unless tag execution (opposite of if)
  let context = LiquidContext::new()
  context.set("hide", bool_value(false))
  let unless_test = unless_node("hide", [text_node("Content shown")])
  let result = render_node(unless_test, context)
  assert_eq(result, "Content shown") // Should render since condition is false
  context.set("hide", bool_value(true))
  let result2 = render_node(unless_test, context)
  assert_eq(result2, "") // Should not render since condition is true
}

///|
test "case tag with matching condition" {
  // Test case tag with matching condition
  let context = LiquidContext::new()
  context.set("user_type", string_value("admin"))
  let when_branches = [
    ("\'admin\'", [text_node("Admin Panel")]),
    ("\'user\'", [text_node("User Dashboard")]),
  ]
  let case_test = case_node(
    "user_type",
    when_branches,
    Some([text_node("Guest Access")]),
  )
  let result = render_node(case_test, context)
  assert_eq(result, "Admin Panel") // Should match admin branch
}

///|
test "case tag with no match" {
  // Test case tag with no matching condition
  let context = LiquidContext::new()
  context.set("user_type", string_value("guest"))
  let when_branches = [
    ("\'admin\'", [text_node("Admin Panel")]),
    ("\'user\'", [text_node("User Dashboard")]),
  ]
  let case_test = case_node(
    "user_type",
    when_branches,
    Some([text_node("Guest Access")]),
  )
  let result = render_node(case_test, context)
  assert_eq(result, "Guest Access") // Should use else branch
}

///|
test "complex condition evaluation in control flow" {
  // Test complex conditions in control flow
  let context = LiquidContext::new()
  context.set("age", number_value(25.0))
  context.set("is_member", bool_value(true))
  let if_test = if_node(
    "age >= 18 and is_member",
    [text_node("Access granted")],
    Some([text_node("Access denied")]),
  )
  let result = render_node(if_test, context)
  assert_eq(result, "Access granted") // Complex condition should evaluate to true
}

// Enhanced Template Loading Tests

///|
test "if node with elsif branches" {
  // Test if node with elsif branches
  let context = LiquidContext::new()
  context.set("score", number_value(75.0))
  let elsif_branches = [
    ("score >= 90", [text_node("A Grade")]),
    ("score >= 80", [text_node("B Grade")]),
    ("score >= 70", [text_node("C Grade")]),
  ]
  let if_test = if_node_with_elsif(
    "score >= 100",
    [text_node("Perfect Score")],
    elsif_branches,
    Some([text_node("F Grade")]),
  )
  let result = render_node(if_test, context)
  assert_eq(result, "C Grade") // Should match the score >= 70 elsif branch
}

///|
test "elsif with multiple conditions" {
  // Test elsif with multiple different conditions
  let context = LiquidContext::new()
  context.set("user_type", string_value("member"))
  context.set("is_premium", bool_value(false))
  let elsif_branches = [
    ("user_type == 'admin'", [text_node("Admin Access")]),
    ("user_type == 'member' and is_premium", [text_node("Premium Member")]),
    ("user_type == 'member'", [text_node("Basic Member")]),
  ]
  let if_test = if_node_with_elsif(
    "user_type == 'owner'",
    [text_node("Owner Access")],
    elsif_branches,
    Some([text_node("Guest Access")]),
  )
  let result = render_node(if_test, context)
  assert_eq(result, "Basic Member") // Should match the member elsif branch
}

///|
test "elsif no match fallback to else" {
  // Test elsif with no matching conditions falls back to else
  let context = LiquidContext::new()
  context.set("level", number_value(5.0))
  let elsif_branches = [
    ("level >= 100", [text_node("Expert")]),
    ("level >= 50", [text_node("Advanced")]),
    ("level >= 20", [text_node("Intermediate")]),
  ]
  let if_test = if_node_with_elsif(
    "level >= 200",
    [text_node("Master")],
    elsif_branches,
    Some([text_node("Beginner")]),
  )
  let result = render_node(if_test, context)
  assert_eq(result, "Beginner") // Should fall back to else since no elsif matches
}

///|
test "elsif first matching condition wins" {
  // Test that first matching elsif condition wins
  let context = LiquidContext::new()
  context.set("value", number_value(85.0))
  let elsif_branches = [
    ("value >= 80", [text_node("First Match")]),
    ("value >= 70", [text_node("Second Match")]),
    ("value >= 60", [text_node("Third Match")]),
  ]
  let if_test = if_node_with_elsif(
    "value >= 100",
    [text_node("Perfect")],
    elsif_branches,
    Some([text_node("Low")]),
  )
  let result = render_node(if_test, context)
  assert_eq(result, "First Match") // Should use first matching elsif, not continue checking
}
