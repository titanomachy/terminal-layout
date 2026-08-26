## Width-aware panel and card models with deterministic string rendering.
##
## A card is a ``Panel`` configured with rounded borders and roomier padding;
## both APIs use the same renderer. Width always means the complete outer
## terminal-cell width, including border columns and horizontal padding.
##
## .. code-block:: nim
##
##   import terminal_layout
##
##   let summary = card("Build complete", title = "Status", width = 32)
##   echo summary.render()

import std/[options, strutils]

import terminal_style

import ./[core, themes]

type
  PanelPadding* = object
    ## Non-negative blank rows and columns surrounding panel body content.
    top*, right*, bottom*, left*: int

  PanelTheme* = object
    ## Border glyphs and whether the panel draws an enclosing border.
    ##
    ## Borderless panels still honor their outer width, padding, alignment,
    ## title, and footer.
    glyphs*: BorderGlyphs
    bordered*: bool

  Panel* = object
    ## A complete, reusable panel model.
    ##
    ## ``title`` and ``footer`` are single-line labels. Their alignments are
    ## independent from body alignment, as are all four text/border styles.
    body*: string
    title*, footer*: Option[string]
    width*: LayoutWidth
    padding*: PanelPadding
    theme*: PanelTheme
    bodyStyle*, titleStyle*, footerStyle*, borderStyle*: TerminalStyle
    contentAlignment*, titleAlignment*, footerAlignment*: TextAlignment
    overflow*: OverflowMode
    wrapMode*: WrapMode
    useColor*: bool
    lineEnding*: string

const
  defaultPanelWidth* = 40
    ## Default complete outer width used by panel and card constructors.

  defaultPanelPadding* = PanelPadding(right: 1, left: 1)
    ## Default panel padding: one blank column on each side of the body.

  defaultCardPadding* = PanelPadding(top: 1, right: 1, bottom: 1, left: 1)
    ## Roomier card padding with one blank cell on every side.

  squarePanelTheme* = PanelTheme(
    glyphs: unicodeLayoutGlyphs.border, bordered: true)
    ## Square Unicode box-drawing borders.

  roundedPanelTheme* = PanelTheme(
    glyphs: BorderGlyphs(
      topLeft: "╭", topRight: "╮", bottomLeft: "╰", bottomRight: "╯",
      horizontal: "─", vertical: "│"), bordered: true)
    ## Rounded Unicode box-drawing borders.

  heavyPanelTheme* = PanelTheme(
    glyphs: BorderGlyphs(
      topLeft: "┏", topRight: "┓", bottomLeft: "┗", bottomRight: "┛",
      horizontal: "━", vertical: "┃"), bordered: true)
    ## Heavy Unicode box-drawing borders.

  doublePanelTheme* = PanelTheme(
    glyphs: BorderGlyphs(
      topLeft: "╔", topRight: "╗", bottomLeft: "╚", bottomRight: "╝",
      horizontal: "═", vertical: "║"), bordered: true)
    ## Double-line Unicode box-drawing borders.

  asciiPanelTheme* = PanelTheme(
    glyphs: asciiLayoutGlyphs.border, bordered: true)
    ## Portable seven-bit ASCII borders.

  borderlessPanelTheme* = PanelTheme(bordered: false)
    ## No border glyphs; rows still occupy the configured outer width.

proc validatePanelPadding*(padding: PanelPadding) =
  ## Raises ``ValueError`` if any panel padding value is negative.
  if padding.top < 0:
    raise newException(ValueError, "top panel padding cannot be negative")
  if padding.right < 0:
    raise newException(ValueError, "right panel padding cannot be negative")
  if padding.bottom < 0:
    raise newException(ValueError, "bottom panel padding cannot be negative")
  if padding.left < 0:
    raise newException(ValueError, "left panel padding cannot be negative")

proc initPanelPadding*(top = 0; right = 0; bottom = 0;
                       left = 0): PanelPadding =
  ## Constructs independently configurable, non-negative panel padding.
  result = PanelPadding(top: top, right: right, bottom: bottom, left: left)
  result.validatePanelPadding()

proc uniformPanelPadding*(amount: int): PanelPadding =
  ## Constructs equal panel padding on all four sides.
  initPanelPadding(amount, amount, amount, amount)

