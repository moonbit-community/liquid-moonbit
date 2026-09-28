///|
test "condition evaluation truthy values" {
  // Test condition evaluation with truthy values
  let context = LiquidContext::new()

  // Boolean true
  context.set("bool_true", bool_value(true))
  let result1 = @liquid.compile(
      "{% if " + "bool_true" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result1, true)

  // Non-empty string
  context.set("non_empty_string", string_value("hello"))
  let result2 = @liquid.compile(
      "{% if " + "non_empty_string" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result2, true)

  // Non-zero number
  context.set("non_zero_number", number_value(42.0))
  let result3 = @liquid.compile(
      "{% if " + "non_zero_number" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result3, true)

  // Non-empty array
  context.set("non_empty_array", array_value([string_value("item")]))
  let result4 = @liquid.compile(
      "{% if " + "non_empty_array" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result4, true)

  // Non-empty object
  let obj_map = Map([])
  obj_map.set("key", string_value("value"))
  context.set("non_empty_object", object_value(obj_map))
  let result5 = @liquid.compile(
      "{% if " + "non_empty_object" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result5, true)
}

///|
test "condition evaluation distinguishes falsy and empty values" {
  // Only false and null are falsy in Liquid
  let context = LiquidContext::new()

  // Boolean false
  context.set("bool_false", bool_value(false))
  let result1 = @liquid.compile(
      "{% if " + "bool_false" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result1, false)

  // Empty string
  context.set("empty_string", string_value(""))
  let result2 = @liquid.compile(
      "{% if " + "empty_string" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result2, true)

  // Zero number
  context.set("zero_number", number_value(0.0))
  let result3 = @liquid.compile(
      "{% if " + "zero_number" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result3, true)

  // Empty array
  context.set("empty_array", array_value([]))
  let result4 = @liquid.compile(
      "{% if " + "empty_array" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result4, true)

  // Null value
  context.set("null_value", null_value())
  let result5 = @liquid.compile(
      "{% if " + "null_value" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result5, false)

  // Non-existent variable
  let result6 = @liquid.compile(
      "{% if " + "nonexistent" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result6, false)
}

///|
test "comparison operator equals" {
  // Test == operator
  let context = LiquidContext::new()
  context.set("name", string_value("Alice"))
  context.set("age", number_value(25.0))
  let result1 = @liquid.compile(
      "{% if " + "name == 'Alice'" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result1, true)
  let result2 = @liquid.compile(
      "{% if " + "name == 'Bob'" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result2, false)
  let result3 = @liquid.compile(
      "{% if " + "age == 25" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result3, true)
}

///|
test "comparison operator not equals" {
  // Test != operator
  let context = LiquidContext::new()
  context.set("status", string_value("active"))
  let result1 = @liquid.compile(
      "{% if " + "status != 'inactive'" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result1, true)
  let result2 = @liquid.compile(
      "{% if " + "status != 'active'" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result2, false)
}

///|
test "comparison operator greater than" {
  // Test > operator
  let context = LiquidContext::new()
  context.set("score", number_value(85.0))
  context.set("threshold", number_value(80.0))
  let result1 = @liquid.compile(
      "{% if " + "score > threshold" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result1, true)
  let result2 = @liquid.compile(
      "{% if " + "threshold > score" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result2, false)
}

///|
test "comparison operator less than" {
  // Test < operator
  let context = LiquidContext::new()
  context.set("price", number_value(50.0))
  context.set("budget", number_value(100.0))
  let result1 = @liquid.compile(
      "{% if " + "price < budget" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result1, true)
  let result2 = @liquid.compile(
      "{% if " + "budget < price" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result2, false)
}

///|
test "comparison operator greater than or equal" {
  // Test >= operator
  let context = LiquidContext::new()
  context.set("level", number_value(5.0))
  let result1 = @liquid.compile(
      "{% if " + "level >= 5" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result1, true)
  let result2 = @liquid.compile(
      "{% if " + "level >= 3" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result2, true)
  let result3 = @liquid.compile(
      "{% if " + "level >= 10" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result3, false)
}

///|
test "comparison operator less than or equal" {
  // Test <= operator
  let context = LiquidContext::new()
  context.set("attempts", number_value(3.0))
  let result1 = @liquid.compile(
      "{% if " + "attempts <= 3" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result1, true)
  let result2 = @liquid.compile(
      "{% if " + "attempts <= 5" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result2, true)
  let result3 = @liquid.compile(
      "{% if " + "attempts <= 1" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result3, false)
}

