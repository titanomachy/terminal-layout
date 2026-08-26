## Shared validation, sizing, and multiline behavior for TerminalLayout.
##
## Component renderers use these types and helpers so widths, insets, overflow,
## and line endings have the same meaning throughout the package. Horizontal
## alignment deliberately reuses ``terminal_style.TextAlignment`` rather than
## introducing a competing enum.

import std/strutils

type
  LayoutWidth* = distinct int
    ## A positive outer width measured in visible terminal cells.
    ##
    ## Construct widths with ``initLayoutWidth`` so invalid values raise
    ## ``ValueError`` before rendering begins.

  LayoutInsets* = object
    ## Non-negative blank space surrounding component content.
    top*, right*, bottom*, left*: int

  OverflowMode* = enum
    ## How content wider than its available terminal-cell width is handled.
    overflowWrap,
    overflowTruncate

const defaultLineEnding* = "\n"
  ## Default line separator used by TerminalLayout renderers.

proc initLayoutWidth*(cells: int): LayoutWidth =
  ## Constructs a positive terminal-cell width.
  ##
  ## Raises ``ValueError`` when ``cells`` is zero or negative.
  if cells <= 0:
    raise newException(ValueError, "layout width must be positive")
  LayoutWidth(cells)

proc validateLayoutWidth*(width: LayoutWidth) =
  ## Raises ``ValueError`` if a directly converted width is not positive.
  ##
  ## Renderers call this validation as well as accepting values produced by
  ## ``initLayoutWidth`` so a caller cannot bypass the rendering contract with
  ## an unchecked distinct-type conversion.
  if int(width) <= 0:
    raise newException(ValueError, "layout width must be positive")

proc cellCount*(width: LayoutWidth): int {.inline.} =
  ## Returns the primitive terminal-cell count stored in ``width``.
  int(width)

proc validateInsets*(insets: LayoutInsets) =
  ## Raises ``ValueError`` if any inset is negative.
  if insets.top < 0:
    raise newException(ValueError, "top inset cannot be negative")
  if insets.right < 0:
    raise newException(ValueError, "right inset cannot be negative")
  if insets.bottom < 0:
    raise newException(ValueError, "bottom inset cannot be negative")
  if insets.left < 0:
    raise newException(ValueError, "left inset cannot be negative")

proc initLayoutInsets*(top = 0; right = 0; bottom = 0;
                       left = 0): LayoutInsets =
  ## Constructs independently configurable, non-negative layout insets.
  result = LayoutInsets(top: top, right: right, bottom: bottom, left: left)
  result.validateInsets()

proc uniformInsets*(amount: int): LayoutInsets =
  ## Constructs equal insets on all four sides.
  initLayoutInsets(amount, amount, amount, amount)

proc horizontalInset*(insets: LayoutInsets): int {.inline.} =
  ## Returns the combined left and right inset.
  insets.left + insets.right

proc verticalInset*(insets: LayoutInsets): int {.inline.} =
  ## Returns the combined top and bottom inset.
  insets.top + insets.bottom

proc validateLineEnding*(lineEnding: string) =
  ## Accepts LF or CRLF and rejects every other output line separator.
  if lineEnding != "\n" and lineEnding != "\r\n":
    raise newException(ValueError, "line ending must be LF or CRLF")

proc splitLayoutLines*(value: string): seq[string] =
  ## Splits LF and CRLF input while preserving empty and trailing lines.
  ##
  ## An empty string produces one empty logical line. A carriage return not
  ## followed by a line feed remains ordinary content.
  var lineStart = 0
  for index, character in value:
    if character != '\n':
      continue
    var lineEnd = index
    if lineEnd > lineStart and value[lineEnd - 1] == '\r':
      dec lineEnd
    result.add value[lineStart ..< lineEnd]
    lineStart = index + 1
  result.add value[lineStart ..< value.len]

proc joinLayoutLines*(lines: openArray[string];
                      lineEnding = defaultLineEnding): string =
  ## Joins logical lines using a validated LF or CRLF separator.
  validateLineEnding(lineEnding)
  lines.join(lineEnding)

proc normalizeLineEndings*(value: string;
                           lineEnding = defaultLineEnding): string =
  ## Rewrites LF and CRLF input to one validated output line separator.
  joinLayoutLines(splitLayoutLines(value), lineEnding)
