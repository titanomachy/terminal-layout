## A complex, static TUI dashboard composed with TerminalLayout and
## TerminalStyle.
##
## TerminalLayout deliberately renders strings rather than owning the screen.
## This example shows how an application can arrange those rendered strings
## side by side with TerminalStyle's ANSI-aware measurement and padding.

# Run with: nim r --path:src examples/tui_showcase.nim

import std/[options, strutils]

# The TerminalLayout facade also re-exports TerminalStyle's color, styling,
# measurement, truncation, and padding APIs used throughout this example.
import terminal_layout

const
  dashboardWidth = 118
  sidebarWidth = 28
  telemetryWidth = 58
  activityWidth = 28
  columnGap = 2

proc columns(blocks: openArray[string]; widths: openArray[int];
             gap = columnGap): string =
  ## Places independently rendered blocks beside one another. TerminalStyle's
  ## cell-aware helpers keep ANSI, emoji, and wide Unicode aligned correctly.
  if blocks.len != widths.len:
    raise newException(ValueError, "every column needs an explicit width")
  if gap < 0:
    raise newException(ValueError, "column gap cannot be negative")

  var
    blockLines: seq[seq[string]]
    rowCount = 0
  for layoutBlock in blocks:
    let rows = splitLayoutLines(layoutBlock)
    blockLines.add rows
    rowCount = max(rowCount, rows.len)

  var output: seq[string]
  for rowIndex in 0 ..< rowCount:
    var row = ""
    for columnIndex in 0 ..< blocks.len:
      let cell = if rowIndex < blockLines[columnIndex].len:
        blockLines[columnIndex][rowIndex]
      else:
        ""
      if displayWidth(cell) > widths[columnIndex]:
        raise newException(ValueError, "rendered block exceeds its column")
      row.add padAnsi(cell, widths[columnIndex])
      if columnIndex < blocks.high:
        row.add repeat(' ', gap)
    output.add row
  joinLayoutLines(output)

proc stack(blocks: openArray[string]): string =
  blocks.join("\n")

proc bar(used, width: int; fillStyle, emptyStyle: TerminalStyle): string =
  let filled = clamp(used, 0, width)
  result.add applyStyle(repeat("█", filled), fillStyle)
  result.add applyStyle(repeat("░", width - filled), emptyStyle)

proc capacityLine(label: string; used: int; value: string;
                  fillStyle, mutedStyle: TerminalStyle): string =
  padAnsi(applyStyle(label, mutedStyle), 5) & " " &
    bar(used, 10, fillStyle, mutedStyle) & " " &
    padAnsi(applyStyle(value, fillStyle), 7, alignRight)

proc telemetryLine(label, samples, value: string;
                   sampleStyle, labelStyle, valueStyle: TerminalStyle): string =
  padAnsi(applyStyle(truncateAnsi(label, 9), labelStyle), 9) & " " &
    padAnsi(applyStyle(truncateAnsi(samples, 28), sampleStyle), 28) & " " &
    padAnsi(applyStyle(truncateAnsi(value, 15), valueStyle), 15, alignRight)

proc metricCard(title, value, delta: string; width: int;
                accentStyle, valueStyle, mutedStyle: TerminalStyle): string =
  initPanel(
    applyStyle(value, valueStyle) & "\n" & applyStyle(delta, mutedStyle),
    width = width,
    title = some(title),
    theme = roundedPanelTheme,
    borderStyle = accentStyle,
    titleStyle = accentStyle,
    contentAlignment = alignCenter).render()

