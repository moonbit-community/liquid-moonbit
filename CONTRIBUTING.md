# Development

Run commands from the repository root. CI installs the MoonBit nightly toolchain;
no minimum supported compiler version is currently declared. Install MoonBit
using its [official instructions](https://docs.moonbitlang.com/en/latest/getting-started.html).

```sh
moon update
moon check --target all --deny-warn --warn-list +25+73
moon fmt --check
moon test --target all
```

For source changes, run `moon fmt` and `moon info` and review any generated
interface changes. The executable usage example lives in `examples/basic/`:

```sh
moon run examples/basic --target native
```

## Packages and tests

The root package exposes `bobzhang/liquid`. `engine/` owns parsing, compilation,
contexts, diagnostics, and rendering; `value/` owns the Liquid value type.
`internal/` contains shared value operations and filter implementations.

Keep tests beside the source package they exercise:

- `_test.mbt`: black-box tests using the package interface.
- `_wbtest.mbt`: white-box tests needing private implementation access.
- Root-package tests exercise the public entry point across package boundaries.

Prefer input-template-to-output/error regressions for template behavior.
The `mbt check` blocks in `README.mbt.md` run as documentation tests.
`README.md` is a symlink to that file; edit `README.mbt.md`.

See [ARCHITECTURE.md](ARCHITECTURE.md) for package dependencies and implementation
limits.

## Reference cases

Ordinary builds and tests do not require Ruby. Only the reference generator and
CI's reference verification step require the `liquid` gem, pinned to 5.4.0.
Install it outside the repository:

```sh
gem install --user-install liquid --version 5.4.0 --no-document
ruby tools/reference_cases.rb --check
```

To update the generated `reference_compatibility_test.mbt` after deliberately
changing the corpus:

```sh
ruby tools/reference_cases.rb --write
```

Review the resulting diff. Expected output must come from the pinned reference
implementation, not from this library. The generator also invokes `moonfmt`,
so the MoonBit toolchain must be on `PATH`.
