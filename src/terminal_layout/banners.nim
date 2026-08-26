## Width-aware, non-semantic terminal headings and announcements.
##
## Banners render either rule-filled heading rows or panel-backed boxes. They
## carry no success, warning, or failure meaning; use callouts for semantic
## status. Width is always the complete outer width in visible terminal cells.
##
## .. code-block:: nim
##
##   import terminal_layout
##
##   echo banner("Build summary", subtitle = "12 checks", width = 32).render()

import std/[options, strutils]

import terminal_style

import ./[core, panels, themes]

type
  BannerBorderMode* = enum
    ## Selects a rule-filled row or an enclosing panel border.
    bannerRule,
    bannerBoxed

  BannerTheme* = object
    ## A named banner glyph and border-mode configuration.
    ##
    ## ``fillGlyph`` is used by rule banners. ``panelTheme`` supplies boxed
    ## geometry, while ``borderMode`` is copied into banners initialized with
    ## this theme. Styles remain properties of each ``Banner`` value.
    fillGlyph*: string
    panelTheme*: PanelTheme
    borderMode*: BannerBorderMode

  Banner* = object
    ## A reusable, non-semantic heading or announcement model.
    ##
    ## ``text`` may contain LF or CRLF-separated lines. ``subtitle`` is
    ## rendered after those lines when present. Rule mode fills every row to
    ## the complete outer ``width``; boxed mode delegates that contract to the
    ## panel renderer. Rendering never mutates the model or appends a line
    ## ending.
    text*: string
    subtitle*: Option[string]
    width*: LayoutWidth
    alignment*: TextAlignment
    fillGlyph*: string
    padding*: PanelPadding
    borderMode*: BannerBorderMode
    panelTheme*: PanelTheme
    textStyle*, fillStyle*: TerminalStyle
    useColor*: bool
    lineEnding*: string

const
  defaultBannerWidth* = 40
    ## Default complete outer width used by banner constructors.

  defaultBannerPadding* = PanelPadding(right: 1, left: 1)
    ## One blank separator cell on each side of non-empty banner text.

  plainRuleBannerTheme* = BannerTheme(
    fillGlyph: "─", panelTheme: squarePanelTheme, borderMode: bannerRule)
    ## A light Unicode rule with no enclosing border.

  boxedBannerTheme* = BannerTheme(
    fillGlyph: "─", panelTheme: squarePanelTheme, borderMode: bannerBoxed)
    ## A square Unicode box around banner content.

  heavyBannerTheme* = BannerTheme(
    fillGlyph: "━", panelTheme: heavyPanelTheme, borderMode: bannerBoxed)
    ## A heavy Unicode box around banner content.

  doubleBannerTheme* = BannerTheme(
    fillGlyph: "═", panelTheme: doublePanelTheme, borderMode: bannerBoxed)
    ## A double-line Unicode box around banner content.

  asciiBannerTheme* = BannerTheme(
    fillGlyph: "=", panelTheme: asciiPanelTheme, borderMode: bannerRule)
    ## A seven-bit ASCII rule; its panel theme also supports boxed rendering.

proc initBannerTheme*(fillGlyph: string; panelTheme = squarePanelTheme;
                      borderMode = bannerRule): BannerTheme =
  ## Constructs a banner theme from a plain one-cell fill glyph and panel
  ## theme, raising ``ValueError`` if either glyph configuration is invalid.
  validateLayoutGlyph(fillGlyph, "banner fill glyph")
  panelTheme.validatePanelTheme()
  BannerTheme(fillGlyph: fillGlyph, panelTheme: panelTheme,
    borderMode: borderMode)

proc customBannerTheme*(fillGlyph: string; panelTheme = squarePanelTheme;
                        borderMode = bannerRule): BannerTheme =
  ## Convenience alias for constructing a validated custom banner theme.
  initBannerTheme(fillGlyph, panelTheme, borderMode)

