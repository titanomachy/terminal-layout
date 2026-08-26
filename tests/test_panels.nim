import std/[options, sequtils, strutils, unittest]

import terminal_layout
import fixtures

suite "panel models, themes, and builders":
  test "constructs validated padding and fluent panel copies":
    let padding = initPanelPadding(top = 1, right = 2, bottom = 3, left = 4)
    check padding.horizontalPadding == 6
    check padding.verticalPadding == 4
    check uniformPanelPadding(2) == PanelPadding(
      top: 2, right: 2, bottom: 2, left: 2)

    let panel = initPanel("body", width = 20)
      .withTitle("Title", alignCenter)
      .withFooter("Footer", alignRight)
      .withPadding(uniformPanelPadding(0))
      .withTheme(doublePanelTheme)
      .withContentAlignment(alignCenter)
      .withOverflow(overflowTruncate)
      .withColor(false)
      .withLineEnding("\r\n")
    check panel.title == some("Title")
    check panel.footer == some("Footer")
    check panel.width.cellCount == 20
    check panel.theme == doublePanelTheme
    check panel.contentAlignment == alignCenter
    check panel.overflow == overflowTruncate
    check not panel.useColor
    check panel.lineEnding == "\r\n"

  test "constructs and validates custom themes":
    let custom = customPanelTheme("1", "2", "3", "4", "-", "|")
    check renderPanel(initPanel("x", width = 5,
        padding = uniformPanelPadding(0), theme = custom)) ==
      "1---2\n|x  |\n3---4"

suite "panel and card snapshots":
  test "renders every built-in border preset":
    let padding = uniformPanelPadding(0)
    check renderPanel(initPanel("x", width = 7, padding = padding,
      theme = squarePanelTheme)) == "┌─────┐\n│x    │\n└─────┘"
    check renderPanel(initPanel("x", width = 7, padding = padding,
      theme = roundedPanelTheme)) == "╭─────╮\n│x    │\n╰─────╯"
    check renderPanel(initPanel("x", width = 7, padding = padding,
      theme = heavyPanelTheme)) == "┏━━━━━┓\n┃x    ┃\n┗━━━━━┛"
    check renderPanel(initPanel("x", width = 7, padding = padding,
      theme = doublePanelTheme)) == "╔═════╗\n║x    ║\n╚═════╝"
    check renderPanel(initPanel("x", width = 7, padding = padding,
      theme = asciiPanelTheme)) == "+-----+\n|x    |\n+-----+"
    check renderPanel(initPanel("x", width = 7, padding = padding,
      theme = borderlessPanelTheme)) == "x      "

  test "places titles and footers independently on border runs":
    let padding = uniformPanelPadding(0)
    check renderPanel(initPanel("x", width = 14, title = some("Title"),
      footer = some("Foot"), padding = padding,
      titleAlignment = alignLeft, footerAlignment = alignRight)) ==
      "┌ Title ─────┐\n" &
      "│x           │\n" &
      "└────── Foot ┘"

    check renderPanel(initPanel("x", width = 14, title = some("Title"),
      padding = padding, titleAlignment = alignCenter)) ==
      "┌── Title ───┐\n│x           │\n└────────────┘"
    check renderPanel(initPanel("x", width = 14, title = some("Title"),
      padding = padding, titleAlignment = alignRight)) ==
      "┌───── Title ┐\n│x           │\n└────────────┘"

  test "uses deterministic card-oriented defaults":
    let value = card("x", title = "Card", footer = "v1", width = 10)
    check value.theme == roundedPanelTheme
    check value.padding == defaultCardPadding
    check $value ==
      "╭ Card ──╮\n" &
      "│        │\n" &
      "│ x      │\n" &
      "│        │\n" &
      "╰ v1 ────╯"

  test "renders each body alignment at a uniform outer width":
    let padding = uniformPanelPadding(0)
    check renderPanel(initPanel("x", width = 12, padding = padding,
      contentAlignment = alignLeft)).splitLines[1] == "│x         │"
    check renderPanel(initPanel("x", width = 12, padding = padding,
      contentAlignment = alignCenter)).splitLines[1] == "│    x     │"
    check renderPanel(initPanel("x", width = 12, padding = padding,
      contentAlignment = alignRight)).splitLines[1] == "│         x│"

  test "keeps asymmetric and blank padding rows deterministic":
    let rendered = renderPanel(initPanel("x", width = 10,
      padding = initPanelPadding(top = 1, right = 1, bottom = 2, left = 2)))
    check rendered ==
      "┌────────┐\n" &
      "│        │\n" &
      "│  x     │\n" &
      "│        │\n" &
      "│        │\n" &
      "└────────┘"
    check rendered.splitLines.mapIt(displayWidth(it)) == @[10, 10, 10, 10, 10, 10]

  test "renders empty and multiline bodies including trailing lines":
    let padding = uniformPanelPadding(0)
    check renderPanel(initPanel("", width = 6, padding = padding)) ==
      "┌────┐\n│    │\n└────┘"
    check renderPanel(initPanel(fixtureMultiline, width = 9,
      padding = padding)) ==
      "┌───────┐\n│first  │\n│       │\n│third  │\n└───────┘"
    check renderPanel(initPanel("first\n", width = 9,
      padding = padding)) ==
      "┌───────┐\n│first  │\n│       │\n└───────┘"

  test "wraps and truncates body content by terminal cells":
    check renderPanel(initPanel("alpha beta gamma", width = 12)) ==
      "┌──────────┐\n" &
      "│ alpha    │\n" &
      "│ beta     │\n" &
      "│ gamma    │\n" &
      "└──────────┘"
    check renderPanel(initPanel("alphabet soup\nsecond course", width = 12,
      overflow = overflowTruncate)) ==
      "┌──────────┐\n" &
      "│ alphabe… │\n" &
      "│ second … │\n" &
      "└──────────┘"

  test "composes a rendered nested panel as an ordinary multiline body":
    let
      inner = renderPanel(initPanel("inside", width = 10,
        padding = uniformPanelPadding(0), theme = asciiPanelTheme))
      outer = renderPanel(initPanel(inner, width = 14))
    check outer ==
      "┌────────────┐\n" &
      "│ +--------+ │\n" &
      "│ |inside  | │\n" &
      "│ +--------+ │\n" &
      "└────────────┘"

