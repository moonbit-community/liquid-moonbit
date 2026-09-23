///|
test "forloop object properties" {
  // Test that For loops create proper forloop objects
  let context = LiquidContext::new()
  let items = array_value([
    string_value("first"),
    string_value("second"),
    string_value("third"),
  ])
  context.set("items", items)

  // Create a simple For node to test forloop object creation
  let for_node = for_node("item", "items", [
    variable_node("forloop.index", []),
    text_node(" "),
    variable_node("item", []),
    text_node(" "),
    variable_node("forloop.first", []),
    text_node(" "),
    variable_node("forloop.last", []),
  ])
  let result = render_node(for_node, context)
  // Should render: "1 first true false 2 second false false 3 third false true "
  assert_eq(result.contains("1 first true false"), true)
  assert_eq(result.contains("3 third false true"), true)
}

///|
test "forloop index and rindex" {
  // Test forloop index and reverse index
  let context = LiquidContext::new()
  let items = array_value([string_value("a"), string_value("b")])
  context.set("items", items)
  let for_node = for_node("item", "items", [
    variable_node("forloop.index", []),
    text_node(":"),
    variable_node("forloop.rindex", []),
    text_node(" "),
  ])
  let result = render_node(for_node, context)
  assert_eq(result, "1:2 2:1 ")
}

///|
test "forloop length property" {
  // Test forloop length property
  let context = LiquidContext::new()
  let items = array_value([
    string_value("apple"),
    string_value("banana"),
    string_value("cherry"),
  ])
  context.set("items", items)
  let for_node = for_node("item", "items", [
    variable_node("forloop.length", []),
    text_node(" "),
  ])
  let result = render_node(for_node, context)
  assert_eq(result, "3 3 3 ") // Length is 3 for all iterations
}

///|
test "forloop with empty array" {
  // Test forloop with empty array
  let context = LiquidContext::new()
  let empty_items = array_value([])
  context.set("empty_items", empty_items)
  let for_node = for_node("item", "empty_items", [
    text_node("Should not appear"),
  ])
  let result = render_node(for_node, context)
  assert_eq(result, "") // No output for empty array
}

///|
test "for tag execution" {
  // Test for tag execution
  let template = parse("{% for item in items %}{{ item }}{% endfor %}")
  json_inspect(template, content={
    "nodes": [
      [
        "For",
        "item",
        "items",
        [["Variable", "item", []]],
        { "reversed": false },
      ],
    ],
  })
  let context = LiquidContext::new()
  let items = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
  ])
  context.set("items", items)
  let result = template.render(context)
  assert_eq(result, "abc")
}

///|
test "cycle tag basic" {
  // Test basic cycle tag
  let template = parse("{% cycle 'odd', 'even' %}")
  json_inspect(template, content={
    "nodes": [["Cycle", "default", ["odd", "even"]]],
  })
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "odd") // Returns first value
}

///|
test "cycle tag parsing" {
  // Test cycle tag parsing recognition
  let template = parse("{% cycle group1: 'red', 'green', 'blue' %}")
  json_inspect(template, content={
    "nodes": [["Cycle", "group1", ["red", "green", "blue"]]],
  })
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "red")
}

///|
test "cycle node helper" {
  // Test cycle node helper function
  let context = LiquidContext::new()
  let cycle_test = cycle_node("colors", ["red", "green", "blue"])
  let result = render_node(cycle_test, context)
  assert_eq(result, "red") // Returns first value
}

///|
test "cycle in template context" {
  // Test cycle tag in template with other content
  let template = parse(
    "Row: {% cycle 'odd', 'even' %} | Next: {% cycle 'odd', 'even' %}",
  )
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "Row: odd | Next: even") // Both cycles return first value
}

// TableRow Tag Tests

///|
test "tablerow tag basic" {
  // Test basic tablerow tag
  let template = parse(
    "{% tablerow item in items cols: 2 %}{{ item }}{% endtablerow %}",
  )
  let context = LiquidContext::new()
  let items = array_value([
    string_value("A"),
    string_value("B"),
    string_value("C"),
    string_value("D"),
  ])
  context.set("items", items)
  let result = template.render(context)
  assert_eq(result.contains("<table>"), true)
  assert_eq(result.contains("<tr>"), true)
  assert_eq(result.contains("<td>"), true)
  assert_eq(
    result, "<table>\n<tr>\n<td>A</td>\n<td>B</td>\n</tr>\n<tr>\n<td>C</td>\n<td>D</td>\n</tr>\n</table>",
  )
}

