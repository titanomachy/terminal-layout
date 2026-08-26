# TerminalLayout API documentation

TerminalLayout is the output-only structural layer of the Nim terminal suite.
It provides shared, Unicode-cell-aware conventions for trees, panels, lists,
callouts, and banners without printing or querying the terminal.

Phase 0 establishes the package foundation. Phase 1 adds generic trees, Phase
2 adds panels and cards, Phase 3 adds nested bullet, numbered, and task lists
plus generic indentation, Phase 4 adds semantic callouts, and Phase 5 adds
non-semantic banners. Phase 6 validates cross-component composition, façade
exports, width properties, and sibling-suite string boundaries.

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

## List example

```nim
import terminal_layout

let checklist = [
  listItem("Tests").withTaskState(taskChecked),
  listItem("Release").withTaskState(taskUnchecked)
]

echo taskList(checklist, initListOptions(useColor = false))
```

## Callout example

```nim
import terminal_layout

let result = success("All checks passed", title = "CI", width = 28,
  useColor = false)

echo result.render()
```

## Banner example

```nim
import std/options
import terminal_layout

let summary = initBanner("BUILD COMPLETE",
  subtitle = some("12 checks · 0 failures"),
  width = 36,
  theme = heavyBannerTheme)

echo summary.render()
```

## Foundation modules

- [`core`](terminal_layout/core.html) — validated widths and insets, overflow
  behavior, and multiline helpers.
- [`themes`](terminal_layout/themes.html) — named Unicode and ASCII glyph sets.
- [`trees`](terminal_layout/trees.html) — tree models, builders, themes,
  validation, options, and ANSI-aware rendering.
- [`panels`](terminal_layout/panels.html) — panel/card models, padding, border
  themes, validation, fluent configuration, and deterministic rendering.
- [`lists`](terminal_layout/lists.html) — recursive list models, marker themes,
  rendering options, bullet/number/task conveniences, and indentation.
- [`callouts`](terminal_layout/callouts.html) — semantic models, explicit
  palettes, constructors, validation, and panel-backed rendering.
- [`banners`](terminal_layout/banners.html) — non-semantic headings,
  rule/box themes, validation, immutable configuration, and rendering.

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

## List behavior

- `listItem` creates concise nested literals; `initListItem`, `add`, and
  `addChild` support incremental ordered construction.
- `ListKind` selects bullet, numbered, or task markers. A parent's
  `withChildKind` setting changes its direct nested level, allowing kinds to be
  mixed without changing sibling order.
- Ordered sibling groups reserve their widest marker width, keeping item text
  aligned across digit-count changes. Each numbered nested level restarts at
  `startingNumber` and uses the configured plain, visible delimiter.
- Explicit and wrapped continuation lines use hanging indentation. Optional
  width constrains complete output lines without padding shorter lines.
- Unicode, ASCII, and validated custom themes keep marker and body styles
  independent; an item can override its own body style.
- Task state is represented by visible checked, unchecked, and indeterminate
  markers even when color is disabled. Plain mode also strips input ANSI.
- `indent` prefixes arbitrary multiline text while safely closing/restoring
  ANSI state and normalizing output to validated LF or CRLF.

See `examples/lists.nim` for a checklist, numbered procedure, mixed nested
navigation, and generic indentation.

## Callout behavior

- `info`, `warning`, `failure`/`error`, and `success` construct built-in
  semantic kinds; `initCallout` also supports an explicitly themed custom kind.
- Boxed callouts delegate border and body geometry to panels. Compact callouts
  use borderless panels, preserving complete outer-width, padding, overflow,
  ANSI, and line-ending semantics.
- Named themes carry a visible label, optional one-cell icon, plain marker,
  panel preset, and independent marker, body, and border styles. Custom values
  are validated before rendering.
- Styled output uses an icon or textual label. Plain output always includes a
  marker such as `[INFO]` or `[FAIL]`, strips existing ANSI, and never relies
  on color for meaning.
- Optional contextual titles follow the semantic marker. The marker must fit
  completely; contextual text and multiline bodies then wrap or truncate with
  TerminalStyle's grapheme-aware helpers.
- Callout renderers return strings, never mutate their models, and never print
  or append a trailing line ending.

See `examples/callouts.nim` for boxed, compact, custom, and nested-list status
reports without a logging-framework dependency.

## Banner behavior

- `banner` concisely creates a centered rule heading; `initBanner` configures
  optional subtitles, complete outer width, alignment, panel padding, themes,
  text/fill styles, color, and line endings.
- Plain-rule, square-boxed, heavy-boxed, double-boxed, and ASCII presets are
  named explicitly. Custom themes validate a plain one-cell fill glyph and
  their panel border glyphs before output is produced.
- Rule banners place fill cells in all unused columns. Empty and vertical
  padding rows become complete rules, and centered odd spare cells put the
  deterministic extra cell on the right.
- Boxed banners reuse the panel renderer for borders, padding, fitting, and
  exact outer-width geometry.
- Main text may be multiline and the optional subtitle follows it. ANSI-aware
  grapheme truncation never splits CJK, combining clusters, emoji, or escape
  sequences.
- Plain mode strips existing ANSI and suppresses styles. LF and CRLF output
  never has an added trailing line ending, and rendering does not mutate the
  banner model.

See `examples/banners.nim` for section-heading, build-summary, and
application-title examples. FIGlet-style large fonts remain deferred.

## Composition and hardening

- Rendered strings are the only integration boundary. Nested lists retain
  their indentation inside panels, trees retain their connector columns inside
  cards, and callouts accept rendered lists without component adapters.
- An outer `useColor = false` strips ANSI from already-rendered children while
  keeping plain semantic markers, Unicode graphemes, and visible widths intact.
- Focused composition snapshots cover list/panel, tree/card, list/callout, and
  banner-separated output. Seeded property-style tests vary input and requested
  widths across every constrained component.
- The façade and every direct submodule remain importable without output,
  terminal queries, or other side effects.
- `nimble suiteIntegration` imports TerminalStyle, TerminalTable,
  TerminalGraph, and TerminalLayout together, checks public-name coexistence,
  renders actual table and graph strings inside panels, and places layout
  strings in table cells. Its sibling source paths are development-only.

See `examples/all_layouts.nim` for one deterministic report containing every
TerminalLayout component.

## Generate locally

```
nimble docs
python3 -m http.server 8000 --directory htmldocs
```
