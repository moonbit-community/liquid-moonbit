///|
test "capture handles nested output filters and separate variables" {
  let context = LiquidContext::new()
  context.set("name", string_value("世界"))
  let template = compile(
    "{% capture first %}<b>{{ name }}</b>{% endcapture %}{% capture second %}{{ first | append: '!' }}{% endcapture %}{{ first }}|{{ second }}",
  ).unwrap()
  assert_eq(template.render(context).unwrap(), "<b>世界</b>|<b>世界</b>!")
  assert_eq(context.get("first").unwrap().to_string(), "<b>世界</b>")
}

///|
test "raw preserves markup unicode and template delimiters" {
  let source = "{% raw %}<p>世界 {{ missing }} {% if true %}</p>{% endraw %}"
  assert_eq(
    compile(source).unwrap().render(LiquidContext::new()).unwrap(),
    "<p>世界 {{ missing }} {% if true %}</p>",
  )
}

///|
test "layout and block extensions retain their documented placeholder behavior" {
  let context = LiquidContext::new()
  let template = compile(
    "{% layout 'base' %}{% block title %}default{% endblock %}|{% content %}",
  ).unwrap()
  assert_eq(
    template.render(context).unwrap(),
    "<!-- Layout: 'base' -->default|<!-- Main content will be inserted here -->",
  )
  context.set("__block_title", string_value("override"))
  context.set("__content__", string_value("body"))
  assert_eq(
    template.render(context).unwrap(),
    "<!-- Layout: 'base' -->override|body",
  )
}

///|
test "render diagnostics accumulate and do not contaminate later renders" {
  let template = compile("{{ first }}|{{ second }}").unwrap()
  let context = LiquidContext::new()
  match template.render(context) {
    Err(errors) => {
      assert_eq(errors.length(), 2)
      assert_eq(errors[0].phase, "render")
      assert_true(errors[0].message.contains("first"))
      assert_true(errors[1].message.contains("second"))
    }
    Ok(_) => fail("Expected missing variable diagnostics")
  }
  context.set("first", string_value("a"))
  context.set("second", string_value("b"))
  assert_eq(template.render(context).unwrap(), "a|b")
  assert_true(template.render(LiquidContext::new()) is Err(_))
}

///|
test "additional edge cases for remaining coverage" {
  // Test comparison operators with string comparisons
  let context = LiquidContext::new()
  context.set("str1", string_value("apple"))
  context.set("str2", string_value("banana"))

  // Test string >= comparison
  let result_gte = @liquid.compile(
      "{% if " + "str2 >= str1" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result_gte, true) // "banana" >= "apple"

  // Test string <= comparison
  let result_lte = @liquid.compile(
      "{% if " + "str1 <= str2" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result_lte, true) // "apple" <= "banana"

  // Test comparison with non-matching condition
  let result_nonmatch = @liquid.compile(
      "{% if " + "str1 > str2" + " %}true{% else %}false{% endif %}",
    )
    .unwrap()
    .render(context)
    .unwrap() ==
    "true"
  assert_eq(result_nonmatch, false) // "apple" > "banana" is false

  // Test slice with single parameter "1"
  let arr = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
  ])
  let result_slice_1 = apply_filter(arr, "slice", [number_value(1)]).unwrap()
  match result_slice_1 {
    Array(sliced) => assert_eq(sliced.length(), 1) // one element from position 1
    _ => fail("Expected Array result")
  }

  // Test slice with string parameter "3"
  let result_slice_3 = apply_filter(arr, "slice", [number_value(3)]).unwrap()
  match result_slice_3 {
    Array(sliced) => assert_eq(sliced.length(), 0) // no elements from position 3
    _ => fail("Expected Array result")
  }

  // Test slice with string where start position is out of bounds
  let long_string = string_value("test")
  // Use a recognized parameter that will create out of bounds condition
  // Since we only have "0", "1", "2", "3" as recognized parameters, let's create a scenario
  // where we test the bounds checking logic by using a short string with parameters that work
  let result_edge = apply_filter(long_string, "slice", [
    number_value(3),
    number_value(2),
  ]).unwrap()
  // "test" has length 4, so position 3 exists (it's "t"), slice(3,2) should give "t"
  assert_eq(result_edge.to_string(), "t")

  // Test slice with string where end_pos calculation is needed
  let result_end_calc = apply_filter(long_string, "slice", [
    number_value(0),
    number_value(2),
  ]).unwrap()
  assert_eq(result_end_calc.to_string(), "te")
}