///|
test "tablerow node helper" {
  // Test tablerow node helper function
  let context = LiquidContext::new()
  let items = array_value([
    string_value("1"),
    string_value("2"),
    string_value("3"),
  ])
  context.set("products", items)
  let tablerow_test = tablerow_node(
    "product",
    "products",
    [
      variable_node("product", []),
      text_node(" ("),
      variable_node("tablerowloop.index", []),
      text_node(")"),
    ],
    2,
  )
  let result = render_node(tablerow_test, context)
  assert_eq(result.contains("<table>"), true)
  assert_eq(result.contains("<tr>"), true)
  assert_eq(result.contains("<td>"), true)
}

///|
test "tablerow with different column counts" {
  // Test tablerow with different column counts
  let context = LiquidContext::new()
  let items = array_value([
    string_value("A"),
    string_value("B"),
    string_value("C"),
    string_value("D"),
    string_value("E"),
  ])
  context.set("items", items)
  let tablerow_3_cols = tablerow_node("item", "items", [text_node("X")], 3)
  let result = render_node(tablerow_3_cols, context)

  // Should have 2 rows: [A,B,C] and [D,E]
  let row_count = result.split("<tr>").collect().length() - 1 // -1 for split behavior
  assert_eq(row_count >= 2, true)
}

///|
test "tablerowloop object properties" {
  // Test tablerowloop object properties
  let context = LiquidContext::new()
  let items = array_value([string_value("first"), string_value("second")])
  context.set("items", items)
  let tablerow_test = tablerow_node(
    "item",
    "items",
    [
      variable_node("tablerowloop.index", []),
      text_node(":"),
      variable_node("tablerowloop.col", []),
      text_node(":"),
      variable_node("tablerowloop.first", []),
    ],
    2,
  )
  let result = render_node(tablerow_test, context)
  assert_eq(result.contains("1:1:true"), true) // First item properties
  assert_eq(result.contains("2:2:false"), true) // Second item properties
}

///|
test "tablerow with empty array" {
  // Test tablerow with empty array
  let context = LiquidContext::new()
  let empty_items = array_value([])
  context.set("empty", empty_items)
  let tablerow_test = tablerow_node("item", "empty", [text_node("content")], 2)
  let result = render_node(tablerow_test, context)
  assert_eq(result, "<table>\n</table>") // Empty table for empty array
}

// Break and Continue Tag Tests

///|
test "break tag parsing" {
  // Test break tag parsing
  let template = parse("{% break %}")
  json_inspect(template, content={ "nodes": ["Break"] })
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "") // Break produces no output
}

///|
test "continue tag parsing" {
  // Test continue tag parsing
  let template = parse("{% continue %}")
  json_inspect(template, content={ "nodes": ["Continue"] })
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "") // Continue produces no output
}

///|
test "break node helper" {
  // Test break node helper function
  let context = LiquidContext::new()
  let break_test = break_node()
  let result = render_node(break_test, context)
  assert_eq(result, "") // Break produces no output
}

///|
test "continue node helper" {
  // Test continue node helper function
  let context = LiquidContext::new()
  let continue_test = continue_node()
  let result = render_node(continue_test, context)
  assert_eq(result, "") // Continue produces no output
}

///|
test "break and continue in template" {
  // Test break and continue in template context
  let template = parse("Start {% break %} Middle {% continue %} End")
  let context = LiquidContext::new()
  let result = template.render(context)
  assert_eq(result, "Start  Middle  End") // Break and continue produce no output
}

///|
test "loop control flow recognition" {
  // Test that loop control flow is recognized
  let template = parse(
    "{% for item in items %}{{ item }}{% if item == 'stop' %}{% break %}{% endif %}{% endfor %}",
  )
  let context = LiquidContext::new()
  let items = array_value([
    string_value("a"),
    string_value("stop"),
    string_value("b"),
  ])
  context.set("items", items)
  let result = template.render(context)
  assert_eq(result, "astop")
}

