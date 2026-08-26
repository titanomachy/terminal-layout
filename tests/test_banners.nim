import std/[options, sequtils, strutils, unittest]

import terminal_layout
import fixtures

suite "banner models, themes, and builders":
  test "constructs themes and immutable banner configurations":
    let original = banner("Build", width = 16)
    let configured = original
      .withSubtitle("main")
      .withWidth(18)
      .withAlignment(alignRight)
      .withFillGlyph("=")
      .withPadding(uniformPanelPadding(0))
      .withBorderMode(bannerBoxed)
      .withColor(false)
      .withLineEnding("\r\n")
    check original.subtitle.isNone
    check original.width.cellCount == 16
    check original.fillGlyph == "─"
    check original.borderMode == bannerRule
    check configured.subtitle == some("main")
    check configured.width.cellCount == 18
    check configured.alignment == alignRight
    check configured.fillGlyph == "="
    check configured.padding == uniformPanelPadding(0)
    check configured.borderMode == bannerBoxed
    check not configured.useColor
    check configured.lineEnding == "\r\n"

  test "constructs and applies a validated custom theme":
    let theme = customBannerTheme("~", roundedPanelTheme, bannerBoxed)
    let value = initBanner("Note", width = 10).withTheme(theme)
    check value.fillGlyph == "~"
    check value.panelTheme == roundedPanelTheme
    check value.borderMode == bannerBoxed
    check renderBanner(value) ==
      "╭────────╮\n" &
      "│  Note  │\n" &
      "╰────────╯"

suite "banner snapshots":
  test "renders one line, subtitles, and multiline text":
    check renderBanner(banner("Title", width = 12)) == "── Title ───"
    check renderBanner(banner("Title", subtitle = "Details", width = 12)) ==
      "── Title ───\n─ Details ──"
    check renderBanner(initBanner("First\nSecond", width = 12)) ==
      "── First ───\n── Second ──"

  test "allocates odd cells and aligns rule content deterministically":
    check renderBanner(initBanner("Go", width = 10,
      alignment = alignLeft)) == " Go ──────"
    check renderBanner(initBanner("Go", width = 10,
      alignment = alignCenter)) == "─── Go ───"
    check renderBanner(initBanner("Go", width = 10,
      alignment = alignRight)) == "────── Go "
    # Five spare cells put two on the left and the deterministic extra cell on
    # the right.
    check renderBanner(initBanner("Title", width = 12,
      alignment = alignCenter)) == "── Title ───"

  test "renders filled, vertically padded, and empty rule banners":
    check renderBanner(initBanner("Fill", width = 10,
      padding = initPanelPadding(top = 1, right = 1, bottom = 1, left = 1))
      .withFillGlyph("=")) ==
      "==========\n== Fill ==\n=========="
    check renderBanner(banner("", width = 7)) == "───────"

  test "renders boxed, heavy, double, and ASCII presets":
    check renderBanner(initBanner("Go", width = 10,
      theme = boxedBannerTheme)) ==
      "┌────────┐\n│   Go   │\n└────────┘"
    check renderBanner(initBanner("Go", width = 10,
      theme = heavyBannerTheme)) ==
      "┏━━━━━━━━┓\n┃   Go   ┃\n┗━━━━━━━━┛"
    check renderBanner(initBanner("Go", width = 10,
      theme = doubleBannerTheme)) ==
      "╔════════╗\n║   Go   ║\n╚════════╝"
    check renderBanner(initBanner("Go", width = 10,
      theme = asciiBannerTheme)) == "=== Go ==="
    check renderBanner(initBanner("Go", width = 10,
      theme = asciiBannerTheme).withBorderMode(bannerBoxed)) ==
      "+--------+\n|   Go   |\n+--------+"

  test "keeps narrow and wide output deterministic":
    check renderBanner(initBanner(fixtureCjk, width = 3)) == " … "
    let rendered = renderBanner(initBanner("wide", width = 24))
    check rendered == "───────── wide ─────────"
    check displayWidth(rendered) == 24

