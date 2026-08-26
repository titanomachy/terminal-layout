# TerminalLayout API documentation

TerminalLayout is the output-only structural layer of the Nim terminal suite.
It provides shared, Unicode-cell-aware conventions for trees, panels, lists,
callouts, and banners without printing or querying the terminal.

Phase 0 establishes the package foundation. Phase 1 adds generic tree models,
builders, themes, options, and deterministic rendering. Phase 2 adds bordered
panels and card conveniences. The remaining component namespaces already
compile and will be implemented in later phases.

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

## Panel example

```nim
import terminal_layout

let report = initCard("Builds: 8\nFailures: 0", width = 32)
  .withTitle("CI report", alignCenter)
  .withFooter("main", alignRight)

echo report.render()
```

## Foundation modules

- [`core`](terminal_layout/core.html) — validated widths and insets, overflow
  behavior, and multiline helpers.
- [`themes`](terminal_layout/themes.html) — named Unicode and ASCII glyph sets.
- [`trees`](terminal_layout/trees.html) — tree models, builders, themes,
  validation, options, and ANSI-aware rendering.
- [`panels`](terminal_layout/panels.html) — panel/card models, padding, border
  themes, validation, fluent configuration, and deterministic rendering.
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

## Panel behavior

- Panel width is the complete outer terminal-cell width, including borders and
  horizontal padding; every rendered row is padded to that width.
- Square, rounded, heavy, double, ASCII, and borderless presets are built in,
  and custom bordered themes validate every glyph.
- Body text wraps or truncates with ANSI-aware TerminalStyle helpers. Styled
  multiline component output can be used directly as the body.
- Titles and footers align independently. Bordered labels use one separator
  cell on each side when space allows and truncate without splitting styled
  graphemes or replacing corners.
- `initCard` and `card` return the same underlying `Panel` model with rounded,
  fully padded defaults.
- Plain rendering strips existing ANSI controls, and LF/CRLF output never has
  an added trailing line ending.

See `examples/panels.nim` for representative rendered table and graph strings
and a tree nested inside panels without extra production dependencies.

## Generate locally

```
nimble docs
python3 -m http.server 8000 --directory htmldocs
```