// Liquid Tag Tests

///|
test "for loop actual execution" {
  // Test for loop actual execution
  let context = LiquidContext::new()
  let items = array_value([
    string_value("apple"),
    string_value("banana"),
    string_value("cherry"),
  ])
  context.set("fruits", items)
  let for_test = for_node("fruit", "fruits", [
    variable_node("fruit", []),
    text_node(":"),
    variable_node("forloop.index", []),
    text_node(" "),
  ])
  let result = render_node(for_test, context)
  assert_eq(result.contains("apple:1"), true)
  assert_eq(result.contains("banana:2"), true)
  assert_eq(result.contains("cherry:3"), true)
}

///|
test "forloop complete properties" {
  // Test all forloop properties comprehensively
  let context = LiquidContext::new()
  let items = array_value([
    string_value("first"),
    string_value("second"),
    string_value("third"),
    string_value("fourth"),
  ])
  context.set("items", items)
  let for_test = for_node("item", "items", [
    text_node("Item "),
    variable_node("forloop.index", []),
    text_node(" ("),
    variable_node("forloop.index0", []),
    text_node(") - "),
    variable_node("item", []),
    text_node(" - First: "),
    variable_node("forloop.first", []),
    text_node(" Last: "),
    variable_node("forloop.last", []),
    text_node(" RIndex: "),
    variable_node("forloop.rindex", []),
    text_node(" RIndex0: "),
    variable_node("forloop.rindex0", []),
    text_node(" Length: "),
    variable_node("forloop.length", []),
    text_node("\n"),
  ])
  let result = render_node(for_test, context)

  // Check first item properties
  assert_eq(
    result.contains(
      "Item 1 (0) - first - First: true Last: false RIndex: 4 RIndex0: 3 Length: 4",
    ),
    true,
  )

  // Check last item properties
  assert_eq(
    result.contains(
      "Item 4 (3) - fourth - First: false Last: true RIndex: 1 RIndex0: 0 Length: 4",
    ),
    true,
  )
}

///|
test "forloop in nested context" {
  // Test forloop properties in nested context
  let context = LiquidContext::new()
  let categories = array_value([string_value("tech"), string_value("sports")])
  context.set("categories", categories)
  let for_test = for_node("category", "categories", [
    text_node("Category "),
    variable_node("forloop.index", []),
    text_node(": "),
    variable_node("category", [filter("upcase", [])]),
    text_node(" ("),
    variable_node("forloop.first", []),
    text_node("/"),
    variable_node("forloop.last", []),
    text_node(")\n"),
  ])
  let result = render_node(for_test, context)
  assert_eq(result.contains("Category 1: TECH (true/false)"), true)
  assert_eq(result.contains("Category 2: SPORTS (false/true)"), true)
}

///|
test "forloop edge cases" {
  // Test forloop with edge cases
  let context = LiquidContext::new()

  // Single item array
  let single_item = array_value([string_value("only")])
  context.set("single", single_item)
  let for_single = for_node("item", "single", [
    variable_node("forloop.first", []),
    text_node(":"),
    variable_node("forloop.last", []),
    text_node(":"),
    variable_node("forloop.length", []),
  ])
  let result = render_node(for_single, context)
  assert_eq(result, "true:true:1") // Single item is both first and last
}

