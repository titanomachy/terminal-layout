## A caller-supplied project hierarchy.

import terminal_layout

let project = tree("terminal-layout",
  tree("src",
    tree("terminal_layout.nim"),
    tree("terminal_layout",
      tree("core.nim"),
      tree("themes.nim"),
      tree("trees.nim"))),
  tree("tests", tree("test_core.nim"), tree("test_trees.nim")))

when isMainModule:
  echo project.render(theme = roundedTreeTheme)
