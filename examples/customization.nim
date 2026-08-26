## Explicit TerminalStyle and glyph customization with a plain-mode fallback.

import terminal_layout

let
  accent = initTerminalStyle(foreground = colorCyan,
    attributes = {taBold})
  customTheme = customTreeTheme("+", "`", "|", "-",
    connectorStyle = accent,
    labelStyle = initTerminalStyle(foreground = colorWhite))
  dependencies = tree("terminal_layout",
    tree("terminal_style"),
    tree("Nim standard library"))
  styledOutput = dependencies.render(theme = customTheme)
  plainOutput = dependencies.render(
    initTreeOptions(useColor = false), customTheme)

when isMainModule:
  echo styledOutput
  echo ""
  echo plainOutput
