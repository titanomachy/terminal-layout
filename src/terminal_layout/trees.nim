## Generic tree models, themes, builders, and deterministic string rendering.
##
## Tree labels are arbitrary strings: paths, object keys, AST descriptions,
## and dependency names have no special behavior. Callers own traversal and
## data loading; this module only lays out the supplied value model.
##
## .. code-block:: nim
##
##   import terminal_layout
##
##   let project = tree("project",
##     tree("src", tree("main.nim"), tree("render.nim")),
##     tree("tests", tree("test_render.nim")))
##
##   echo project.render()

import std/[options, strutils]

import terminal_style

import ./[core, themes]

type
  TreeNode* = object
    ## One caller-defined label and its ordered child nodes.
    ##
    ## ``style`` overrides the theme label style for this node.
    ## ``connectorStyle`` overrides the theme style for the branch entering
    ## this node. A missing override inherits the corresponding theme style.
    label*: string
    children*: seq[TreeNode]
    style*: Option[TerminalStyle]
    connectorStyle*: Option[TerminalStyle]

  TreeTheme* = object
    ## Connector glyphs and independently applied tree styles.
    glyphs*: TreeGlyphs
    connectorStyle*: TerminalStyle
    labelStyle*: TerminalStyle
    pruningStyle*: TerminalStyle

  TreeOptions* = object
    ## Rendering choices shared by a complete tree or forest.
    ##
    ## ``indentation`` is the terminal-cell width of each connector column.
    ## ``width`` is an optional outer width for every output line. Visible
    ## top-level nodes have depth zero; ``maxDepth`` uses that same convention.
    showRoot*: bool
    indentation*: int
    width*: Option[LayoutWidth]
    maxDepth*: Option[int]
    pruneMarker*: string
    overflow*: OverflowMode
    wrapMode*: WrapMode
    useColor*: bool
    lineEnding*: string

const
  unicodeTreeTheme* = TreeTheme(glyphs: unicodeLayoutGlyphs.tree)
    ## Square Unicode connectors with no styles applied by default.

  asciiTreeTheme* = TreeTheme(glyphs: asciiLayoutGlyphs.tree)
    ## Portable seven-bit ASCII connectors.

  roundedTreeTheme* = TreeTheme(
    glyphs: TreeGlyphs(tee: "├", elbow: "╰", vertical: "│", horizontal: "─"))
    ## Unicode connectors with a rounded final branch.

  defaultTreeOptions* = TreeOptions(
    showRoot: true,
    indentation: 3,
    pruneMarker: "…",
    overflow: overflowWrap,
    wrapMode: wrapWords,
    useColor: true,
    lineEnding: defaultLineEnding)
    ## Valid defaults with no width or depth limit.

proc initTreeNode*(label: string;
                   style = none(TerminalStyle);
                   connectorStyle = none(TerminalStyle)): TreeNode =
  ## Constructs a leaf node with optional style overrides.
  TreeNode(label: label, style: style, connectorStyle: connectorStyle)

proc initTreeNode*(label: string; children: openArray[TreeNode];
                   style = none(TerminalStyle);
                   connectorStyle = none(TerminalStyle)): TreeNode =
  ## Constructs a node by copying an ordered child collection.
  TreeNode(label: label, children: @children, style: style,
    connectorStyle: connectorStyle)

proc tree*(label: string; children: varargs[TreeNode]): TreeNode =
  ## Concisely constructs nested tree literals.
  ##
  ## Use ``initTreeNode`` when the node also needs style overrides.
  initTreeNode(label, children)

proc withStyle*(node: TreeNode; style: TerminalStyle): TreeNode =
  ## Returns a copy with a node-level label-style override.
  result = node
  result.style = some(style)

proc withConnectorStyle*(node: TreeNode;
                         connectorStyle: TerminalStyle): TreeNode =
  ## Returns a copy with an incoming-connector style override.
  result = node
  result.connectorStyle = some(connectorStyle)

proc addChild*(node: var TreeNode; child: TreeNode) =
  ## Appends one already-constructed child while preserving insertion order.
  node.children.add child

proc addChild*(node: var TreeNode; label: string;
               style = none(TerminalStyle);
               connectorStyle = none(TerminalStyle)) =
  ## Constructs and appends one child label with optional style overrides.
  node.children.add initTreeNode(label, style, connectorStyle)

proc add*(node: var TreeNode; child: TreeNode) =
  ## Alias for ``addChild`` suited to incremental construction.
  node.addChild child

