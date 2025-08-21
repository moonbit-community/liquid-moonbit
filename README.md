# Liquid MoonBit

A Liquid templating language implementation in MoonBit, inspired by [Shopify's Liquid](https://shopify.github.io/liquid/).

## Overview

Liquid MoonBit is a safe, customer-facing template language for flexible web apps. It provides a simple syntax for dynamic content generation with built-in security features and extensible filter system.

## Features

### Core Functionality
- ✅ **Variable Output**: `{{ variable }}`
- ✅ **Basic Filters**: `{{ value | filter_name }}`
- ✅ **String Manipulation**: upcase, downcase, capitalize, strip, etc.
- ✅ **Template Context**: Variable binding and evaluation
- 🚧 **Control Flow**: if/else, for loops, case statements
- 🚧 **Template Inheritance**: includes and layouts
- 🚧 **Advanced Filters**: Array manipulation, date formatting

### Language Features
- **Safe**: Templates can't execute arbitrary code
- **Fast**: Compiled to efficient MoonBit bytecode
- **Extensible**: Custom filters and functions
- **Familiar**: Compatible with Liquid syntax

## Quick Start

### Installation

```bash
moon new my-project
cd my-project
# Add liquid-moonbit as a dependency (when published)
```

### Basic Usage

```moonbit
// Import the library
let template = "Hello, {{ name }}!"
let context = Context::new()
context.set("name", "World")

let result = render_template(template, context)
// Output: "Hello, World!"
```

### Variable Substitution

```liquid
<!-- Template -->
Hello, {{ user.name }}!
Your role: {{ user.role | capitalize }}
Last login: {{ user.last_login | date: "%B %d, %Y" }}
```

```moonbit
// MoonBit code
let context = Context::new()
context.set("user.name", "Alice")
context.set("user.role", "admin")
context.set("user.last_login", "2023-12-01")

let result = render_template(template, context)
```

### Filters

```liquid
<!-- String filters -->
{{ "hello world" | upcase }}          <!-- HELLO WORLD -->
{{ "  spaced  " | strip }}             <!-- spaced -->
{{ "hello" | capitalize }}             <!-- Hello -->

<!-- Array filters -->
{{ items | first }}                    <!-- First item -->
{{ items | last }}                     <!-- Last item -->
{{ items | size }}                     <!-- Array length -->
{{ items | join: ", " }}               <!-- Comma-separated -->
```

### Control Flow

```liquid
<!-- Conditionals -->
{% if user.premium %}
  Welcome, premium user!
{% else %}
  Consider upgrading to premium.
{% endif %}

<!-- Loops -->
{% for product in products %}
  {{ forloop.index }}. {{ product.name }} - ${{ product.price }}
{% endfor %}

<!-- Case statements -->
{% case user.role %}
  {% when 'admin' %}
    Admin Dashboard
  {% when 'user' %}
    User Dashboard
  {% else %}
    Guest Access
{% endcase %}
```

## Examples

The `examples/` directory contains comprehensive template examples:

- [`basic.liquid`](examples/basic.liquid) - Basic variable substitution
- [`filters.liquid`](examples/filters.liquid) - Filter demonstrations
- [`control_flow.liquid`](examples/control_flow.liquid) - Conditionals and loops
- [`blog_post.liquid`](examples/blog_post.liquid) - Real-world blog template

## API Reference

### Core Types

```moonbit
// Value types
enum LiquidValue {
  String(String)
  Number(Double)
  Bool(Bool)
  Array(Array[LiquidValue])
  Object(Map[String, LiquidValue])
  Null
}

// Template context
struct Context {
  variables : Map[String, LiquidValue]
}

// Template renderer
struct Renderer {
  context : Context
}
```

### Main Functions

```moonbit
// Create a new context
Context::new() -> Context

// Set variables
context.set(key: String, value: String) -> Unit

// Render template
render_template(template: String, context: Context) -> String

// Apply filters
apply_filter(value: String, filter_name: String) -> String
```

### Built-in Filters

#### String Filters
- `upcase` - Convert to uppercase
- `downcase` - Convert to lowercase
- `capitalize` - Capitalize first letter
- `strip` - Remove leading/trailing whitespace
- `size` - Get string length

#### Array Filters
- `first` - Get first element
- `last` - Get last element
- `join` - Join array elements
- `reverse` - Reverse array order
- `sort` - Sort array elements

#### Utility Filters
- `default` - Provide fallback value
- `truncate` - Limit string length
- `escape` - HTML escape

## Architecture

The Liquid MoonBit implementation consists of several modules:

1. **Lexer** (`lexer.mbt`) - Tokenizes template strings
2. **Parser** (`parser.mbt`) - Builds Abstract Syntax Tree (AST)
3. **Renderer** (`renderer.mbt`) - Evaluates AST and generates output
4. **Types** (`hello.mbt`) - Core data types and structures

### Processing Pipeline

```
Template String → Lexer → Tokens → Parser → AST → Renderer → Output
```

## Testing

Run the test suite:

```bash
moon test
```

Run the demo:

```bash
moon run src/main
```

## Compatibility

This implementation aims for compatibility with Shopify Liquid syntax while leveraging MoonBit's type safety and performance characteristics.

### Supported Tags
- ✅ Output: `{{ }}`
- ✅ Variables: `{{ variable }}`
- ✅ Filters: `{{ value | filter }}`
- 🚧 if/else: `{% if %}...{% endif %}`
- 🚧 for: `{% for item in items %}...{% endfor %}`
- 🚧 assign: `{% assign var = value %}`
- 🚧 capture: `{% capture var %}...{% endcapture %}`
- 🚧 include: `{% include 'template' %}`

### Supported Operators
- ✅ Equality: `==`, `!=`
- 🚧 Comparison: `<`, `>`, `<=`, `>=`
- 🚧 Logic: `and`, `or`, `not`
- 🚧 Contains: `contains`

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

## Status

🚧 **This is a work in progress.** The current implementation provides basic template functionality with variable substitution and simple filters. Advanced features like control flow, template inheritance, and complex filters are in development.

### Roadmap

- [ ] Complete lexer/parser integration
- [ ] Full control flow implementation
- [ ] Template inheritance system
- [ ] Advanced filter library
- [ ] Performance optimizations
- [ ] Comprehensive documentation
- [ ] Package publication to mooncakes.io