let
  cyanColor = hexColor("#67E8F9")
  blueColor = hexColor("#60A5FA")
  violetColor = hexColor("#C084FC")
  greenColor = hexColor("#4ADE80")
  amberColor = hexColor("#FBBF24")
  slateColor = hexColor("#64748B")
  textColor = hexColor("#E2E8F0")

  cyanStyle = initTerminalStyle(foreground = cyanColor)
  cyanStrong = initTerminalStyle(foreground = cyanColor,
    attributes = {taBold})
  blueStyle = initTerminalStyle(foreground = blueColor)
  violetStyle = initTerminalStyle(foreground = violetColor)
  greenStyle = initTerminalStyle(foreground = greenColor)
  greenStrong = initTerminalStyle(foreground = greenColor,
    attributes = {taBold})
  amberStyle = initTerminalStyle(foreground = amberColor)
  mutedStyle = initTerminalStyle(foreground = slateColor, attributes = {taDim})
  textStyle = initTerminalStyle(foreground = textColor)
  valueStyle = initTerminalStyle(foreground = textColor,
    attributes = {taBold})
  titleStyle = initTerminalStyle(foreground = textColor,
    attributes = {taBold, taUnderline})
  footerStyle = initTerminalStyle(foreground = textColor,
    background = hexColor("#172033"))

  dashboardHeader = initBanner(
    "NEXUS // RELEASE CONTROL",
    subtitle = some("production  ·  eu-west-1  ·  live operations"),
    width = dashboardWidth,
    padding = initPanelPadding(right = 2, left = 2),
    theme = doubleBannerTheme,
    textStyle = titleStyle,
    fillStyle = violetStyle).render()

  workspaceTheme = initTreeTheme(
    roundedTreeTheme.glyphs,
    connectorStyle = blueStyle,
    labelStyle = textStyle,
    pruningStyle = amberStyle)

  workspace = tree("nexus-cloud",
    tree("production",
      tree("api-gateway  ●").withStyle(greenStyle),
      tree("billing      ●").withStyle(greenStyle),
      tree("workers",
        tree("mailer     ●").withStyle(greenStyle),
        tree("search     ◐").withStyle(amberStyle))),
    tree("staging",
      tree("canary       ●").withStyle(cyanStyle)),
    tree("replica  ●").withStyle(violetStyle))

  workspacePanel = initPanel(
    workspace.render(
      initTreeOptions(useColor = true).withWidth(sidebarWidth - 4),
      workspaceTheme),
    width = sidebarWidth,
    title = some("WORKSPACE"),
    footer = some("8 services"),
    theme = roundedPanelTheme,
    titleStyle = cyanStrong,
    footerStyle = mutedStyle,
    borderStyle = blueStyle).render()

  runbookItems = [
    listItem("Migrations locked").withTaskState(taskChecked),
    listItem("Smoke tests passed").withTaskState(taskChecked),
    listItem("Warm edge caches").withTaskState(taskIndeterminate),
    listItem("Promote canary").withTaskState(taskUnchecked)
  ]
  runbookTheme = initListTheme(
    unicodeLayoutGlyphs.list,
    markerStyle = violetStyle,
    bodyStyle = textStyle)
  runbookPanel = initPanel(
    taskList(runbookItems,
      initListOptions(useColor = true).withWidth(sidebarWidth - 4),
      runbookTheme),
    width = sidebarWidth,
    title = some("RUNBOOK"),
    theme = squarePanelTheme,
    titleStyle = violetStyle,
    borderStyle = initTerminalStyle(foreground = slateColor)).render()

  leftColumn = stack([workspacePanel, "", runbookPanel])

  requestCard = metricCard("REQUESTS", "18.4k", "↑ 12.8%", 17,
    cyanStyle, valueStyle, greenStyle)
  latencyCard = metricCard("P95 LATENCY", "82 ms", "↓ 18 ms", 17,
    violetStyle, valueStyle, greenStyle)
  errorCard = metricCard("ERROR RATE", "0.07%", "24h low", 18,
    greenStyle, valueStyle, mutedStyle)
  metricGrid = columns(
    [requestCard, latencyCard, errorCard], [17, 17, 18], gap = 1)

  telemetryChart = [
    telemetryLine("requests", "▁▂▂▃▄▅▆▅▇▆▇█▇▆▇▅▆▇▆▇", "18.4k / sec",
      cyanStyle, mutedStyle, valueStyle),
    telemetryLine("latency", "▆▅▄▅▃▂▃▂▂▁▂▂▃▂▁▂▁▂▂▁", "p95  82 ms",
      violetStyle, mutedStyle, valueStyle),
    telemetryLine("errors", "▁▁▁▂▁▁▁▁▂▁▁▁▁▁▁▁▂▁▁▁", "0.07 percent",
      greenStyle, mutedStyle, valueStyle),
    telemetryLine("saturation", "▂▃▄▃▄▅▅▆▅▆▇▆▅▅▄▅▆▅▄▃", "61 percent",
      amberStyle, mutedStyle, valueStyle)
  ].join("\n")

  regionBars = [
    telemetryLine("eu-west", bar(22, 28, cyanStyle, mutedStyle),
      "46% traffic", cyanStyle, mutedStyle, textStyle),
    telemetryLine("us-east", bar(17, 28, blueStyle, mutedStyle),
      "35% traffic", blueStyle, mutedStyle, textStyle),
    telemetryLine("ap-north", bar(9, 28, violetStyle, mutedStyle),
      "19% traffic", violetStyle, mutedStyle, textStyle)
  ].join("\n")

  telemetryPanel = initPanel(
    metricGrid & "\n\n" &
      applyStyle("LAST 60 SECONDS", cyanStrong) & "\n" & telemetryChart &
      "\n\n" & applyStyle("ROUTING", violetStyle) & "\n" & regionBars,
    width = telemetryWidth,
    title = some("LIVE TELEMETRY"),
    footer = some("updated 42 ms ago"),
    theme = heavyPanelTheme,
    titleStyle = cyanStrong,
    footerStyle = mutedStyle,
    borderStyle = cyanStyle).render()

  deploymentItems = [
    listItem("Artifact signed and replicated").withTaskState(taskChecked),
    listItem("Canary healthy across three regions").withTaskState(taskChecked),
    listItem("Progressive rollout at 72 percent").withTaskState(taskIndeterminate)
  ]
  deploymentTheme = customCalloutTheme(
    "SHIP", "[SHIP]",
    icon = some("◆"),
    panelTheme = roundedPanelTheme,
    markerStyle = greenStrong,
    bodyStyle = textStyle,
    borderStyle = greenStyle)
  deploymentCallout = initCallout(
    taskList(deploymentItems,
      initListOptions(useColor = true).withWidth(telemetryWidth - 4),
      initListTheme(unicodeLayoutGlyphs.list,
        markerStyle = greenStyle, bodyStyle = textStyle)),
    kind = calloutCustom,
    title = some("DEPLOYMENT #8472"),
    width = telemetryWidth,
    theme = some(deploymentTheme)).render()

  centerColumn = stack([telemetryPanel, "", deploymentCallout])

  activityItems = [
    listItem(applyStyle("12:42", cyanStyle) & " deploy #8472 started"),
    listItem(applyStyle("12:40", mutedStyle) & " image promoted"),
    listItem(applyStyle("12:37", violetStyle) & " 24 suites passed"),
    listItem(applyStyle("12:31", amberStyle) & " cache warming"),
    listItem(applyStyle("12:28", greenStyle) & " backup verified"),
    listItem(applyStyle("12:14", mutedStyle) & " config synchronized")
  ]
  activityPanel = initPanel(
    bulletList(activityItems,
      initListOptions(useColor = true).withWidth(activityWidth - 4),
      initListTheme(unicodeLayoutGlyphs.list,
        markerStyle = cyanStyle, bodyStyle = textStyle)),
    width = activityWidth,
    title = some("ACTIVITY"),
    theme = roundedPanelTheme,
    titleStyle = cyanStrong,
    borderStyle = blueStyle).render()

  capacityPanel = initPanel(
    [
      capacityLine("CPU", 6, "61%", cyanStyle, mutedStyle),
      capacityLine("MEM", 7, "73%", violetStyle, mutedStyle),
      capacityLine("DISK", 4, "38%", greenStyle, mutedStyle),
      capacityLine("EDGE", 9, "91%", amberStyle, mutedStyle)
    ].join("\n"),
    width = activityWidth,
    title = some("CAPACITY"),
    theme = squarePanelTheme,
    titleStyle = violetStyle,
    borderStyle = initTerminalStyle(foreground = slateColor)).render()

  certificateNotice = warning(
    "TLS certificate rotates automatically in 3d 8h.",
    title = "HEADS UP",
    width = activityWidth,
    presentation = calloutBoxed).render()

  rightColumn = stack([activityPanel, "", capacityPanel, "",
    certificateNotice])

  keyHints = "  " & applyStyle("[1]", cyanStrong) & " Overview   " &
    applyStyle("[2]", cyanStrong) & " Deployments   " &
    applyStyle("[3]", cyanStrong) & " Logs   " &
    applyStyle("[/]", violetStyle) & " Search   " &
    applyStyle("[?]", amberStyle) & " Help" &
    padAnsi(applyStyle("CONNECTED  ●", greenStrong), 30, alignRight)
  statusBar = applyStyle(padAnsi(keyHints, dashboardWidth), footerStyle)

  dashboard = [
    dashboardHeader,
    "",
    columns([leftColumn, centerColumn, rightColumn],
      [sidebarWidth, telemetryWidth, activityWidth]),
    "",
    statusBar
  ].join("\n")

