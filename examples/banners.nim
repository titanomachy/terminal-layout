## Non-semantic section headings, build summaries, and application titles.

import std/[options, strutils]

import terminal_layout

let sections = @[
  banner("Dependencies", width = 36).render(),
  banner("Tests", width = 36).render(),
  banner("Artifacts", width = 36).render()
]

let buildSummary = initBanner(
  "BUILD COMPLETE",
  subtitle = some("12 checks · 0 failures"),
  width = 36,
  theme = heavyBannerTheme,
  textStyle = initTerminalStyle(attributes = {taBold}),
  fillStyle = initTerminalStyle(foreground = colorGreen))

let applicationTitle = initBanner(
  "TerminalLayout",
  subtitle = some("Deterministic terminal composition"),
  width = 44,
  theme = doubleBannerTheme,
  useColor = false)

# Rendered banners are ordinary strings. Callers choose when and where to
# write them, and banners carry no semantic status severity.
echo sections.join("\n")
echo buildSummary.render()
echo applicationTitle.render()
