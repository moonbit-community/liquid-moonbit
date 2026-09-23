///|
test "math filters use numeric arguments" {
  let context = LiquidContext::new()
  context.set("n", number_value(10))
  context.set("operand", number_value(7))
  assert_eq(
    @liquid.compile(
      "{{ n | plus: operand }}|{{ n | minus: 7 }}|{{ n | times: 7 }}|{{ n | divided_by: 4.0 }}|{{ n | modulo: 7 }}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "17|3|70|2.5|3",
  )
  assert_eq(
    @liquid.compile("{{ 10 | divided_by: 4 }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "2",
  )
  assert_eq(
    @liquid.compile("{{ '10' | plus: '-2.5' }}|{{ 3.14159 | round: 3 }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "7.5|3.142",
  )
  assert_eq(
    @liquid.compile("{{ n | divided_by: 0 }}|{{ n | modulo: 0 }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "|",
  )
}

///|
test "date filters format actual calendar values" {
  let context = LiquidContext::new()
  for date in ["2024-06-15", "2025-06-07", "2000-02-29", "1900-03-01"] {
    context.set("date", string_value(date))
    assert_eq(
      @liquid.compile("{{ date | date: '%Y-%m-%d' }}")
      .unwrap()
      .render(context)
      .unwrap(),
      date,
    )
  }
  assert_eq(
    @liquid.compile("{{ '2024-03-10' | date: '%A, %B %d' }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "Sunday, March 10",
  )
  assert_eq(
    @liquid.compile("{{ '2023-11-30' | date: '%B %d, %Y' }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "November 30, 2023",
  )
  assert_eq(
    @liquid.compile(
      "{{ '2024-02-29T23:07:09+08:00' | date: '%a %j %H:%M:%S %z' }}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "Thu 060 23:07:09 +0800",
  )
  assert_eq(
    apply_filter(string_value("2025-06-07"), "date_to_rfc822", [])
    .unwrap()
    .to_string(),
    "Sat, 07 Jun 2025 00:00:00 +0000",
  )
  for
    invalid in [
      "1900-02-29", "2025-02-29", "2024-13-01", "2024-01-32", "not a date", "2024-01-01T25:00:00Z",
    ] {
    assert_eq(
      apply_filter(string_value(invalid), "date", [string_value("%B %d, %Y")])
      .unwrap()
      .to_string(),
      invalid,
    )
  }
}
