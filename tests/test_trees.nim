import std/[options, sequtils, strutils, unittest]

import terminal_layout
import fixtures

suite "tree models and builders":
  test "supports concise literals and incremental ordered construction":
    let literal = tree("root", tree("first"), tree("second", tree("leaf")))
    check literal.label == "root"
    check literal.children.mapIt(it.label) == @["first", "second"]
    check literal.children[1].children[0].label == "leaf"

    var incremental = initTreeNode("root")
    incremental.add "first"
    incremental.addChild tree("second", tree("leaf"))
    check renderTree(incremental) == renderTree(literal)

  test "copies child collections and supports immutable style overrides":
    var children = @[tree("first")]
    let
      labelStyle = initTerminalStyle(foreground = colorRed)
      connectorStyle = initTerminalStyle(foreground = colorGreen)
      root = initTreeNode("root", children)
        .withStyle(labelStyle)
        .withConnectorStyle(connectorStyle)
    children.add tree("later")
    check root.children.len == 1
    check root.style.isSome
    check root.connectorStyle.isSome
    check ansiCode(root.style.get) == ansiCode(labelStyle)
    check ansiCode(root.connectorStyle.get) == ansiCode(connectorStyle)

suite "tree snapshots":
  test "renders single, deep, wide, and empty-label trees":
    check renderTree(tree("root")) == "root"
    check $tree("root") == "root"

    let hierarchy = tree("root",
      tree("alpha", tree("one"), tree("two", tree("leaf"))),
      tree("omega"))
    check hierarchy.render() ==
      "root\n" &
      "├─ alpha\n" &
      "│  ├─ one\n" &
      "│  └─ two\n" &
      "│     └─ leaf\n" &
      "└─ omega"

    check renderTree(tree("root", tree("one"), tree("two"), tree("three"))) ==
      "root\n├─ one\n├─ two\n└─ three"
    check renderTree(tree("")) == ""
    check renderTree(tree("root", tree(""))) == "root\n└─ "

  test "renders forests and hidden roots in stable caller order":
    let forest = [tree("alpha", tree("leaf")), tree("omega")]
    check renderTree(forest) ==
      "├─ alpha\n" &
      "│  └─ leaf\n" &
      "└─ omega"

    let hidden = initTreeOptions(showRoot = false)
    check renderTree(tree("hidden", forest), hidden) == renderTree(forest)
    check renderTree(newSeq[TreeNode]()) == ""
    check renderTree(tree("leaf"), hidden) == ""

  test "renders Unicode, ASCII, rounded, and custom themes":
    let value = tree("root", tree("first"), tree("last"))
    check renderTree(value, theme = unicodeTreeTheme) ==
      "root\n├─ first\n└─ last"
    check renderTree(value, theme = asciiTreeTheme) ==
      "root\n+- first\n`- last"
    check renderTree(value, theme = roundedTreeTheme) ==
      "root\n├─ first\n╰─ last"

    let custom = customTreeTheme("T", "L", "V", "H")
    check renderTree(value, theme = custom) ==
      "root\nTH first\nLH last"

  test "aligns explicit and wrapped continuation lines under labels":
    let multiline = tree("root",
      tree("alpha", tree("first\r\nsecond")),
      tree("omega"))
    check renderTree(multiline) ==
      "root\n" &
      "├─ alpha\n" &
      "│  └─ first\n" &
      "│     second\n" &
      "└─ omega"

    let wrapped = tree("root", tree("alpha beta gamma"))
    let options = initTreeOptions().withWidth(10)
    check renderTree(wrapped, options) ==
      "root\n└─ alpha\n   beta\n   gamma"

  test "truncates each explicit label line by terminal cells":
    let value = tree("root", tree("alphabet soup\r\nsecond course"))
    let options = initTreeOptions(overflow = overflowTruncate).withWidth(10)
    check renderTree(value, options) ==
      "root\n└─ alphab…\n   second…"

  test "visibly marks every pruned branch":
    let value = tree("root",
      tree("first", tree("hidden")),
      tree("second", tree("also hidden")))
    check renderTree(value, initTreeOptions().withMaxDepth(0)) ==
      "root\n└─ …"
    check renderTree(value, initTreeOptions(pruneMarker = "more")
        .withMaxDepth(1)) ==
      "root\n" &
      "├─ first\n" &
      "│  └─ more\n" &
      "└─ second\n" &
      "   └─ more"

