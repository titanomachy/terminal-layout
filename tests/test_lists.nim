import std/[options, sequtils, strutils, unittest]

import terminal_layout
import fixtures

suite "list models, themes, and builders":
  test "supports concise literals and incremental ordered construction":
    let literal = listItem("root", listItem("first"),
      listItem("second", listItem("leaf")))
    check literal.text == "root"
    check literal.children.mapIt(it.text) == @["first", "second"]
    check literal.children[1].children[0].text == "leaf"

    var incremental = initListItem("root")
    incremental.add "first"
    incremental.addChild listItem("second", listItem("leaf"))
    check bulletList(incremental.children) == bulletList(literal.children)

  test "copies children and supports immutable item configuration":
    var children = @[listItem("first")]
    let item = initListItem("root", children)
      .withStyle(initTerminalStyle(foreground = colorRed))
      .withTaskState(taskChecked)
      .withChildKind(listNumbers)
    children.add listItem("later")
    check item.children.len == 1
    check item.style.isSome
    check item.taskState == some(taskChecked)
    check item.childKind == some(listNumbers)

  test "constructs validated themes and fluent options":
    let theme = customListTheme("+", "[", "X", "~")
    check bulletList([listItem("item")], theme = theme) == "+ item"

    let options = initListOptions()
      .withKind(listNumbers)
      .withStartingNumber(3)
      .withDelimiter(")")
      .withIndentation(4)
      .withWidth(20)
      .withOverflow(overflowTruncate)
      .withColor(false)
      .withLineEnding("\r\n")
    check options.kind == listNumbers
    check options.startingNumber == 3
    check options.delimiter == ")"
    check options.indentation == 4
    check options.width.get.cellCount == 20
    check options.overflow == overflowTruncate
    check not options.useColor
    check options.lineEnding == "\r\n"

suite "list snapshots":
  test "renders bullet, numbered, and concise string lists":
    let items = [listItem("alpha"), listItem("beta")]
    check renderList(items) == "• alpha\n• beta"
    check bulletList(items) == "• alpha\n• beta"
    check numberedList(items) == "1. alpha\n2. beta"
    check bulletList("alpha", "beta") == "• alpha\n• beta"
    check numberedList("alpha", "beta") == "1. alpha\n2. beta"
    check taskList("alpha", "beta") == "☐ alpha\n☐ beta"

  test "right-aligns multi-digit markers to one sibling text column":
    let items = [listItem("nine"), listItem("ten"), listItem("eleven")]
    let options = initListOptions(startingNumber = 9, delimiter = ")")
    check numberedList(items, options) ==
      " 9) nine\n" &
      "10) ten\n" &
      "11) eleven"

  test "renders every semantic task state in ordinary text":
    let items = [
      listItem("queued").withTaskState(taskUnchecked),
      listItem("done").withTaskState(taskChecked),
      listItem("partial").withTaskState(taskIndeterminate),
      listItem("implicit")
    ]
    check taskList(items) ==
      "☐ queued\n" &
      "☑ done\n" &
      "◐ partial\n" &
      "☐ implicit"

  test "supports mixed kinds at nested levels in stable order":
    let items = [
      listItem("Project",
        listItem("Install"),
        listItem("Verify",
          listItem("Linux").withTaskState(taskUnchecked),
          listItem("macOS").withTaskState(taskChecked)
        ).withChildKind(listTasks)
      ).withChildKind(listNumbers),
      listItem("Release")
    ]
    check bulletList(items) ==
      "• Project\n" &
      "  1. Install\n" &
      "  2. Verify\n" &
      "    ☐ Linux\n" &
      "    ☑ macOS\n" &
      "• Release"

  test "uses hanging indentation for explicit and wrapped lines":
    let items = [listItem("first\r\nsecond"),
      listItem("alpha beta gamma")]
    let options = initListOptions().withWidth(12)
    check bulletList(items, options) ==
      "• first\n" &
      "  second\n" &
      "• alpha\n" &
      "  beta gamma"

  test "truncates each explicit item line by terminal cells":
    let items = [listItem("alphabet soup\nsecond course")]
    let options = initListOptions(overflow = overflowTruncate).withWidth(10)
    check bulletList(items, options) == "• alphabe…\n  second …"

  test "renders custom and ASCII markers":
    let items = [
      listItem("open").withTaskState(taskUnchecked),
      listItem("done").withTaskState(taskChecked),
      listItem("partial").withTaskState(taskIndeterminate)
    ]
    check bulletList([listItem("item")], theme = asciiListTheme) == "* item"
    check taskList(items, theme = asciiListTheme) ==
      "o open\nx done\n- partial"

  test "handles empty collections, empty items, and blank logical lines":
    check renderList(newSeq[ListItem]()) == ""
    check bulletList([listItem(fixtureEmpty)]) == "•"
    check bulletList([listItem(fixtureMultiline)]) ==
      "• first\n\n  third"
    for line in bulletList([listItem(fixtureMultiline)]).splitLines:
      check not line.endsWith(" ")

