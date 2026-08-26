## Width-aware semantic callouts built on the panel renderer.
##
## Callouts add an explicit status marker to arbitrary text without printing or
## consulting terminal state. Boxed callouts delegate all geometry to
## ``Panel``; compact callouts use a borderless panel so width, padding,
## overflow, ANSI handling, and line endings retain the same meaning.
##
## .. code-block:: nim
##
##   import terminal_layout
##
##   echo success("All checks passed", width = 32).render()
##   echo warning("Cache is nearly full", width = 32,
##     presentation = calloutCompact).render()

import std/options

import terminal_style

import ./[core, panels, themes]

type
  CalloutKind* = enum
    ## Semantic category carried by a callout independently of its colors.
    calloutInfo,
    calloutWarning,
    calloutFailure,
    calloutSuccess,
    calloutCustom

  CalloutPresentation* = enum
    ## Whether a callout uses a panel border or a compact borderless row.
    calloutBoxed,
    calloutCompact

  CalloutTheme* = object
    ## Explicit semantic text, icon, panel preset, and styles for a callout.
    ##
    ## ``label`` is the styled-mode fallback when ``icon`` is absent.
    ## ``plainMarker`` is always used when color is disabled, ensuring that
    ## status meaning never depends on ANSI color or a Unicode icon.
    label*: string
    icon*: Option[string]
    plainMarker*: string
    panelTheme*: PanelTheme
    markerStyle*, bodyStyle*, borderStyle*: TerminalStyle

  Callout* = object
    ## A reusable semantic message with complete outer-width semantics.
    ##
    ## The body may contain multiline ANSI text or another rendered component.
    ## ``title`` adds context after the semantic marker; it does not replace
    ## that marker in plain output. Rendering never mutates this value.
    kind*: CalloutKind
    body*: string
    title*: Option[string]
    width*: LayoutWidth
    padding*: PanelPadding
    presentation*: CalloutPresentation
    theme*: CalloutTheme
    overflow*: OverflowMode
    wrapMode*: WrapMode
    useColor*: bool
    lineEnding*: string

const
  defaultCalloutWidth* = defaultPanelWidth
    ## Default complete outer width used by callout constructors.

  defaultCalloutPadding* = defaultPanelPadding
    ## Default callout padding: one blank body cell on the left and right.

  infoCalloutTheme* = CalloutTheme(
    label: "INFO", icon: some("ℹ"), plainMarker: "[INFO]",
    panelTheme: squarePanelTheme,
    markerStyle: TerminalStyle(foreground: colorCyan,
      attributes: {taBold}),
    borderStyle: TerminalStyle(foreground: colorCyan))
    ## Cyan information theme with a square Unicode border.

  warningCalloutTheme* = CalloutTheme(
    label: "WARN", icon: some("⚠"), plainMarker: "[WARN]",
    panelTheme: squarePanelTheme,
    markerStyle: TerminalStyle(foreground: colorYellow,
      attributes: {taBold}),
    borderStyle: TerminalStyle(foreground: colorYellow))
    ## Yellow warning theme with a square Unicode border.

  failureCalloutTheme* = CalloutTheme(
    label: "FAIL", icon: some("×"), plainMarker: "[FAIL]",
    panelTheme: heavyPanelTheme,
    markerStyle: TerminalStyle(foreground: colorRed,
      attributes: {taBold}),
    borderStyle: TerminalStyle(foreground: colorRed))
    ## Red failure theme with a heavy Unicode border.

  successCalloutTheme* = CalloutTheme(
    label: "OK", icon: some("✓"), plainMarker: "[OK]",
    panelTheme: squarePanelTheme,
    markerStyle: TerminalStyle(foreground: colorGreen,
      attributes: {taBold}),
    borderStyle: TerminalStyle(foreground: colorGreen))
    ## Green success theme with a square Unicode border.

proc validateSemanticText(value, name: string) =
  if value.contains('\n') or value.contains('\r'):
    raise newException(ValueError, name & " must be a single line")
  if value.contains('\e') or stripAnsi(value) != value:
    raise newException(ValueError, name & " cannot contain ANSI controls")
  if displayWidth(value) == 0:
    raise newException(ValueError, name & " must be visible")

proc initCalloutTheme*(label, plainMarker: string;
                       icon = none(string);
                       panelTheme = squarePanelTheme;
                       markerStyle = TerminalStyle();
                       bodyStyle = TerminalStyle();
                       borderStyle = TerminalStyle()): CalloutTheme =
  ## Constructs a validated explicit callout palette.
  ##
  ## Labels and plain markers must be visible, single-line plain text. An icon,
  ## when present, must be a plain glyph occupying exactly one terminal cell.
  validateSemanticText(label, "callout label")
  validateSemanticText(plainMarker, "callout plain marker")
  if icon.isSome:
    validateLayoutGlyph(icon.get, "callout icon")
  panelTheme.validatePanelTheme()
  CalloutTheme(label: label, icon: icon, plainMarker: plainMarker,
    panelTheme: panelTheme, markerStyle: markerStyle, bodyStyle: bodyStyle,
    borderStyle: borderStyle)