suite "Unicode width and ANSI behavior":
  test "measures CJK, combining marks, and emoji at exact outer widths":
    let value = tree("root",
      tree(fixtureCjk & fixtureCjk),
      tree(fixtureCombining & fixtureEmoji))
    let rendered = renderTree(value, initTreeOptions().withWidth(7))
    check rendered == "root\n├─ 界界\n└─ é👨‍👩‍👧‍👦"
    check rendered.splitLines.mapIt(displayWidth(it)) == @[4, 7, 6]

  test "preserves ANSI across wraps and isolates connector and label styles":
    let
      connectorStyle = initTerminalStyle(foreground = colorCyan)
      labelStyle = initTerminalStyle(attributes = {taBold})
      pruningStyle = initTerminalStyle(foreground = colorYellow)
      theme = initTreeTheme(unicodeLayoutGlyphs.tree,
        connectorStyle, labelStyle, pruningStyle)
      child = tree(red("alpha beta"))
        .withStyle(initTerminalStyle(foreground = colorGreen))
      value = tree("root", child)
      rendered = renderTree(value, initTreeOptions().withWidth(10), theme)
      lines = rendered.splitLines

    check lines.len == 3
    check lines[0] == termBold & "root" & termClear
    check lines[1].startsWith(termCyan & "└─ " & termClear & termGreen)
    check lines[1].endsWith(termClear)
    check lines[2].startsWith("   " & termGreen)
    check lines[2].endsWith(termClear)
    check stripAnsi(rendered) == "root\n└─ alpha\n   beta"
    for line in lines:
      check line.count(termClear) >= 1

  test "honors node connector overrides without style leakage":
    let
      theme = initTreeTheme(unicodeLayoutGlyphs.tree,
        connectorStyle = initTerminalStyle(foreground = colorCyan),
        labelStyle = initTerminalStyle(attributes = {taBold}))
      child = tree("child")
        .withStyle(initTerminalStyle(foreground = colorRed))
        .withConnectorStyle(initTerminalStyle(foreground = colorGreen))
      rendered = renderTree(tree("root", child), theme = theme)
    check rendered ==
      termBold & "root" & termClear & "\n" &
      termGreen & "└─ " & termClear & termRed & "child" & termClear

  test "plain rendering strips input ANSI and suppresses all theme styles":
    let theme = initTreeTheme(unicodeLayoutGlyphs.tree,
      connectorStyle = initTerminalStyle(foreground = colorCyan),
      labelStyle = initTerminalStyle(attributes = {taBold}))
    let options = initTreeOptions(useColor = false)
    let rendered = renderTree(tree(red("root"), tree(green("child"))),
      options, theme)
    check rendered == "root\n└─ child"
    check '\e' notin rendered

suite "tree rendering contract":
  test "uses validated CRLF output without a trailing line ending":
    let options = initTreeOptions(lineEnding = "\r\n")
    let rendered = renderTree(tree("root", tree("child")), options)
    check rendered == "root\r\n└─ child"
    check not rendered.endsWith("\r\n")

  test "validates options, themes, and unrepresentable widths":
    var options = defaultTreeOptions
    options.indentation = 0
    expect ValueError:
      discard renderTree(tree("root"), options)

    options = defaultTreeOptions
    options.width = some(LayoutWidth(0))
    expect ValueError:
      discard renderTree(tree("root"), options)

    expect ValueError:
      discard initTreeOptions(maxDepth = some(-1))
    expect ValueError:
      discard initTreeOptions(pruneMarker = "")
    expect ValueError:
      discard initTreeOptions(pruneMarker = "bad\nmarker")
    expect ValueError:
      discard initTreeOptions(lineEnding = "\r")
    expect ValueError:
      discard customTreeTheme("界", "L", "V", "H")
    expect ValueError:
      discard renderTree(tree(fixtureCjk),
        initTreeOptions(wrapMode = wrapCharacters).withWidth(1))

  test "keeps arbitrary domain labels unchanged":
    let value = tree("project/src/main.nim",
      tree("user.name: Ada"),
      tree("terminal_layout -> terminal_style"))
    check stripAnsi(renderTree(value)) ==
      "project/src/main.nim\n" &
      "├─ user.name: Ada\n" &
      "└─ terminal_layout -> terminal_style"
