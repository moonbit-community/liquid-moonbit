# Migrating from 0.1.1 to the unreleased API

The `main` branch contains breaking changes that are not yet published under a
new registry version. The module metadata still says `0.1.1`; this does not mean
its API matches the published 0.1.1 package. Use the README's local-workspace
instructions to try the new interface.

| Previous interface | Current approach |
| --- | --- |
| `parse(source)` returning `LiquidTemplate` | `compile(source)` returning `Result[Template, Array[Diagnostic]]` |
| String-returning template rendering | `Template::render(context)` returning `Result[String, Array[Diagnostic]]` |
| Public AST and node constructors | Compile template source; compiled nodes are private |
| `apply_filter(value, name)` | `apply_filter(value, name, [])`, then handle its `Result` |
| `Filter` and `apply_filter_with_params` | Pass evaluated `LiquidValue` arguments directly to `apply_filter` |
| `ErrorPolicy`, strict/warn/silent constructors | Handle structured diagnostics in the application |
| Standalone expression evaluation helpers | Evaluate expressions through a compiled template |
| Layout construction/rendering wrappers | Removed; the remaining `layout` and `section` tags are placeholders, not replacements |

For example, replace the old call:

```text
parse("Hello {{ name }}!").render(context)
```

with compilation and explicit error handling:

```mbt nocheck
match @liquid.compile("Hello {{ name }}!") {
  Err(errors) => for error in errors { println(error.message) }
  Ok(template) =>
    match template.render(context) {
      Err(errors) => for error in errors { println(error.message) }
      Ok(output) => println(output)
    }
}
```

This fragment assumes an existing context and package import. Executable examples
are in [README.mbt.md](README.mbt.md).

There are no compatibility aliases. `LiquidContext` storage is opaque; supply
values using `set`, retrieve them using `get`, and register partial sources with
`register_template`.

## Behavior to review when upgrading

- Rendering returns diagnostics instead of logging warnings or inserting error
  markers. Earlier assignments can remain in the context after failure.
- Template filter arguments resolve expressions. Quote literal text; bare names
  resolve variables. Direct filter calls preserve quote characters in strings.
- Unknown direct filters and invalid concatenation operands return `Err` rather
  than silently preserving the input.
- `where` compares values by type. `concat` combines arrays and no longer uses
  the former string self-concatenation behavior.
- Empty-string splitting produces an empty array. `default` without arguments
  produces an empty string for empty input.
- `float_value` preserves floating arithmetic for integral host floats.
- Include arguments are evaluated before being bound to the shared context.

These changes do not imply full Liquid or Shopify theme compatibility. Read the
README's supported scope before migrating templates.
