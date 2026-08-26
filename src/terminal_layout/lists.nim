## Bulleted, numbered, task, and recursively nested terminal lists.
##
## List rendering is output-only and preserves caller insertion order. Widths
## are optional complete outer widths in visible terminal cells. Wrapped and
## explicit continuation lines use hanging indentation under the item text.
##
## .. code-block:: nim
##
##   import terminal_layout
##
##   let steps = [
##     listItem("Install Nim"),
##     listItem("Run the tests", listItem("nimble test"))
##   ]
##
##   echo numberedList(steps)

import std/[options, strutils]

import terminal_style

import ./[core, themes]

type
  ListKind* = enum
    ## Marker family used for one sibling level.
    listBullets,
    listNumbers,
    listTasks

  TaskState* = enum
    ## Semantic state represented by a task-list marker in styled and plain
    ## output.
    taskUnchecked,
    taskChecked,
    taskIndeterminate

  ListItem* = object
    ## One text value and its ordered nested items.
    ##
    ## ``style`` overrides the theme body style for this item. ``taskState``
    ## is used when the containing level is a task list and defaults to
    ## ``taskUnchecked`` when absent. ``childKind`` changes only this item's
    ## nested level; absent values inherit the current level's kind.
    text*: string
    children*: seq[ListItem]
    style*: Option[TerminalStyle]
    taskState*: Option[TaskState]
    childKind*: Option[ListKind]

  ListTheme* = object
    ## One-cell bullet/task glyphs and independent marker/body styles.
    glyphs*: ListGlyphs
    markerStyle*: TerminalStyle
    bodyStyle*: TerminalStyle

  ListOptions* = object
    ## Rendering choices shared by a complete list.
    ##
    ## ``startingNumber`` is reused whenever a numbered nested level begins.
    ## ``indentation`` is the number of leading cells added for each nesting
    ## depth. ``width``, when present, is the maximum complete outer line
    ## width; renderers do not pad shorter lines to that width.
    kind*: ListKind
    startingNumber*: int
    delimiter*: string
    indentation*: int
    width*: Option[LayoutWidth]
    overflow*: OverflowMode
    wrapMode*: WrapMode
    useColor*: bool
    lineEnding*: string

const
  unicodeListTheme* = ListTheme(glyphs: unicodeLayoutGlyphs.list)
    ## Unicode bullet and semantic task markers with no default styles.

  asciiListTheme* = ListTheme(glyphs: asciiLayoutGlyphs.list)
    ## Portable seven-bit ASCII bullet and task markers.

  defaultListOptions* = ListOptions(
    kind: listBullets,
    startingNumber: 1,
    delimiter: ".",
    indentation: 2,
    overflow: overflowWrap,
    wrapMode: wrapWords,
    useColor: true,
    lineEnding: defaultLineEnding)
    ## Valid bullet-list defaults with no outer width constraint.

proc initListItem*(text: string;
                   style = none(TerminalStyle);
                   taskState = none(TaskState);
                   childKind = none(ListKind)): ListItem =
  ## Constructs a leaf item with optional style, task state, and nested kind.
  ListItem(text: text, style: style, taskState: taskState,
    childKind: childKind)

proc initListItem*(text: string; children: openArray[ListItem];
                   style = none(TerminalStyle);
                   taskState = none(TaskState);
                   childKind = none(ListKind)): ListItem =
  ## Constructs an item by copying an ordered child collection.
  ListItem(text: text, children: @children, style: style,
    taskState: taskState, childKind: childKind)

proc listItem*(text: string; children: varargs[ListItem]): ListItem =
  ## Concisely constructs nested list literals.
  ##
  ## Use ``initListItem`` when the item also needs a style, task state, or a
  ## different kind for its children.
  initListItem(text, children)

proc withStyle*(item: ListItem; style: TerminalStyle): ListItem =
  ## Returns a copy with an item-level body-style override.
  result = item
  result.style = some(style)