proc validateBannerTheme*(theme: BannerTheme) =
  ## Raises ``ValueError`` when a theme contains an invalid fill or panel
  ## glyph. Renderers call this for directly constructed public values.
  discard initBannerTheme(theme.fillGlyph, theme.panelTheme,
    theme.borderMode)

proc validateBanner*(value: Banner) =
  ## Validates banner width, padding, glyphs, boxed geometry, and line ending.
  ##
  ## At least one terminal cell must remain for content after horizontal
  ## padding and, in boxed mode, the two border columns. Text that cannot fit
  ## is safely truncated by the renderer rather than partially emitted.
  value.width.validateLayoutWidth()
  value.padding.validatePanelPadding()
  validateLayoutGlyph(value.fillGlyph, "banner fill glyph")
  value.panelTheme.validatePanelTheme()
  validateLineEnding(value.lineEnding)

  let borderWidth = if value.borderMode == bannerBoxed: 2 else: 0
  if value.width.cellCount - borderWidth -
      value.padding.horizontalPadding <= 0:
    raise newException(ValueError,
      "banner width leaves no cells available for text")

proc initBanner*(text: string; subtitle = none(string);
                 width = defaultBannerWidth;
                 alignment: TextAlignment = alignCenter;
                 padding = defaultBannerPadding;
                 theme = plainRuleBannerTheme;
                 textStyle = TerminalStyle();
                 fillStyle = TerminalStyle();
                 useColor = true;
                 lineEnding = defaultLineEnding): Banner =
  ## Constructs and validates a banner with an explicit complete outer width.
  ##
  ## The selected theme supplies the initial fill glyph, panel preset, and
  ## rule/boxed mode. Use immutable helpers or public fields for subsequent
  ## configuration; rendering validates public fields again.
  result = Banner(text: text, subtitle: subtitle,
    width: initLayoutWidth(width), alignment: alignment,
    fillGlyph: theme.fillGlyph, padding: padding,
    borderMode: theme.borderMode, panelTheme: theme.panelTheme,
    textStyle: textStyle, fillStyle: fillStyle, useColor: useColor,
    lineEnding: lineEnding)
  result.validateBanner()

proc banner*(text: string; subtitle = "";
             width = defaultBannerWidth): Banner =
  ## Concisely constructs a centered rule banner, omitting an empty subtitle.
  initBanner(text,
    subtitle = if subtitle.len == 0: none(string) else: some(subtitle),
    width = width)

proc withSubtitle*(value: Banner; subtitle: string): Banner =
  ## Returns a copy with a subtitle rendered after the main text lines.
  result = value
  result.subtitle = some(subtitle)

proc withWidth*(value: Banner; cells: int): Banner =
  ## Returns a validated copy with a new complete outer width.
  result = value
  result.width = initLayoutWidth(cells)
  result.validateBanner()

proc withAlignment*(value: Banner;
                    alignment: TextAlignment): Banner =
  ## Returns a copy with new terminal-cell alignment for every content row.
  result = value
  result.alignment = alignment

proc withFillGlyph*(value: Banner; glyph: string): Banner =
  ## Returns a validated copy with a custom plain one-cell rule glyph.
  result = value
  result.fillGlyph = glyph
  result.validateBanner()

proc withPadding*(value: Banner; padding: PanelPadding): Banner =
  ## Returns a validated copy with new text and vertical-row padding.
  result = value
  result.padding = padding
  result.validateBanner()

proc withBorderMode*(value: Banner;
                     borderMode: BannerBorderMode): Banner =
  ## Returns a validated copy using rule-filled or panel-backed rendering.
  result = value
  result.borderMode = borderMode
  result.validateBanner()

proc withTheme*(value: Banner; theme: BannerTheme): Banner =
  ## Returns a validated copy using a theme's glyphs and default border mode.
  result = value
  result.fillGlyph = theme.fillGlyph
  result.panelTheme = theme.panelTheme
  result.borderMode = theme.borderMode
  result.validateBanner()