const
  requestSparkline = "▁▂▂▃▄▅▆▅▇▆▇█▇▆▇▅▆▇▆▇"
  latencySparkline = "▆▅▄▅▃▂▃▂▂▁▂▂▃▂▁▂▁▂▂▁"
  errorSparkline = "▁▁▁▂▁▁▁▁▂▁▁▁▁▁▁▁▂▁▁▁"
  saturationSparkline = "▂▃▄▃▄▅▅▆▅▆▇▆▅▅▄▅▆▅▄▃"
  sparkGlyphs = ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
  sparklineWidth = 20
  requestSamples = [0, 1, 1, 2, 3, 4, 5, 4,
    6, 5, 6, 7, 6, 5, 6, 4]
  latencySamples = [5, 4, 3, 4, 2, 1, 2, 1,
    1, 0, 1, 1, 2, 1, 0, 1]
  errorSamples = [0, 0, 0, 1, 0, 0, 0, 0,
    1, 0, 0, 0, 0, 0, 0, 0]
  saturationSamples = [1, 2, 3, 2, 3, 4, 4, 5,
    4, 5, 6, 5, 4, 4, 3, 4]
  requestTenths = [4, 5, 7, 8, 9, 8, 7, 6,
    4, 3, 2, 1, 0, 1, 2, 3]
  latencyValues = [82, 81, 79, 78, 80, 83, 86, 88,
    87, 85, 83, 81, 80, 79, 80, 81]
  errorHundredths = [7, 6, 5, 5, 4, 5, 6, 8,
    9, 8, 7, 6, 5, 5, 6, 7]
  rolloutValues = [72, 74, 77, 80, 83, 86, 88, 87,
    85, 82, 79, 77, 75, 73, 72, 71]
  updateAges = [42, 31, 18, 7, 15, 24, 36, 48,
    39, 27, 16, 8, 14, 23, 33, 41]
  cpuPercentages = [61, 67, 74, 79, 83, 77, 70, 64,
    58, 53, 49, 51, 54, 57, 59, 60]
  memoryPercentages = [73, 75, 78, 82, 86, 89, 87, 84,
    81, 78, 75, 72, 70, 69, 70, 72]
  activityTimes = ["12:40", "12:41", "12:42", "12:43", "12:44",
    "12:45", "12:46", "12:47", "12:48"]
  activityMessages = ["config synchronized", "backup verified",
    "caches warmed", "24 suites completed", "image promoted",
    "deploy started", "canary probe healthy", "traffic shifted",
    "release promoted"]

