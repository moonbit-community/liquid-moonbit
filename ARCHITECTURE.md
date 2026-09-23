# Implementation structure

The library stays in one MoonBit package. Files separate responsibilities; new
packages or pluggable registries are unnecessary for the current dependency set.

## Primary interface

- `compile(source)` returns `Result[Template, Array[Diagnostic]]`.
- `Template` is opaque; its compiled nodes and expressions are private.
- `Template::render(context)` returns either the complete output or diagnostics.
- `LiquidContext` supplies values and explicitly registered partial templates.
- `apply_filter` applies a filter to typed arguments and returns a result.

The public `LiquidValue` represents application data, not parser implementation.
New internal node or expression kinds do not change the opaque template interface.

## Compilation and execution

`parser.mbt` tokenizes and parses template blocks. It records diagnostics for
unknown/misplaced tags, invalid assignment/loop syntax, empty required arguments,
unclosed delimiters, and missing block terminators. Parse offsets are zero-based
UTF-16 code-unit offsets. Errors inside multiline liquid tags point at the opening
liquid tag.

`compiled_nodes.mbt` defines private render instructions and partial calls.
The parser builds these instructions directly without an intermediate public AST. `expression_ast.mbt` compiles literal values, property paths, filter
calls, and conditions. Compilation preserves Liquid's right-to-left logical
association. `expressions.mbt` owns truthiness and typed comparisons.

`render_nodes.mbt` and `rendering.mbt` execute the compiled instructions.
Expressions are evaluated directly without tokenizing them inside loops.
Registers for loop control, cycles, counters, and ifchanged belong to one render.
Includes share registers; render partials receive independent registers.
Partial arguments are evaluated before any caller variables are temporarily
overridden, and the variables are restored afterward.

Registered partials compile lazily and are cached by source for the current
render. The cache does not survive a render, so changing a registered template
between renders cannot return stale code.

## Filters

Every entry point delegates to `apply_filter` in `filters.mbt`.
Arguments stay as values, including arrays, objects, and floating-point numbers.
Options such as default's allow_false are passed as named values.

Sequence, numeric, date, collection, string, and scalar modules own their
implementations. A filter has one implementation regardless of whether it is
called from a template or a MoonBit function.

## Errors and compatibility

`diagnostics.mbt` defines machine-readable phase, code, message, optional offset,
and optional partial-template name. Runtime errors currently have no source
offset; the implementation returns None rather than guessing a location.

Rendering never logs diagnostics or injects error markers into output.
It returns Err if any diagnostic occurred. It does not provide transactional
rollback: assignments already executed may remain in the context.

This refactor intentionally removes interface compatibility. The public syntax
AST, node constructors, `parse`, `LiquidTemplate`, `ErrorPolicy`, layout wrappers,
and standalone expression evaluation functions are gone. Context storage is
opaque. The sole direct filter function is `apply_filter(value, name, arguments,
options?)`, which accepts evaluated values and returns `Result`. No aliases or
input-on-error adapters remain.

## Behavior changes in this refactor

- Template filter arguments consistently use expression semantics. Quote literal
  text; bare names resolve against the context. Direct filter calls receive
  values and preserve literal quote characters in strings.
- Where compares object property values by type instead of stringifying them.
- Concat rejects non-array operands; the old string self-concatenation placeholder
  is removed. Invalid operands return a diagnostic.
- Default with no arguments returns an empty string for empty input, consistently
  across entry points.
- Splitting an empty string returns an empty array, matching the pinned reference.
- Include argument evaluation no longer observes earlier argument bindings.
- No-argument arithmetic uses the same numeric rules as explicit arguments.
  Existing convenience defaults remain, including slice's three-element default.

This is an architectural refactor, not a claim of full Liquid conformance.
Existing extension filters and convenience defaults are still supported; broader
grammar, filter semantics, resource limits, and runtime source spans need separate
conformance work. Layout and section tags still produce placeholders; they do
not implement a complete layout or theme loader.

## Tests

Tests are grouped by behavior: conditions, assignment, value lookup, template
composition, loop properties, and individual filter domains. Old AST snapshots
and removed-API construction tests are retired; behavioral assertions use source
templates or typed filter calls. Focused tests cover structured errors, repeated
rendering, partial scopes, and loop metadata. Numeric file suffixes and legacy
test groups are gone.

The reference fixture suite is generated against the pinned Shopify Liquid
version documented in tools/reference_cases.rb. It is a limited conformance
corpus, not an exhaustive certification.