proc horizontalPadding*(padding: PanelPadding): int {.inline.} =
  ## Returns the combined left and right panel padding.
  padding.left + padding.right

proc verticalPadding*(padding: PanelPadding): int {.inline.} =
  ## Returns the combined top and bottom panel padding.
  padding.top + padding.bottom

proc initPanelTheme*(glyphs: BorderGlyphs; bordered = true): PanelTheme =
  ## Constructs a custom panel theme and validates bordered glyphs.
  if bordered:
    for (name, glyph) in [
        ("panel.topLeft", glyphs.topLeft),
        ("panel.topRight", glyphs.topRight),
        ("panel.bottomLeft", glyphs.bottomLeft),
        ("panel.bottomRight", glyphs.bottomRight),
        ("panel.horizontal", glyphs.horizontal),
        ("panel.vertical", glyphs.vertical)]:
      validateLayoutGlyph(glyph, name)
  PanelTheme(glyphs: glyphs, bordered: bordered)

proc customPanelTheme*(topLeft, topRight, bottomLeft, bottomRight,
                       horizontal, vertical: string): PanelTheme =
  ## Constructs a bordered theme from six plain one-cell glyphs.
  initPanelTheme(BorderGlyphs(topLeft: topLeft, topRight: topRight,
    bottomLeft: bottomLeft, bottomRight: bottomRight,
    horizontal: horizontal, vertical: vertical))

proc validatePanelTheme*(theme: PanelTheme) =
  ## Raises ``ValueError`` if a bordered theme has an invalid glyph.
  discard initPanelTheme(theme.glyphs, theme.bordered)

proc validatePanel*(panel: Panel) =
  ## Validates all geometry, labels, theme glyphs, and line-ending choices.
  panel.width.validateLayoutWidth()
  panel.padding.validatePanelPadding()
  panel.theme.validatePanelTheme()
  validateLineEnding(panel.lineEnding)

  for (name, label) in [("panel title", panel.title),
                        ("panel footer", panel.footer)]:
    if label.isSome and (label.get.contains('\n') or label.get.contains('\r')):
      raise newException(ValueError, name & " must be a single line")

  let borderWidth = if panel.theme.bordered: 2 else: 0
  if panel.width.cellCount - borderWidth - panel.padding.horizontalPadding <= 0:
    raise newException(ValueError,
      "panel width leaves no cells available for body content")

proc initPanel*(body: string; width = defaultPanelWidth;
                title = none(string); footer = none(string);
                padding = defaultPanelPadding;
                theme = squarePanelTheme;
                bodyStyle = TerminalStyle();
                titleStyle = TerminalStyle();
                footerStyle = TerminalStyle();
                borderStyle = TerminalStyle();
                contentAlignment: TextAlignment = alignLeft;
                titleAlignment: TextAlignment = alignLeft;
                footerAlignment: TextAlignment = alignLeft;
                overflow = overflowWrap;
                wrapMode = wrapWords;
                useColor = true;
                lineEnding = defaultLineEnding): Panel =
  ## Constructs and validates a panel with an explicit complete outer width.
  result = Panel(body: body, title: title, footer: footer,
    width: initLayoutWidth(width), padding: padding, theme: theme,
    bodyStyle: bodyStyle, titleStyle: titleStyle, footerStyle: footerStyle,
    borderStyle: borderStyle, contentAlignment: contentAlignment,
    titleAlignment: titleAlignment, footerAlignment: footerAlignment,
    overflow: overflow, wrapMode: wrapMode, useColor: useColor,
    lineEnding: lineEnding)
  result.validatePanel()

proc initCard*(body: string; width = defaultPanelWidth;
               title = none(string); footer = none(string);
               padding = defaultCardPadding;
               theme = roundedPanelTheme;
               bodyStyle = TerminalStyle();
               titleStyle = TerminalStyle();
               footerStyle = TerminalStyle();
               borderStyle = TerminalStyle();
               contentAlignment: TextAlignment = alignLeft;
               titleAlignment: TextAlignment = alignLeft;
               footerAlignment: TextAlignment = alignLeft;
               overflow = overflowWrap;
               wrapMode = wrapWords;
               useColor = true;
               lineEnding = defaultLineEnding): Panel =
  ## Constructs a card-oriented panel with rounded borders and full padding.
  initPanel(body, width, title, footer, padding, theme, bodyStyle, titleStyle,
    footerStyle, borderStyle, contentAlignment, titleAlignment,
    footerAlignment, overflow, wrapMode, useColor, lineEnding)

