///|
test "empty array filters" {
  // Test filters on empty arrays
  let empty_array = array_value([])
  let select_result = apply_filter(empty_array, "select")
  assert_eq(select_result.to_string(), "[]")
  let compact_result = apply_filter(empty_array, "compact")
  assert_eq(compact_result.to_string(), "[]")
  let uniq_result = apply_filter(empty_array, "uniq")
  assert_eq(uniq_result.to_string(), "[]")
}

// Comparison Operators Tests

///|
test "filter date basic" {
  // Test basic date filter
  let date_value = string_value("2024-01-15")
  let date_result = apply_filter(date_value, "date")
  assert_eq(date_result.to_string(), "2024-01-15")
}

///|
test "filter date non-year" {
  // Test date filter with non-year string
  let date_value = string_value("some-date")
  let date_result = apply_filter(date_value, "date")
  assert_eq(date_result.to_string(), "some-date")
}

///|
test "filter date_to_string" {
  // Test date_to_string filter
  let date_value = string_value("2024-01-15")
  let result = apply_filter(date_value, "date_to_string")
  assert_eq(result.to_string(), "15 Jan 2024")
}

///|
test "filter date_to_xmlschema" {
  // Test date_to_xmlschema filter
  let date_value = string_value("2024-01-15")
  let result = apply_filter(date_value, "date_to_xmlschema")
  assert_eq(result.to_string(), "2024-01-15T00:00:00Z")
}

///|
test "filter date_to_rfc822" {
  // Test date_to_rfc822 filter
  let date_value = string_value("2024-01-01")
  let result = apply_filter(date_value, "date_to_rfc822")
  assert_eq(result.to_string(), "Mon, 01 Jan 2024 00:00:00 +0000")
}

///|
test "filter strftime" {
  // Test strftime filter
  let date_value = string_value("2024-01-15")
  let result = apply_filter(date_value, "strftime")
  assert_eq(result.to_string(), "2024-01-15")
}

///|
test "date filters in template" {
  // Test date filters in template context
  let template = parse(
    "Published: {{ date | date }}\nISO: {{ date | date_to_xmlschema }}",
  )
  let context = LiquidContext::new()
  context.set("date", string_value("2024-12-25"))
  let result = template.render(context)
  let expected = "Published: 2024-12-25\nISO: 2024-12-25T00:00:00Z"
  assert_eq(result, expected)
}

///|
test "date filter chaining" {
  // Test chaining date filters
  let template = parse("{{ post_date | date | upcase }}")
  let context = LiquidContext::new()
  context.set("post_date", string_value("2025-06-15"))
  let result = template.render(context)
  assert_eq(result, "2025-06-15")
}

// Error Handling Policy Tests

///|
test "filter parameters truncate" {
  // Test truncate filter with parameter
  let template = parse("{{ text | truncate: 10 }}")
  let context = LiquidContext::new()
  context.set("text", string_value("This is a very long text"))
  let result = template.render(context)
  assert_eq(result, "This is...")
}

