# Contributing

Contributions are welcome through focused issues and pull requests.

## Development setup

TerminalLayout requires Nim 2.0.0 or newer and `terminal_style` 0.1.1 or
newer. Install the dependency from Nimble, or use a sibling
`terminal-styles` checkout while developing the terminal suite.

From the package root, run:

```sh
nimble check
nimble test
nimble examples
nimble docs
```

When sibling TerminalTable and TerminalGraph repositories are available, also
run:

```sh
nimble suiteIntegration
```

## Change requirements

Keep renderers deterministic and output-only: they return strings and must not
print, query the terminal, access the filesystem, or mutate caller-owned
models. Widths are complete outer widths measured in visible terminal cells.
Use TerminalStyle helpers for ANSI controls, grapheme clusters, CJK, combining
marks, and emoji instead of measuring bytes or code points.

New or changed public behavior needs:

- `##` API documentation describing validation, width, mutation, and output
  semantics where relevant;
- exact output snapshots and focused validation tests;
- ANSI, Unicode, plain-mode, multiline, and narrow-width coverage when the
  behavior affects rendering;
- a finite example and README/API-index update; and
- an entry under `Unreleased` in `CHANGELOG.md`.

Add stable modules to `src/terminal_layout.nim`, `tests/import_probe.nim`, and
the relevant Nimble tasks. Keep domain traversal, parsing, terminal detection,
and I/O outside the layout components.

By contributing, you agree that your contribution is licensed under the MIT
license in `LICENSE`. Do not submit code whose license is unknown or
incompatible. Record incorporated or adapted third-party material in
`THIRD_PARTY_NOTICES.md`.
