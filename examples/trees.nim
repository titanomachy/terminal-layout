## Manual tree examples using caller-supplied domain data.

when compiles((block:
  import terminal_layout
)):
  import terminal_layout
else:
  import ../src/terminal_layout

let directoryTree = tree("terminal-layout",
  tree("src",
    tree("terminal_layout.nim"),
    tree("terminal_layout",
      tree("core.nim"),
      tree("themes.nim"),
      tree("trees.nim"))),
  tree("tests", tree("test_core.nim"), tree("test_trees.nim")))

let jsonLikeTree = tree("user",
  tree("name: Ada"),
  tree("roles", tree("admin"), tree("developer")),
  tree("active: true"))

let dependencyTree = tree("terminal_layout",
  tree("terminal_style",
    tree("ANSI composition"),
    tree("Unicode cell widths")))

when isMainModule:
  echo "Directory"
  echo directoryTree.render(theme = roundedTreeTheme)
  echo "\nJSON-like data"
  echo jsonLikeTree.render(theme = asciiTreeTheme)
  echo "\nDependencies"
  echo dependencyTree.render(
    options = initTreeOptions(useColor = false).withWidth(40))
