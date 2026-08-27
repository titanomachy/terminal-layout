## Minimal TerminalLayout façade example.

# Run with: nim r --path:src examples/foundation.nim

import terminal_layout

let
  width = initLayoutWidth(32)
  insets = initLayoutInsets(top = 1, right = 2, bottom = 1, left = 2)
  message = joinLayoutLines(["TerminalLayout", "foundation ready"])

doAssert width.cellCount == 32
doAssert insets.horizontalInset == 4
doAssert displayWidth(message) == 16
