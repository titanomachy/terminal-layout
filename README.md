# TerminalLayout

TerminalLayout is the output-only structural layer of the Nim terminal suite.
It provides generic trees, panels, and cards, and will add nested lists,
semantic callouts, and banners. Renderers return deterministic strings;
importing the package or constructing a value never prints, queries the
terminal, or mutates terminal state.

The package currently contains the shared foundation, complete tree renderer,
and complete panel/card renderer, with shared tests, examples, and generated
API documentation.

Requires Nim 2.0.0 or newer and TerminalStyle 0.1.1 or newer.

## Install

```sh
nimble install terminal_style
nimble install terminal_layout
```

## Trees and hierarchies

Construct nested literals with `tree` and render them without side effects:

```nim
import terminal_layout

let project = tree("project",
  tree("src", tree("main.nim"), tree("render.nim")),
  tree("tests", tree("test_render.nim")))

echo project.render(theme = roundedTreeTheme)
```

```text
project
├─ src
│  ├─ main.nim
│  ╰─ render.nim
╰─ tests
   ╰─ test_render.nim
```

`TreeNode` is an ordinary value model, so runtime construction preserves the
caller's insertion order:

```nim
var root = initTreeNode("services")
root.add "api"
root.addChild tree("workers", tree("email"), tree("billing"))

echo renderTree(root, theme = asciiTreeTheme)
```

The built-in `unicodeTreeTheme`, `roundedTreeTheme`, and `asciiTreeTheme`
presets apply no color by default. `initTreeTheme` and `customTreeTheme` accept
custom one-cell connectors plus independent connector, label, and pruning
styles. Nodes can override their own label and incoming-connector styles with
`withStyle` and `withConnectorStyle`.

Tree options make structural behavior explicit:

```nim
let options = initTreeOptions(
  showRoot = false,
  overflow = overflowWrap,
  wrapMode = wrapWords,
  useColor = false,
  lineEnding = "\n"
).withWidth(32).withMaxDepth(3)

echo renderTree(project, options)
```

- Width is the complete outer line width. Prefix columns consume part of it,
  and labels wrap or truncate in the remaining terminal cells.
- Explicit and wrapped continuation lines use hanging indentation under the
  label column.
- Visible top-level nodes have depth zero. Every omitted descendant branch is
  replaced with `pruneMarker`; descendants are never silently discarded.
- A single tree has no connector before its visible root. Forest roots and the
  children of a hidden root are connected with tee/elbow branches.
- `useColor = false` strips ANSI already present in labels and suppresses theme
  and node styles.
- Rendering never mutates `TreeNode` values or appends a line ending.

The [tree example](examples/trees.nim) manually models a directory, JSON-like
data, and a dependency hierarchy. TerminalLayout deliberately does not walk
the filesystem or parse JSON on the caller's behalf.

## Panels and cards

Panels are width-aware composition containers for arbitrary text and rendered
TerminalLayout, TerminalTable, or TerminalGraph output. Width is always the
complete outer width, including border columns and horizontal padding:

```nim
let report = initPanel(
  "Builds: 8\nFailures: 0",
  width = 32,
  padding = initPanelPadding(top = 1, right = 2, bottom = 1, left = 2),
  theme = doublePanelTheme)
  .withTitle("CI report", alignCenter)
  .withFooter("main", alignRight)

echo report.render()
```

`squarePanelTheme`, `roundedPanelTheme`, `heavyPanelTheme`,
`doublePanelTheme`, `asciiPanelTheme`, and `borderlessPanelTheme` provide named
presets. `initPanelTheme` and `customPanelTheme` validate custom one-cell
borders before rendering. Each `Panel` stores independent body, title, footer,
and border styles plus body and label alignments.

`initCard` returns the same `Panel` model with rounded borders and one cell of
padding on every side; `card` is its concise convenience form. Fluent helpers
can change titles, footers, width, padding, theme, content alignment, overflow,
color, and line endings without mutating the original value.

- Body text wraps by default or truncates each explicit line when
  `overflowTruncate` is selected. Every emitted row is padded to the outer
  width in visible terminal cells.
- A bordered title or footer has one separator cell on each side when its
  horizontal run has at least three cells. Colliding labels are truncated by
  complete styled graphemes and never replace the corners.
- Empty bodies produce one body row. Top and bottom padding always produce the
  exact requested number of blank rows.
- `useColor = false` strips ANSI already present in the body and labels and
  suppresses panel styles.
- Borderless panels keep the same width, padding, alignment, title, and footer
  contract while omitting the enclosing rules.
- Rendering never mutates `Panel` values or appends a line ending.

The [panel example](examples/panels.nim) composes representative table and
graph strings, plus a rendered tree, without taking TerminalTable or
TerminalGraph as production dependencies.

## Foundation API

The façade also exports the shared foundation and complete TerminalStyle API:

- `LayoutWidth` is a validated positive outer width in terminal cells.
- `LayoutInsets` stores non-negative top, right, bottom, and left space.
- `OverflowMode` makes wrapping or truncation explicit.
- Horizontal alignment reuses TerminalStyle's `TextAlignment` values:
  `alignLeft`, `alignCenter`, and `alignRight`.
- `splitLayoutLines`, `joinLayoutLines`, and `normalizeLineEndings` preserve
  empty and trailing lines, accept CRLF input, and emit validated LF or CRLF.
- `unicodeLayoutGlyphs` and `asciiLayoutGlyphs` centralize one-cell border,
  tree, list, callout, and banner characters.

For example:

```nim
let
  width = initLayoutWidth(40)
  insets = initLayoutInsets(top = 1, right = 2, bottom = 1, left = 2)
  lines = splitLayoutLines("first\r\nsecond")

doAssert width.cellCount == 40
doAssert insets.horizontalInset == 4
doAssert displayWidth("界") == 2
doAssert joinLayoutLines(lines) == "first\nsecond"
```

List, callout, and banner renderers will be added vertically in later phases.
Their module names are already stable and side-effect free.

## Rendering contract

TerminalLayout components follow these package-wide rules:

- Rendering returns a string without an appended trailing line ending.
- Width means visible terminal cells, not UTF-8 bytes or code points.
- ANSI controls, combining marks, CJK characters, and emoji are measured with
  TerminalStyle.
- Plain rendering strips existing ANSI controls and does not apply styles.
- Invalid dimensions, insets, line endings, and one-cell glyphs fail with
  `ValueError` before partial output is produced.
- ASCII output is selected explicitly; the package performs no locale, TTY,
  color, or terminal-width detection.

## Modules

- `terminal_layout/core` contains shared validation, sizing, overflow, and
  multiline behavior.
- `terminal_layout/themes` contains component-neutral Unicode and ASCII glyph
  presets.
- `terminal_layout/trees` contains the generic tree model, builders, themes,
  options, validation, and deterministic renderer.
- `terminal_layout/panels` contains panel/card models, padding, themes,
  validation, fluent configuration, and deterministic rendering.
- `terminal_layout/lists`, `callouts`, and `banners` are stable component
  namespaces for upcoming implementation phases.
- `terminal_layout` re-exports every stable module and `terminal_style`.

## Development

```sh
nimble test
nimble examples
nimble docs
```

`nimble docs` generates the API reference in `htmldocs/`. The shared fixtures
cover ANSI, CJK, combining-mark, emoji, empty, multiline, and CRLF input. The
tree and panel suites add snapshots for their themes and structural edge cases.
