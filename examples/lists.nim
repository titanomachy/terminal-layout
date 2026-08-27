## A nested release checklist.

import terminal_layout

let
  release = [
    listItem("Release",
      listItem("Review changes").withTaskState(taskChecked),
      listItem("Run tests").withTaskState(taskChecked),
      listItem("Publish package").withTaskState(taskUnchecked)
    ).withChildKind(listTasks)
  ]

when isMainModule:
  echo bulletList(release, initListOptions(useColor = false))
