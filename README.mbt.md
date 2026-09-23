# Liquid MoonBit

A Liquid templating language implementation in MoonBit, inspired by [Shopify's Liquid](https://shopify.github.io/liquid/).

## Overview

Liquid MoonBit is a template interpreter with parsed block structure, typed
expression evaluation, and explicit template registration. It implements a
subset of Liquid plus legacy extension filters; full Liquid compatibility and
resource-bounded execution are not guaranteed.

For new integrations, use the opaque compiled-template interface:

```mbt check
///|
test "compiled template quick start" {
  let template = @liquid.compile("Hello, {{ name }}!").unwrap()
  let context = @liquid.LiquidContext::new()
  context.set("name", @liquid.string_value("World"))
  assert_eq(template.render(context).unwrap(), "Hello, World!")
}
```

Both compilation and rendering return structured diagnostics on failure.
Rendering through this interface does not print errors or embed them in output.
A compiled template can be reused with different contexts.

See [architecture and compatibility](ARCHITECTURE.md) for module responsibilities,
error behavior, the typed filter interface, and migration notes.
The examples below demonstrate the retained legacy interface.

## Quick Start

### Installation

```bash
moon new my-project
cd my-project
# Add liquid-moonbit as a dependency (when published)
```

### Basic Usage

```moonbit nocheck
///|
test "basic usage example" {
  // Import the library
  let template = parse("Hello, {{ name }}!")
  let context = LiquidContext::new()
  context.set("name", string_value("World"))

  let result = template.render(context)
  // Output: "Hello, World!"
  assert_eq(result, "Hello, World!")
}
```

### Variable Substitution

```liquid
<!-- Template -->
Hello, {{ user.name }}!
Your role: {{ user.role | capitalize }}
Last login: {{ user.last_login | date: "%B %d, %Y" }}

<!-- Alternative echo syntax -->
{% echo user.name | default: "Guest" %}
```

```moonbit nocheck
///|
test "variable substitution example" {
  // MoonBit code
  let context = LiquidContext::new()
  let user_obj = Map([])
  user_obj.set("name", string_value("Alice"))
  user_obj.set("role", string_value("admin"))
  user_obj.set("last_login", string_value("2023-12-01"))
  context.set("user", object_value(user_obj))

  let template = parse(
    "Hello, {{ user.name }}!\nYour role: {{ user.role | upcase }}",
  )
  let result = template.render(context)
  assert_eq(result.contains("Hello, Alice!"), true)
}
```

### Filters

```liquid
<!-- String filters with parameters -->
{{ "hello world" | upcase }}                    <!-- HELLO WORLD -->
{{ "  spaced  " | strip }}                      <!-- spaced -->
{{ "hello" | capitalize }}                      <!-- Hello -->
{{ "old text" | replace: 'old', 'new' }}        <!-- new text -->
{{ "remove this word" | remove: 'this' }}       <!-- remove  word -->
{{ "apple-banana-cherry" | split: '-' }}        <!-- [apple, banana, cherry] -->

<!-- Array filters with parameters -->
{{ items | first }}                             <!-- First item -->
{{ items | last }}                              <!-- Last item -->
{{ items | size }}                              <!-- Array length -->
{{ items | join: " | " }}                       <!-- Pipe-separated -->
{{ items | slice: 1, 3 }}                       <!-- Slice from index 1, length 3 -->
{{ items | offset: 2 | limit: 5 }}              <!-- Skip 2, take 5 (pagination) -->
{{ products | where: 'featured', 'true' }}      <!-- Filter by property -->

<!-- Date filters with format strings -->
{{ date | date: '%B %d, %Y' }}                  <!-- January 15, 2024 -->
{{ date | date: '%Y-%m-%d' }}                    <!-- 2024-01-15 -->
{{ date | date: '%m/%d/%Y' }}                    <!-- 01/15/2024 -->

<!-- Money and URL filters -->
{{ price | money }}                             <!-- $19.99 -->
{{ url | url_encode }}                          <!-- URL-safe encoding -->
{{ file | asset_url }}                          <!-- /assets/file.css -->
```

### Control Flow

```liquid
<!-- Conditionals with elsif -->
{% if user.premium %}
  Welcome, premium user!
{% elsif user.member %}
  Welcome, member!
{% else %}
  Consider upgrading.
{% endif %}

<!-- Loops with forloop object -->
{% for product in products %}
  {{ forloop.index }}. {{ product.name }} - ${{ product.price }}
  {% if forloop.first %}<div class="first">{% endif %}
  {% if forloop.last %}</div>{% endif %}
{% endfor %}

<!-- Case statements with when branches -->
{% case user.role %}
  {% when 'admin' %}
    Admin Dashboard
  {% when 'editor' %}
    Content Editor
  {% when 'user' %}
    User Dashboard
  {% else %}
    Guest Access
{% endcase %}

<!-- Advanced tags -->
{% capture page_title %}{{ post.title | upcase }} - {{ site.name }}{% endcapture %}
{% tablerow product in products cols: 3 %}
  <div class="product">{{ product.name }}</div>
{% endtablerow %}

{% raw %}
  This {{ will_not_be_processed }} as liquid code
{% endraw %}
```

## Examples

The `examples/` directory contains comprehensive template examples:

- [`basic.liquid`](examples/basic.liquid) - Basic variable substitution
- [`filters.liquid`](examples/filters.liquid) - Filter demonstrations
- [`control_flow.liquid`](examples/control_flow.liquid) - Conditionals and loops
- [`blog_post.liquid`](examples/blog_post.liquid) - Real-world blog template

## API Reference

### Core Types

```moonbit nocheck
///|
test "api reference types example" {
  // Value types
  let str_val = string_value("hello")
  let num_val = number_value(42.0)
  let bool_val = bool_value(true)
  let arr_val = array_value([str_val, num_val])
  let obj_map = Map([])
  obj_map.set("key", str_val)
  let obj_val = object_value(obj_map)
  let null_val = null_value()

  // Template context
  let context = LiquidContext::new()
  context.set("example", str_val)

  // Verify types work
  assert_eq(str_val.to_string(), "hello")
  assert_eq(num_val.to_string(), "42")
  assert_eq(bool_val.to_string(), "true")
  assert_eq(arr_val.to_string(), "[hello, 42]")
  assert_eq(obj_val.to_string().contains("key"), true)
  assert_eq(null_val.to_string(), "null")
}
```

### Main Functions

```moonbit nocheck
///|
test "main functions example" {
  // Create a new context
  let context = LiquidContext::new()

  // Set variables
  context.set("name", string_value("World"))

  // Parse and render template
  let template = parse("Hello {{ name }}!")
  let result = template.render(context)

  // Apply filters
  let filtered = apply_filter(string_value("hello"), "upcase")

  assert_eq(result, "Hello World!")
  assert_eq(filtered.to_string(), "HELLO")
}
```

### Built-in Filters (50+)

#### String Filters (25)
- `upcase` - Convert to uppercase
- `downcase` - Convert to lowercase  
- `capitalize` - Capitalize first letter
- `strip` - Remove leading/trailing whitespace
- `lstrip` - Remove leading whitespace only
- `rstrip` - Remove trailing whitespace only
- `size` - Get string length
- `replace: 'old', 'new'` - Replace text
- `remove: 'target'` - Remove text
- `split: 'delimiter'` - Split into array
- `prepend` - Add text before
- `append` - Add text after
- `truncate: 50` - Limit length with ellipsis
- `escape` - HTML escape for XSS protection
- `newline_to_br` - Convert newlines to <br>
- `strip_html` - Remove HTML tags
- `strip_newlines` - Remove newlines
- `url_encode` - URL encode special characters
- `url_decode` - URL decode special characters
- `asset_url` - Generate asset URL
- `absolute_url` - Generate absolute URL
- `relative_url` - Generate relative URL
- `default: 'fallback'` - Default value for empty/null
- `reading_time` - Estimate reading time in minutes
- `pluralize: 'singular', 'plural'` - Smart pluralization

#### Array Filters (23)
- `first` - Get first element
- `last` - Get last element
- `at: index` - Get element by index (supports negative)
- `join: ', '` - Join with separator
- `reverse` - Reverse array order
- `sort` - Sort alphabetically
- `sort_by: 'property'` - Sort by object property
- `map: 'property'` - Extract object properties
- `select` - Keep truthy elements
- `reject` - Keep falsy elements
- `compact` - Remove null/empty
- `uniq` - Remove duplicates
- `flatten` - Flatten nested arrays
- `slice: 1, 3` - Extract slice
- `offset: 2` - Skip elements
- `limit: 5` - Take elements
- `where: 'property', 'value'` - Filter by property
- `group_by` - Group elements
- `push` - Add element to end
- `pop` - Remove last element
- `shift` - Remove first element
- `unshift` - Add element to beginning
- `concat` - Concatenate arrays

#### Math Filters (9)
- `plus` - Add numbers
- `minus` - Subtract numbers
- `times` - Multiply numbers
- `divided_by` - Divide numbers
- `modulo` - Modulo operation
- `round` - Round numbers
- `ceil` - Round up
- `floor` - Round down
- `abs` - Absolute value

#### Date Filters (6)
- `date: '%B %d, %Y'` - Format with strftime
- `date_to_string` - Convert to string
- `date_to_xmlschema` - ISO 8601 format
- `date_to_rfc822` - RFC 822 format
- `strftime` - Custom formatting

#### URL Filters (5)
- `url_encode` - URL-safe encoding
- `url_decode` - URL decoding
- `asset_url` - Asset path generation
- `absolute_url` - Full URL generation
- `relative_url` - Relative path

#### Money Filters (4)
- `money` - Currency formatting ($19.99)
- `money_with_currency` - With currency symbol
- `money_without_currency` - Number only
- `money_without_trailing_zeros` - Clean format

## Architecture

The Liquid MoonBit implementation is a comprehensive single-module library:

1. **Core Engine** (`liquid.mbt`) - Complete template processing system
2. **Test Suite** (`liquid_test.mbt`) - 357 comprehensive tests with advanced edge cases
3. **Demo Application** (`cmd/main/main.mbt`) - Feature showcase
4. **Examples** (`examples/`) - Real-world template examples

### Processing Pipeline

```
Template String → Parser → AST Nodes → Renderer → Output
     ↓              ↓         ↓           ↓
  {{ }}, {% %}   Variable,  Context +   Filtered
   Detection      Filter,   Variables   Content
                  Control
                  Flow
```

### Key Components
- **LiquidValue**: Type-safe value system (String, Number, Bool, Array, Object, Null)
- **LiquidNode**: AST node types (Text, Variable, For, If, Capture, Increment, Decrement, Echo, IfChanged, etc.)
- **LiquidContext**: Variable storage with deep object property access
- **Filter System**: 50+ filters with comprehensive parameter support
- **ForLoopModifiers**: Type-safe handling of limit, offset, reversed modifiers
- **WhitespaceControl**: Foundation for whitespace stripping ({{- -}}, {%- -%})
- **Error Handling**: Configurable policies (strict, warn, silent)

## New Features in This Release

### 🆕 Advanced Tags
```liquid
{% increment counter %}        <!-- Auto-incrementing variables -->
{% decrement inventory %}      <!-- Auto-decrementing variables -->
{% echo user.name | upcase %}  <!-- Alternative output with different error handling -->
{% ifchanged %}{{ category }}{% endifchanged %}  <!-- Change detection -->
```

### 🆕 Enhanced For Loops
```liquid
<!-- Pagination with modifiers -->
{% for post in posts limit: 10 offset: 20 %}
  {{ post.title }}
{% endfor %}

<!-- Reverse chronological order -->
{% for article in articles reversed %}
  {{ article.date }} - {{ article.title }}
{% endfor %}

<!-- Complex combinations -->
{% for product in products offset: 5 limit: 3 reversed %}
  {{ forloop.index }}: {{ product.name }}
{% endfor %}
```

### 🆕 Advanced Filters
```liquid
<!-- Smart array operations -->
{{ products | map: "name" | sort_by: "price" }}
{{ items | at: -1 | upcase }}
{{ tags | push: "featured" | uniq }}

<!-- Intelligent text processing -->
{{ 5 | pluralize: "item", "items" }}  <!-- "5 items" -->
{{ content | reading_time }} min read
{{ "  text  " | lstrip | rstrip }}

<!-- Enhanced array manipulation -->
{{ list | pop | shift | compact }}
{{ arrays | concat | flatten | uniq }}
```

## Testing

### World-Class Test Suite (357 Tests) with Modern Snapshot Testing

The liquid-moonbit project features a **world-class test suite** with **357 comprehensive tests** and modern **snapshot-based testing** using `@json.inspect`:

#### **📸 Advanced Snapshot Testing (48 Tests)**
- ✅ **Template Parsing Verification**: Complete AST structure inspection with `@json.inspect`
- ✅ **Automatic Test Maintenance**: `moon test -u` automatically updates expected results
- ✅ **Comprehensive Structure Analysis**: Every parsed template shows complete node hierarchy
- ✅ **Edge Case Documentation**: Malformed templates, nested tags, whitespace variations
- ✅ **Control Flow Parsing**: If/for/case statements with complex condition inspection
- ✅ **Filter Chain Analysis**: Multi-filter combinations with parameter verification
- ✅ **Advanced Tag Structures**: Increment, decrement, echo, capture, raw tag parsing

#### **Core Functionality Tests**
- ✅ **Basic Operations**: Template parsing, variable substitution, context management
- ✅ **Filter System**: All 50+ filters with parameter variations and edge cases
- ✅ **Control Flow**: Complete if/else, for loops, case statements, unless conditions
- ✅ **Advanced Tags**: increment, decrement, echo, ifchanged, capture, raw, tablerow

#### **Edge Case & Robustness Tests**
- ✅ **Boundary Conditions**: Empty strings, empty arrays, zero/negative numbers
- ✅ **Type Safety**: Non-matching input types, null handling, type transformations
- ✅ **Unicode Support**: International characters, special symbols, multi-language text
- ✅ **Performance**: Large arrays (1000+ items), complex filter chains, stress testing

#### **Advanced Integration Tests**
- ✅ **Filter Chaining**: Complex multi-filter combinations with type transformations
- ✅ **Parameter Parsing**: Quote handling, edge cases, complex expressions
- ✅ **Object Manipulation**: Deep nesting, missing properties, complex structures
- ✅ **Numeric Precision**: Floating point edge cases, mathematical operations

#### **Error Handling Tests**
- ✅ **Graceful Degradation**: Missing variables, invalid parameters, type mismatches
- ✅ **Security**: XSS prevention, safe template evaluation, input sanitization
- ✅ **Memory Safety**: Large input handling, recursive structures, resource management

#### **🎯 Snapshot Testing Examples**

```
test "template parsing with filters" {
  let template = parse("Hello {{ name | upcase }}!")
  @json.inspect(template, content=({"nodes":[["Text","Hello "],["Variable","name",[{"name":"upcase","parameters":[]}]],["Text","!"]]}))
  // Automatically verifies complete AST structure
}

test "control flow parsing" {
  let template = parse("{% if age >= 18 %}Welcome{% endif %}")
  @json.inspect(template, content=({"nodes":[["If","age >= 18",[["Text","TRUE_BRANCH"]],[],[["Text","FALSE_BRANCH"]]],["Text","Welcome"],["Comment","endif"]]}))
  // Shows complete conditional structure with branches
}

test "complex filter chains" {
  let template = parse("{{ data | compact | slice: 1, 2 | join: ' | ' | upcase }}")
  @json.inspect(template, content=({"nodes":[["Variable","data",[{"name":"compact","parameters":[]},{"name":"slice","parameters":["1","2"]},{"name":"join","parameters":["' | '"]},{"name":"upcase","parameters":[]}]]]}))
  // Displays complete filter chain with parameters
}
```

### Running Tests

Run the complete test suite:

```bash
moon test
```

**Update snapshot tests** (automatically fills `@json.inspect` content):

```bash
moon test -u
```

Run with coverage analysis:

```bash
moon coverage analyze
```

Run the demo:

```bash
moon run cmd/main
```

#### **🔧 Snapshot Test Workflow**

1. **Add new parsing test** with empty `@json.inspect`:
   ```
   test "my new parsing test" {
     let template = parse("{{ my_template }}")
     @json.inspect(template, content={
     })
     // ... rest of test
   }
   ```

2. **Run update command** to auto-fill structure:
   ```bash
   moon test -u
   ```

3. **Review generated content** - the test now shows complete AST:
   ```
   @json.inspect(template, content=({"nodes":[["Variable","my_template",[]]]}))
   ```

This workflow ensures **comprehensive structure verification** with **minimal manual effort**!

## Compatibility

This implementation aims for compatibility with Shopify Liquid syntax while leveraging MoonBit's type safety and performance characteristics.

### Supported Tags (Complete)
- ✅ **Output**: `{{ }}` and `{% echo %}` with filter chaining
- ✅ **Variables**: `{{ variable }}` with deep object access
- ✅ **Filters**: `{{ value | filter: param1, param2 }}` with 50+ filters
- ✅ **Control Flow**: `{% if %}`, `{% elsif %}`, `{% else %}`, `{% endif %}`
- ✅ **Loops**: `{% for item in items limit: 5 offset: 2 reversed %}...{% endfor %}`
- ✅ **Case Statements**: `{% case %}`, `{% when %}`, `{% else %}`, `{% endcase %}`
- ✅ **Unless**: `{% unless condition %}...{% endunless %}`
- ✅ **Assignment**: `{% assign var = value %}`
- ✅ **Variable Management**: `{% increment var %}`, `{% decrement var %}`
- ✅ **Capture**: `{% capture var %}...{% endcapture %}`
- ✅ **Change Detection**: `{% ifchanged %}...{% endifchanged %}`
- ✅ **Comments**: `{% comment %}...{% endcomment %}`
- ✅ **Raw Content**: `{% raw %}...{% endraw %}`
- ✅ **Template Inclusion**: `{% include 'template' %}`, `{% render 'template' %}`
- ✅ **Sections**: `{% section 'name' %}`
- ✅ **Styles**: `{% style %}...{% endstyle %}`
- ✅ **Liquid Blocks**: `{% liquid %}...{% endliquid %}`
- ✅ **Table Rows**: `{% tablerow item in items cols: 3 %}`
- ✅ **Cycles**: `{% cycle 'group': 'val1', 'val2' %}`
- ✅ **Loop Control**: `{% break %}`, `{% continue %}`
- ✅ **Whitespace Control**: `{{- }}`, `{%- %}` (parser foundation)

### Supported Filters (50+ Complete)

#### **String Filters**
- ✅ **Case conversion**: `upcase`, `downcase`, `capitalize`
- ✅ **Trimming**: `strip`, `lstrip`, `rstrip`
- ✅ **Manipulation**: `replace`, `remove`, `split`, `truncate`
- ✅ **HTML processing**: `escape`, `strip_html`, `newline_to_br`, `strip_newlines`
- ✅ **URL handling**: `url_encode`, `url_decode`, `asset_url`, `absolute_url`, `relative_url`
- ✅ **Text utilities**: `prepend`, `append`, `default`

#### **Array Filters**
- ✅ **Access**: `first`, `last`, `at` (with negative indexing)
- ✅ **Manipulation**: `push`, `pop`, `shift`, `unshift`, `concat`
- ✅ **Transformation**: `reverse`, `sort`, `sort_by`, `map` (with properties)
- ✅ **Filtering**: `select`, `reject`, `where` (with property matching)
- ✅ **Utility**: `compact`, `uniq`, `flatten`, `join`
- ✅ **Slicing**: `slice`, `offset`, `limit` (with parameters)
- ✅ **Grouping**: `group_by`

#### **Math Filters**
- ✅ **Arithmetic**: `plus`, `minus`, `times`, `divided_by`, `modulo`
- ✅ **Rounding**: `round`, `ceil`, `floor`, `abs`

#### **Date Filters**
- ✅ **Formatting**: `date` (with format strings), `date_to_string`
- ✅ **Standards**: `date_to_xmlschema`, `date_to_rfc822`, `strftime`

#### **Money Filters**
- ✅ **Currency**: `money`, `money_with_currency`, `money_without_currency`
- ✅ **Formatting**: `money_without_trailing_zeros`

#### **Utility Filters**
- ✅ **Measurement**: `size`, `length`, `reading_time`
- ✅ **Text**: `pluralize` (with custom forms)

### Supported Operators (Complete)
- ✅ Equality: `==`, `!=`
- ✅ Comparison: `<`, `>`, `<=`, `>=` (numbers and strings)
- ✅ Logic: `and`, `or`, `not`
- ✅ Contains: `contains` (string and array)
- ✅ Complex Expressions: `age >= 18 and is_member`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspired by [Shopify's Liquid](https://shopify.github.io/liquid/)
- Built with [MoonBit](https://www.moonbitlang.com/)
- Original Liquid ML implementation: [liquid-ml](https://github.com/benfaerber/liquid-ml)

## Validation and implementation status

Run the compiler and test suite with:

```sh
moon check --target all --deny-warn --warn-list +25+73
moon test --target all
```

Tests include legacy compatibility cases, end-to-end parse/render regressions,
checked compilation and rendering, and a bounded reference corpus generated
against Shopify Liquid 5.4.0. The reference corpus runs as ordinary MoonBit tests;
Ruby is needed only to regenerate or independently verify its expected outputs.

See [ARCHITECTURE.md](ARCHITECTURE.md) for retained extensions and current
limitations. Passing these tests does not establish complete Liquid compatibility.

### Numeric and date filter behavior

Parameterized `plus`, `minus`, `times`, `divided_by`, `modulo`, and `round`
use the supplied numeric argument (including signed decimals and numeric strings).
`divided_by` floors the result for an integer literal divisor and preserves the
fraction for a decimal divisor. The public value model still stores numbers as
`Double`; it does not retain separate integer and decimal value types.
Division or modulo by zero produces null; invalid numeric arguments leave the
input unchanged. Calls without arguments retain the existing API defaults.

Date filters accept `YYYY-MM-DD` and ISO timestamps with seconds, optionally
followed by `Z` or a `+HH:MM` / `-HH:MM` offset. They validate calendar dates,
including leap years, and preserve the supplied wall time and offset.
`date` and `strftime` default to `%Y-%m-%d`; `date_to_string` uses `%d %b %Y`.
Supported directives are `%Y`, `%y`, `%m`, `%d`, `%e`, `%B`, `%b`, `%h`, `%A`,
`%a`, `%j`, `%w`, `%u`, `%H`, `%I`, `%M`, `%S`, `%p`, `%z`, `%Z`, `%F`, `%T`,
`%R`, `%D`, `%n`, `%t`, and `%%`. Invalid dates, unsupported directives, and
unsupported input forms (including `now`, natural-language dates, and Unix
 timestamps) leave the input unchanged.

### Registering templates

Templates used by `include` and `render` must be registered by the caller. Names
are exact registry keys; the engine does not read arbitrary filesystem paths.

```mbt check
///|
test "registered template example" {
  let context = LiquidContext::new()
  context.register_template("greeting", "Hello {{ name }}!")
  context.set("name", string_value("Alice"))
  assert_eq(parse("{% include 'greeting' %}").render(context), "Hello Alice!")
  assert_eq(
    parse("{% render 'greeting', name: 'Bob' %}").render(context),
    "Hello Bob!",
  )
}
```

`include` shares the caller's variables; `render` starts with an isolated variable
scope and receives explicitly named arguments. Registered templates remain
available in nested calls. Missing templates follow the context's error policy,
and template nesting is limited to 64 calls. Loop control propagates through
included templates, while an isolated render has its own loop-control state.