proc customCalloutTheme*(label, plainMarker: string;
                         icon = none(string);
                         panelTheme = squarePanelTheme;
                         markerStyle = TerminalStyle();
                         bodyStyle = TerminalStyle();
                         borderStyle = TerminalStyle()): CalloutTheme =
  ## Convenience alias for constructing a validated custom semantic theme.
  initCalloutTheme(label, plainMarker, icon, panelTheme, markerStyle,
    bodyStyle, borderStyle)

proc validateCalloutTheme*(theme: CalloutTheme) =
  ## Raises ``ValueError`` if semantic text, an icon, or panel glyphs are invalid.
  discard initCalloutTheme(theme.label, theme.plainMarker, theme.icon,
    theme.panelTheme, theme.markerStyle, theme.bodyStyle, theme.borderStyle)

proc themeFor*(kind: CalloutKind): CalloutTheme =
  ## Returns the built-in explicit palette for a non-custom callout kind.
  ##
  ## A custom kind has no implicit palette and raises ``ValueError``.
  case kind
  of calloutInfo: infoCalloutTheme
  of calloutWarning: warningCalloutTheme
  of calloutFailure: failureCalloutTheme
  of calloutSuccess: successCalloutTheme
  of calloutCustom:
    raise newException(ValueError, "custom callouts require an explicit theme")

proc validateCallout*(callout: Callout) =
  ## Validates theme data, title, line ending, and presentation geometry.
  callout.width.validateLayoutWidth()
  callout.padding.validatePanelPadding()
  callout.theme.validateCalloutTheme()
  validateLineEnding(callout.lineEnding)
  if callout.title.isSome and
      (callout.title.get.contains('\n') or callout.title.get.contains('\r')):
    raise newException(ValueError, "callout title must be a single line")

  # Construct the panel shape during validation so directly mutated Callout
  # values fail before rendering begins, just like directly mutated Panels.
  let panelTheme = if callout.presentation == calloutBoxed:
    callout.theme.panelTheme
  else:
    borderlessPanelTheme
  discard initPanel("", callout.width.cellCount,
    padding = callout.padding, theme = panelTheme,
    overflow = callout.overflow, wrapMode = callout.wrapMode,
    useColor = callout.useColor, lineEnding = callout.lineEnding)

  # The semantic marker is never sacrificed to title/body truncation. Context
  # and body text may wrap or truncate according to the selected overflow mode.
  let
    marker = if callout.useColor:
      if callout.theme.icon.isSome: callout.theme.icon.get
      else: callout.theme.label
    else:
      callout.theme.plainMarker
    markerCapacity = if callout.presentation == calloutBoxed:
      callout.width.cellCount - 4 # corners and documented label separators
    else:
      callout.width.cellCount - callout.padding.horizontalPadding
  if displayWidth(marker) > markerCapacity:
    raise newException(ValueError,
      "callout width cannot contain its semantic marker")

proc initCallout*(body: string; kind = calloutInfo;
                  title = none(string);
                  width = defaultCalloutWidth;
                  padding = defaultCalloutPadding;
                  presentation = calloutBoxed;
                  theme = none(CalloutTheme);
                  overflow = overflowWrap;
                  wrapMode = wrapWords;
                  useColor = true;
                  lineEnding = defaultLineEnding): Callout =
  ## Constructs a validated callout with an explicit complete outer width.
  ##
  ## Built-in kinds select their named themes. ``calloutCustom`` requires
  ## ``some(customTheme)`` so palette selection is never ambient or inferred.
  let selectedTheme = if theme.isSome: theme.get else: themeFor(kind)
  result = Callout(kind: kind, body: body, title: title,
    width: initLayoutWidth(width), padding: padding,
    presentation: presentation, theme: selectedTheme,
    overflow: overflow, wrapMode: wrapMode, useColor: useColor,
    lineEnding: lineEnding)
  result.validateCallout()

proc info*(body: string; title = ""; width = defaultCalloutWidth;
           padding = defaultCalloutPadding;
           presentation = calloutBoxed; useColor = true): Callout =
  ## Concisely constructs an information callout.
  initCallout(body, calloutInfo,
    if title.len == 0: none(string) else: some(title), width, padding,
    presentation, useColor = useColor)

proc warning*(body: string; title = ""; width = defaultCalloutWidth;
              padding = defaultCalloutPadding;
              presentation = calloutBoxed; useColor = true): Callout =
  ## Concisely constructs a warning callout.
  initCallout(body, calloutWarning,
    if title.len == 0: none(string) else: some(title), width, padding,
    presentation, useColor = useColor)

