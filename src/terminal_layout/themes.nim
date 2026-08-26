## Component-neutral glyph sets used to build TerminalLayout themes.
##
## The presets keep structural characters in one place. Every field is one
## visible terminal cell, allowing renderers to measure borders, connectors,
## markers, semantic symbols, and banner rules consistently.

import terminal_style

type
  BorderGlyphs* = object
    ## One-cell corner and rule glyphs for bordered components.
    topLeft*, topRight*, bottomLeft*, bottomRight*: string
    horizontal*, vertical*: string

  TreeGlyphs* = object
    ## One-cell branch glyphs for hierarchy connectors.
    tee*, elbow*, vertical*, horizontal*: string

  ListGlyphs* = object
    ## One-cell markers for bullets and each task-list state.
    bullet*, unchecked*, checked*, indeterminate*: string

  CalloutGlyphs* = object
    ## One-cell semantic markers for callout variants.
    info*, warning*, failure*, success*: string

  BannerGlyphs* = object
    ## One-cell rule glyph used to fill banner headings.
    horizontal*: string

  LayoutGlyphs* = object
    ## Complete component-neutral glyph vocabulary for one rendering family.
    border*: BorderGlyphs
    tree*: TreeGlyphs
    list*: ListGlyphs
    callout*: CalloutGlyphs
    banner*: BannerGlyphs

const
  unicodeLayoutGlyphs* = LayoutGlyphs(
    border: BorderGlyphs(
      topLeft: "┌", topRight: "┐", bottomLeft: "└", bottomRight: "┘",
      horizontal: "─", vertical: "│"),
    tree: TreeGlyphs(tee: "├", elbow: "└", vertical: "│", horizontal: "─"),
    list: ListGlyphs(bullet: "•", unchecked: "☐", checked: "☑",
      indeterminate: "◐"),
    callout: CalloutGlyphs(info: "ℹ", warning: "⚠", failure: "×",
      success: "✓"),
    banner: BannerGlyphs(horizontal: "─"))
    ## Unicode box-drawing, list, semantic, and banner glyphs.

  asciiLayoutGlyphs* = LayoutGlyphs(
    border: BorderGlyphs(
      topLeft: "+", topRight: "+", bottomLeft: "+", bottomRight: "+",
      horizontal: "-", vertical: "|"),
    tree: TreeGlyphs(tee: "+", elbow: "`", vertical: "|", horizontal: "-"),
    list: ListGlyphs(bullet: "*", unchecked: "o", checked: "x",
      indeterminate: "-"),
    callout: CalloutGlyphs(info: "i", warning: "!", failure: "x",
      success: "+"),
    banner: BannerGlyphs(horizontal: "="))
    ## Portable fallback using only seven-bit ASCII characters.

proc validateLayoutGlyph*(glyph: string; name = "layout glyph") =
  ## Validates a plain glyph that occupies exactly one terminal cell.
  ##
  ## ANSI controls and line breaks are rejected because component styles and
  ## multiline layout are handled separately.
  if glyph.contains('\n') or glyph.contains('\r'):
    raise newException(ValueError, name & " cannot contain a line ending")
  if glyph.contains('\e') or stripAnsi(glyph) != glyph:
    raise newException(ValueError, name & " cannot contain ANSI controls")
  if displayWidth(glyph) != 1 or sliceAnsi(glyph, 0, 1) != glyph:
    raise newException(ValueError, name & " must occupy exactly one cell")

proc validateLayoutGlyphs*(glyphs: LayoutGlyphs) =
  ## Validates every field in a complete layout glyph set.
  for (name, glyph) in [
      ("border.topLeft", glyphs.border.topLeft),
      ("border.topRight", glyphs.border.topRight),
      ("border.bottomLeft", glyphs.border.bottomLeft),
      ("border.bottomRight", glyphs.border.bottomRight),
      ("border.horizontal", glyphs.border.horizontal),
      ("border.vertical", glyphs.border.vertical),
      ("tree.tee", glyphs.tree.tee),
      ("tree.elbow", glyphs.tree.elbow),
      ("tree.vertical", glyphs.tree.vertical),
      ("tree.horizontal", glyphs.tree.horizontal),
      ("list.bullet", glyphs.list.bullet),
      ("list.unchecked", glyphs.list.unchecked),
      ("list.checked", glyphs.list.checked),
      ("list.indeterminate", glyphs.list.indeterminate),
      ("callout.info", glyphs.callout.info),
      ("callout.warning", glyphs.callout.warning),
      ("callout.failure", glyphs.callout.failure),
      ("callout.success", glyphs.callout.success),
      ("banner.horizontal", glyphs.banner.horizontal)]:
    validateLayoutGlyph(glyph, name)
