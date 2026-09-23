///|
test "elsif with complex conditions" {
  // Test elsif with complex logical conditions
  let context = LiquidContext::new()
  context.set("age", number_value(25.0))
  context.set("is_student", bool_value(true))
  context.set("has_id", bool_value(true))
  let elsif_branches = [
    ("age >= 65", [text_node("Senior Discount")]),
    ("age < 18", [text_node("Youth Discount")]),
    ("is_student and has_id", [text_node("Student Discount")]),
  ]
  let if_test = if_node_with_elsif(
    "age >= 100",
    [text_node("Centenarian")],
    elsif_branches,
    Some([text_node("Regular Price")]),
  )
  let result = render_node(if_test, context)
  assert_eq(result, "Student Discount") // Should match complex elsif condition
}

// Enhanced Case/When Implementation Tests

///|
test "case statement with when branches" {
  // Test case statement with proper when branch matching
  let context = LiquidContext::new()
  context.set("role", string_value("admin"))
  let when_branches = [
    ("\'admin\'", [text_node("Administrator Dashboard")]),
    ("\'editor\'", [text_node("Content Editor")]),
    ("\'viewer\'", [text_node("Read Only Access")]),
  ]
  let case_test = case_node(
    "role",
    when_branches,
    Some([text_node("Unknown Role")]),
  )
  let result = render_node(case_test, context)
  assert_eq(result, "Administrator Dashboard") // Should match admin when branch
}

///|
test "case statement no match uses else" {
  // Test case statement with no matching when branch
  let context = LiquidContext::new()
  context.set("status", string_value("pending"))
  let when_branches = [
    ("\'active\'", [text_node("System Active")]),
    ("\'inactive\'", [text_node("System Inactive")]),
    ("\'maintenance\'", [text_node("Under Maintenance")]),
  ]
  let case_test = case_node(
    "status",
    when_branches,
    Some([text_node("Unknown Status")]),
  )
  let result = render_node(case_test, context)
  assert_eq(result, "Unknown Status") // Should use else branch
}

///|
test "case with multiple when conditions" {
  // Test case with multiple when conditions
  let context = LiquidContext::new()
  context.set("user_level", string_value("member"))
  let when_branches = [
    ("\'guest\'", [text_node("Limited Access")]),
    ("\'member\'", [text_node("Member Benefits")]),
    ("\'premium\'", [text_node("Premium Features")]),
    ("\'admin\'", [text_node("Full Control")]),
  ]
  let case_test = case_node("user_level", when_branches, None)
  let result = render_node(case_test, context)
  assert_eq(result, "Member Benefits") // Should match member when branch
}

///|
test "case statement in template parsing" {
  // Test case statement parsing in template
  let template = parse(
    "{% case user_type %}{% when 'admin' %}Admin{% when 'user' %}User{% else %}Guest{% endcase %}",
  )
  let context = LiquidContext::new()
  context.set("user_type", string_value("user"))
  let result = template.render(context)
  assert_eq(result, "User") // Should contain case logic
}

// Offset and Limit Filter Parameters Tests

///|
test "boundary condition comprehensive testing" {
  // Test boundary conditions across all filters

  // Empty string tests
  let empty_string = string_value("")
  let string_filters = [
    "upcase", "downcase", "trim", "capitalize", "split", "replace", "remove",
  ]
  for filter_name in string_filters {
    let result = apply_filter(empty_string, filter_name)
    // Should handle empty strings gracefully
    match result {
      String(_) | Array(_) => () // Valid responses
      _ => fail("Filter " + filter_name + " should handle empty strings")
    }
  }

  // Empty array tests
  let empty_array = array_value([])
  let array_filters = [
    "first", "last", "reverse", "sort", "join", "select", "reject", "compact", "uniq",
    "flatten",
  ]
  for filter_name in array_filters {
    let result = apply_filter(empty_array, filter_name)
    // Should handle empty arrays gracefully
    match result {
      Array(_) | String(_) | Null => () // Valid responses
      _ => fail("Filter " + filter_name + " should handle empty arrays")
    }
  }

  // Zero and negative number tests
  let edge_numbers = [0.0, -0.0, -1.0, -100.0]
  let number_filters = [
    "money", "money_with_currency", "money_without_currency", "money_without_trailing_zeros",
  ]
  for filter_name in number_filters {
    for num in edge_numbers {
      let result = apply_filter(number_value(num), filter_name)
      match result {
        String(_) => () // Money filters should return strings
        _ =>
          fail(
            "Money filter " +
            filter_name +
            " should return String for " +
            num.to_string(),
          )
      }
    }
  }
}