proc rotatedSparkline(samples: openArray[int]; phase: int): string =
  for index in 0 ..< sparklineWidth:
    result.add sparkGlyphs[samples[(index + phase) mod samples.len]]

proc twoDigits(value: int): string =
  if value < 10:
    "0" & $value
  else:
    $value

proc renderDashboard*(frame: int): string =
  ## Returns a deterministic dashboard frame with simulated live telemetry.
  ## Negative frame numbers raise ``ValueError``. The result has no trailing
  ## line ending, does not mutate shared dashboard data, and keeps every
  ## non-empty row exactly 118 visible terminal cells wide.
  if frame < 0:
    raise newException(ValueError, "dashboard frame cannot be negative")

  let
    phase = frame mod requestTenths.len
    chartPhase = frame mod requestTenths.len
    activityPhase = phase div 4
    requestValue = "18." & $requestTenths[phase] & "k"
    latencyValue = $latencyValues[phase] & " ms"
    errorDigits = twoDigits(errorHundredths[phase])
    cpuPercentage = cpuPercentages[phase]
    memoryPercentage = memoryPercentages[phase]

  let activityStyles = [cyanStyle, mutedStyle, violetStyle, amberStyle,
    greenStyle, mutedStyle]
  var liveActivityItems: seq[ListItem]
  let newestActivity = 5 + activityPhase
  for offset in 0 ..< activityStyles.len:
    let eventIndex = newestActivity - offset
    liveActivityItems.add listItem(
      applyStyle(activityTimes[eventIndex], activityStyles[offset]) & " " &
        activityMessages[eventIndex])

  let
    liveActivityPanel = initPanel(
      bulletList(liveActivityItems,
        initListOptions(useColor = true).withWidth(activityWidth - 4),
        initListTheme(unicodeLayoutGlyphs.list,
          markerStyle = cyanStyle, bodyStyle = textStyle)),
      width = activityWidth,
      title = some("ACTIVITY"),
      theme = roundedPanelTheme,
      titleStyle = cyanStrong,
      borderStyle = blueStyle).render()
    liveCapacityPanel = initPanel(
      [
        capacityLine("CPU", (cpuPercentage + 5) div 10,
          $cpuPercentage & "%", cyanStyle, mutedStyle),
        capacityLine("MEM", (memoryPercentage + 5) div 10,
          $memoryPercentage & "%", violetStyle, mutedStyle),
        capacityLine("DISK", 4, "38%", greenStyle, mutedStyle),
        capacityLine("EDGE", 9, "91%", amberStyle, mutedStyle)
      ].join("\n"),
      width = activityWidth,
      title = some("CAPACITY"),
      theme = squarePanelTheme,
      titleStyle = violetStyle,
      borderStyle = initTerminalStyle(foreground = slateColor)).render()
    liveRightColumn = stack([liveActivityPanel, "", liveCapacityPanel, "",
      certificateNotice])

  result = [
    dashboardHeader,
    "",
    columns([leftColumn, centerColumn, liveRightColumn],
      [sidebarWidth, telemetryWidth, activityWidth]),
    "",
    statusBar
  ].join("\n")
  result = result.replace("18.4k", requestValue)
  result = result.replace("82 ms", latencyValue)
  result = result.replace("0.07%", "0." & errorDigits & "%")
  result = result.replace("0.07 percent", "0." & errorDigits & " percent")
  result = result.replace("72 percent", $rolloutValues[phase] & " percent")
  result = result.replace("updated 42 ms ago",
    "updated " & twoDigits(updateAges[phase]) & " ms ago")
  result = result.replace(requestSparkline,
    rotatedSparkline(requestSamples, chartPhase))
  result = result.replace(latencySparkline,
    rotatedSparkline(latencySamples, chartPhase))
  result = result.replace(errorSparkline,
    rotatedSparkline(errorSamples, chartPhase))
  result = result.replace(saturationSparkline,
    rotatedSparkline(saturationSamples, chartPhase))

  for line in splitLayoutLines(result):
    if line.len > 0:
      doAssert displayWidth(line) == dashboardWidth

# Every non-empty dashboard row occupies the same visible width even though
# the string contains ANSI controls and wide Unicode text.
for line in splitLayoutLines(dashboard):
  if line.len > 0:
    doAssert displayWidth(line) == dashboardWidth

when isMainModule:
  echo dashboard