///|
test "comparison operator contains string" {
  // Test contains operator with strings
  let context = LiquidContext::new()
  context.set("message", string_value("Hello World"))
  let result1 = @liquid.compile(
      "{% if " +
      "message contains 'World'" +
      " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result1, true)
  let result2 = @liquid.compile(
      "{% if " +
      "message contains 'Universe'" +
      " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
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
  let result1 = @liquid.compile(
      "{% if " +
      "fruits contains 'banana'" +
      " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result1, true)
  let result2 = @liquid.compile(
      "{% if " +
      "fruits contains 'orange'" +
      " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result2, false)
}

///|
test "string comparison ordering" {
  // Test string comparison with ordering
  let context = LiquidContext::new()
  context.set("word1", string_value("apple"))
  context.set("word2", string_value("banana"))
  let result1 = @liquid.compile(
      "{% if " + "word1 < word2" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result1, true) // "apple" < "banana"
  let result2 = @liquid.compile(
      "{% if " + "word2 > word1" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result2, true) // "banana" > "apple"
}

///|
test "comparison with whitespace" {
  // Test comparison operators with various whitespace
  let context = LiquidContext::new()
  context.set("x", number_value(10.0))
  let result1 = @liquid.compile(
      "{% if " + "x   ==   10" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result1, true)
  let result2 = @liquid.compile(
      "{% if " + "x>=5" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result2, true)
  let result3 = @liquid.compile(
      "{% if " + "  x  <  20  " + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result3, true)
}

///|
test "logical operators with comparisons" {
  // Test logical operators combined with comparisons
  let context = LiquidContext::new()
  context.set("score", number_value(85.0))
  context.set("name", string_value("Alice"))

  // Test: score > 80 and name == 'Alice'
  let result1 = @liquid.compile(
      "{% if " +
      "score > 80 and name == 'Alice'" +
      " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result1, true)

  // Test: score < 50 or name == 'Alice'
  let result2 = @liquid.compile(
      "{% if " +
      "score < 50 or name == 'Alice'" +
      " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result2, true)

  // Test: not score < 80
  let result3 = @liquid.compile(
      "{% if " + "not score < 80" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result3, true)
}

///|
test "control flow with conditions" {
  // Test control flow with complex conditions
  let template = @liquid.compile(
    "{% if age >= 18 and is_member %}Welcome{% endif %}",
  ).unwrap()

  let context = LiquidContext::new()
  context.set("age", number_value(25.0))
  context.set("is_member", bool_value(true))
  let result = template.render(context).unwrap()
  assert_eq(result, "Welcome") // Condition evaluation works
}

///|
test "logical operator and" {
  // Test and operator
  let context = LiquidContext::new()
  context.set("is_admin", bool_value(true))
  context.set("is_active", bool_value(true))
  context.set("is_guest", bool_value(false))
  let result1 = @liquid.compile(
      "{% if " + "is_admin and is_active" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result1, true)
  let result2 = @liquid.compile(
      "{% if " + "is_admin and is_guest" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result2, false)
  let result3 = @liquid.compile(
      "{% if " + "is_guest and is_active" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result3, false)
}

///|
test "logical operator or" {
  // Test or operator
  let context = LiquidContext::new()
  context.set("is_admin", bool_value(true))
  context.set("is_moderator", bool_value(false))
  context.set("is_guest", bool_value(false))
  let result1 = @liquid.compile(
      "{% if " +
      "is_admin or is_moderator" +
      " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result1, true)
  let result2 = @liquid.compile(
      "{% if " +
      "is_moderator or is_guest" +
      " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result2, false)
  let result3 = @liquid.compile(
      "{% if " + "is_guest or is_admin" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result3, true)
}

///|
test "logical operator not" {
  // Test not operator
  let context = LiquidContext::new()
  context.set("is_visible", bool_value(true))
  context.set("is_hidden", bool_value(false))
  let result1 = @liquid.compile(
      "{% if " + "not is_visible" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result1, false)
  let result2 = @liquid.compile(
      "{% if " + "not is_hidden" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
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
  let result1 = @liquid.compile(
      "{% if " + "age >= 18 and is_member" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result1, true)

  // Test: has_discount or is_member
  let result2 = @liquid.compile(
      "{% if " +
      "has_discount or is_member" +
      " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result2, true)

  // Test: not has_discount and is_member
  let result3 = @liquid.compile(
      "{% if " +
      "not has_discount and is_member" +
      " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result3, true)
}

///|
test "logical operators with string contains" {
  // Test logical operators with contains
  let context = LiquidContext::new()
  context.set("title", string_value("Hello World"))
  context.set("category", string_value("tech"))
  let result1 = @liquid.compile(
      "{% if " +
      "title contains 'Hello' and category == 'tech'" +
      " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result1, true)
  let result2 = @liquid.compile(
      "{% if " +
      "title contains 'Goodbye' or category == 'tech'" +
      " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result2, true)
}

///|
test "case branches handle matching fallback and absent fallback" {
  let template = compile(
    "{% case role %}{% when 'admin' %}manage{% when 'editor' %}edit{% else %}read{% endcase %}|{% case role %}{% when 'admin' %}yes{% endcase %}",
  ).unwrap()
  for
    (role, expected) in [
      ("admin", "manage|yes"),
      ("editor", "edit|"),
      ("guest", "read|"),
    ] {
    let context = LiquidContext::new()
    context.set("role", string_value(role))
    assert_eq(template.render(context).unwrap(), expected)
  }
}

///|
test "edge case empty template" {
  // Test parsing and rendering empty template
  let template = @liquid.compile("").unwrap()

  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "")
}

///|
test "edge case only text template" {
  // Test template with only text (no variables)
  let template = @liquid.compile("Hello World!").unwrap()

  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "Hello World!")
}

///|
test "edge case malformed liquid tags" {
  assert_true(@liquid.compile("Hello {{ name") is Err(_))
}

///|
test "edge case nested liquid tags" {
  assert_true(
    @liquid.compile("Hello {{ {{ name }} }}!")
    .unwrap()
    .render(LiquidContext::new())
    is Err(_),
  )
}

///|
test "edge case multiple consecutive variables" {
  // Test multiple consecutive variables
  let template = @liquid.compile("{{a}}{{b}}{{c}}").unwrap()

  let context = LiquidContext::new()
  context.set("a", string_value("1"))
  context.set("b", string_value("2"))
  context.set("c", string_value("3"))
  let result = template.render(context).unwrap()
  assert_eq(result, "123")
}

///|
test "unless tag basic" {
  // Test unless tag (opposite of if)
  let template = @liquid.compile(
    "{% unless show_message %}Hidden content{% endunless %}",
  ).unwrap()

  let context = LiquidContext::new()
  context.set("show_message", bool_value(false))

  let result = template.render(context).unwrap()
  assert_eq(result, "Hidden content")
}

///|
test "if tag execution" {
  // Test if tag execution
  let template = @liquid.compile("{% if show_message %}Hello World{% endif %}").unwrap()

  let context = LiquidContext::new()
  context.set("show_message", bool_value(true))
  let result = template.render(context).unwrap()
  assert_eq(result, "Hello World")
}

///|
test "unless tag execution" {
  // Test unless tag execution
  let template = @liquid.compile(
    "{% unless is_hidden %}Visible content{% endunless %}",
  ).unwrap()
  let context = LiquidContext::new()
  context.set("is_hidden", bool_value(false))
  let result = template.render(context).unwrap()
  assert_eq(result, "Visible content")
}

///|
test "case tag execution" {
  // Test case tag execution
  let template = @liquid.compile(
    "{% case user_type %}{% when 'admin' %}Admin{% else %}User{% endcase %}",
  ).unwrap()
  let context = LiquidContext::new()
  context.set("user_type", string_value("guest"))
  let result = template.render(context).unwrap()
  assert_eq(result, "User")
}

///|
test "nested control flow" {
  // Test nested control flow structures
  let template = @liquid.compile(
    "{% if show %}{% for item in items %}{{ item }}{% endfor %}{% endif %}",
  ).unwrap()
  let context = LiquidContext::new()
  context.set("show", bool_value(true))
  let items = array_value([string_value("test")])
  context.set("items", items)
  let result = template.render(context).unwrap()
  assert_eq(result, "test")
}

///|
test "case statement in template parsing" {
  // Test case statement parsing in template
  let template = @liquid.compile(
    "{% case user_type %}{% when 'admin' %}Admin{% when 'user' %}User{% else %}Guest{% endcase %}",
  ).unwrap()
  let context = LiquidContext::new()
  context.set("user_type", string_value("user"))
  let result = template.render(context).unwrap()
  assert_eq(result, "User") // Should contain case logic
}