proc card*(body: string; title = ""; footer = "";
           width = defaultPanelWidth): Panel =
  ## Concisely constructs a card, omitting empty title and footer arguments.
  initCard(body, width,
    title = if title.len == 0: none(string) else: some(title),
    footer = if footer.len == 0: none(string) else: some(footer))

proc withTitle*(panel: Panel; title: string;
                alignment: TextAlignment = alignLeft): Panel =
  ## Returns a validated copy with a title and its border-line alignment.
  result = panel
  result.title = some(title)
  result.titleAlignment = alignment
  result.validatePanel()

proc withFooter*(panel: Panel; footer: string;
                 alignment: TextAlignment = alignLeft): Panel =
  ## Returns a validated copy with a footer and its border-line alignment.
  result = panel
  result.footer = some(footer)
  result.footerAlignment = alignment
  result.validatePanel()

proc withWidth*(panel: Panel; cells: int): Panel =
  ## Returns a validated copy with a new complete outer width.
  result = panel
  result.width = initLayoutWidth(cells)
  result.validatePanel()

proc withPadding*(panel: Panel; padding: PanelPadding): Panel =
  ## Returns a validated copy with new body padding.
  result = panel
  result.padding = padding
  result.validatePanel()

proc withTheme*(panel: Panel; theme: PanelTheme): Panel =
  ## Returns a validated copy using another border preset or custom theme.
  result = panel
  result.theme = theme
  result.validatePanel()

proc withContentAlignment*(panel: Panel;
                           alignment: TextAlignment): Panel =
  ## Returns a copy with a new body-row alignment.
  result = panel
  result.contentAlignment = alignment

proc withOverflow*(panel: Panel; overflow: OverflowMode;
                   wrapMode = wrapWords): Panel =
  ## Returns a copy with new body overflow and wrapping behavior.
  result = panel
  result.overflow = overflow
  result.wrapMode = wrapMode

proc withColor*(panel: Panel; useColor: bool): Panel =
  ## Returns a copy that enables or disables all ANSI styling.
  result = panel
  result.useColor = useColor

proc withLineEnding*(panel: Panel; lineEnding: string): Panel =
  ## Returns a validated copy using LF or CRLF between rendered rows.
  result = panel
  result.lineEnding = lineEnding
  result.validatePanel()

proc logicalLines(value: string): seq[string] =
  # TerminalStyle's wrapping parser safely closes and restores ANSI state at
  # explicit newlines, even when no width-based wrapping is requested.
  wrapAnsi(value, max(1, displayWidth(value)), wrapCharacters)

proc bodyLines(panel: Panel; contentWidth: int): seq[string] =
  let value = if panel.useColor: panel.body else: stripAnsi(panel.body)
  case panel.overflow
  of overflowWrap:
    # Preserve already-fitted logical rows exactly. In particular, leading
    # spaces in rendered trees and nested lists are layout data rather than
    # disposable word-wrapping whitespace.
    for logicalLine in logicalLines(value):
      if displayWidth(logicalLine) <= contentWidth:
        result.add logicalLine
      else:
        let wrapped = wrapAnsi(logicalLine, contentWidth, panel.wrapMode)
        for line in wrapped:
          if displayWidth(line) > contentWidth:
            raise newException(ValueError,
              "panel width cannot contain a complete body grapheme")
          result.add line
  of overflowTruncate:
    for line in logicalLines(value):
      result.add truncateAnsi(line, contentWidth)

proc alignedCounts(missing: int; alignment: TextAlignment): tuple[left,
    right: int] =
  case alignment
  of alignLeft:
    result.right = missing
  of alignCenter:
    result.left = missing div 2
    result.right = missing - result.left
  of alignRight:
    result.left = missing