///|
test "additional edge cases for remaining coverage" {
  // Test comparison operators with string comparisons
  let context = LiquidContext::new()
  context.set("str1", string_value("apple"))
  context.set("str2", string_value("banana"))

  // Test string >= comparison
  let result_gte = evaluate_condition("str2 >= str1", context)
  assert_eq(result_gte, true) // "banana" >= "apple"

  // Test string <= comparison
  let result_lte = evaluate_condition("str1 <= str2", context)
  assert_eq(result_lte, true) // "apple" <= "banana"

  // Test comparison with non-matching condition
  let result_nonmatch = evaluate_condition("str1 > str2", context)
  assert_eq(result_nonmatch, false) // "apple" > "banana" is false

  // Test slice with single parameter "1"
  let arr = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
  ])
  let filter_slice_1 = filter("slice", ["1"])
  let result_slice_1 = apply_filter_with_params(arr, filter_slice_1)
  match result_slice_1 {
    Array(sliced) => assert_eq(sliced.length(), 1) // one element from position 1
    _ => fail("Expected Array result")
  }

  // Test slice with string parameter "3"
  let filter_slice_3 = filter("slice", ["3"])
  let result_slice_3 = apply_filter_with_params(arr, filter_slice_3)
  match result_slice_3 {
    Array(sliced) => assert_eq(sliced.length(), 0) // no elements from position 3
    _ => fail("Expected Array result")
  }

  // Test slice with string where start position is out of bounds
  let long_string = string_value("test")
  // Use a recognized parameter that will create out of bounds condition
  // Since we only have "0", "1", "2", "3" as recognized parameters, let's create a scenario
  // where we test the bounds checking logic by using a short string with parameters that work
  let filter_edge = filter("slice", ["3", "2"]) // start at pos 3, length 2
  let result_edge = apply_filter_with_params(long_string, filter_edge)
  // "test" has length 4, so position 3 exists (it's "t"), slice(3,2) should give "t"
  assert_eq(result_edge.to_string(), "t")

  // Test slice with string where end_pos calculation is needed
  let filter_end_calc = filter("slice", ["0", "2"])
  let result_end_calc = apply_filter_with_params(long_string, filter_end_calc)
  assert_eq(result_end_calc.to_string(), "te")
}

///|
test "for loop with limit modifier" {
  // Test for loop with limit modifier using helper function
  let context = LiquidContext::new()
  let items = array_value([
    string_value("first"),
    string_value("second"),
    string_value("third"),
    string_value("fourth"),
  ])
  context.set("items", items)
  let modifiers = for_loop_modifiers(Some(2), None, false)
  let for_test = for_node_with_modifiers(
    "item",
    "items",
    [variable_node("item", []), text_node(" ")],
    modifiers,
  )
  let result = render_node(for_test, context)
  // Should only show first 2 items
  assert_eq(result, "first second ")
}

///|
test "for loop with offset modifier" {
  // Test for loop with offset modifier using helper function
  let context = LiquidContext::new()
  let items = array_value([
    string_value("first"),
    string_value("second"),
    string_value("third"),
    string_value("fourth"),
  ])
  context.set("items", items)
  let modifiers = for_loop_modifiers(None, Some(1), false)
  let for_test = for_node_with_modifiers(
    "item",
    "items",
    [variable_node("item", []), text_node(" ")],
    modifiers,
  )
  let result = render_node(for_test, context)
  // Should skip first item
  assert_eq(result, "second third fourth ")
}

///|
test "for loop with reversed modifier" {
  // Test for loop with reversed modifier using helper function
  let context = LiquidContext::new()
  let items = array_value([
    string_value("first"),
    string_value("second"),
    string_value("third"),
  ])
  context.set("items", items)
  let modifiers = for_loop_modifiers(None, None, true)
  let for_test = for_node_with_modifiers(
    "item",
    "items",
    [variable_node("item", []), text_node(" ")],
    modifiers,
  )
  let result = render_node(for_test, context)
  // Should be in reverse order: third second first
  assert_eq(result, "third second first ")
}

///|
test "for loop with combined modifiers" {
  // Test for loop with limit, offset, and reversed modifiers using helper function
  let context = LiquidContext::new()
  let items = array_value([
    string_value("first"),
    string_value("second"),
    string_value("third"),
    string_value("fourth"),
    string_value("fifth"),
  ])
  context.set("items", items)
  let modifiers = for_loop_modifiers(Some(2), Some(1), true)
  let for_test = for_node_with_modifiers(
    "item",
    "items",
    [variable_node("item", []), text_node(" ")],
    modifiers,
  )
  let result = render_node(for_test, context)
  // Should: skip first (offset:1), take 2 items (limit:2), then reverse
  // Items after offset: [second, third, fourth, fifth]
  // Items after limit: [second, third]
  // Items after reverse: [third, second]
  assert_eq(result, "third second ")
}

