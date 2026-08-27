## Minimal report showing the normal construct, render, and compose workflow.

# Run with: nim r --path:src examples/quick_start.nim

import terminal_layout

let
  checks = [
    listItem("Compile").withTaskState(taskChecked),
    listItem("Run tests").withTaskState(taskChecked),
    listItem("Publish").withTaskState(taskUnchecked)
  ]
  checklist = taskList(checks, initListOptions(useColor = false))
  renderedReport = success(checklist, title = "Release", width = 32,
    useColor = false).render()

when isMainModule:
  echo renderedReport
