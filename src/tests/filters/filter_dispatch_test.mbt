///|
test "typed filter arguments retain arrays objects and quotes" {
  let object = object_value(Map([("key", string_value("value"))]))
  let left = array_value([number_value(1)])
  let right = array_value([object])
  let result = @liquid.apply_filter(left, "concat", [right]).unwrap()
  assert_eq(
    @liquid.apply_filter(result, "at", [number_value(1)]).unwrap().to_string(),
    object.to_string(),
  )
  assert_eq(
    @liquid.apply_filter(string_value("a"), "replace", [
      string_value("a"),
      string_value("'quoted'"),
    ])
    .unwrap()
    .to_string(),
    "'quoted'",
  )
  assert_true(
    @liquid.apply_filter(left, "concat", [string_value("bad")]) is Err(_),
  )
  assert_true(@liquid.apply_filter(left, "unknown", []) is Err(_))
}

///|
test "direct filters and templates use the same typed dispatcher" {
  for
    (source, value, name, args) in [
      (
        "{{ 'abcdef' | slice: 2, 2 }}",
        string_value("abcdef"),
        "slice",
        [number_value(2), number_value(2)],
      ),
      (
        "{{ 10 | divided_by: 4.0 }}",
        number_value(10),
        "divided_by",
        [@liquid.float_value(4)],
      ),
      (
        "{{ 'a' | replace: 'a', 'b' }}",
        string_value("a"),
        "replace",
        [string_value("a"), string_value("b")],
      ),
    ] {
    assert_eq(
      compile(source).unwrap().render(LiquidContext::new()).unwrap(),
      apply_filter(value, name, args).unwrap().to_string(),
    )
  }
}
