# TerminalLayout API documentation

TerminalLayout is the output-only structural layer of the Nim terminal suite.
It provides shared, Unicode-cell-aware conventions for trees, panels, lists,
callouts, and banners without printing or querying the terminal.

Phase 0 establishes the package foundation. Phase 1 adds generic tree models,
builders, themes, options, and deterministic rendering. The remaining
component namespaces already compile and will be implemented in later phases.

- [Main `terminal_layout` façade](terminal_layout.html)
- [Search all exported symbols](theindex.html)

## Install

```
nimble install terminal_style
nimble install terminal_layout
```

## Tree example

```nim
import terminal_layout

let project = tree("project",
  tree("src", tree("main.nim"), tree("render.nim")),
  tree("tests", tree("test_render.nim")))

echo project.render(theme = roundedTreeTheme)
```

## Foundation modules

- [`core`](terminal_layout/core.html) — validated widths and insets, overflow
  behavior, and multiline helpers.
- [`themes`](terminal_layout/themes.html) — named Unicode and ASCII glyph sets.
- [`trees`](terminal_layout/trees.html) — tree models, builders, themes,
  validation, options, and ANSI-aware rendering.
- [`panels`](terminal_layout/panels.html) — reserved panel and card namespace.
- [`lists`](terminal_layout/lists.html) — reserved list namespace.
- [`callouts`](terminal_layout/callouts.html) — reserved semantic callout
  namespace.
- [`banners`](terminal_layout/banners.html) — reserved banner namespace.

The façade also re-exports `terminal_style`, including `TextAlignment`, ANSI
styling, terminal-cell measurement, wrapping, truncation, and padding.

## Tree behavior

- `tree` creates concise nested literals; `initTreeNode`, `add`, and `addChild`
  support incremental construction.
- Unicode, rounded, ASCII, and validated custom themes keep connector and label
  styles independent.
- Optional width and depth limits use `.withWidth` and `.withMaxDepth` without
  magic sentinel values.
- Multiline and wrapped labels use hanging indentation, while truncation and
  every prefix are measured in terminal cells.
- `useColor = false` strips existing ANSI controls as well as suppressing
  component styles.
- A visible pruning marker replaces every branch omitted by a depth limit.

See `examples/trees.nim` for directory, JSON-like, and dependency hierarchies
constructed without filesystem walking or parser dependencies.

## Generate locally

```
nimble docs
python3 -m http.server 8000 --directory htmldocs
```
