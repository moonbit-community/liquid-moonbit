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