proc renderBorderLine(panel: Panel; top: bool;
                      label: Option[string];
                      alignment: TextAlignment;
                      labelStyle: TerminalStyle): string =
  let
    glyphs = panel.theme.glyphs
    leftCorner = if top: glyphs.topLeft else: glyphs.bottomLeft
    rightCorner = if top: glyphs.topRight else: glyphs.bottomRight
    runWidth = panel.width.cellCount - 2

  if label.isNone:
    return applyStyle(leftCorner & repeat(glyphs.horizontal, runWidth) &
      rightCorner, panel.borderStyle, panel.useColor)

  let
    rawLabel = if panel.useColor: label.get else: stripAnsi(label.get)
    separatorWidth = if runWidth >= 3: 2 else: 0
    labelWidth = max(0, runWidth - separatorWidth)
    fittedLabel = truncateAnsi(rawLabel, labelWidth)
    segmentWidth = displayWidth(fittedLabel) + separatorWidth
    spare = runWidth - segmentWidth
    placement = alignedCounts(spare, alignment)
    leftRule = repeat(glyphs.horizontal, placement.left)
    rightRule = repeat(glyphs.horizontal, placement.right)
    separator = if separatorWidth == 2: " " else: ""
    before = leftCorner & leftRule & separator
    after = separator & rightRule & rightCorner

  result = applyStyle(before, panel.borderStyle, panel.useColor)
  result.add applyStyle(fittedLabel, labelStyle, panel.useColor)
  result.add applyStyle(after, panel.borderStyle, panel.useColor)

proc renderPanel*(panel: Panel): string =
  ## Renders a panel or card without an appended trailing line ending.
  ##
  ## Logical body rows that already fit retain their leading whitespace so
  ## pre-rendered trees, lists, tables, and graphs preserve their structure.
  ## Only rows wider than the content area are wrapped or truncated.
  ##
  ## Bordered title/footer labels use one border-colored separator cell on
  ## each side whenever the horizontal run has at least three cells. A label
  ## collision is resolved by ANSI-aware grapheme truncation inside that run;
  ## corners are always preserved.
  panel.validatePanel()
  let
    outerWidth = panel.width.cellCount
    borderWidth = if panel.theme.bordered: 2 else: 0
    innerWidth = outerWidth - borderWidth
    contentWidth = innerWidth - panel.padding.horizontalPadding
    blankInner = repeat(' ', innerWidth)
    vertical = if panel.theme.bordered:
      applyStyle(panel.theme.glyphs.vertical, panel.borderStyle,
        panel.useColor)
    else:
      ""

  var output: seq[string]

  if panel.theme.bordered:
    output.add renderBorderLine(panel, true, panel.title,
      panel.titleAlignment, panel.titleStyle)
  elif panel.title.isSome:
    let title = if panel.useColor: panel.title.get else:
      stripAnsi(panel.title.get)
    output.add padAnsi(applyStyle(truncateAnsi(title, outerWidth),
      panel.titleStyle, panel.useColor), outerWidth, panel.titleAlignment)

  for _ in 0 ..< panel.padding.top:
    output.add vertical & blankInner & vertical

  for line in bodyLines(panel, contentWidth):
    let styledBody = applyStyle(line, panel.bodyStyle, panel.useColor)
    output.add vertical & repeat(' ', panel.padding.left) &
      padAnsi(styledBody, contentWidth, panel.contentAlignment) &
      repeat(' ', panel.padding.right) & vertical

  for _ in 0 ..< panel.padding.bottom:
    output.add vertical & blankInner & vertical

  if panel.theme.bordered:
    output.add renderBorderLine(panel, false, panel.footer,
      panel.footerAlignment, panel.footerStyle)
  elif panel.footer.isSome:
    let footer = if panel.useColor: panel.footer.get else:
      stripAnsi(panel.footer.get)
    output.add padAnsi(applyStyle(truncateAnsi(footer, outerWidth),
      panel.footerStyle, panel.useColor), outerWidth, panel.footerAlignment)

  joinLayoutLines(output, panel.lineEnding)

proc render*(panel: Panel): string =
  ## Convenience alias for ``renderPanel(panel)``.
  renderPanel(panel)

proc `$`*(panel: Panel): string =
  ## Renders a panel using the configuration stored in its value model.
  renderPanel(panel)