proc add*(node: var TreeNode; label: string;
          style = none(TerminalStyle);
          connectorStyle = none(TerminalStyle)) =
  ## Constructs and appends a child; alias for ``addChild``.
  node.addChild(label, style, connectorStyle)

proc initTreeTheme*(glyphs: TreeGlyphs;
                    connectorStyle = TerminalStyle();
                    labelStyle = TerminalStyle();
                    pruningStyle = TerminalStyle()): TreeTheme =
  ## Constructs and validates a custom tree theme.
  for (name, glyph) in [
      ("tree.tee", glyphs.tee),
      ("tree.elbow", glyphs.elbow),
      ("tree.vertical", glyphs.vertical),
      ("tree.horizontal", glyphs.horizontal)]:
    validateLayoutGlyph(glyph, name)
  TreeTheme(glyphs: glyphs, connectorStyle: connectorStyle,
    labelStyle: labelStyle, pruningStyle: pruningStyle)

proc customTreeTheme*(tee, elbow, vertical, horizontal: string;
                      connectorStyle = TerminalStyle();
                      labelStyle = TerminalStyle();
                      pruningStyle = TerminalStyle()): TreeTheme =
  ## Constructs a custom theme from four one-cell connector glyphs.
  initTreeTheme(TreeGlyphs(tee: tee, elbow: elbow, vertical: vertical,
    horizontal: horizontal), connectorStyle, labelStyle, pruningStyle)

proc validateTreeTheme*(theme: TreeTheme) =
  ## Raises ``ValueError`` if any connector is not exactly one plain cell.
  discard initTreeTheme(theme.glyphs, theme.connectorStyle, theme.labelStyle,
    theme.pruningStyle)

proc validateTreeOptions*(options: TreeOptions) =
  ## Validates dimensions, depth, pruning visibility, and line endings.
  if options.indentation <= 0:
    raise newException(ValueError, "tree indentation must be positive")
  if options.width.isSome:
    options.width.get.validateLayoutWidth()
  if options.maxDepth.isSome and options.maxDepth.get < 0:
    raise newException(ValueError, "maximum tree depth cannot be negative")
  if options.pruneMarker.contains('\n') or
      options.pruneMarker.contains('\r'):
    raise newException(ValueError, "tree pruning marker must be one line")
  if displayWidth(stripAnsi(options.pruneMarker)) == 0:
    raise newException(ValueError, "tree pruning marker must be visible")
  validateLineEnding(options.lineEnding)

proc initTreeOptions*(showRoot = true; indentation = 3;
                      width = none(LayoutWidth);
                      maxDepth = none(int);
                      pruneMarker = "…";
                      overflow = overflowWrap;
                      wrapMode = wrapWords;
                      useColor = true;
                      lineEnding = defaultLineEnding): TreeOptions =
  ## Constructs and validates tree rendering options.
  result = TreeOptions(showRoot: showRoot, indentation: indentation,
    width: width, maxDepth: maxDepth, pruneMarker: pruneMarker,
    overflow: overflow, wrapMode: wrapMode, useColor: useColor,
    lineEnding: lineEnding)
  result.validateTreeOptions()

proc withWidth*(options: TreeOptions; cells: int): TreeOptions =
  ## Returns validated options constrained to an outer terminal-cell width.
  result = options
  result.width = some(initLayoutWidth(cells))
  result.validateTreeOptions()

proc withMaxDepth*(options: TreeOptions; depth: int): TreeOptions =
  ## Returns validated options that visibly prune below ``depth``.
  result = options
  result.maxDepth = some(depth)
  result.validateTreeOptions()

proc effectiveStyle(override: Option[TerminalStyle];
                    fallback: TerminalStyle): TerminalStyle {.inline.} =
  if override.isSome: override.get else: fallback

proc logicalLines(value: string): seq[string] =
  ## Uses TerminalStyle's state-aware splitter so ANSI styles spanning an
  ## explicit newline are closed and restored on the resulting lines.
  wrapAnsi(value, max(1, displayWidth(value)), wrapCharacters)

proc labelLines(label: string; availableWidth: Option[int];
                options: TreeOptions): seq[string] =
  let value = if options.useColor: label else: stripAnsi(label)
  if availableWidth.isNone:
    return logicalLines(value)

  let width = availableWidth.get
  if width <= 0:
    raise newException(ValueError,
      "tree width leaves no cells available for a label")

  case options.overflow
  of overflowWrap:
    result = wrapAnsi(value, width, options.wrapMode)
    for line in result:
      if displayWidth(line) > width:
        raise newException(ValueError,
          "tree width cannot contain a complete label grapheme")
  of overflowTruncate:
    for line in logicalLines(value):
      result.add truncateAnsi(line, width)