proc withTaskState*(item: ListItem; state: TaskState): ListItem =
  ## Returns a copy with an explicit semantic task state.
  result = item
  result.taskState = some(state)

proc withChildKind*(item: ListItem; kind: ListKind): ListItem =
  ## Returns a copy whose direct children use another marker family.
  result = item
  result.childKind = some(kind)

proc addChild*(item: var ListItem; child: ListItem) =
  ## Appends one already-constructed child while preserving insertion order.
  item.children.add child

proc addChild*(item: var ListItem; text: string;
               style = none(TerminalStyle);
               taskState = none(TaskState);
               childKind = none(ListKind)) =
  ## Constructs and appends one child with optional per-item configuration.
  item.children.add initListItem(text, style, taskState, childKind)

proc add*(item: var ListItem; child: ListItem) =
  ## Alias for ``addChild`` suited to incremental construction.
  item.addChild child

proc add*(item: var ListItem; text: string;
          style = none(TerminalStyle);
          taskState = none(TaskState);
          childKind = none(ListKind)) =
  ## Constructs and appends a child; alias for ``addChild``.
  item.addChild(text, style, taskState, childKind)

proc initListTheme*(glyphs: ListGlyphs;
                    markerStyle = TerminalStyle();
                    bodyStyle = TerminalStyle()): ListTheme =
  ## Constructs and validates a custom list theme.
  for (name, glyph) in [
      ("list.bullet", glyphs.bullet),
      ("list.unchecked", glyphs.unchecked),
      ("list.checked", glyphs.checked),
      ("list.indeterminate", glyphs.indeterminate)]:
    validateLayoutGlyph(glyph, name)
  ListTheme(glyphs: glyphs, markerStyle: markerStyle,
    bodyStyle: bodyStyle)

proc customListTheme*(bullet, unchecked, checked, indeterminate: string;
                      markerStyle = TerminalStyle();
                      bodyStyle = TerminalStyle()): ListTheme =
  ## Constructs a theme from four plain one-cell marker glyphs.
  initListTheme(ListGlyphs(bullet: bullet, unchecked: unchecked,
    checked: checked, indeterminate: indeterminate), markerStyle, bodyStyle)

proc validateListTheme*(theme: ListTheme) =
  ## Raises ``ValueError`` if any marker is not exactly one plain cell.
  discard initListTheme(theme.glyphs, theme.markerStyle, theme.bodyStyle)

proc validateListOptions*(options: ListOptions) =
  ## Validates numbering, delimiter, indentation, width, and line ending.
  if options.startingNumber <= 0:
    raise newException(ValueError, "list starting number must be positive")
  if options.delimiter.len == 0 or
      options.delimiter.contains('\n') or
      options.delimiter.contains('\r'):
    raise newException(ValueError,
      "list number delimiter must be visible and single-line")
  if options.delimiter.contains('\e') or
      stripAnsi(options.delimiter) != options.delimiter or
      displayWidth(options.delimiter) == 0:
    raise newException(ValueError,
      "list number delimiter must be plain and visible")
  if options.indentation < 0:
    raise newException(ValueError, "list indentation cannot be negative")
  if options.width.isSome:
    options.width.get.validateLayoutWidth()
  validateLineEnding(options.lineEnding)

proc initListOptions*(kind = listBullets;
                      startingNumber = 1;
                      delimiter = ".";
                      indentation = 2;
                      width = none(LayoutWidth);
                      overflow = overflowWrap;
                      wrapMode = wrapWords;
                      useColor = true;
                      lineEnding = defaultLineEnding): ListOptions =
  ## Constructs and validates list rendering options.
  result = ListOptions(kind: kind, startingNumber: startingNumber,
    delimiter: delimiter, indentation: indentation, width: width,
    overflow: overflow, wrapMode: wrapMode, useColor: useColor,
    lineEnding: lineEnding)
  result.validateListOptions()