proc withColor*(value: Banner; useColor: bool): Banner =
  ## Returns a copy that enables or disables text and fill ANSI styling.
  result = value
  result.useColor = useColor

proc withLineEnding*(value: Banner; lineEnding: string): Banner =
  ## Returns a validated copy using LF or CRLF between rendered rows.
  result = value
  result.lineEnding = lineEnding
  result.validateBanner()

proc logicalLines(value: string): seq[string] =
  # TerminalStyle closes and restores ANSI state around explicit line breaks.
  wrapAnsi(value, max(1, displayWidth(value)), wrapCharacters)

proc contentLines(value: Banner): seq[string] =
  let text = if value.useColor: value.text else: stripAnsi(value.text)
  result = logicalLines(text)
  if value.subtitle.isSome:
    let subtitle = if value.useColor: value.subtitle.get else:
      stripAnsi(value.subtitle.get)
    result.add logicalLines(subtitle)

proc alignedCounts(missing: int;
                   alignment: TextAlignment): tuple[left, right: int] =
  case alignment
  of alignLeft:
    result.right = missing
  of alignCenter:
    result.left = missing div 2
    result.right = missing - result.left
  of alignRight:
    result.left = missing

proc styledFill(value: Banner; cells: int): string =
  applyStyle(repeat(value.fillGlyph, cells), value.fillStyle, value.useColor)

proc renderRuleLine(value: Banner; line: string): string =
  let
    outerWidth = value.width.cellCount
    contentWidth = outerWidth - value.padding.horizontalPadding
    fitted = truncateAnsi(line, contentWidth)
    fittedWidth = displayWidth(fitted)

  # An empty logical line is a complete rule. This avoids ambiguous separator
  # spaces while keeping empty text and vertical padding deterministic.
  if fittedWidth == 0:
    return value.styledFill(outerWidth)

  let
    missing = outerWidth - value.padding.horizontalPadding - fittedWidth
    placement = alignedCounts(missing, value.alignment)
    before = repeat(value.fillGlyph, placement.left) &
      repeat(' ', value.padding.left)
    after = repeat(' ', value.padding.right) &
      repeat(value.fillGlyph, placement.right)

  result = applyStyle(before, value.fillStyle, value.useColor)
  result.add applyStyle(fitted, value.textStyle, value.useColor)
  result.add applyStyle(after, value.fillStyle, value.useColor)

proc renderRuleBanner(value: Banner): string =
  var rows: seq[string]
  for _ in 0 ..< value.padding.top:
    rows.add value.styledFill(value.width.cellCount)
  for line in value.contentLines:
    rows.add value.renderRuleLine(line)
  for _ in 0 ..< value.padding.bottom:
    rows.add value.styledFill(value.width.cellCount)
  joinLayoutLines(rows, value.lineEnding)

proc renderBoxedBanner(value: Banner): string =
  let body = value.contentLines.join("\n")
  renderPanel(initPanel(body,
    width = value.width.cellCount,
    padding = value.padding,
    theme = value.panelTheme,
    bodyStyle = value.textStyle,
    borderStyle = value.fillStyle,
    contentAlignment = value.alignment,
    overflow = overflowTruncate,
    useColor = value.useColor,
    lineEnding = value.lineEnding))

proc renderBanner*(value: Banner): string =
  ## Renders a banner without printing or appending a trailing line ending.
  ##
  ## Rule mode uses the theme fill glyph for unused cells and puts the extra
  ## odd cell on the right for centered text. Boxed mode delegates border,
  ## padding, fitting, ANSI, and terminal-cell geometry to ``renderPanel``.
  ## Both modes truncate only at complete grapheme boundaries.
  value.validateBanner()
  case value.borderMode
  of bannerRule:
    renderRuleBanner(value)
  of bannerBoxed:
    renderBoxedBanner(value)

proc render*(value: Banner): string =
  ## Convenience alias for ``renderBanner(value)``.
  renderBanner(value)

proc `$`*(value: Banner): string =
  ## Renders a banner using the configuration stored in its value model.
  renderBanner(value)
