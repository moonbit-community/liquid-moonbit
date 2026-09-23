# Liquid for MoonBit

A Liquid template engine with reusable compiled templates, typed filter arguments,
and structured diagnostics. The package also includes Jekyll/Shopify-inspired
extensions; it does not claim full compatibility with every Liquid dialect.

## Compile and render

Compile once, then render with a context. Both operations return `Result`;
applications decide how to display or log diagnostics.

```mbt check
///|
test {
  let context = LiquidContext::new()
  context.set("name", string_value("MoonBit"))
  let template = compile("Hello {{ name | upcase }}!").unwrap()
  assert_eq(template.render(context).unwrap(), "Hello MOONBIT!")
}
```

Templates support output pipelines, assignment, capture, conditions, case,
loops, loop control, counters, cycle, ifchanged, raw text, comments, and whitespace
control. Context values can be strings, numbers, explicit floats, booleans,
arrays, objects, or null. Use `float_value` to preserve floating arithmetic when
supplying an integral float from the host.

## Typed filters

Filter arguments are values, not strings containing Liquid syntax. Literal quote
characters remain part of a supplied string. Filters return diagnostics for
unknown names and invalid concatenation operands.

```mbt check
///|
test {
  let result = apply_filter(array_value([number_value(1)]), "concat", [
    array_value([number_value(2)]),
  ]).unwrap()
  assert_eq(result.to_string(), "[1, 2]")
}
```

## Registered templates

`include` shares the caller's variables; `render` starts an isolated context with
explicit arguments. Register source text on the context. Recursive partials are
bounded, and partial diagnostics identify the template.

```mbt check
///|
test {
  let context = LiquidContext::new()
  context.register_template("greeting", "Hello {{ name }}!")
  let template = compile("{% render 'greeting', name: 'Alice' %}").unwrap()
  assert_eq(template.render(context).unwrap(), "Hello Alice!")
}
```

## Diagnostics and API changes

`Diagnostic` exposes `phase`, `code`, `message`, `offset`, and `template`.
Parse offsets identify an opening tag; runtime offsets are currently absent.
Rendering returns `Err` if diagnostics occur. Context mutations performed before
an error are not rolled back; use a fresh context when transactional behavior is
needed. Missing output values are errors unless handled by a filter such as
`default`; absent values in conditions remain falsy.

This refactor intentionally breaks the former API. The public AST, node
constructors, `parse`, `LiquidTemplate`, string-parameter filter wrappers,
expression evaluation helpers, layout wrappers, and `ErrorPolicy` have been
removed. Use `compile`, `Template::render`, and typed `apply_filter` instead.
There are no compatibility aliases.

## Development

```sh
moon check --target all --deny-warn --warn-list +25+73
moon fmt --check
moon test --target wasm
moon test --target wasm-gc
moon test --target js
moon test --target native
```

The reference corpus contains 20 cases generated with Shopify Ruby Liquid 5.4.0.
It covers selected behavior, not complete standards compliance. Install that gem
outside this repository, then run `ruby tools/reference_cases.rb --check`.
See [ARCHITECTURE.md](ARCHITECTURE.md) for module responsibilities and limitations.
