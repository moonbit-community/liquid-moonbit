# Implementation structure

The library stays in one MoonBit package. Files separate responsibilities; new
packages or pluggable registries are unnecessary for the current dependency set.

## Primary interface

- `compile(source)` returns `Result[Template, Array[Diagnostic]]`.
- `Template` is opaque; its compiled nodes and expressions are private.
- `Template::render(context)` returns either the complete output or diagnostics.
- `LiquidContext` supplies values and explicitly registered partial templates.
- `apply_filter_values` applies a filter to typed arguments and returns a result.

The public `LiquidValue` represents application data, not parser implementation.
New internal node or expression kinds do not change the opaque template interface.

## Compilation and execution

`parser.mbt` tokenizes and parses template blocks. It records diagnostics for
unknown/misplaced tags, invalid assignment/loop syntax, empty required arguments,
unclosed delimiters, and missing block terminators. Parse offsets are zero-based
UTF-16 code-unit offsets. Errors inside multiline liquid tags point at the opening
liquid tag.

`compiled_nodes.mbt` converts the compatibility syntax tree into private render
instructions. `expression_ast.mbt` compiles literal values, property paths, filter
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

Every entry point delegates to `apply_filter_values` in `filters.mbt`.
Arguments stay as values, including arrays, objects, and floating-point numbers.
Options such as default's allow_false are passed as named values.

Sequence, numeric, date, collection, string, and scalar modules own their
implementations. A filter has one implementation regardless of whether it is
called from a template or a MoonBit function. Compatibility adapters handle
argument syntax; they do not implement independent filter behavior.

## Errors and compatibility

`diagnostics.mbt` defines machine-readable phase, code, message, optional offset,
and optional partial-template name. Runtime errors currently have no source
offset; the implementation returns None rather than guessing a location.

Checked rendering never logs diagnostics or injects error markers into output.
It returns Err if any diagnostic occurred. It does not provide transactional
rollback: assignments already executed may remain in the context.

The `legacy_*.mbt` interfaces remain callable without deprecation warnings.
`parse`, `LiquidTemplate`, and node constructors retain the inspectable syntax
tree. Legacy rendering compiles that tree for each render, then uses the same
executor. This accommodates callers that mutate the public node array.
String-returning legacy render methods retain ErrorPolicy behavior.

The legacy filter adapters preserve their signatures and input-on-error fallback.
For typed arguments and observable filter errors, use apply_filter_values.
The primary interface does not expose the compatibility AST. Existing exported
constructors have not been deleted or had their signatures changed.

## Behavior changes in this refactor

- Template filter arguments consistently use expression semantics. Quote literal
  text; bare names resolve against the context. The context-free
  apply_filter_with_params adapter still treats unquoted nonnumeric text as
  literal text.
- Where compares object property values by type instead of stringifying them.
- Concat rejects non-array operands; the old string self-concatenation placeholder
  is removed. The legacy adapter preserves its input when the filter rejects it.
- Default with no arguments returns an empty string for empty input, consistently
  across entry points.
- Splitting an empty string returns an empty array, matching the pinned reference.
- Include argument evaluation no longer observes earlier argument bindings.
- No-argument arithmetic uses the same numeric rules as explicit arguments.
  Existing convenience defaults remain, including slice's three-element default.

This is an architectural refactor, not a claim of full Liquid conformance.
Legacy extension filters and convenience defaults are still supported; broader
grammar, filter semantics, resource limits, and runtime source spans need separate
compatibility work.

## Tests

All original tests remain, organized into legacy feature groups. Focused tests
exercise the primary interface, typed filter dispatch, error results, repeated
rendering, and partial scopes.

The reference fixture suite is generated against the pinned Shopify Liquid
version documented in tools/reference_cases.rb. It is a limited conformance
corpus, not an exhaustive certification.