proc renderTreeNodes(nodes: openArray[TreeNode]; options: TreeOptions;
                     theme: TreeTheme; connectTopLevel: bool): string =
  options.validateTreeOptions()
  theme.validateTreeTheme()

  var output: seq[string]

  proc styledConnector(value: string;
                       override = none(TerminalStyle)): string =
    applyStyle(value, effectiveStyle(override, theme.connectorStyle),
      options.useColor)

  proc ancestorPrefix(ancestors: openArray[bool]): string =
    for hasLaterSibling in ancestors:
      if hasLaterSibling:
        result.add styledConnector(theme.glyphs.vertical)
        result.add repeat(' ', options.indentation - 1)
      else:
        result.add repeat(' ', options.indentation)

  proc branchPrefix(isLast: bool;
                    connectorStyle: Option[TerminalStyle]): string =
    let join = if isLast: theme.glyphs.elbow else: theme.glyphs.tee
    var branch = join
    if options.indentation > 2:
      branch.add repeat(theme.glyphs.horizontal, options.indentation - 2)
    if options.indentation > 1:
      branch.add ' '
    styledConnector(branch, connectorStyle)

  proc renderNode(node: TreeNode; ancestors: seq[bool]; depth: int;
                  connected, isLast: bool) =
    let
      structuralWidth = ancestors.len * options.indentation +
        (if connected: options.indentation else: 0)
      availableWidth = if options.width.isSome:
        some(options.width.get.cellCount - structuralWidth)
      else:
        none(int)
      prefix = ancestorPrefix(ancestors)
      branch = if connected:
        branchPrefix(isLast, node.connectorStyle)
      else:
        ""
      continuation = prefix & repeat(' ',
        if connected: options.indentation else: 0)
      style = effectiveStyle(node.style, theme.labelStyle)
      lines = labelLines(node.label, availableWidth, options)

    for index, line in lines:
      let linePrefix = if index == 0: prefix & branch else: continuation
      output.add linePrefix & applyStyle(line, style, options.useColor)

    if node.children.len == 0:
      return

    if options.maxDepth.isSome and depth >= options.maxDepth.get:
      let marker = TreeNode(label: options.pruneMarker,
        style: some(theme.pruningStyle))
      var childAncestors = ancestors
      if connected:
        childAncestors.add not isLast
      renderNode(marker, childAncestors, depth + 1, true, true)
      return

    var childAncestors = ancestors
    if connected:
      childAncestors.add not isLast
    for index, child in node.children:
      renderNode(child, childAncestors, depth + 1, true,
        index == node.children.high)

  for index, node in nodes:
    renderNode(node, @[], 0, connectTopLevel, index == nodes.high)

  joinLayoutLines(output, options.lineEnding)

proc renderTree*(root: TreeNode; options = defaultTreeOptions;
                 theme = unicodeTreeTheme): string =
  ## Renders one tree without a connector before its visible root.
  ##
  ## With ``showRoot = false``, the root's children render as a connected
  ## top-level forest. The returned string never has an added trailing line
  ## ending.
  if options.showRoot:
    renderTreeNodes([root], options, theme, false)
  else:
    renderTreeNodes(root.children, options, theme, true)

proc renderTree*(forest: openArray[TreeNode];
                 options = defaultTreeOptions;
                 theme = unicodeTreeTheme): string =
  ## Renders an ordered forest with connectors before its top-level nodes.
  ##
  ## ``showRoot`` has no effect because a forest has no single root to hide.
  renderTreeNodes(forest, options, theme, true)

proc render*(root: TreeNode; options = defaultTreeOptions;
             theme = unicodeTreeTheme): string =
  ## Convenience alias for ``renderTree(root, options, theme)``.
  renderTree(root, options, theme)

proc render*(forest: openArray[TreeNode]; options = defaultTreeOptions;
             theme = unicodeTreeTheme): string =
  ## Convenience alias for ``renderTree(forest, options, theme)``.
  renderTree(forest, options, theme)

proc `$`*(root: TreeNode): string =
  ## Renders one tree with the default Unicode theme and options.
  renderTree(root)