///|
test "additional edge cases for complete coverage" {
  // Test more edge cases to increase coverage

  // Test strip_tags with non-string
  let strip_tags_result = apply_filter(number_value(123.0), "strip_tags", []).unwrap()
  assert_eq(strip_tags_result.to_string(), "123")

  // Test normalize_whitespace with non-string
  let normalize_result = apply_filter(
    bool_value(true),
    "normalize_whitespace",
    [],
  ).unwrap()
  assert_eq(normalize_result.to_string(), "true")

  // Test various filters with different input types to hit uncovered branches
  let filters_to_test = [
    "strip_tags", "normalize_whitespace", "truncatewords", "at",
  ]
  let non_string_inputs = [number_value(42.0), bool_value(false), null_value()]
  for filter_name in filters_to_test {
    for input in non_string_inputs {
      let result = apply_filter(input, filter_name, []).unwrap()
      // These should all return the original input when type doesn't match
      assert_eq(result.to_string(), input.to_string())
    }
  }
}

///|
test "basic logic tag parsing" {
  // Test that logic tags are parsed (even if not fully implemented yet)
  let template = @liquid.compile("Start {% assign name = 'test' %} End").unwrap()

  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "Start  End") // Assign produces no output
}

///|
test "comment tag parsing" {
  // Test comment tag is properly parsed and ignored
  let template = @liquid.compile(
    "Before{% comment %}This is a comment{% endcomment %}After",
  ).unwrap()

  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "BeforeAfter")
}

///|
test "capture tag parsing" {
  // Test capture tag parsing (basic recognition)
  let template = @liquid.compile(
    "{% capture my_var %}content{% endcapture %}{{ my_var }}",
  ).unwrap()

  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "content")
}

///|
test "raw tag parsing" {
  // Test raw tag parsing (basic recognition)
  let template = @liquid.compile("{% raw %}{{ not_processed }}{% endraw %}").unwrap()

  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "{{ not_processed }}")
}

///|
test "liquid tag parsing" {
  assert_eq(
    @liquid.compile("{% liquid\n assign name = 'World'\n echo name\n %}")
    .unwrap()
    .render(LiquidContext::new())
    .unwrap(),
    "World",
  )
}

///|
test "section tag parsing" {
  // Test section tag parsing
  let template = @liquid.compile("{% section 'header' %}").unwrap()
  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result.contains("<section"), true)
  assert_eq(result.contains("header"), true)
}

///|
test "style tag parsing" {
  // Test style tag parsing
  let template = @liquid.compile(
    "{% style %}body { color: red; }{% endstyle %}",
  ).unwrap()
  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result.contains("<style>"), true)
  assert_eq(result, "<style>body { color: red; }</style>")
}

///|
test "render tag parsing" {
  let context = LiquidContext::new()
  context.register_template("product-card", "<article>Product</article>")
  assert_eq(
    @liquid.compile("{% render 'product-card' %}")
    .unwrap()
    .render(context)
    .unwrap(),
    "<article>Product</article>",
  )
}

///|
test "multiple parameter parsing" {
  // Test parsing multiple parameters with commas
  let template = @liquid.compile("{{ text | slice: 0, 5 | upcase }}").unwrap()

  let context = LiquidContext::new()
  context.set("text", string_value("hello world"))
  let result = template.render(context).unwrap()
  assert_eq(result, "HELLO") // Slice first 5 chars, then uppercase
}

///|
test "when tag parsing recognition" {
  assert_true(@liquid.compile("{% when 'admin' %}") is Err(_))
}

///|
test "capture tag parsing in template" {
  // Test capture tag parsing in template
  let template = @liquid.compile(
    "{% capture my_content %}Hello {{ name }}!{% endcapture %}{{ my_content }}",
  ).unwrap()
  let context = LiquidContext::new()
  context.set("name", string_value("World"))
  let result = template.render(context).unwrap()
  // Should capture content and then display it
  assert_eq(result, "Hello World!")
}

///|
test "raw tag parsing in template" {
  // Test raw tag parsing in template
  let template = @liquid.compile("{% raw %}{{ not_processed }}{% endraw %}").unwrap()
  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "{{ not_processed }}") // Raw content without processing
}

///|
test "comprehensive parameter parsing edge cases" {
  // Test edge cases in parameter parsing for filters

  // Test with various parameter formats
  let params = ["\"quoted\"", "'single'", "unquoted", "\"", "'", ""]
  let expected_results = params
  for i in 0..<params.length() {
    let param = params[i]
    let expected = expected_results[i]

    // Test with pluralize filter
    let result = apply_filter(number_value(1.0), "pluralize", [
      string_value(param),
      string_value("items"),
    ]).unwrap()
    assert_eq(result.to_string(), "1 " + expected)
  }
}

