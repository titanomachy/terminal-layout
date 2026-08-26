## Shared text fixtures for every TerminalLayout component test suite.
##
## Keeping these edge cases in one module makes later tree, panel, list,
## callout, banner, and composition tests exercise the same inputs.

const
  fixtureAnsi* = "\e[31mred\e[0m"
  fixtureCjk* = "界"
  fixtureCombining* = "e\u0301"
  fixtureEmoji* = "👨‍👩‍👧‍👦"
  fixtureEmpty* = ""
  fixtureMultiline* = "first\n\nthird"
  fixtureCrlf* = "first\r\n\r\nthird\r\n"

