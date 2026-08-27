## Compose every TerminalLayout component through ordinary rendered strings.
##
## This example performs no filesystem traversal or terminal detection. Every
## width, theme, and color choice is explicit, and callers retain control over
## when the completed report is written.

# Run with: nim r --path:src examples/all_layouts.nim

import std/[options, strutils]

when compiles((block:
  import terminal_layout
)):
  import terminal_layout
else:
  import ../src/terminal_layout

let navigation = @[
  listItem("Overview"),
  listItem("Services",
    listItem("API"),
    listItem("Worker"))
    .withChildKind(listBullets),
  listItem("Settings")
]

let navigationPanel = initPanel(
  numberedList(navigation,
    initListOptions(useColor = false).withWidth(32)),
  width = 36,
  title = some("Navigation"),
  theme = roundedPanelTheme,
  useColor = false)

let projectTree = tree("terminal-layout",
  tree("src", tree("terminal_layout")),
  tree("tests"),
  tree("examples"))

let projectCard = initCard(
  projectTree.render(initTreeOptions(useColor = false)),
  title = some("Project"),
  footer = some("output only"),
  width = 36,
  useColor = false)

let checks = @[
  listItem("Compile examples").withTaskState(taskChecked),
  listItem("Run tests").withTaskState(taskChecked),
  listItem("Generate docs").withTaskState(taskChecked)
]

let buildCallout = success(
  taskList(checks, initListOptions(useColor = false).withWidth(32)),
  title = "Build",
  width = 36,
  useColor = false)

# Banners separate the sections without adding semantic severity. Panels,
# cards, callouts, trees, and lists compose solely through returned strings.
let report = @[
  banner("Navigation", width = 36).render(),
  navigationPanel.render(),
  banner("Structure", width = 36).render(),
  projectCard.render(),
  banner("Status", width = 36).render(),
  buildCallout.render()
].join("\n")

echo report