suite "panel Unicode width and ANSI behavior":
  test "measures CJK, combining marks, and emoji by visible cells":
    let value = fixtureCjk & fixtureCjk & fixtureCombining & fixtureEmoji
    let rendered = renderPanel(initPanel(value, width = 9,
      padding = uniformPanelPadding(0)))
    check rendered == "┌───────┐\n│界界é👨‍👩‍👧‍👦│\n└───────┘"
    check rendered.splitLines.mapIt(displayWidth(it)) == @[9, 9, 9]

  test "preserves styled multiline input and isolates panel styles":
    let panel = initPanel(red("alpha\nbeta"), width = 10,
      title = some("Status"),
      bodyStyle = initTerminalStyle(attributes = {taBold}),
      titleStyle = initTerminalStyle(foreground = colorGreen),
      borderStyle = initTerminalStyle(foreground = colorCyan))
    let rendered = renderPanel(panel)
    check stripAnsi(rendered) ==
      "┌ Status ┐\n│ alpha  │\n│ beta   │\n└────────┘"
    check rendered.contains(termCyan)
    check rendered.contains(termGreen)
    check rendered.contains(termRed)
    for line in rendered.splitLines:
      check line.endsWith(termClear)

  test "plain output strips input ANSI and suppresses every panel style":
    let rendered = renderPanel(initPanel(fixtureAnsi, width = 10,
      title = some(green("Title")), footer = some(yellow("Foot")),
      bodyStyle = initTerminalStyle(attributes = {taBold}),
      titleStyle = initTerminalStyle(foreground = colorGreen),
      footerStyle = initTerminalStyle(foreground = colorYellow),
      borderStyle = initTerminalStyle(foreground = colorCyan),
      useColor = false))
    check rendered ==
      "┌ Title ─┐\n│ red    │\n└ Foot ──┘"
    check '\e' notin rendered

  test "truncates title collisions without splitting styled graphemes":
    let rendered = renderPanel(initPanel(red("x"), width = 5,
      title = some(red(fixtureCjk & fixtureEmoji)),
      padding = uniformPanelPadding(0)))
    check stripAnsi(rendered) == "┌ … ┐\n│x  │\n└───┘"
    check rendered.splitLines.mapIt(displayWidth(it)) == @[5, 5, 5]

suite "panel rendering contract":
  test "uses complete outer widths, CRLF, and no trailing line ending":
    let rendered = renderPanel(initPanel("body", width = 10,
      lineEnding = "\r\n"))
    check rendered == "┌────────┐\r\n│ body   │\r\n└────────┘"
    check not rendered.endsWith("\r\n")
    check rendered.split("\r\n").mapIt(displayWidth(it)) == @[10, 10, 10]

  test "rejects invalid geometry, labels, glyphs, and line endings early":
    for invalid in [
        PanelPadding(top: -1), PanelPadding(right: -1),
        PanelPadding(bottom: -1), PanelPadding(left: -1)]:
      expect ValueError:
        invalid.validatePanelPadding()
    expect ValueError:
      discard uniformPanelPadding(-1)
    expect ValueError:
      discard initPanel("x", width = 4)
    expect ValueError:
      discard initPanel("x", width = 2, theme = borderlessPanelTheme)
    expect ValueError:
      discard initPanel("x", title = some("bad\ntitle"))
    expect ValueError:
      discard initPanel("x", footer = some("bad\rfooter"))
    expect ValueError:
      discard initPanel("x", lineEnding = "\r")
    expect ValueError:
      discard customPanelTheme("界", "2", "3", "4", "-", "|")
    expect ValueError:
      discard renderPanel(initPanel(fixtureCjk, width = 3,
        padding = uniformPanelPadding(0), wrapMode = wrapCharacters))

    var invalid = initPanel("x")
    invalid.width = LayoutWidth(0)
    expect ValueError:
      discard renderPanel(invalid)
