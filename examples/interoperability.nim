## String-based composition with representative table and graph output.
##
## TerminalTable and TerminalGraph are intentionally not imported here. Their
## renderers return strings, which can be passed to TerminalLayout unchanged.

import std/options

import terminal_layout

let
  renderedTable = "Name    Result\ncompile pass\ntest    pass"
  renderedGraph = "requests  ▁▂▄▆█"
  dashboardBody = renderedTable & "\n\n" & renderedGraph
  renderedDashboard = initPanel(dashboardBody,
    width = 32,
    title = some("Build dashboard"),
    theme = asciiPanelTheme,
    useColor = false).render()

when isMainModule:
  echo renderedDashboard