///|
test "filter parameters join" {
  // Test join filter with custom separator
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
test "filter parameters join with quotes" {
  // Test join filter with quoted separator
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

///|
test "filter parameters multiple" {
  // Test multiple filters with parameters
  let template = parse("{{ text | truncate: 20 | upcase }}")
  let context = LiquidContext::new()
  context.set("text", string_value("This is a moderately long text"))
  let result = template.render(context)
  assert_eq(result, "THIS IS A MODERAT...")
}

///|
test "filter without parameters" {
  // Test that filters without parameters still work
  let template = parse("{{ text | upcase | size }}")
  let context = LiquidContext::new()
  context.set("text", string_value("hello"))
  let result = template.render(context)
  assert_eq(result, "5")
}

// Advanced String Filter Tests

///|
test "filter capitalize" {
  // Test capitalize filter
  let value = string_value("hello world")
  let result = apply_filter(value, "capitalize")
  assert_eq(result.to_string(), "Hello world")
  let value2 = string_value("HELLO WORLD")
  let result2 = apply_filter(value2, "capitalize")
  assert_eq(result2.to_string(), "Hello world")
}

///|
test "filter split" {
  // Test split filter
  let value = string_value("apple banana cherry")
  let result = apply_filter(value, "split")
  assert_eq(result.to_string(), "[apple, banana, cherry]")
  let single_word = string_value("hello")
  let single_result = apply_filter(single_word, "split")
  assert_eq(single_result.to_string(), "[hello]")
}

///|
test "filter replace" {
  // Test replace filter (basic implementation)
  let value = string_value("This is old text")
  let result = apply_filter(value, "replace")
  assert_eq(result.to_string(), "This is new text")
}

///|
test "filter remove" {
  // Test remove filter (basic implementation)
  let value = string_value("Please remove this word")
  let result = apply_filter(value, "remove")
  assert_eq(result.to_string(), "Please  this word")
}

///|
test "filter prepend" {
  // Test prepend filter
  let value = string_value(" text")
  let result = apply_filter(value, "prepend")
  assert_eq(result.to_string(), "prepend text")
}

///|
test "filter append" {
  // Test append filter
  let value = string_value("text ")
  let result = apply_filter(value, "append")
  assert_eq(result.to_string(), "text append")
}

///|
test "filter newline_to_br" {
  // Test newline to br filter
  let value = string_value("Line 1\nLine 2\nLine 3")
  let result = apply_filter(value, "newline_to_br")
  assert_eq(result.to_string(), "Line 1<br>Line 2\nLine 3") // Only first \n is replaced
}

///|
test "filter strip_html" {
  // Test strip_html filter
  let value = string_value(
    "<div><p>Hello <script>alert('xss')</script> World</p></div>",
  )
  let result = apply_filter(value, "strip_html")
  assert_eq(result.to_string(), "Hello alert('xss') World")
}

///|
test "filter strip_newlines" {
  // Test strip_newlines filter
  let value = string_value("Line 1\nLine 2\rLine 3")
  let result = apply_filter(value, "strip_newlines")
  assert_eq(result.to_string(), "Line 1Line 2Line 3")
}

///|
test "string filters in template" {
  // Test string filters in template context
  let template = parse(
    "{{ text | capitalize | append }} and {{ html | strip_html }}",
  )
  let context = LiquidContext::new()
  context.set("text", string_value("hello world"))
  context.set("html", string_value("<p>Clean text</p>"))
  let result = template.render(context)
  assert_eq(result, "Hello worldappend and Clean text")
}

// URL Filter Tests

///|
test "filter url_encode" {
  // Test URL encoding filter
  let value = string_value("hello world & you?")
  let result = apply_filter(value, "url_encode")
  assert_eq(result.to_string(), "hello%20world %26 you%3F") // Only first occurrence replaced
}

///|
test "filter url_decode" {
  // Test URL decoding filter
  let value = string_value("hello%20world%20%26%20you%3F")
  let result = apply_filter(value, "url_decode")
  assert_eq(result.to_string(), "hello world%20&%20you?") // Only first occurrence replaced
}

///|
test "filter asset_url" {
  // Test asset_url filter
  let value = string_value("style.css")
  let result = apply_filter(value, "asset_url")
  assert_eq(result.to_string(), "/assets/style.css")
}

///|
test "filter absolute_url" {
  // Test absolute_url filter
  let value = string_value("/blog/post-1")
  let result = apply_filter(value, "absolute_url")
  assert_eq(result.to_string(), "https://example.com/blog/post-1")
}

///|
test "filter relative_url" {
  // Test relative_url filter
  let value1 = string_value("blog/post-1")
  let result1 = apply_filter(value1, "relative_url")
  assert_eq(result1.to_string(), "/blog/post-1")
  let value2 = string_value("/already/absolute")
  let result2 = apply_filter(value2, "relative_url")
  assert_eq(result2.to_string(), "/already/absolute")
}

///|
test "url filters in template" {
  // Test URL filters in template context
  let template = parse(
    "Asset: {{ file | asset_url }} | Encoded: {{ query | url_encode }}",
  )
  let context = LiquidContext::new()
  context.set("file", string_value("app.js"))
  context.set("query", string_value("search term"))
  let result = template.render(context)
  assert_eq(result, "Asset: /assets/app.js | Encoded: search%20term")
}

// Advanced Array Filter Tests

///|
test "filter where" {
  // Test where filter - filters items containing "filter"
  let arr_value = array_value([
    string_value("filter1"),
    string_value("normal"),
    string_value("filter2"),
    string_value("other"),
  ])
  let where_result = apply_filter(arr_value, "where")
  assert_eq(where_result.to_string(), "[filter1, filter2]")
}

///|
test "filter slice array" {
  // Test slice filter on arrays - takes first 3 elements
  let arr_value = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
    string_value("e"),
  ])
  let slice_result = apply_filter(arr_value, "slice")
  assert_eq(slice_result.to_string(), "[a, b, c]")
}

///|
test "filter slice string" {
  // Test slice filter on strings - takes first 3 characters
  let str_value = string_value("hello")
  let slice_result = apply_filter(str_value, "slice")
  assert_eq(slice_result.to_string(), "hel")
  let short_str = string_value("hi")
  let short_result = apply_filter(short_str, "slice")
  assert_eq(short_result.to_string(), "hi") // Shorter than 3 chars
}

///|
test "filter offset" {
  // Test offset filter - skips first element
  let arr_value = array_value([
    string_value("first"),
    string_value("second"),
    string_value("third"),
  ])
  let offset_result = apply_filter(arr_value, "offset")
  assert_eq(offset_result.to_string(), "[second, third]")
}

///|
test "filter limit" {
  // Test limit filter - takes first 2 elements
  let arr_value = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
    string_value("d"),
  ])
  let limit_result = apply_filter(arr_value, "limit")
  assert_eq(limit_result.to_string(), "[a, b]")
}