suite "banner Unicode width and ANSI behavior":
  test "measures CJK, combining marks, and emoji by visible cells":
    let value = fixtureCjk & fixtureCombining & fixtureEmoji
    let rendered = renderBanner(initBanner(value, width = 12))
    check rendered == "── 界é👨‍👩‍👧‍👦 ───"
    check displayWidth(rendered) == 12

  test "preserves styled text and contains text and fill resets":
    let value = initBanner(red("Build"), width = 12,
      textStyle = initTerminalStyle(attributes = {taBold}),
      fillStyle = initTerminalStyle(foreground = colorCyan))
    let rendered = renderBanner(value)
    check stripAnsi(rendered) == "── Build ───"
    check rendered.contains(termRed)
    check rendered.contains(termCyan)
    check rendered.endsWith(termClear)

  test "truncates styled content without splitting ANSI sequences":
    let rendered = renderBanner(initBanner(red("abcdef"), width = 6))
    check stripAnsi(rendered) == " abc… "
    check rendered.contains(termRed)
    check rendered.contains("\e[0m…")

  test "plain rendering strips input ANSI and suppresses styles":
    let rendered = renderBanner(initBanner(fixtureAnsi, width = 10,
      textStyle = initTerminalStyle(attributes = {taBold}),
      fillStyle = initTerminalStyle(foreground = colorCyan),
      useColor = false))
    check rendered == "── red ───"
    check '\e' notin rendered

  test "boxed banners preserve Unicode geometry and strip ANSI in plain mode":
    let rendered = renderBanner(initBanner(
      fixtureCjk & fixtureCombining & fixtureEmoji,
      subtitle = some(green("ready")), width = 12,
      theme = boxedBannerTheme, useColor = false))
    check rendered ==
      "┌──────────┐\n" &
      "│  界é👨‍👩‍👧‍👦   │\n" &
      "│  ready   │\n" &
      "└──────────┘"
    check rendered.splitLines.mapIt(displayWidth(it)) == @[12, 12, 12, 12]
    check '\e' notin rendered

suite "banner rendering contract":
  test "uses exact outer widths, CRLF, and no trailing line ending":
    let rendered = renderBanner(initBanner("One\nTwo",
      subtitle = some("Three"), width = 10,
      lineEnding = "\r\n"))
    check rendered ==
      "── One ───\r\n── Two ───\r\n─ Three ──"
    check not rendered.endsWith("\r\n")
    check rendered.split("\r\n").mapIt(displayWidth(it)) == @[10, 10, 10]

  test "does not mutate caller-owned banner values":
    var value = initBanner("Title", subtitle = some("Subtitle"), width = 18,
      theme = heavyBannerTheme)
    let
      beforeText = value.text
      beforeSubtitle = value.subtitle
      beforeWidth = value.width.cellCount
      beforeGlyph = value.fillGlyph
      beforeTheme = value.panelTheme
    discard renderBanner(value)
    check value.text == beforeText
    check value.subtitle == beforeSubtitle
    check value.width.cellCount == beforeWidth
    check value.fillGlyph == beforeGlyph
    check value.panelTheme == beforeTheme

  test "rejects invalid widths, padding, glyphs, themes, and line endings":
    expect ValueError:
      discard initBanner("x", width = 2)
    expect ValueError:
      discard initBanner("x", width = 4, theme = boxedBannerTheme)
    expect ValueError:
      discard initBanner("x", padding = PanelPadding(left: -1))
    expect ValueError:
      discard customBannerTheme("")
    expect ValueError:
      discard customBannerTheme("界")
    expect ValueError:
      discard customBannerTheme("\n")
    expect ValueError:
      discard customBannerTheme(termRed & "=" & termClear)
    expect ValueError:
      discard initBanner("x", lineEnding = "\r")

    var invalid = banner("x")
    invalid.width = LayoutWidth(0)
    expect ValueError:
      discard renderBanner(invalid)

    invalid = banner("x")
    invalid.fillGlyph = "界"
    expect ValueError:
      discard renderBanner(invalid)

    invalid = initBanner("x", theme = boxedBannerTheme)
    invalid.panelTheme.glyphs.horizontal = "界"
    expect ValueError:
      discard renderBanner(invalid)
