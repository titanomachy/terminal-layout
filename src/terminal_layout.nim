## Pure-Nim structural layout primitives for deterministic terminal output.
##
## Import this façade to access shared layout types, multiline helpers,
## Unicode and ASCII glyph presets, trees, panels/cards, lists/indentation,
## semantic callouts, non-semantic banners, and the complete
## ``terminal_style`` API. Importing TerminalLayout does not print, query the
## terminal, or mutate terminal state.
## Rendered component strings are intentionally composable: an outer panel,
## card, or callout preserves already-fitting child layout rows and may strip
## all nested ANSI by setting ``useColor = false``.
##
## .. code-block:: nim
##
##   import terminal_layout
##
##   let project = tree("project", tree("src"), tree("tests")).render()
##
##   echo initCard(project, width = 32, useColor = false)
##     .withTitle("Project").render()

import terminal_style
import terminal_layout/[banners, callouts, core, lists, panels, themes, trees]

export banners, callouts, core, lists, panels, terminal_style, themes, trees
