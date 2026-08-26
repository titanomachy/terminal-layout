import std/unittest

import terminal_layout
import fixtures

suite "shared layout foundation":
  test "constructs and validates positive terminal-cell widths":
    let width = initLayoutWidth(42)
    check width.cellCount == 42

    expect ValueError:
      discard initLayoutWidth(0)
    expect ValueError:
      discard initLayoutWidth(-1)
    expect ValueError:
      validateLayoutWidth(LayoutWidth(0))

  test "constructs and validates non-negative layout insets":
    let
      insets = initLayoutInsets(top = 1, right = 2, bottom = 3, left = 4)
      uniform = uniformInsets(2)
    check insets.horizontalInset == 6
    check insets.verticalInset == 4
    check uniform == LayoutInsets(top: 2, right: 2, bottom: 2, left: 2)

    for invalid in [
        LayoutInsets(top: -1),
        LayoutInsets(right: -1),
        LayoutInsets(bottom: -1),
        LayoutInsets(left: -1)]:
      expect ValueError:
        invalid.validateInsets()
    expect ValueError:
      discard uniformInsets(-1)

  test "defines explicit wrapping and truncation behavior":
    check overflowWrap != overflowTruncate

  test "splits multiline input without discarding empty or trailing lines":
    check splitLayoutLines(fixtureEmpty) == @[""]
    check splitLayoutLines(fixtureMultiline) == @["first", "", "third"]
    check splitLayoutLines(fixtureCrlf) == @["first", "", "third", ""]
    check splitLayoutLines("one\rtwo") == @["one\rtwo"]

  test "joins and normalizes only validated output line endings":
    let lines = @["first", "", "third", ""]
    check joinLayoutLines(lines) == "first\n\nthird\n"
    check joinLayoutLines(lines, "\r\n") == fixtureCrlf
    check joinLayoutLines(newSeq[string]()) == ""
    check normalizeLineEndings(fixtureCrlf) == "first\n\nthird\n"
    check normalizeLineEndings(fixtureMultiline, "\r\n") ==
      "first\r\n\r\nthird"

    for invalid in ["", "\r", "\n\r", "line"]:
      expect ValueError:
        discard joinLayoutLines(lines, invalid)

  test "provides ANSI, CJK, combining, emoji, and empty fixtures":
    check stripAnsi(fixtureAnsi) == "red"
    check displayWidth(fixtureCjk) == 2
    check displayWidth(fixtureCombining) == 1
    check displayWidth(fixtureEmoji) == 2
    check displayWidth(fixtureEmpty) == 0

suite "layout glyph presets":
  test "validates the named Unicode and ASCII presets":
    unicodeLayoutGlyphs.validateLayoutGlyphs()
    asciiLayoutGlyphs.validateLayoutGlyphs()

    check unicodeLayoutGlyphs.tree.tee == "├"
    check asciiLayoutGlyphs.border.topLeft == "+"

  test "accepts one-cell graphemes and rejects invalid glyphs":
    validateLayoutGlyph(fixtureCombining)

    for invalid in [fixtureEmpty, fixtureCjk, "ab", "x\ny", fixtureAnsi,
        "\ex", "\tx"]:
      expect ValueError:
        validateLayoutGlyph(invalid)

suite "facade":
  test "re-exports the shared TerminalStyle API":
    check displayWidth(red("界")) == 2
    check stripAnsi(red("ready")) == "ready"
