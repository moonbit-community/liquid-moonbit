///|
test "filter date basic" {
  // Test basic date filter
  let date_value = string_value("2024-01-15")
  let date_result = apply_filter(date_value, "date", []).unwrap()
  assert_eq(date_result.to_string(), "2024-01-15")
}

///|
test "filter date non-year" {
  // Test date filter with non-year string
  let date_value = string_value("some-date")
  let date_result = apply_filter(date_value, "date", []).unwrap()
  assert_eq(date_result.to_string(), "some-date")
}

///|
test "filter date_to_string" {
  // Test date_to_string filter
  let date_value = string_value("2024-01-15")
  let result = apply_filter(date_value, "date_to_string", []).unwrap()
  assert_eq(result.to_string(), "15 Jan 2024")
}

///|
test "filter date_to_xmlschema" {
  // Test date_to_xmlschema filter
  let date_value = string_value("2024-01-15")
  let result = apply_filter(date_value, "date_to_xmlschema", []).unwrap()
  assert_eq(result.to_string(), "2024-01-15T00:00:00Z")
}

///|
test "filter date_to_rfc822" {
  // Test date_to_rfc822 filter
  let date_value = string_value("2024-01-01")
  let result = apply_filter(date_value, "date_to_rfc822", []).unwrap()
  assert_eq(result.to_string(), "Mon, 01 Jan 2024 00:00:00 +0000")
}

///|
test "filter strftime" {
  // Test strftime filter
  let date_value = string_value("2024-01-15")
  let result = apply_filter(date_value, "strftime", []).unwrap()
  assert_eq(result.to_string(), "2024-01-15")
}

///|
test "date filters in template" {
  // Test date filters in template context
  let template = @liquid.compile(
    "Published: {{ date | date }}\nISO: {{ date | date_to_xmlschema }}",
  ).unwrap()
  let context = LiquidContext::new()
  context.set("date", string_value("2024-12-25"))
  let result = template.render(context).unwrap()
  let expected = "Published: 2024-12-25\nISO: 2024-12-25T00:00:00Z"
  assert_eq(result, expected)
}

///|
test "date filter with format parameter" {
  // Test date filter with format string parameter
  let template = @liquid.compile("{{ date | date: '%B %d, %Y' }}").unwrap()
  let context = LiquidContext::new()
  context.set("date", string_value("2024-01-15"))
  let result = template.render(context).unwrap()
  assert_eq(result, "January 15, 2024")
}

///|
test "date filter with ISO format" {
  // Test date filter with ISO format
  let template = @liquid.compile("{{ date | date: '%Y-%m-%d' }}").unwrap()
  let context = LiquidContext::new()
  context.set("date", string_value("2023-12-25"))
  let result = template.render(context).unwrap()
  assert_eq(result, "2023-12-25")
}

///|
test "date filter with US format" {
  // Test date filter with US format
  let template = @liquid.compile("{{ date | date: '%m/%d/%Y' }}").unwrap()
  let context = LiquidContext::new()
  context.set("date", string_value("2024-06-15"))
  let result = template.render(context).unwrap()
  assert_eq(result, "06/15/2024")
}

///|
test "date filter with custom format" {
  // Test date filter with custom format
  let template = @liquid.compile("{{ date | date: '%A, %B %d' }}").unwrap()
  let context = LiquidContext::new()
  context.set("date", string_value("2024-03-10"))
  let result = template.render(context).unwrap()
  assert_eq(result, "Sunday, March 10")
}

///|
test "date filter without parameter" {
  // Test date filter without parameter (uses default)
  let template = @liquid.compile("{{ date | date }}").unwrap()
  let context = LiquidContext::new()
  context.set("date", string_value("2024-05-20"))
  let result = template.render(context).unwrap()
  assert_eq(result, "2024-05-20") // Uses default format
}

///|
test "date filter chaining with parameters" {
  // Test date filter chaining with other filters
  let template = @liquid.compile("{{ date | date: '%B %d, %Y' | upcase }}").unwrap()
  let context = LiquidContext::new()
  context.set("date", string_value("2023-11-30"))
  let result = template.render(context).unwrap()
  assert_eq(result, "NOVEMBER 30, 2023") // Parameter parsing issue
}

