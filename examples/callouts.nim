## Semantic status reporting with boxed, compact, and custom callouts.

import std/[options, strutils]

import terminal_layout

let checks = taskList([
  listItem("Compile").withTaskState(taskChecked),
  listItem("Test").withTaskState(taskChecked),
  listItem("Publish").withTaskState(taskUnchecked)
], initListOptions(useColor = false))

let report = @[
  info("Deployment started", title = "Release", width = 34).render(),
  warning("Disk usage is above 80%", width = 34,
    presentation = calloutCompact).render(),
  failure("Integration test failed", title = "CI", width = 34).render(),
  success(checks, title = "Checks", width = 34,
    useColor = false).render()
]

let noteTheme = customCalloutTheme(
  "NOTE", "[NOTE]",
  icon = some("!"),
  panelTheme = asciiPanelTheme,
  markerStyle = initTerminalStyle(foreground = colorMagenta,
    attributes = {taBold}),
  borderStyle = initTerminalStyle(foreground = colorMagenta))

let custom = initCallout(
  "Maintenance begins at 22:00",
  kind = calloutCustom,
  width = 34,
  theme = some(noteTheme)).render()

# Rendering is ordinary string production. Applications decide whether these
# values go to stdout, a file, a UI buffer, or another layout component.
echo (report & @[custom]).join("\n\n")
