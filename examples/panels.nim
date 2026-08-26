## Panel composition examples using already-rendered multiline strings.
##
## The table and graph values are representative output strings so this
## package demonstrates the integration boundary without production
## dependencies on TerminalTable or TerminalGraph.

import std/options

when compiles((block:
  import terminal_layout
)):
  import terminal_layout
else:
  import ../src/terminal_layout

let
  renderedTable =
    "┌─────────┬───────┐\n" &
    "│ Package │ Tests │\n" &
    "├─────────┼───────┤\n" &
    "│ layout  │  42   │\n" &
    "└─────────┴───────┘"

  renderedGraph =
    "builds  ████████ 8\n" &
    "issues  ██       2"

  releaseCard = initCard(
    renderedTable,
    width = 25,
    title = some("Release"),
    footer = some("generated locally"),
    titleAlignment = alignCenter,
    footerAlignment = alignRight,
    useColor = false)

  metricsPanel = initPanel(
    renderedGraph,
    width = 24,
    title = some("Metrics"),
    theme = doublePanelTheme,
    padding = initPanelPadding(top = 0, right = 1, bottom = 0, left = 1),
    useColor = false)

  nestedTreePanel = initPanel(
    renderTree(tree("project", tree("src"), tree("tests"))),
    width = 24,
    title = some("Tree"),
    theme = asciiPanelTheme,
    useColor = false)

when isMainModule:
  echo releaseCard.render()
  echo ""
  echo metricsPanel.render()
  echo ""
  echo nestedTreePanel.render()
