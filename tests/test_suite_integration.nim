## Development-only integration checks for sibling terminal-suite packages.
##
## Run through ``nimble suiteIntegration`` from the suite workspace. The
## sibling source paths are test-only and are not TerminalLayout dependencies.

import std/[options, sequtils, strutils, unittest]

import terminal_graph
import terminal_layout
import terminal_style
import terminal_table

suite "terminal suite string-boundary integration":
  test "renders an actual TerminalTable inside a panel":
    var table = initTable(["Service", "State"])
    table.theme = asciiTheme
    table.addRow("api", green("ready"))

    let rendered = initPanel(table.render(), width = 24,
      title = some("Table")).render()
    check "+---------+-------+" in stripAnsi(rendered)
    check rendered.splitLines.mapIt(displayWidth(it)) == repeat(24, 7)

  test "renders an actual TerminalGraph inside a panel":
    var graph = initStaticGraph("Load", unit = "%")
    let series = graph.addSeries("cpu", style = psFill, marker = "#")
    graph.push(series, [20.0, 45.0, 30.0, 60.0])

    let graphOutput = graph.render(width = 24, height = 8, useColor = false)
    let rendered = initPanel(graphOutput, width = 28,
      padding = uniformPanelPadding(1), useColor = false).render()
    check "Load" in rendered
    check "cpu" in rendered
    check rendered.splitLines.allIt(displayWidth(it) == 28)

  test "embeds TerminalLayout strings in TerminalTable cells":
    let
      treeOutput = tree("root", tree("child")).render()
      listOutput = bulletList("one", "two")
    var table = initTable(["Tree", "List"])
    table.theme = roundedTheme
    table.addRow(treeOutput, listOutput)

    let rendered = table.render(maxWidth = 40)
    check "└─ child" in rendered
    check "• one" in rendered
    check "• two" in rendered
