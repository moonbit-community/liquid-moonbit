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
  let context = @liquid.LiquidContext::new()
  context.set("name", @liquid.string_value("MoonBit"))
  let template = @liquid.compile("Hello {{ name | upcase }}!").unwrap()
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
  let result = @liquid.apply_filter(
    @liquid.array_value([@liquid.number_value(1)]),
    "concat",
    [@liquid.array_value([@liquid.number_value(2)])],
  ).unwrap()
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
  let context = @liquid.LiquidContext::new()
  context.register_template("greeting", "Hello {{ name }}!")
  let template = @liquid.compile("{% render 'greeting', name: 'Alice' %}").unwrap()
  assert_eq(template.render(context).unwrap(), "Hello Alice!")
}
```

## Diagnostics

`Diagnostic` exposes `phase`, `code`, `message`, `offset`, and `template`.
Parse offsets identify an opening tag using zero-based UTF-16 code units;
runtime offsets are currently absent.
Rendering returns `Err` if diagnostics occur. Context mutations performed before
an error are not rolled back. A fresh context isolates variable bindings between
renders; it does not provide transactional rollback. Missing output values are
errors unless handled by a filter such as `default`; absent values in conditions
remain falsy.

## Source organization

Import `moonbit-community/liquid` for the public interface. The root package provides the entry point:
`engine/` owns compilation and rendering, `value/` owns the Liquid value type,
and `internal/` contains shared value operations and filter implementations.
Tests live beside the source they exercise. Files ending in `_test.mbt` use
the package interface (black-box tests); `_wbtest.mbt` is reserved for tests
that need private implementation access (white-box tests). Public entry-point
integration tests live in the root package.

## Runnable example

```sh
moon run examples/basic --target native
```

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
See [ARCHITECTURE.md](https://github.com/moonbit-community/liquid-moonbit/blob/main/ARCHITECTURE.md) for module responsibilities and limitations.
