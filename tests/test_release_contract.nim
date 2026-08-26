import std/[options, sequtils, strutils, unittest]

import terminal_layout

suite "documented public release surface":
  test "constructs and composes every component through the facade":
    let
      hierarchy = tree("project", tree("src"), tree("tests"))
      navigation = bulletList("Home", "Settings")
      panelOutput = initPanel(navigation, width = 18,
        title = some("Menu"), useColor = false).render()
      calloutOutput = info(hierarchy.render(), width = 20,
        useColor = false).render()
      bannerOutput = banner("Report", width = 20).render()

    check hierarchy.render() == "project\n├─ src\n└─ tests"
    check panelOutput ==
      "┌ Menu ──────────┐\n" &
      "│ • Home         │\n" &
      "│ • Settings     │\n" &
      "└────────────────┘"
    check calloutOutput.startsWith("┌ [INFO] ──────────┐\n")
    check "project" in calloutOutput
    check bannerOutput == "────── Report ──────"

  test "reexports TerminalStyle customization and visible-cell helpers":
    let
      accent = initTerminalStyle(foreground = colorCyan,
        attributes = {taBold})
      theme = initListTheme(unicodeLayoutGlyphs.list,
        markerStyle = accent)
      styled = bulletList([listItem("界")], theme = theme)
      plain = bulletList([listItem(red("value"))],
        initListOptions(useColor = false), theme)

    check displayWidth(stripAnsi(styled)) == 4
    check '\e' in styled
    check styled.endsWith(termClear & " 界")
    check plain == "• value"
    check '\e' notin plain

  test "keeps documented default and output contracts stable":
    let components = [
      initPanel("body").render(),
      info("body").render(),
      initBanner("body").render()
    ]

    check defaultPanelWidth == 40
    check defaultCalloutWidth == 40
    check defaultBannerWidth == 40
    for rendered in components:
      check not rendered.endsWith("\n")
      check splitLayoutLines(rendered).allIt(displayWidth(it) == 40)

  test "supports validated CRLF output without a trailing separator":
    let rendered = initPanel("first\nsecond", width = 12,
      lineEnding = "\r\n", useColor = false).render()

    check "\r\n" in rendered
    check not rendered.endsWith("\r\n")
    check rendered.split("\r\n").allIt(displayWidth(it) == 12)
