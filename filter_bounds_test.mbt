///|
test "filter lengths and indices use general integers" {
  let context = LiquidContext::new()
  context.set(
    "items",
    array_value(["a", "b", "c", "d", "e", "f", "g", "h"].map(string_value)),
  )
  assert_eq(
    parse(
      "{{ 'abcdefghij' | slice: 6, 2 }}|{{ 'abcdefghij' | slice: -2 }}|{{ 'abcdefghij' | slice: 100 }}",
    ).render(context),
    "gh|i|",
  )
  assert_eq(
    parse(
      "{{ items | slice: -3, 2 | join: '' }}|{{ items | slice: 2 | join: '' }}",
    ).render(context),
    "fg|c",
  )
  assert_eq(
    parse(
      "{{ 'abcdefghij' | truncate: 4 }}|{{ 'abcdefghij' | truncate: 6, '--' }}|{{ 'abcdefghij' | truncate: 999 }}",
    ).render(context),
    "a...|abcd--|abcdefghij",
  )
  assert_eq(
    parse(
      "{{ 'a b c d e f g' | truncatewords: 3 }}|{{ 'a b c d' | truncatewords: 2, '!' }}",
    ).render(context),
    "a b c...|a b!",
  )
  assert_eq(
    parse(
      "{{ items | offset: 6 | join: '' }}|{{ items | limit: 6 | join: '' }}|{{ items | at: -3 }}",
    ).render(context),
    "gh|abcdef|f",
  )
  assert_eq(
    parse(
      "{{ items | at: -99 }}|{{ items | slice: -99, 2 | join: '' }}|{{ items | slice: 1, -1 | join: '' }}",
    ).render(context),
    "||",
  )
}

///|
test "string bounds count unicode characters" {
  let context = LiquidContext::new()
  assert_eq(
    parse(
      "{{ 'a😀中bc' | slice: 1, 2 }}|{{ 'a😀中bc' | truncate: 4, '…' }}",
    ).render(context),
    "😀中|a😀中…",
  )
}
