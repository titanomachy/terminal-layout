## List, checklist, nested navigation, and generic indentation examples.

when compiles((block:
  import terminal_layout
)):
  import terminal_layout
else:
  import ../src/terminal_layout

let
  checklist = [
    listItem("Review changes").withTaskState(taskChecked),
    listItem("Run tests").withTaskState(taskChecked),
    listItem("Publish package").withTaskState(taskUnchecked)
  ]

  procedure = [
    listItem("Install Nim"),
    listItem("Run nimble install"),
    listItem("Import terminal_layout")
  ]

  navigation = [
    listItem("Project",
      listItem("src", listItem("terminal_layout.nim")),
      listItem("tests", listItem("test_lists.nim"))
    ).withChildKind(listNumbers),
    listItem("Documentation")
  ]

  renderedChecklist = taskList(checklist,
    initListOptions(useColor = false))
  renderedProcedure = numberedList(procedure,
    initListOptions(startingNumber = 3, delimiter = ")", useColor = false))
  renderedNavigation = bulletList(navigation,
    initListOptions(indentation = 3, useColor = false), asciiListTheme)
  indentedSummary = indent("Lists ready\nNo output side effects", 4,
    useColor = false)

when isMainModule:
  echo renderedChecklist
  echo ""
  echo renderedProcedure
  echo ""
  echo renderedNavigation
  echo ""
  echo indentedSummary
