# Package

version       = "0.1.0"
author        = "titanomachy"
description   = "Trees, Panels, Cards, Banners, Callouts, Bullet lists"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.0"
requires "terminal_style >= 0.1.1"

task test, "Run the terminal_layout test suite":
  exec "nim r --path:src tests/test_core.nim"
  exec "nim r --path:src tests/test_trees.nim"
  exec "nim r --path:src tests/test_panels.nim"
  exec "nim r --path:src tests/test_lists.nim"
  exec "nim r --path:src tests/test_callouts.nim"
  exec "nim r --hints:off --warnings:off --path:src tests/import_probe.nim"

task examples, "Check that all examples compile":
  exec "nim check --path:src examples/foundation.nim"
  exec "nim check --path:src examples/trees.nim"
  exec "nim check --path:src examples/panels.nim"
  exec "nim check --path:src examples/lists.nim"
  exec "nim check --path:src examples/callouts.nim"

task docs, "Generate terminal_layout API documentation":
  exec "nim doc --project --index:on --outdir:htmldocs --path:src src/terminal_layout.nim"
  exec "nim buildIndex --out:htmldocs/theindex.html htmldocs"
  exec "nim md2html --out:htmldocs/index.html docs/api-index.md"