///|
test "template rendering basic" {
  // Test basic template rendering
  let template = @liquid.compile("Hello {{ name }}!").unwrap()
  let context = LiquidContext::new()
  context.set("name", string_value("World"))
  let result = template.render(context).unwrap()
  assert_eq(result, "Hello World!")
}

///|
test "template rendering with missing variable" {
  assert_true(
    @liquid.compile("Hello {{ missing }}!")
    .unwrap()
    .render(LiquidContext::new())
    is Err(_),
  )
}

///|
test "template rendering multiple variables" {
  // Test rendering with multiple variables
  let template = @liquid.compile(
    "{{ greeting }} {{ name }}, you have {{ count }} messages.",
  ).unwrap()

  let context = LiquidContext::new()
  context.set("greeting", string_value("Hello"))
  context.set("name", string_value("Alice"))
  context.set("count", number_value(5.0))
  let result = template.render(context).unwrap()
  assert_eq(result, "Hello Alice, you have 5 messages.")
}

///|
test "integration basic template" {
  // Test basic template similar to examples/basic.liquid
  let template = @liquid.compile(
    "Hello, {{ name }}!\nWelcome to {{ site_name }}.\nYour role: {{ user.role }}",
  ).unwrap()

  let context = LiquidContext::new()
  context.set("name", string_value("World"))
  context.set("site_name", string_value("Liquid MoonBit"))
  let user_obj = Map([])
  user_obj.set("role", string_value("Developer"))
  context.set("user", object_value(user_obj))
  let result = template.render(context).unwrap()
  let expected = "Hello, World!\nWelcome to Liquid MoonBit.\nYour role: Developer"
  assert_eq(result, expected)
}

///|
test "integration blog post metadata" {
  // Test blog post template metadata like examples/blog_post.liquid
  let template = @liquid.compile(
    "{{ post.title }}\nby {{ post.author.name }}\nTags: {{ post.tags | size }} tags",
  ).unwrap()

  let context = LiquidContext::new()
  let author_obj = Map([])
  author_obj.set("name", string_value("Jane Doe"))
  let post_obj = Map([])
  post_obj.set("title", string_value("My First Post"))
  post_obj.set("author", object_value(author_obj))
  let tags = array_value([string_value("tech"), string_value("moonbit")])
  post_obj.set("tags", tags)
  context.set("post", object_value(post_obj))
  let result = template.render(context).unwrap()
  let expected = "My First Post\nby Jane Doe\nTags: 2 tags"
  assert_eq(result, expected)
}

///|
test "integration complex template" {
  // Test complex template with multiple features
  let template = @liquid.compile(
    "Welcome {{ name | upcase }}!\nYou have {{ count }} items.\nFirst item: {{ items | size }} total",
  ).unwrap()

  let context = LiquidContext::new()
  context.set("name", string_value("alice"))
  context.set("count", number_value(3.0))
  let items = array_value([
    string_value("apple"),
    string_value("banana"),
    string_value("cherry"),
  ])
  context.set("items", items)
  let result = template.render(context).unwrap()
  let expected = "Welcome ALICE!\nYou have 3 items.\nFirst item: 3 total"
  assert_eq(result, expected)
}

///|
test "basic comment tag" {
  // Test comment tags are ignored
  let template = @liquid.compile(
    "Hello {% comment %}This is ignored{% endcomment %}World!",
  ).unwrap()

  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "Hello World!")
}

///|
test "mixed variable and logic tags" {
  // Test parsing templates with both {{ }} and {% %} tags
  let template = @liquid.compile(
    "Hello {{ name }}! {% comment %}greeting{% endcomment %} Welcome!",
  ).unwrap()

  let context = LiquidContext::new()
  context.set("name", string_value("World"))
  let result = template.render(context).unwrap()
  assert_eq(result, "Hello World!  Welcome!")
}

///|
test "section and style in template" {
  // Test section and style tags in template context
  let template = @liquid.compile(
    "{% section 'main' %}{% style %}h1 { color: blue; }{% endstyle %}",
  ).unwrap()
  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result.contains("<section"), true)
  assert_eq(result.contains("<style>"), true)
}

///|
test "parameter with quotes and spaces" {
  // Test parameter parsing with quotes and spaces
  let template = @liquid.compile("{{ items | join: ' -> ' }}").unwrap()

  let context = LiquidContext::new()
  let items = array_value([
    string_value("step1"),
    string_value("step2"),
    string_value("step3"),
  ])
  context.set("items", items)
  let result = template.render(context).unwrap()
  assert_eq(result, "step1 -> step2 -> step3")
}