proc withWidth*(options: ListOptions; cells: int): ListOptions =
  ## Returns validated options constrained to a maximum outer line width.
  result = options
  result.width = some(initLayoutWidth(cells))
  result.validateListOptions()

proc withKind*(options: ListOptions; kind: ListKind): ListOptions =
  ## Returns a copy using another marker family at the top level.
  result = options
  result.kind = kind

proc withStartingNumber*(options: ListOptions;
                         startingNumber: int): ListOptions =
  ## Returns validated options using another first ordered-list number.
  result = options
  result.startingNumber = startingNumber
  result.validateListOptions()

proc withDelimiter*(options: ListOptions; delimiter: string): ListOptions =
  ## Returns validated options using another ordered-marker delimiter.
  result = options
  result.delimiter = delimiter
  result.validateListOptions()

proc withIndentation*(options: ListOptions;
                      indentation: int): ListOptions =
  ## Returns validated options using another per-depth indentation.
  result = options
  result.indentation = indentation
  result.validateListOptions()

proc withOverflow*(options: ListOptions; overflow: OverflowMode;
                   wrapMode = wrapWords): ListOptions =
  ## Returns a copy with new text overflow and wrapping behavior.
  result = options
  result.overflow = overflow
  result.wrapMode = wrapMode

proc withColor*(options: ListOptions; useColor: bool): ListOptions =
  ## Returns a copy that enables or disables input and component ANSI styling.
  result = options
  result.useColor = useColor

proc withLineEnding*(options: ListOptions;
                     lineEnding: string): ListOptions =
  ## Returns validated options using LF or CRLF between rendered rows.
  result = options
  result.lineEnding = lineEnding
  result.validateListOptions()

proc effectiveStyle(override: Option[TerminalStyle];
                    fallback: TerminalStyle): TerminalStyle {.inline.} =
  if override.isSome: override.get else: fallback

proc logicalLines(value: string): seq[string] =
  # TerminalStyle closes and restores active ANSI state around explicit line
  # boundaries while retaining empty and trailing logical lines.
  wrapAnsi(value, max(1, displayWidth(value)), wrapCharacters)

proc markerFor(item: ListItem; kind: ListKind; ordinal: int;
               options: ListOptions; theme: ListTheme): string =
  case kind
  of listBullets:
    theme.glyphs.bullet
  of listNumbers:
    $(options.startingNumber + ordinal) & options.delimiter
  of listTasks:
    case item.taskState.get(taskUnchecked)
    of taskUnchecked:
      theme.glyphs.unchecked
    of taskChecked:
      theme.glyphs.checked
    of taskIndeterminate:
      theme.glyphs.indeterminate

proc fittedLines(value: string; width: Option[int];
                 options: ListOptions): seq[string] =
  if width.isNone:
    return logicalLines(value)

  let available = width.get
  if available <= 0:
    if displayWidth(value) == 0:
      return logicalLines(value)
    raise newException(ValueError,
      "list width leaves no cells available for item text")

  case options.overflow
  of overflowWrap:
    result = wrapAnsi(value, available, options.wrapMode)
    for line in result:
      if displayWidth(line) > available:
        raise newException(ValueError,
          "list width cannot contain a complete item grapheme")
  of overflowTruncate:
    for line in logicalLines(value):
      result.add truncateAnsi(line, available)

