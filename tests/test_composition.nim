import std/[options, random, sequtils, strutils, unittest]

import terminal_layout
import fixtures

proc widths(value: string): seq[int] =
  ## Measures logical output rows without assuming UTF-8 byte widths.
  splitLayoutLines(value).mapIt(displayWidth(it))

proc checkAtMost(value: string; maximum: int) =
  for lineWidth in value.widths:
    check lineWidth <= maximum

suite "component composition snapshots":
  test "places a nested list inside a panel":
    let
      navigation = @[
        listItem("Home"),
        listItem("Account",
          listItem("Profile"),
          listItem(fixtureCjk & " locale"))
          .withChildKind(listBullets)
      ]
      body = numberedList(navigation,
        initListOptions(useColor = false).withWidth(18))
      rendered = initPanel(body, width = 22,
        title = some("Navigation"), useColor = false).render()

    check rendered ==
      "┌ Navigation ────────┐\n" &
      "│ 1. Home            │\n" &
      "│ 2. Account         │\n" &
      "│   • Profile        │\n" &
      "│   • 界 locale      │\n" &
      "└────────────────────┘"
    check rendered.widths == @[22, 22, 22, 22, 22, 22]

  test "places a Unicode tree inside a card":
    let
      model = tree("workspace",
        tree("src", tree(fixtureCjk & ".nim")),
        tree("tests", tree(fixtureEmoji)))
      treeBody = model.render(initTreeOptions(useColor = false))
      rendered = initCard(treeBody, title = some("Project"), width = 24,
        useColor = false).render()

    check rendered ==
      "╭ Project ─────────────╮\n" &
      "│                      │\n" &
      "│ workspace            │\n" &
      "│ ├─ src               │\n" &
      "│ │  └─ 界.nim         │\n" &
      "│ └─ tests             │\n" &
      "│    └─ 👨‍👩‍👧‍👦             │\n" &
      "│                      │\n" &
      "╰──────────────────────╯"
    check rendered.widths == repeat(24, 9)

  test "places a semantic task list inside a plain callout":
    let
      tasks = @[
        listItem(green("Compile")).withTaskState(taskChecked),
        listItem(fixtureCjk & " tests").withTaskState(taskIndeterminate)
      ]
      body = taskList(tasks,
        initListOptions(useColor = false).withWidth(20))
      rendered = success(body, title = "CI", width = 24,
        useColor = false).render()

    check rendered ==
      "┌ [OK] CI ─────────────┐\n" &
      "│ ☑ Compile            │\n" &
      "│ ◐ 界 tests           │\n" &
      "└──────────────────────┘"
    check '\e' notin rendered
    check rendered.widths == @[24, 24, 24, 24]

  test "uses banners to separate composed sections":
    let rendered = [
      banner("Structure", width = 20).render(),
      initPanel("body", width = 20, useColor = false).render(),
      banner("Checks", width = 20).render()
    ].join("\n")

    check rendered ==
      "──── Structure ─────\n" &
      "┌──────────────────┐\n" &
      "│ body             │\n" &
      "└──────────────────┘\n" &
      "────── Checks ──────"
    check rendered.widths == repeat(20, 5)

suite "nested ANSI and plain rendering":
  test "contains styles at component boundaries without leaking state":
    let
      items = @[listItem(red("failed")), listItem(green("recovered"))]
      styledList = bulletList(items,
        theme = initListTheme(unicodeLayoutGlyphs.list,
          markerStyle = initTerminalStyle(foreground = colorCyan)))
      rendered = initPanel(styledList, width = 20,
        borderStyle = initTerminalStyle(foreground = colorYellow)).render()

    check stripAnsi(rendered) ==
      "┌──────────────────┐\n" &
      "│ • failed         │\n" &
      "│ • recovered      │\n" &
      "└──────────────────┘"
    check termRed in rendered
    check termGreen in rendered
    check termCyan in rendered
    check termYellow in rendered
    for line in rendered.splitLines:
      check line.endsWith(termClear)

  test "outer plain mode strips ANSI from already-rendered children":
    let
      styledTree = tree(red("root"), tree(green(fixtureCjk))).render()
      styledList = bulletList(red("one"), green(fixtureEmoji))
      content = styledTree & "\n" & styledList
      rendered = initPanel(content, width = 18, useColor = false).render()

    check '\e' notin rendered
    check stripAnsi(rendered) == rendered
    check "root" in rendered
    check fixtureCjk in rendered
    check fixtureEmoji in rendered
    check rendered.widths == repeat(18, 6)

suite "deterministic constrained-width properties":
  test "never exceeds requested terminal-cell widths":
    var rng = initRand(0x5EED)
    let samples = [
      "alpha beta", fixtureCjk & " data", fixtureCombining & "cho",
      fixtureEmoji & " family", red("styled value"), "first\nsecond"
    ]

    for _ in 0 ..< 64:
      let
        sample = samples[rng.rand(samples.high)]
        panelWidth = rng.rand(8 .. 36)
        bannerWidth = rng.rand(5 .. 36)
        listWidth = rng.rand(8 .. 36)
        treeWidth = rng.rand(8 .. 36)
        calloutWidth = rng.rand(12 .. 36)

        panelOutput = initPanel(sample, width = panelWidth,
          padding = uniformPanelPadding(0), overflow = overflowTruncate)
          .render()
        bannerOutput = initBanner(sample, width = bannerWidth,
          padding = uniformPanelPadding(0)).render()
        listOutput = renderList([listItem(sample)],
          initListOptions(overflow = overflowTruncate).withWidth(listWidth))
        treeOutput = tree(sample).render(
          initTreeOptions(overflow = overflowTruncate).withWidth(treeWidth))
        calloutOutput = info(sample, width = calloutWidth,
          padding = uniformPanelPadding(0)).withOverflow(overflowTruncate)
          .render()

      check panelOutput.widths == repeat(panelWidth, panelOutput.widths.len)
      check bannerOutput.widths == repeat(bannerWidth, bannerOutput.widths.len)
      listOutput.checkAtMost(listWidth)
      treeOutput.checkAtMost(treeWidth)
      check calloutOutput.widths ==
        repeat(calloutWidth, calloutOutput.widths.len)

      check panelOutput == initPanel(sample, width = panelWidth,
        padding = uniformPanelPadding(0), overflow = overflowTruncate)
        .render()
      check bannerOutput == initBanner(sample, width = bannerWidth,
        padding = uniformPanelPadding(0)).render()
      check listOutput == renderList([listItem(sample)],
        initListOptions(overflow = overflowTruncate).withWidth(listWidth))
      check treeOutput == tree(sample).render(
        initTreeOptions(overflow = overflowTruncate).withWidth(treeWidth))
      check calloutOutput == info(sample, width = calloutWidth,
        padding = uniformPanelPadding(0)).withOverflow(overflowTruncate)
        .render()
