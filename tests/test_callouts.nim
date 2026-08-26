import std/[options, sequtils, strutils, unittest]

import terminal_layout
import fixtures

proc styledBoxSnapshot(theme: CalloutTheme; icon: string): string =
  let glyphs = theme.panelTheme.glyphs
  result = applyStyle(glyphs.topLeft & " ", theme.borderStyle) &
    applyStyle(icon, theme.markerStyle) &
    applyStyle(" " & repeat(glyphs.horizontal, 9) & glyphs.topRight,
      theme.borderStyle) & "\n" &
    applyStyle(glyphs.vertical, theme.borderStyle) & " message    " &
    applyStyle(glyphs.vertical, theme.borderStyle) & "\n" &
    applyStyle(glyphs.bottomLeft & repeat(glyphs.horizontal, 12) &
      glyphs.bottomRight, theme.borderStyle)

suite "callout models, themes, and builders":
  test "selects semantic themes and supports immutable configuration":
    let original = info("body", width = 18)
    let configured = original
      .withTitle("Network")
      .withWidth(20)
      .withPadding(uniformPanelPadding(0))
      .withPresentation(calloutCompact)
      .withOverflow(overflowTruncate)
      .withColor(false)
      .withLineEnding("\r\n")
    check original.title.isNone
    check original.width.cellCount == 18
    check configured.kind == calloutInfo
    check configured.title == some("Network")
    check configured.width.cellCount == 20
    check configured.padding == uniformPanelPadding(0)
    check configured.presentation == calloutCompact
    check configured.overflow == overflowTruncate
    check not configured.useColor
    check configured.lineEnding == "\r\n"
    check themeFor(calloutWarning) == warningCalloutTheme

  test "constructs explicit custom themes and custom callouts":
    let theme = customCalloutTheme("NOTE", "[NOTE]",
      panelTheme = asciiPanelTheme,
      markerStyle = initTerminalStyle(foreground = colorMagenta),
      borderStyle = initTerminalStyle(foreground = colorMagenta))
    let value = initCallout("Remember this", calloutCustom, width = 20,
      theme = some(theme), useColor = false)
    check renderCallout(value) ==
      "+ [NOTE] ----------+\n" &
      "| Remember this    |\n" &
      "+------------------+"

suite "callout snapshots":
  test "renders every built-in kind boxed in styled and plain modes":
    let styled = [
      info("message", width = 14),
      warning("message", width = 14),
      failure("message", width = 14),
      success("message", width = 14)
    ]
    let styledSnapshots = [
      "┌ ℹ ─────────┐\n│ message    │\n└────────────┘",
      "┌ ⚠ ─────────┐\n│ message    │\n└────────────┘",
      "┏ × ━━━━━━━━━┓\n┃ message    ┃\n┗━━━━━━━━━━━━┛",
      "┌ ✓ ─────────┐\n│ message    │\n└────────────┘"
    ]
    let
      styledThemes = [infoCalloutTheme, warningCalloutTheme,
        failureCalloutTheme, successCalloutTheme]
      styledIcons = ["ℹ", "⚠", "×", "✓"]
    for index, value in styled:
      let rendered = renderCallout(value)
      check rendered == styledBoxSnapshot(styledThemes[index],
        styledIcons[index])
      check stripAnsi(rendered) == styledSnapshots[index]
      check '\e' in rendered

    let plain = [
      info("message", width = 14, useColor = false),
      warning("message", width = 14, useColor = false),
      failure("message", width = 14, useColor = false),
      success("message", width = 14, useColor = false)
    ]
    let plainSnapshots = [
      "┌ [INFO] ────┐\n│ message    │\n└────────────┘",
      "┌ [WARN] ────┐\n│ message    │\n└────────────┘",
      "┏ [FAIL] ━━━━┓\n┃ message    ┃\n┗━━━━━━━━━━━━┛",
      "┌ [OK] ──────┐\n│ message    │\n└────────────┘"
    ]
    for index, value in plain:
      let rendered = renderCallout(value)
      check rendered == plainSnapshots[index]
      check '\e' notin rendered

  test "renders every built-in kind compact in styled and plain modes":
    let styled = [
      info("message", width = 14, presentation = calloutCompact),
      warning("message", width = 14, presentation = calloutCompact),
      failure("message", width = 14, presentation = calloutCompact),
      success("message", width = 14, presentation = calloutCompact)
    ]
    let
      styledThemes = [infoCalloutTheme, warningCalloutTheme,
        failureCalloutTheme, successCalloutTheme]
      styledIcons = ["ℹ", "⚠", "×", "✓"]
    for index, value in styled:
      let rendered = renderCallout(value)
      check rendered == " " & applyStyle(styledIcons[index],
        styledThemes[index].markerStyle) & " message    "
      check stripAnsi(rendered) == [
        " ℹ message    ", " ⚠ message    ",
        " × message    ", " ✓ message    "][index]
      check displayWidth(rendered) == 14
      check '\e' in rendered

    let plain = [
      info("message", width = 14, presentation = calloutCompact,
        useColor = false),
      warning("message", width = 14, presentation = calloutCompact,
        useColor = false),
      failure("message", width = 14, presentation = calloutCompact,
        useColor = false),
      success("message", width = 14, presentation = calloutCompact,
        useColor = false)
    ]
    for index, value in plain:
      check renderCallout(value) == [
        " [INFO]       \n message      ",
        " [WARN]       \n message      ",
        " [FAIL]       \n message      ",
        " [OK] message "][index]

  test "adds contextual titles without replacing plain semantics":
    check renderCallout(warning("Disk", title = "Storage", width = 18,
        useColor = false)) ==
      "┌ [WARN] Storage ┐\n" &
      "│ Disk           │\n" &
      "└────────────────┘"
    check stripAnsi(renderCallout(warning("Disk", title = "Storage",
        width = 18))) ==
      "┌ ⚠ Storage ─────┐\n" &
      "│ Disk           │\n" &
      "└────────────────┘"

  test "uses a visible label when a custom icon is omitted":
    let theme = customCalloutTheme("NOTICE", "[NOTICE]",
      panelTheme = asciiPanelTheme)
    let styled = initCallout("body", calloutCustom, width = 16,
      theme = some(theme))
    check renderCallout(styled) ==
      "+ NOTICE ------+\n| body         |\n+--------------+"

  test "renders multiline and nested component bodies through panels":
    let nested = taskList([
      listItem("tests").withTaskState(taskChecked),
      listItem("release").withTaskState(taskUnchecked)
    ], initListOptions(useColor = false))
    let rendered = renderCallout(success(nested, width = 18,
      useColor = false))
    check rendered ==
      "┌ [OK] ──────────┐\n" &
      "│ ☑ tests        │\n" &
      "│ ☐ release      │\n" &
      "└────────────────┘"
    check rendered.splitLines.mapIt(displayWidth(it)) == @[18, 18, 18, 18]

  test "keeps empty bodies deterministic":
    check renderCallout(info("", width = 12, useColor = false)) ==
      "┌ [INFO] ──┐\n│          │\n└──────────┘"
    check renderCallout(info("", width = 12,
        presentation = calloutCompact, useColor = false)) ==
      " [INFO]     "

