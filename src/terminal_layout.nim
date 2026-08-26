## Pure-Nim structural layout primitives for deterministic terminal output.
##
## Import this façade to access shared layout types, multiline helpers,
## Unicode and ASCII glyph presets, trees, panels/cards, lists/indentation,
## semantic callouts, the stable banner namespace, and the complete
## ``terminal_style`` API. Importing TerminalLayout does not print, query the
## terminal, or mutate terminal state.
##
## .. code-block:: nim
##
##   import terminal_layout
##
##   let project = tree("project", tree("src"), tree("tests"))
##
##   echo initCard(project.render(), width = 32)
##     .withTitle("Project").render()

import terminal_style
import terminal_layout/[banners, callouts, core, lists, panels, themes, trees]

export banners, callouts, core, lists, panels, terminal_style, themes, trees
