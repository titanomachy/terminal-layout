## Minimal TerminalLayout façade example.

when compiles((block:
  import terminal_layout
)):
  import terminal_layout
else:
  import ../src/terminal_layout

let
  width = initLayoutWidth(32)
  insets = initLayoutInsets(top = 1, right = 2, bottom = 1, left = 2)
  message = joinLayoutLines(["TerminalLayout", "foundation ready"])

doAssert width.cellCount == 32
doAssert insets.horizontalInset == 4
doAssert displayWidth(message) == 16