suite "callout Unicode width and ANSI behavior":
  test "measures CJK, combining marks, and emoji by visible cells":
    let value = fixtureCjk & fixtureCombining & fixtureEmoji
    let rendered = renderCallout(info(value, width = 10,
      padding = uniformPanelPadding(0), useColor = false))
    check rendered == "┌ [INFO] ┐\n│界é👨‍👩‍👧‍👦   │\n└────────┘"
    check rendered.splitLines.mapIt(displayWidth(it)) == @[10, 10, 10]

  test "preserves styled input and keeps semantic resets contained":
    let theme = customCalloutTheme("ALERT", "[ALERT]", icon = some("!"),
      markerStyle = initTerminalStyle(foreground = colorYellow),
      bodyStyle = initTerminalStyle(attributes = {taBold}),
      borderStyle = initTerminalStyle(foreground = colorRed))
    let callout = initCallout(red("alpha\nbeta"), calloutCustom,
      width = 14, theme = some(theme))
    let rendered = renderCallout(callout)
    check stripAnsi(rendered) ==
      "┌ ! ─────────┐\n│ alpha      │\n│ beta       │\n└────────────┘"
    check rendered.contains(termYellow)
    check rendered.contains(termRed)
    for line in rendered.splitLines:
      check line.endsWith(termClear)

  test "plain rendering strips ANSI from title and body":
    let rendered = renderCallout(info(fixtureAnsi,
      title = green("Status"), width = 18, useColor = false))
    check rendered ==
      "┌ [INFO] Status ─┐\n│ red            │\n└────────────────┘"
    check '\e' notin rendered

suite "callout rendering contract":
  test "wraps, truncates, uses CRLF, and adds no trailing line ending":
    check renderCallout(info("alpha beta gamma", width = 12,
        useColor = false)) ==
      "┌ [INFO] ──┐\n│ alpha    │\n│ beta     │\n│ gamma    │\n└──────────┘"
    let rendered = renderCallout(info("alphabet soup\nsecond course",
      width = 12, useColor = false)
      .withOverflow(overflowTruncate)
      .withLineEnding("\r\n"))
    check rendered ==
      "┌ [INFO] ──┐\r\n│ alphabe… │\r\n│ second … │\r\n└──────────┘"
    check not rendered.endsWith("\r\n")

  test "does not mutate caller-owned values":
    var value = warning("body", title = "Context", width = 16)
    let
      beforeBody = value.body
      beforeTitle = value.title
      beforeWidth = value.width.cellCount
      beforeTheme = value.theme
    discard renderCallout(value)
    check value.body == beforeBody
    check value.title == beforeTitle
    check value.width.cellCount == beforeWidth
    check value.theme == beforeTheme

  test "rejects invalid semantic data, glyphs, geometry, and line endings":
    expect ValueError:
      discard initCallout("body", calloutCustom)
    expect ValueError:
      discard customCalloutTheme("", "[X]")
    expect ValueError:
      discard customCalloutTheme("BAD\nLABEL", "[X]")
    expect ValueError:
      discard customCalloutTheme("X", "")
    expect ValueError:
      discard customCalloutTheme("X", termRed & "[X]" & termClear)
    expect ValueError:
      discard customCalloutTheme("X", "[X]", icon = some("界"))
    expect ValueError:
      discard customCalloutTheme("X", "[X]",
        icon = some(termRed & "!" & termClear))
    expect ValueError:
      discard initCallout("body", title = some("bad\ntitle"))
    expect ValueError:
      discard info("body", width = 4)
    expect ValueError:
      discard info("body", width = 9, useColor = false)
    expect ValueError:
      discard info("body", width = 2, presentation = calloutCompact)
    expect ValueError:
      discard initCallout("body", lineEnding = "\r")

    var invalid = info("body")
    invalid.width = LayoutWidth(0)
    expect ValueError:
      discard renderCallout(invalid)

    invalid = info("body")
    invalid.theme.icon = some("界")
    expect ValueError:
      discard renderCallout(invalid)
