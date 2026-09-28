# Liquid for MoonBit

A Liquid template engine for MoonBit with reusable compiled templates, typed
filter arguments, and structured diagnostics. Use it to render caller-supplied
text templates with strings, numbers, booleans, arrays, objects, and null values.
The library runs on wasm, wasm-gc, JavaScript, and native backends.

## Version and installation

**This README describes the unreleased API on `main`.** The latest registry
release checked on September 28, 2026 is `bobzhang/liquid@0.1.1`, which uses the
old API. The version in `moon.mod` has not yet been bumped. Installing `0.1.1`
alone will not provide the `compile` interface shown below.

To try the current implementation directly:

```sh
git clone https://github.com/moonbit-community/liquid-moonbit.git
cd liquid-moonbit
moon run examples/basic --target native
```

To use this checkout from an existing application, put the two modules beside a
`moon.work` file:

```text
workspace/
  moon.work
  my-app/
  liquid-moonbit/
```

```moonbit nocheck
// moon.work
members = ["my-app", "liquid-moonbit"]
```

From `my-app/`, declare the dependency:

```sh
moon add bobzhang/liquid@0.1.1
```

The workspace resolves that dependency to the local checkout, overriding the
registry version. Without the workspace, this command installs the old release.
See MoonBit's [local dependency documentation](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html#dependency-management).
Add the package import to your application's `moon.pkg`:

```moonbit nocheck
///|
import {
  "bobzhang/liquid",
}
```

The examples below use that import as `@liquid`. Their `test` blocks also serve
as executable documentation in this repository. For upgrades from the old API,
see [MIGRATION.md](MIGRATION.md).

## Compile and render

Compile a template once and render it with a context. Both operations return
`Result`; applications decide how to handle failures. The first example uses
`unwrap()` for brevity; see error handling below for fallible input.

```mbt check
///|
test {
  let context = @liquid.LiquidContext::new()
  context.set("name", @liquid.string_value("MoonBit"))
  let template = @liquid.compile("Hello {{ name | upcase }}!").unwrap()
  assert_eq(template.render(context).unwrap(), "Hello MOONBIT!")
}
```

Templates can combine conditions, loops, and filters:

```mbt check
///|
test {
  let context = @liquid.LiquidContext::new()
  context.set(
    "names",
    @liquid.array_value([
      @liquid.string_value("Ada"),
      @liquid.string_value("Lin"),
    ]),
  )
  let template = @liquid.compile(
    "{% for name in names %}{% if forloop.first %}Hello {% endif %}{{ name }}{% unless forloop.last %}, {% endunless %}{% else %}Nobody{% endfor %}",
  ).unwrap()
  assert_eq(template.render(context).unwrap(), "Hello Ada, Lin")
}
```

Use `string_value`, `number_value`, `float_value`, `bool_value`, `array_value`,
`object_value`, and `null_value` to supply data. Use `float_value(4)` when an
integral host number must retain floating-point semantics, such as a divisor
that should produce `2.5` from `10`. See [NUMERIC_VALUES.md](NUMERIC_VALUES.md).

## Typed filters

Template filter arguments are expressions: quote literal strings; bare names
resolve against the context. Direct `apply_filter` calls accept evaluated
`LiquidValue` arguments. Do not add Liquid quoting to those strings: quote
characters are preserved as data.

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

`apply_filter` returns `Result[LiquidValue, Diagnostic]`; unknown filters and
invalid concatenation operands return `Err`. Named options use the optional
`options` map, for example `allow_false` on `default`.

## Registered templates

Register template source with `context.register_template(name, source)`.
The library does not read template files from disk. `include` shares the caller's
variables; `render` starts an isolated variable context with explicit arguments.
Both can access registered templates. Partial recursion is bounded.

```mbt check
///|
test {
  let context = @liquid.LiquidContext::new()
  context.register_template("greeting", "Hello {{ name }}!")
  let template = @liquid.compile("{% render 'greeting', name: 'Alice' %}").unwrap()
  assert_eq(template.render(context).unwrap(), "Hello Alice!")
}
```

## Error handling and context lifetime

Handle compilation and rendering failures separately. This example exercises a
missing-variable error and a syntax error without unwrapping either result:

```mbt check
///|
test {
  let context = @liquid.LiquidContext::new()
  match @liquid.compile("Hello {{ missing }}!") {
    Err(errors) => fail("Unexpected compile error: " + errors[0].message)
    Ok(template) =>
      match template.render(context) {
        Ok(_) => fail("Expected a missing-variable error")
        Err(errors) => {
          assert_eq(errors[0].phase, "render")
          assert_eq(errors[0].code, "missing_variable")
          assert_eq(errors[0].offset, None)
        }
      }
  }
  match @liquid.compile("Hello {{ name") {
    Ok(_) => fail("Expected an unclosed output tag")
    Err(errors) => {
      assert_eq(errors[0].phase, "parse")
      assert_eq(errors[0].code, "unclosed_tag")
      assert_eq(errors[0].offset, Some(6))
    }
  }
}
```

Each diagnostic exposes `phase`, `code`, `message`, `offset`, and `template`.
Parse offsets are zero-based UTF-16 code-unit offsets identifying an opening
tag, not line numbers or byte offsets. Runtime offsets are currently `None`.
Partial-template failures carry a template name where available; errors can be
serialized with `to_json()` for application logging.

Missing values in `{{ output }}` are errors unless handled by a filter such as
`default`. Missing values in conditions are falsy. Rendering returns `Err` when
diagnostics occur, rather than returning partial output or inserting error text.

**Rendering can modify the supplied context.** `assign`, `capture`, and shared
includes can leave variables behind, even if rendering later fails. Reusing a
context can therefore affect subsequent renders. Use a fresh context per
independent request to isolate variable bindings; this does not provide
transactional commit/rollback or deep-copy shared arrays and objects.

## Supported scope and limitations

This is a general-purpose Liquid implementation with selected extensions, not
a complete Shopify theme runtime or a claim of full Liquid conformance.

| Area | Current scope |
| --- | --- |
| Core templates | Output pipelines, assignment, capture, conditions, case, loops with modifiers and else, break/continue, counters, cycle, ifchanged, raw, comments, and whitespace control |
| Common filters | String case/escaping/replacement, split/join, slice/truncate, array selection/sorting, concat, arithmetic, rounding, default, and date formatting |
| Extensions | Includes additional filters such as `offset`, `limit`, `at`, and money formatting; behavior and convenience defaults can differ from other Liquid implementations |
| Partials | Caller-registered source templates for `include` and `render`; no automatic filesystem or theme loading |
| `layout` and `section` | **Placeholders only:** `layout` emits a comment; `section` emits an empty HTML wrapper with a comment. Neither loads or composes templates. Do not rely on these tags for working layouts or sections |

Some filters accept convenience defaults, such as a three-element `slice` when
no arguments are supplied. Pass explicit arguments when matching another
Liquid implementation's behavior matters.

Runtime source locations, comprehensive execution/output limits, and broader
language conformance remain incomplete. The partial nesting limit alone does
not make this library a resource-bounded sandbox for untrusted templates.

## Development

Ruby is not required to use this library or run ordinary `moon test` commands.
It is used only to regenerate or verify the 20 reference cases against Shopify
Ruby Liquid 5.4.0; those cases do not establish complete conformance.

See [CONTRIBUTING.md](CONTRIBUTING.md) for checks, reference fixtures, toolchain
notes, and colocated test conventions, and [ARCHITECTURE.md](ARCHITECTURE.md)
for package responsibilities.
