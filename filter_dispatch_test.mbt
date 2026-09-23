///|
test "typed and legacy filter entry points agree" {
  let context = LiquidContext::new()
  for
    (name, source, value, args, legacy) in [
      (
        "slice",
        "{{ 'abcdef' | slice: 2, 2 }}",
        string_value("abcdef"),
        [number_value(2), number_value(2)],
        ["2", "2"],
      ),
      (
        "divided_by",
        "{{ 10 | divided_by: 4.0 }}",
        number_value(10),
        [@liquid.float_value(4)],
        ["4.0"],
      ),
      (
        "replace",
        "{{ 'a' | replace: 'a', 'b' }}",
        string_value("a"),
        [string_value("a"), string_value("b")],
        ["'a'", "'b'"],
      ),
    ] {
    let direct = @liquid.apply_filter_values(value, name, args)
      .unwrap()
      .to_string()
    assert_eq(parse(source).render(context), direct)
    assert_eq(
      apply_filter_with_params(value, filter(name, legacy)).to_string(),
      direct,
    )
  }
  assert_eq(
    apply_filter(string_value(""), "default").to_string(),
    parse("{{ '' | default }}").render(context),
  )
}

///|
test "typed filter arguments retain arrays objects and quotes" {
  let object = object_value(Map([("key", string_value("value"))]))
  let left = array_value([number_value(1)])
  let right = array_value([object])
  let result = @liquid.apply_filter_values(left, "concat", [right]).unwrap()
  assert_eq(
    @liquid.apply_filter_values(result, "at", [number_value(1)])
    .unwrap()
    .to_string(),
    object.to_string(),
  )
  assert_eq(
    @liquid.apply_filter_values(string_value("a"), "replace", [
      string_value("a"),
      string_value("'quoted'"),
    ])
    .unwrap()
    .to_string(),
    "'quoted'",
  )
  assert_true(
    @liquid.apply_filter_values(left, "concat", [string_value("bad")]) is Err(_),
  )
  assert_true(@liquid.apply_filter_values(left, "unknown", []) is Err(_))
}
