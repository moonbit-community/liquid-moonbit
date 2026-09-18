///|
test "property paths must resolve every segment" {
  let context = LiquidContext::with_error_policy(silent_policy())
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
    assert_eq(parse("{{ " + path + " }}").render(context), "")
  }
  assert_eq(
    parse("{{ user.name }}:{{ user.address.city }}").render(context),
    "Alice:Paris",
  )
}