///|
test "for loop modifiers with forloop object" {
  // Test that forloop properties work correctly with modifiers using helper function
  let context = LiquidContext::new()
  let items = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
  ])
  context.set("items", items)
  let modifiers = for_loop_modifiers(Some(2), None, false)
  let for_test = for_node_with_modifiers(
    "item",
    "items",
    [
      variable_node("forloop.index", []),
      text_node(": "),
      variable_node("item", []),
      text_node(" "),
    ],
    modifiers,
  )
  let result = render_node(for_test, context)
  // Should show indices 1 and 2 for the limited items
  assert_eq(result, "1: a 2: b ")
}

///|
test "enhanced forloop properties" {
  // Test enhanced forloop object properties
  let context = LiquidContext::new()
  let items = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
  ])
  context.set("items", items)
  let for_test = for_node("item", "items", [
    variable_node("forloop.cycle", []),
    text_node(" "),
    variable_node("forloop.name", []),
    text_node(" "),
    variable_node("item", []),
    text_node(" "),
  ])
  let result = render_node(for_test, context)
  // Should show cycle (odd/even) and collection name
  assert_eq(result.contains("items"), true) // Collection name
  assert_eq(result.contains("odd"), true) // First iteration is odd
  assert_eq(result.contains("even"), true) // Second iteration is even
}

///|
test "enhanced tablerowloop properties" {
  // Test enhanced tablerowloop object properties
  let context = LiquidContext::new()
  let items = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
  ])
  context.set("items", items)
  let tablerow_test = tablerow_node(
    "item",
    "items",
    [
      variable_node("tablerowloop.col_first", []),
      text_node(" "),
      variable_node("tablerowloop.col_last", []),
      text_node(" "),
      variable_node("tablerowloop.rindex", []),
      text_node(" "),
    ],
    2,
  )
  let result = render_node(tablerow_test, context)
  // Should show column first/last indicators and reverse index
  assert_eq(result.contains("true"), true) // col_first for first column
  assert_eq(result.contains("false"), true) // col_last for first column
  assert_eq(result.contains("4"), true) // rindex for first item
}

///|
test "enhanced tablerowloop comprehensive" {
  // Test all enhanced tablerowloop properties
  let context = LiquidContext::new()
  let items = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
  ])
  context.set("items", items)
  let tablerow_test = tablerow_node(
    "item",
    "items",
    [
      text_node("Col: "),
      variable_node("tablerowloop.col", []),
      text_node(", ColFirst: "),
      variable_node("tablerowloop.col_first", []),
      text_node(", ColLast: "),
      variable_node("tablerowloop.col_last", []),
      text_node(", RIndex: "),
      variable_node("tablerowloop.rindex", []),
      text_node(" | "),
    ],
    2,
  )
  let result = render_node(tablerow_test, context)
  // Should show enhanced column and index properties
  assert_eq(result.contains("Col: 1"), true) // First column
  assert_eq(result.contains("ColFirst: true"), true) // First in row
  assert_eq(result.contains("ColLast: false"), true) // Not last in row
  assert_eq(result.contains("RIndex: 4"), true) // Reverse index
  assert_eq(result.contains("Col: 2"), true) // Second column
  assert_eq(result.contains("ColLast: true"), true) // Last in row
}

///|
test "additional edge cases for complete coverage" {
  // Test more edge cases to increase coverage

  // Test strip_tags with non-string
  let strip_tags_result = apply_filter(number_value(123.0), "strip_tags")
  assert_eq(strip_tags_result.to_string(), "123")

  // Test normalize_whitespace with non-string
  let normalize_result = apply_filter(bool_value(true), "normalize_whitespace")
  assert_eq(normalize_result.to_string(), "true")

  // Test various filters with different input types to hit uncovered branches
  let filters_to_test = [
    "strip_tags", "normalize_whitespace", "truncatewords", "at",
  ]
  let non_string_inputs = [number_value(42.0), bool_value(false), null_value()]
  for filter_name in filters_to_test {
    for input in non_string_inputs {
      let result = apply_filter(input, filter_name)
      // These should all return the original input when type doesn't match
      assert_eq(result.to_string(), input.to_string())
    }
  }
}
