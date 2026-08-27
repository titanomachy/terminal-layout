## Compact and boxed semantic status reporting.

# Run with: nim r --path:src examples/callouts.nim

import terminal_layout

let checks = taskList([
  listItem("Compile").withTaskState(taskChecked),
  listItem("Test").withTaskState(taskChecked),
  listItem("Publish").withTaskState(taskUnchecked)
], initListOptions(useColor = false))

when isMainModule:
  echo warning("Disk usage is above 80%", width = 34,
    presentation = calloutCompact, useColor = false).render()
  echo ""
  echo success(checks, title = "Checks", width = 34,
    useColor = false).render()
