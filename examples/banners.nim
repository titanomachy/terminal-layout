## A section heading and build summary.

import std/options
import terminal_layout

let section = banner("Dependencies", width = 36)

let buildSummary = initBanner(
  "BUILD COMPLETE",
  subtitle = some("12 checks · 0 failures"),
  width = 36,
  theme = heavyBannerTheme,
  textStyle = initTerminalStyle(attributes = {taBold}),
  fillStyle = initTerminalStyle(foreground = colorGreen),
  useColor = false)

when isMainModule:
  echo section.render()
  echo buildSummary.render()