///|
test "empty string and array edge cases" {
  // Test edge cases with empty strings and arrays
  let empty_str = string_value("")
  let empty_arr = array_value([])

  // Test capitalize with empty string
  assert_eq(apply_filter(empty_str, "capitalize", []).unwrap().to_string(), "")

  // Test first/last with empty arrays
  assert_eq(apply_filter(empty_arr, "first", []).unwrap().to_string(), "null")
  assert_eq(apply_filter(empty_arr, "last", []).unwrap().to_string(), "null")

  // Test first/last with empty strings
  assert_eq(apply_filter(empty_str, "first", []).unwrap().to_string(), "null")
  assert_eq(apply_filter(empty_str, "last", []).unwrap().to_string(), "null")

  // Test truncate with short string
  let short_str = string_value("short")
  assert_eq(
    apply_filter(short_str, "truncate", []).unwrap().to_string(),
    "short",
  )
}

///|
test "raw tag in complex template" {
  // Test raw tag in complex template context
  let template = @liquid.compile(
    "Before {% raw %}{{ variable }}{% endraw %} After",
  ).unwrap()
  let context = LiquidContext::new()
  context.set("variable", string_value("should not be used"))
  let result = template.render(context).unwrap()
  assert_eq(result, "Before {{ variable }} After")
}

///|
test "multiple raw tags" {
  // Test multiple raw tags
  let template = @liquid.compile(
    "{% raw %}First {{ block }}{% endraw %} and {% raw %}Second {{ block }}{% endraw %}",
  ).unwrap()
  let context = LiquidContext::new()
  let result = template.render(context).unwrap()
  assert_eq(result, "First {{ block }} and Second {{ block }}")
}

///|
test "advanced string manipulation edge cases" {
  // Test advanced string manipulation scenarios

  // Test capitalize with various edge cases
  let capitalize_cases = [
    ("", ""),
    ("a", "A"),
    ("HELLO", "Hello"),
    ("hELLO wORLD", "Hello world"),
    ("123abc", "123abc"),
  ]
  for i in 0..<capitalize_cases.length() {
    let input = capitalize_cases[i].0
    let expected = capitalize_cases[i].1
    let result = apply_filter(string_value(input), "capitalize", []).unwrap()
    assert_eq(result.to_string(), expected)
  }

  // Test unicode strings (may not support full unicode capitalization)
  let unicode_result = apply_filter(string_value("ñoño"), "capitalize", []).unwrap()
  match unicode_result {
    String(_) => () // Just verify it doesn't crash
    _ => fail("capitalize should handle unicode strings")
  }

  // Test truncate with exact boundary conditions
  let long_string_50 = "12345678901234567890123456789012345678901234567890" // Exactly 50 chars
  let long_string_51 = "123456789012345678901234567890123456789012345678901" // 51 chars
  let result_50 = apply_filter(string_value(long_string_50), "truncate", []).unwrap()
  assert_eq(result_50.to_string(), long_string_50) // Should not truncate
  let result_51 = apply_filter(string_value(long_string_51), "truncate", []).unwrap()
  assert_eq(result_51.to_string(), long_string_50[:47].to_owned() + "...") // Should truncate
}

///|
test "performance and stress edge cases" {
  // Test filters with larger inputs to ensure they handle scale

  // Large array test
  let large_array_items : Array[LiquidValue] = []
  for i in 0..<1000 {
    large_array_items.push(string_value("item" + i.to_string()))
  }
  let large_array = array_value(large_array_items)

  // Test array filters with large input
  let sort_result = apply_filter(large_array, "sort", []).unwrap()
  match sort_result {
    Array(arr) => assert_eq(arr.length(), 1000)
    _ => fail("sort should handle large arrays")
  }
  let uniq_result = apply_filter(large_array, "uniq", []).unwrap()
  match uniq_result {
    Array(arr) => assert_eq(arr.length(), 1000) // All items are unique
    _ => fail("uniq should handle large arrays")
  }

  // Large string test
  let large_string_parts : Array[String] = []
  for i in 0..<1000 {
    large_string_parts.push("word" + i.to_string())
  }
  let large_string = large_string_parts.join(" ")
  let truncate_result = apply_filter(
    string_value(large_string),
    "truncatewords",
    [],
  ).unwrap()
  match truncate_result {
    String(s) => assert_eq(s.contains("..."), true) // Should be truncated
    _ => fail("truncatewords should handle large strings")
  }
}
