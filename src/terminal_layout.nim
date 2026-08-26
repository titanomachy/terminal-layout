## Pure-Nim structural layout primitives for deterministic terminal output.
##
## Import this façade to access shared layout types, multiline helpers,
## Unicode and ASCII glyph presets, the component namespaces, and the complete
## ``terminal_style`` API. Importing TerminalLayout does not print, query the
## terminal, or mutate terminal state.
##
## .. code-block:: nim
##
##   import terminal_layout
##
##   let project = tree("project",
##     tree("src", tree("main.nim"), tree("render.nim")),
##     tree("tests", tree("test_render.nim")))
##
##   echo project.render(theme = roundedTreeTheme)

import terminal_style
import terminal_layout/[banners, callouts, core, lists, panels, themes, trees]

export banners, callouts, core, lists, panels, terminal_style, themes, trees
