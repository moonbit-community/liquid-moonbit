///|
test "property paths must resolve every segment" {
  let context = LiquidContext::new()
  context.set(
    "user",
    object_value({
      "name": string_value("Alice"),
      "age": number_value(30),
      "active": bool_value(true),
      "items": array_value([]),
      "none": null_value(),
      "address": object_value({ "city": string_value("Paris") }),
    }),
  )
  for
    path in [
      "user.name.nope", "user.age.nope", "user.active.nope", "user.items.nope", "user.none.nope",
      "user.missing.nope", "user.address.city.nope",
    ] {
    assert_true(context.get(path) is None)
    assert_true(
      @liquid.compile("{{ " + path + " }}").unwrap().render(context) is Err(_),
    )
  }
  assert_eq(
    @liquid.compile("{{ user.name }}:{{ user.address.city }}")
    .unwrap()
    .render(context)
    .unwrap(),
    "Alice:Paris",
  )
}