proc failure*(body: string; title = ""; width = defaultCalloutWidth;
              padding = defaultCalloutPadding;
              presentation = calloutBoxed; useColor = true): Callout =
  ## Concisely constructs a failure callout.
  initCallout(body, calloutFailure,
    if title.len == 0: none(string) else: some(title), width, padding,
    presentation, useColor = useColor)

proc error*(body: string; title = ""; width = defaultCalloutWidth;
            padding = defaultCalloutPadding;
            presentation = calloutBoxed; useColor = true): Callout =
  ## Alias for ``failure`` using error-oriented application terminology.
  failure(body, title, width, padding, presentation, useColor)

proc success*(body: string; title = ""; width = defaultCalloutWidth;
              padding = defaultCalloutPadding;
              presentation = calloutBoxed; useColor = true): Callout =
  ## Concisely constructs a success callout.
  initCallout(body, calloutSuccess,
    if title.len == 0: none(string) else: some(title), width, padding,
    presentation, useColor = useColor)

proc withTitle*(callout: Callout; title: string): Callout =
  ## Returns a validated copy with contextual title text after its marker.
  result = callout
  result.title = some(title)
  result.validateCallout()

proc withWidth*(callout: Callout; cells: int): Callout =
  ## Returns a validated copy with a new complete outer width.
  result = callout
  result.width = initLayoutWidth(cells)
  result.validateCallout()

proc withPadding*(callout: Callout; padding: PanelPadding): Callout =
  ## Returns a validated copy with panel-compatible body padding.
  result = callout
  result.padding = padding
  result.validateCallout()

proc withPresentation*(callout: Callout;
                       presentation: CalloutPresentation): Callout =
  ## Returns a validated copy in boxed or compact presentation.
  result = callout
  result.presentation = presentation
  result.validateCallout()

proc withTheme*(callout: Callout; theme: CalloutTheme): Callout =
  ## Returns a validated copy using an explicit semantic palette.
  result = callout
  result.theme = theme
  result.validateCallout()

proc withOverflow*(callout: Callout; overflow: OverflowMode;
                   wrapMode = wrapWords): Callout =
  ## Returns a copy with panel-compatible overflow and wrapping behavior.
  result = callout
  result.overflow = overflow
  result.wrapMode = wrapMode

proc withColor*(callout: Callout; useColor: bool): Callout =
  ## Returns a validated copy enabling or disabling ANSI and theme styles.
  result = callout
  result.useColor = useColor
  result.validateCallout()

proc withLineEnding*(callout: Callout; lineEnding: string): Callout =
  ## Returns a validated copy using LF or CRLF between rendered rows.
  result = callout
  result.lineEnding = lineEnding
  result.validateCallout()

proc semanticHeading(callout: Callout): string =
  let semanticMarker = if callout.useColor:
    if callout.theme.icon.isSome: callout.theme.icon.get
    else: callout.theme.label
  else:
    callout.theme.plainMarker
  result = semanticMarker
  if callout.title.isSome and callout.title.get.len > 0:
    result.add " " & callout.title.get

proc renderCallout*(callout: Callout): string =
  ## Renders a boxed or compact callout without a trailing line ending.
  ##
  ## Boxed rendering delegates to ``renderPanel``. Compact rendering delegates
  ## width, padding, wrapping/truncation, and line endings to a borderless
  ## panel. Plain rendering always starts with ``theme.plainMarker`` and strips
  ## ANSI already present in the title and body.
  callout.validateCallout()

  if callout.presentation == calloutBoxed:
    let panel = initPanel(callout.body, callout.width.cellCount,
      title = some(semanticHeading(callout)), padding = callout.padding,
      theme = callout.theme.panelTheme,
      bodyStyle = callout.theme.bodyStyle,
      titleStyle = callout.theme.markerStyle,
      borderStyle = callout.theme.borderStyle,
      overflow = callout.overflow, wrapMode = callout.wrapMode,
      useColor = callout.useColor, lineEnding = callout.lineEnding)
    return renderPanel(panel)

  let
    rawHeading = semanticHeading(callout)
    heading = applyStyle(rawHeading, callout.theme.markerStyle,
      callout.useColor)
    bodyValue = if callout.useColor: callout.body else:
      stripAnsi(callout.body)
    styledBody = applyStyle(bodyValue, callout.theme.bodyStyle,
      callout.useColor)
    content = if callout.body.len == 0: heading else:
      heading & " " & styledBody
    panel = initPanel(content, callout.width.cellCount,
      padding = callout.padding, theme = borderlessPanelTheme,
      overflow = callout.overflow, wrapMode = callout.wrapMode,
      useColor = callout.useColor, lineEnding = callout.lineEnding)
  renderPanel(panel)

proc render*(callout: Callout): string =
  ## Convenience alias for ``renderCallout(callout)``.
  renderCallout(callout)

proc `$`*(callout: Callout): string =
  ## Renders the callout configuration without writing to an output stream.
  renderCallout(callout)