///|
test "filter edge cases date filters non-string" {
  // Test date filters with non-string inputs
  let num_val = number_value(42.0)
  let bool_val = bool_value(true)
  let arr_val = array_value([string_value("test")])
  assert_eq(apply_filter(num_val, "date", []).unwrap().to_string(), "42")
  assert_eq(
    apply_filter(bool_val, "date_to_string", []).unwrap().to_string(),
    "true",
  )
  assert_eq(
    apply_filter(arr_val, "date_to_xmlschema", []).unwrap().to_string(),
    "[test]",
  )
  assert_eq(
    apply_filter(num_val, "date_to_rfc822", []).unwrap().to_string(),
    "42",
  )
  assert_eq(apply_filter(bool_val, "strftime", []).unwrap().to_string(), "true")
}

///|
test "date filter format edge cases" {
  // Test date filter with different format parameters

  // Test date with double quotes
  let template1 = @liquid.compile("{{ date | date: \"%B %d, %Y\" }}").unwrap()
  let context1 = LiquidContext::new()
  context1.set("date", string_value("2024-01-15"))
  let result1 = template1.render(context1).unwrap()
  assert_eq(result1.contains("2024"), true) // Should handle double quotes

  // Test date with quoted format
  let template2 = @liquid.compile("{{ date | date: '%m/%d/%Y' }}").unwrap()
  let context2 = LiquidContext::new()
  context2.set("date", string_value("2023-12-25"))
  let result2 = template2.render(context2).unwrap()
  assert_eq(result2.contains("2023"), true) // Should handle quoted format
}

///|
test "date filter parameter variations" {

  // Test date filter with double quotes format parameter
  let date_string = string_value("2024-01-15")
  let result_double_quotes = apply_filter(date_string, "date", [
    string_value("%Y-%m-%d"),
  ]).unwrap()
  assert_eq(result_double_quotes.to_string(), "2024-01-15")

  // Test date filter with "%B %d, %Y" format
  let result_long_format = apply_filter(date_string, "date", [
    string_value("%B %d, %Y"),
  ]).unwrap()
  assert_eq(result_long_format.to_string(), "January 15, 2024")

  // Test date filter with "%m/%d/%Y" format and 2023 date
  let date_2023 = string_value("2023-12-25")
  let result_us_format = apply_filter(date_2023, "date", [
    string_value("%m/%d/%Y"),
  ]).unwrap()
  assert_eq(result_us_format.to_string(), "12/25/2023")

  // Test date filter with non-year date string
  let non_year_date = string_value("some-date")
  let result_non_year = apply_filter(non_year_date, "date", [
    string_value("%m/%d/%Y"),
  ]).unwrap()
  assert_eq(result_non_year.to_string(), "some-date")

  // Test date filter with non-string value
  let number_val = number_value(2024.0)
  let result_number = apply_filter(number_val, "date", [
    string_value("%B %d, %Y"),
  ]).unwrap()
  assert_eq(result_number.to_string(), "2024")
}

///|
test "date filter format edge cases v2" {
  // Test date filter with 2023 date and long format
  let date_2023 = string_value("2023-12-01")
  let result_2023_long = apply_filter(date_2023, "date", [
    string_value("%B %d, %Y"),
  ]).unwrap()
  assert_eq(result_2023_long.to_string(), "December 01, 2023")

  // Test date filter with non-2024 date and long format
  let date_other = string_value("2022-01-01")
  let result_other_long = apply_filter(date_other, "date", [
    string_value("%B %d, %Y"),
  ]).unwrap()
  assert_eq(result_other_long.to_string(), "January 01, 2022")
}

///|
test "date filter chaining" {
  // Test chaining date filters
  let template = @liquid.compile("{{ post_date | date | upcase }}").unwrap()
  let context = LiquidContext::new()
  context.set("post_date", string_value("2025-06-15"))
  let result = template.render(context).unwrap()
  assert_eq(result, "2025-06-15")
}
