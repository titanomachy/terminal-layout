## A simulated streaming version of the full TerminalLayout TUI showcase.
##
## The dashboard data is deterministic and requires no network service. This
## entry point owns terminal refresh behavior while TerminalLayout and
## TerminalStyle continue to produce output-only strings.

# Run with: nim r --path:src examples/streaming_tui_showcase.nim

import std/[atomics, os]
import tui_showcase

const
  frameDelayMs = 180
  recordingFrameCount = 32
  enterAlternateScreen = "\e[?1049h\e[?25l"
  leaveAlternateScreen = "\e[0m\e[?25h\e[?1049l"
  moveHome = "\e[H"
  clearRemainder = "\e[J"

var keepRunning: Atomic[bool]

proc stopStreaming() {.noconv.} =
  keepRunning.store(false, moRelaxed)

proc streamDashboard(frameLimit = 0) =
  keepRunning.store(true, moRelaxed)
  setControlCHook(stopStreaming)

  try:
    stdout.write enterAlternateScreen
    stdout.flushFile()

    var frame = 0
    while keepRunning.load(moRelaxed) and
        (frameLimit == 0 or frame < frameLimit):
      stdout.write moveHome
      stdout.write renderDashboard(frame div 2)
      stdout.write clearRemainder
      stdout.flushFile()
      sleep frameDelayMs
      inc frame
  finally:
    stdout.write leaveAlternateScreen
    stdout.flushFile()
    when declared(unsetControlCHook):
      unsetControlCHook()

when isMainModule:
  let frameLimit =
    if "--once" in commandLineParams(): recordingFrameCount
    else: 0
  streamDashboard(frameLimit)