proc renderList*(items: openArray[ListItem];
                 options = defaultListOptions;
                 theme = unicodeListTheme): string =
  ## Renders ordered items without padding or an added trailing line ending.
  ##
  ## Each sibling group reserves the width of its widest marker, so ordered
  ## markers remain right-aligned and every item body starts in the same text
  ## column when numbering gains digits. Nested levels inherit their parent's
  ## kind unless the parent item has ``childKind`` set. Rendering validates
  ## public fields and does not mutate the supplied items.
  options.validateListOptions()
  theme.validateListTheme()

  var output: seq[string]

  proc renderLevel(levelItems: openArray[ListItem]; kind: ListKind;
                   depth: int) =
    if levelItems.len == 0:
      return

    var markers = newSeq[string](levelItems.len)
    var markerWidth = 0
    for index, item in levelItems:
      markers[index] = markerFor(item, kind, index, options, theme)
      markerWidth = max(markerWidth, displayWidth(markers[index]))

    let leadingWidth = depth * options.indentation
    if options.width.isSome and
        leadingWidth + markerWidth > options.width.get.cellCount:
      raise newException(ValueError,
        "list width cannot contain the marker at this nesting depth")
    for index, item in levelItems:
      let
        marker = markers[index]
        markerPadding = repeat(' ', markerWidth - displayWidth(marker))
        rawText = if options.useColor: item.text else: stripAnsi(item.text)
        availableWidth = if options.width.isSome:
          some(options.width.get.cellCount - leadingWidth - markerWidth - 1)
        else:
          none(int)
        lines = fittedLines(rawText, availableWidth, options)
        bodyStyle = effectiveStyle(item.style, theme.bodyStyle)
        leading = repeat(' ', leadingWidth)
        hanging = leading & repeat(' ', markerWidth + 1)

      for lineIndex, line in lines:
        if lineIndex == 0:
          let styledMarker = applyStyle(marker, theme.markerStyle,
            options.useColor)
          output.add leading & markerPadding & styledMarker &
            (if displayWidth(line) > 0:
              " " & applyStyle(line, bodyStyle, options.useColor)
            else:
              "")
        elif displayWidth(line) > 0:
          output.add hanging & applyStyle(line, bodyStyle, options.useColor)
        else:
          output.add ""

      let nestedKind = item.childKind.get(kind)
      renderLevel(item.children, nestedKind, depth + 1)

  renderLevel(items, options.kind, 0)
  joinLayoutLines(output, options.lineEnding)

proc bulletList*(items: openArray[ListItem];
                 options = defaultListOptions;
                 theme = unicodeListTheme): string =
  ## Renders items as bullets, overriding only the top-level option kind.
  renderList(items, options.withKind(listBullets), theme)

proc numberedList*(items: openArray[ListItem];
                   options = defaultListOptions;
                   theme = unicodeListTheme): string =
  ## Renders items as numbers, overriding only the top-level option kind.
  renderList(items, options.withKind(listNumbers), theme)

proc taskList*(items: openArray[ListItem];
               options = defaultListOptions;
               theme = unicodeListTheme): string =
  ## Renders items as semantic tasks, defaulting missing states to unchecked.
  renderList(items, options.withKind(listTasks), theme)

proc toListItems(texts: openArray[string]): seq[ListItem] =
  for value in texts:
    result.add initListItem(value)

proc bulletList*(texts: varargs[string]): string =
  ## Concisely renders plain strings with default Unicode bullet options.
  bulletList(toListItems(texts))

proc numberedList*(texts: varargs[string]): string =
  ## Concisely renders plain strings with default numbered-list options.
  numberedList(toListItems(texts))

proc taskList*(texts: varargs[string]): string =
  ## Concisely renders plain strings as unchecked tasks with default options.
  taskList(toListItems(texts))

proc indent*(value: string; amount: int;
             useColor = true;
             lineEnding = defaultLineEnding): string =
  ## Prefixes every logical line with ``amount`` blank terminal cells.
  ##
  ## ANSI state spanning explicit newlines is safely closed and restored.
  ## Plain mode strips existing controls. LF and CRLF input is normalized to
  ## the selected validated output separator without appending another line.
  if amount < 0:
    raise newException(ValueError, "indentation amount cannot be negative")
  validateLineEnding(lineEnding)
  let
    content = if useColor: value else: stripAnsi(value)
    prefix = repeat(' ', amount)
  var output: seq[string]
  for line in logicalLines(content):
    output.add prefix & line
  joinLayoutLines(output, lineEnding)