suite "list Unicode width and ANSI behavior":
  test "measures CJK, combining marks, and emoji by visible cells":
    let items = [listItem(fixtureCjk & fixtureCjk),
      listItem(fixtureCombining & fixtureEmoji)]
    let rendered = bulletList(items,
      initListOptions(wrapMode = wrapCharacters).withWidth(6))
    check rendered == "• 界界\n• é👨‍👩‍👧‍👦"
    check rendered.splitLines.mapIt(displayWidth(it)) == @[6, 5]

  test "isolates marker, body, and per-item styles across wrapping":
    let theme = initListTheme(unicodeLayoutGlyphs.list,
      markerStyle = initTerminalStyle(foreground = colorCyan),
      bodyStyle = initTerminalStyle(attributes = {taBold}))
    let items = [listItem(red("alpha beta")).withStyle(
      initTerminalStyle(foreground = colorGreen))]
    let rendered = bulletList(items, initListOptions().withWidth(8), theme)
    let lines = rendered.splitLines
    check stripAnsi(rendered) == "• alpha\n  beta"
    check lines[0].startsWith(termCyan & "•" & termClear & " " & termGreen)
    check lines[0].endsWith(termClear)
    check lines[1].startsWith("  " & termGreen)
    check lines[1].endsWith(termClear)

  test "plain rendering preserves task semantics and strips all ANSI":
    let theme = initListTheme(unicodeLayoutGlyphs.list,
      markerStyle = initTerminalStyle(foreground = colorCyan),
      bodyStyle = initTerminalStyle(attributes = {taBold}))
    let items = [
      listItem(red("open")).withTaskState(taskUnchecked),
      listItem(green("done")).withTaskState(taskChecked),
      listItem(yellow("partial")).withTaskState(taskIndeterminate)
    ]
    let rendered = taskList(items, initListOptions(useColor = false), theme)
    check rendered == "☐ open\n☑ done\n◐ partial"
    check '\e' notin rendered

suite "list rendering and indentation contract":
  test "uses maximum outer widths, CRLF, and no trailing line ending":
    let items = [listItem("alpha beta"), listItem("gamma")]
    let rendered = numberedList(items,
      initListOptions(lineEnding = "\r\n").withWidth(8))
    check rendered == "1. alpha\r\n   beta\r\n2. gamma"
    check not rendered.endsWith("\r\n")
    for line in rendered.split("\r\n"):
      check displayWidth(line) <= 8

  test "does not mutate caller-owned items":
    var items = @[listItem("root", listItem("child"))]
    let before = items
    discard numberedList(items, initListOptions().withWidth(12))
    check items == before

  test "indents arbitrary ANSI and CRLF content safely":
    let styled = termRed & "first\r\nsecond" & termClear
    let rendered = indent(styled, 2, lineEnding = "\r\n")
    check stripAnsi(rendered) == "  first\r\n  second"
    check rendered.split("\r\n").allIt(it.endsWith(termClear))
    check indent(fixtureAnsi, 1, useColor = false) == " red"
    check indent("", 2) == "  "
    check not indent("value", 2).endsWith("\n")

  test "rejects invalid options, markers, indentation, and narrow widths":
    expect ValueError:
      discard initListOptions(startingNumber = 0)
    expect ValueError:
      discard initListOptions(delimiter = "")
    expect ValueError:
      discard initListOptions(delimiter = "bad\nvalue")
    expect ValueError:
      discard initListOptions(delimiter = termRed & "." & termClear)
    expect ValueError:
      discard initListOptions(indentation = -1)
    expect ValueError:
      discard initListOptions(lineEnding = "\r")
    expect ValueError:
      discard customListTheme("界", "o", "x", "-")
    expect ValueError:
      discard indent("value", -1)
    expect ValueError:
      discard indent("value", 1, lineEnding = "\r")
    expect ValueError:
      discard bulletList([listItem(fixtureCjk)],
        initListOptions(wrapMode = wrapCharacters).withWidth(3))
    expect ValueError:
      discard numberedList([listItem("")], initListOptions().withWidth(1))
    expect ValueError:
      discard bulletList([listItem("", listItem(""))],
        initListOptions().withWidth(2))

    var invalid = defaultListOptions
    invalid.width = some(LayoutWidth(0))
    expect ValueError:
      discard renderList([listItem("value")], invalid)

    var invalidTheme = unicodeListTheme
    invalidTheme.glyphs.checked = "\e[31mx\e[0m"
    expect ValueError:
      discard taskList([listItem("value")], theme = invalidTheme)
