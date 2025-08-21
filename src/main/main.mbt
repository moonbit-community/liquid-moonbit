fn main {
  println("=== Liquid Template Engine Demo ===\n")
  
  // Simple Variable Replacement Demo
  println("1. Simple Variable Replacement")
  let template1 = "Hello {{ name }}!"
  let name = "World"
  let result1 = template1.replace(old="{{ name }}", new=name)
  println("Template: \"" + template1 + "\"")
  println("Variable: name = \"" + name + "\"")
  println("Result: \"" + result1 + "\"")
  println("")

  // Multiple Variable Replacement Demo
  println("2. Multiple Variable Replacement")
  let template2 = "Hello {{ name }}, welcome to {{ place }}!"
  let name_var = "Alice"
  let place_var = "MoonBit"
  let result2 = template2.replace(old="{{ name }}", new=name_var).replace(old="{{ place }}", new=place_var)
  println("Template: \"" + template2 + "\"")
  println("Variables: name = \"" + name_var + "\", place = \"" + place_var + "\"")
  println("Result: \"" + result2 + "\"")
  println("")

  // Filter Demonstrations
  println("3. Filter Demonstrations")
  println("3.1 Upcase Filter")
  let template_upcase = @lib.parse("{{ text | upcase }}")
  let context_upcase = @lib.LiquidContext::new()
  context_upcase.set("text", @lib.string_value("hello world"))
  let result_upcase = template_upcase.render(context_upcase)
  println("Template: \"{{ text | upcase }}\"")
  println("Variable: text = \"hello world\"")
  println("Result: \"" + result_upcase + "\"")
  println("")

  println("3.2 Downcase Filter")
  let template_downcase = @lib.parse("{{ text | downcase }}")
  let context_downcase = @lib.LiquidContext::new()
  context_downcase.set("text", @lib.string_value("HELLO WORLD"))
  let result_downcase = template_downcase.render(context_downcase)
  println("Template: \"{{ text | downcase }}\"")
  println("Variable: text = \"HELLO WORLD\"")
  println("Result: \"" + result_downcase + "\"")
  println("")

  println("3.3 Size Filter")
  let template_size = @lib.parse("{{ items | size }}")
  let context_size = @lib.LiquidContext::new()
  let items_array = @lib.array_value([
    @lib.string_value("apple"),
    @lib.string_value("banana"),
    @lib.string_value("cherry")
  ])
  context_size.set("items", items_array)
  let result_size = template_size.render(context_size)
  println("Template: \"{{ items | size }}\"")
  println("Variable: items = [\"apple\", \"banana\", \"cherry\"]")
  println("Result: \"" + result_size + "\"")
  println("")

  println("3.4 Chained Filters")
  let template_chained = @lib.parse("{{ text | upcase | size }}")
  let context_chained = @lib.LiquidContext::new()
  context_chained.set("text", @lib.string_value("hello"))
  let result_chained = template_chained.render(context_chained)
  println("Template: \"{{ text | upcase | size }}\"")
  println("Variable: text = \"hello\"")
  println("Result: \"" + result_chained + "\" (length of \"HELLO\")")
  println("")

  // Complex Template with Multiple Variables
  println("4. Complex Template Example")
  let complex_template_str = "Dear {{ user_name }}, you have {{ message_count }} new messages."
  let complex_template = @lib.parse(complex_template_str)
  let complex_context = @lib.LiquidContext::new()
  complex_context.set("user_name", @lib.string_value("Bob"))
  complex_context.set("message_count", @lib.number_value(5.0))
  let complex_result = complex_template.render(complex_context)
  println("Template: \"" + complex_template_str + "\"")
  println("Result: \"" + complex_result + "\"")
  println("")

  // Object-like Access Simulation
  println("5. Object Access Simulation")
  let user_template_str = "User: {{ user.name }} (Role: {{ user.role }})"
  let user_template = @lib.parse(user_template_str)
  let user_context = @lib.LiquidContext::new()
  user_context.set("user.name", @lib.string_value("Charlie"))
  user_context.set("user.role", @lib.string_value("Admin"))
  let user_result = user_template.render(user_context)
  println("Template: \"" + user_template_str + "\"")
  println("Result: \"" + user_result + "\"")
  println("")

  // Nested Template Simulation
  println("6. Nested Template Example")
  let header_template_str = "=== {{ title }} ==="
  let body_template_str = "Content: {{ content }}"
  let footer_template_str = "--- End of {{ title }} ---"
  
  let header_template = @lib.parse(header_template_str)
  let body_template = @lib.parse(body_template_str)
  let footer_template = @lib.parse(footer_template_str)
  
  let nested_context = @lib.LiquidContext::new()
  nested_context.set("title", @lib.string_value("Report"))
  nested_context.set("content", @lib.string_value("This is the main content"))
  
  let header = header_template.render(nested_context)
  let body = body_template.render(nested_context)
  let footer = footer_template.render(nested_context)
  
  println(header)
  println(body)
  println(footer)
  println("")

  // Advanced Template Example
  println("7. Advanced Template with Multiple Features")
  let advanced_template_str = "Welcome {{ name | upcase }}! You have {{ count }} items (size: {{ items | size }})."
  let advanced_template = @lib.parse(advanced_template_str)
  let advanced_context = @lib.LiquidContext::new()
  advanced_context.set("name", @lib.string_value("alice"))
  advanced_context.set("count", @lib.number_value(3.0))
  let items = @lib.array_value([
    @lib.string_value("item1"),
    @lib.string_value("item2"), 
    @lib.string_value("item3")
  ])
  advanced_context.set("items", items)
  let advanced_result = advanced_template.render(advanced_context)
  println("Template: \"" + advanced_template_str + "\"")
  println("Result: \"" + advanced_result + "\"")
  println("")

  println("=== Demo Complete ===")
}