///|
test "filter lengths and indices use general integers" {
  let context = LiquidContext::new()
  context.set(
    "items",
    array_value(["a", "b", "c", "d", "e", "f", "g", "h"].map(string_value)),
  )
  assert_eq(
    @liquid.compile(
      "{{ 'abcdefghij' | slice: 6, 2 }}|{{ 'abcdefghij' | slice: -2 }}|{{ 'abcdefghij' | slice: 100 }}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "gh|i|",
  )
  assert_eq(
    @liquid.compile(
      "{{ items | slice: -3, 2 | join: '' }}|{{ items | slice: 2 | join: '' }}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "fg|c",
  )
  assert_eq(
    @liquid.compile(
      "{{ 'abcdefghij' | truncate: 4 }}|{{ 'abcdefghij' | truncate: 6, '--' }}|{{ 'abcdefghij' | truncate: 999 }}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "a...|abcd--|abcdefghij",
  )
  assert_eq(
    @liquid.compile(
      "{{ 'a b c d e f g' | truncatewords: 3 }}|{{ 'a b c d' | truncatewords: 2, '!' }}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "a b c...|a b!",
  )
  assert_eq(
    @liquid.compile(
      "{{ items | offset: 6 | join: '' }}|{{ items | limit: 6 | join: '' }}|{{ items | at: -3 }}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "gh|abcdef|f",
  )
  assert_eq(
    @liquid.compile(
      "{{ items | at: -99 }}|{{ items | slice: -99, 2 | join: '' }}|{{ items | slice: 1, -1 | join: '' }}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "||",
  )
}

///|
test "string bounds count unicode characters" {
  let context = LiquidContext::new()
  assert_eq(
    @liquid.compile(
      "{{ 'a😀中bc' | slice: 1, 2 }}|{{ 'a😀中bc' | truncate: 4, '…' }}",
    )
    .unwrap()
    .render(context)
    .unwrap(),
    "😀中|a😀中…",
  )
}
