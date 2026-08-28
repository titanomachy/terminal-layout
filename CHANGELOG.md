# Changelog

This project follows Semantic Versioning.

## v0.1.1 - 2026-08-28

### Added

- Publish the generated API documentation and a CI-generated line-coverage
  percentage badge through GitHub Pages.

### Changed

- Replace the README workflow-status badge with the published coverage badge.
- Align status markers in the TUI showcase workspace tree and refresh its
  static screenshot, animated preview, and deterministic terminal recording.
- Present the README requirements as a clearer list.

## v0.1.0 - 2026-08-27

### Added

- Add static and simulated-streaming RGB release-control TUI showcases with a
  three-column compositor, nested component rendering, exact-width checks, a
  locally recorded animated README preview, changing telemetry and capacity
  bars, incoming activity events, API documentation guidance, and example
  compilation coverage.
- Add exact rendered-output images to the README component sections and
  streamline the landing page and standalone examples for new users.
- Add a release-oriented README quick start, component gallery, stable-defaults
  reference, TerminalStyle customization guide, dependency rationale,
  interoperability diagram, module map, development guidance, and explicit
  deferred-scope section.
- Add standalone quick-start, TerminalStyle customization, and string-based
  TerminalTable/TerminalGraph interoperability examples and register them in
  the example compilation task.
- Add a focused public release-contract suite covering façade construction and
  composition, documented defaults, TerminalStyle re-exports, visible-cell
  behavior, plain rendering, and LF/CRLF output without trailing separators.
- Add `CONTRIBUTING.md`, `RELEASING.md`, and `THIRD_PARTY_NOTICES.md` following
  the terminal-suite conventions and tailored to TerminalLayout's rendering
  and dependency contracts.
- Add a `releaseCheck` Nimble task that runs package validation, the full test
  suite, every example check, and generated documentation.
- Add Phase 7 API landing-page guidance and expanded Nim-generated module
  comments for outer widths, line endings, input immutability, glyph styling,
  and output-only behavior.
- Add `terminal_style >= 0.1.1` as the shared ANSI styling and Unicode
  terminal-cell layout dependency.
- Add a side-effect-free `terminal_layout` façade that exports every stable
  component module and the complete TerminalStyle API.
- Add stable `trees`, `panels`, `lists`, `callouts`, and `banners` module
  skeletons for the component phases.
- Add a validated positive `LayoutWidth`, non-negative `LayoutInsets`, and
  explicit wrap/truncate `OverflowMode` foundation types.
- Add CRLF-aware multiline splitting, validated LF/CRLF joining, and line
  ending normalization that preserves empty and trailing lines.
- Add centralized one-cell border, tree, list, callout, and banner glyph types
  with named Unicode and seven-bit ASCII presets.
- Add validation for invalid widths, insets, line endings, multiline edge
  cases, ANSI-bearing glyphs, and glyph display widths.
- Add reusable ANSI, CJK, combining-mark, emoji, empty-string, multiline, and
  CRLF fixtures for all later component tests.
- Add an import probe covering the façade and each stable submodule without
  runtime output or side effects.
- Add a minimal façade example, generated API documentation index, and Nim doc
  comments for every public foundation type, preset, and helper.
- Add `test`, `examples`, and `docs` Nimble tasks following the TerminalStyle,
  TerminalTable, and TerminalGraph suite conventions.
- Ignore Nim compiler caches, generated API documentation, locally compiled
  test/example executables, and Nimble development metadata.
- Document the package scope, foundation API, rendering contract, module
  boundaries, development tasks, and dependency requirements in the README.
- Add a recursive `TreeNode` value model with ordered children plus optional
  node-level label and incoming-connector style overrides.
- Add concise `tree` literals, `initTreeNode` constructors, immutable style
  modifiers, and incremental `add`/`addChild` builders.
- Add `TreeTheme` with square Unicode, rounded Unicode, ASCII, and validated
  custom connector presets plus independent connector, label, and pruning
  styles.
- Add validated `TreeOptions` for root visibility, connector-column
  indentation, optional outer width and maximum depth, pruning markers,
  wrapping or truncation, wrapping mode, color, and LF/CRLF output.
- Add deterministic rendering for one root or an ordered forest through
  `renderTree`, `render`, and `$` conveniences.
- Add sibling-aware tee, elbow, vertical-continuation, and blank-prefix layout
  with hanging indentation for explicit and wrapped continuation lines.
- Add visible depth pruning, ANSI-aware wrapping and truncation, Unicode-cell
  width enforcement, and plain rendering that strips existing ANSI controls.
- Add tree snapshots covering single, deep, wide, forest, hidden-root,
  multiline, empty-label, pruned, Unicode, ASCII, rounded, custom, styled, and
  plain output.
- Add validation and contract tests for stable ordering, exact CJK/combining/
  emoji widths, reset boundaries, CRLF output, invalid dimensions and glyphs,
  unrepresentable graphemes, and the no-added-trailing-line-ending rule.
- Add manual directory, JSON-like, and dependency hierarchy examples without
  filesystem or parser dependencies.
- Add tree API guidance and rendering semantics to the README, façade docs,
  generated API index, and public Nim doc comments.
- Include the tree tests and example in the package Nimble tasks and generated
  executable ignore rules.
- Add a reusable `Panel` value model with optional single-line title and footer,
  independent body/title/footer/border styles, body and label alignments,
  validated outer width, overflow behavior, color control, and LF/CRLF output.
- Add validated `PanelPadding`, immutable panel configuration helpers, and
  `initPanel`, `renderPanel`, `render`, and `$` entry points.
- Add `initCard` and `card` conveniences that return the same `Panel` model with
  rounded borders and one-cell padding on every side.
- Add square, rounded, heavy, double, ASCII, borderless, and validated custom
  panel themes.
- Add terminal-cell-aware panel geometry, ANSI-safe wrapping and truncation,
  complete-row padding, deterministic empty bodies and asymmetric padding,
  and plain rendering that strips existing ANSI controls.
- Add independently aligned title/footer border labels with preserved corners,
  documented separator spacing, and grapheme-safe collision truncation.
- Add panel snapshots and contract tests covering every preset, cards, all
  alignments, padding, empty/multiline/nested bodies, CJK, combining marks,
  emoji, ANSI styles, plain output, CRLF, exact widths, and invalid inputs.
- Add a panel composition example using representative TerminalTable and
  TerminalGraph output strings plus a rendered tree, without new production
  dependencies.
- Add panel/card user guidance, generated API documentation prose, and Nim doc
  comments for every public panel type, preset, constructor, helper,
  validator, and renderer.
- Include the panel test and example in the package Nimble tasks and generated
  executable ignore rules.
- Add a recursive `ListItem` value model with ordered children, optional body
  style and task state, and explicit nested-level `ListKind` overrides.
- Add `ListKind` bullet, number, and task variants plus unchecked, checked, and
  indeterminate semantic `TaskState` values.
- Add concise `listItem` literals, copying constructors, immutable style/task/
  child-kind modifiers, and incremental `add`/`addChild` builders.
- Add validated `ListOptions` for the starting number, plain visible delimiter,
  per-depth indentation, optional maximum outer width, wrap/truncate behavior,
  wrapping mode, color, and LF/CRLF output.
- Add Unicode, ASCII, and validated custom `ListTheme` markers with independent
  marker and item-body styles.
- Add deterministic `renderList`, `bulletList`, `numberedList`, and `taskList`
  rendering for nested values and concise plain-string inputs.
- Add hanging indentation for explicit and wrapped item lines, right-aligned
  ordered marker columns across digit changes, stable nested traversal, and
  mixed list kinds at caller-selected child levels.
- Add semantic task markers that remain visible in plain output, ANSI-safe
  wrapping/truncation, grapheme-aware maximum widths, and input ANSI stripping
  when color is disabled.
- Add an ANSI-aware `indent` helper with non-negative cell indentation,
  LF/CRLF normalization, plain rendering, and preserved empty/trailing lines.
- Add focused list model, exact snapshot, Unicode/ANSI width, style-reset,
  validation, no-trailing-whitespace, CRLF, maximum-width, and non-mutation
  tests covering all Phase 3 input cases.
- Add checklist, numbered procedure, mixed nested navigation, and generic
  indentation examples, and wire the new test and example into Nimble tasks
  and generated executable ignore rules.
- Add list and indentation guidance to the README, API landing page, façade
  docs, and complete Nim-generated API comments for public Phase 3 symbols.
- Add `CalloutKind` information, warning, failure, success, and custom semantic
  values plus boxed and compact `CalloutPresentation` modes.
- Add a reusable `Callout` model with body, contextual title, complete outer
  width, panel padding, explicit theme, wrap/truncate behavior, color control,
  and LF/CRLF output.
- Add explicit `CalloutTheme` palettes containing a visible label, optional
  validated one-cell icon, plain-output marker, panel preset, and independent
  marker, body, and border styles.
- Add cyan information, yellow warning, red failure, and green success named
  themes plus validated `initCalloutTheme` and `customCalloutTheme` APIs.
- Add `initCallout`, `info`, `warning`, `failure`/`error`, and `success`
  constructors, immutable configuration helpers, `renderCallout`, `render`,
  and `$` conveniences.
- Add panel-backed boxed rendering and borderless-panel compact rendering with
  shared padding, outer-width, ANSI-aware wrapping/truncation, and line-ending
  semantics rather than a second box implementation.
- Add semantic plain markers (`[INFO]`, `[WARN]`, `[FAIL]`, and `[OK]`) that
  survive ANSI stripping, with marker-preserving narrow-width validation and
  textual fallback when custom icons are omitted.
- Add focused callout model, exact boxed/compact/styled/plain snapshot,
  Unicode/ANSI geometry, reset-containment, multiline composition, empty-body,
  CRLF, validation, and non-mutation tests for all Phase 4 criteria.
- Add a callout example covering status reports, nested list content, compact
  output, and explicit custom palettes without a logging dependency, and wire
  its test/example files into the Nimble tasks and ignore rules.
- Add callout guidance to the README, API landing page, façade docs, and clear
  Nim-generated API comments for every public Phase 4 symbol.
- Add `BannerBorderMode` rule and boxed presentation values plus a reusable
  `Banner` model containing multiline text, an optional subtitle, complete
  outer width, alignment, one-cell fill glyph, panel padding and border
  configuration, independent text/fill styles, color control, and LF/CRLF
  output.
- Add `BannerTheme` with named light rule, square boxed, heavy boxed, double
  boxed, and seven-bit ASCII presets plus validated `initBannerTheme` and
  `customBannerTheme` constructors.
- Add `initBanner`, concise `banner`, immutable subtitle/width/alignment/fill/
  padding/border/theme/color/line-ending helpers, `renderBanner`, `render`, and
  `$` APIs.
- Add deterministic rule rendering that fills every row to its exact outer
  terminal-cell width, applies explicit horizontal/vertical padding, turns
  empty rows into complete rules, and assigns the extra odd centered cell to
  the right.
- Add panel-backed boxed rendering that reuses existing border, padding,
  alignment, ANSI-aware truncation, plain-output, and width geometry rather
  than adding a second box engine.
- Add grapheme-safe fitting for multiline, CJK, combining-mark, emoji, and ANSI
  content, with plain rendering that strips input ANSI and suppresses banner
  styles.
- Add focused banner model and immutability tests, exact-output snapshot tests,
  terminal-cell width and odd-alignment tests, Unicode/ANSI geometry tests,
  style-reset and plain-output tests, CRLF/no-trailing-ending contract tests,
  and invalid width/padding/glyph/theme/line-ending tests.
- Add a banner example covering section headings, a styled build summary, and
  a plain application title, and wire its focused test and example into the
  Nimble tasks and generated executable ignore rules.
- Add banner guidance to the README, generated API landing page, façade docs,
  and complete Nim-generated API comments for every public Phase 5 type,
  preset, constructor, validator, configuration helper, and renderer.
- Add a focused Phase 6 composition suite with exact nested-list/panel,
  tree/card, task-list/callout, and banner-separated snapshots.
- Add nested ANSI reset-containment and outer plain-rendering tests covering
  styled child output, CJK text, combining marks, and emoji graphemes.
- Add 64 reproducible property-style iterations covering deterministic output
  and constrained terminal-cell widths across panels, banners, lists, trees,
  and callouts.
- Add `examples/all_layouts.nim`, composing nested lists in a panel, a tree in
  a card, a task list in a callout, and banners as section separators.
- Add a development-only `suiteIntegration` task that imports all four terminal
  suite façades, renders actual TerminalTable and TerminalGraph output inside
  panels, and embeds TerminalLayout strings in table cells without adding a
  production dependency.
- Add Phase 6 composition and hardening guidance to the README, API landing
  page, façade documentation, panel renderer documentation, Nimble tasks, and
  generated executable ignore rules.

### Changed

- Make the streaming showcase restore terminal state reliably after Ctrl+C by
  using an atomic signal flag, covering setup with cleanup, and removing its
  control-C hook after restoring the main screen and cursor. Document manual
  Linux, macOS, and PowerShell recovery only for uncatchable termination.
- Mark completed Phase 7 documentation, testing, example, contributor,
  notices, and release-readiness work in `PLANS/PLAN1.md`.
- Lower the compiler floor from Nim 2.2.10 to the suite baseline of Nim 2.0.0.
- Replace the generated `add`, `Submodule`, and starter-test APIs with the
  TerminalLayout foundation and focused validation tests.
- Mark every completed Phase 0 deliverable and exit criterion in `PLAN1.md`.
- Mark every completed Phase 1 public API, rendering behavior, test, and
  documentation criterion in `PLAN1.md`.
- Mark every completed Phase 2 public API, rendering behavior, test, example,
  and documentation criterion in `PLAN1.md`.
- Mark every completed Phase 3 public API, rendering behavior, test, example,
  and documentation criterion in `PLAN1.md`.
- Mark every completed Phase 4 public API, rendering behavior, test, example,
  and documentation criterion in `PLAN1.md`.
- Mark every completed Phase 5 public API, rendering behavior, test, example,
  and documentation criterion in `PLAN1.md`.
- Replace the side-effect-free banner namespace skeleton with the complete
  Phase 5 implementation while preserving its stable import path and façade
  export.
- Preserve leading whitespace on already-fitting panel body rows so nested
  rendered trees, lists, tables, and graphs retain their structural columns;
  only oversized rows enter ANSI-aware wrapping.
- Mark completed Phase 6 composition, façade, hardening, interoperability,
  ANSI/plain-output, width-property, dependency, example, and documentation
  criteria in `PLANS/PLAN1.md`.

### Compatibility

- Verify the Phase 7 release gate, generated documentation, all registered
  examples, and the sibling TerminalTable/TerminalGraph integration suite with
  Nim 2.2.10 on Linux.
- Install TerminalStyle and TerminalLayout into an isolated empty Nimble
  directory and compile a separate consumer against only those installed
  package copies with Nim 2.2.10.
- Support Nim 2.0.0 and newer.
- Require TerminalStyle 0.1.1 or newer.
- Verify the foundation tests and compile probes with Nim 2.0.10 and 2.2.10.
- Verify the tree suite with Nim 2.0.10 and 2.2.10, and pass the complete
  Nimble test, example, documentation, and package-validation tasks.
- Verify the foundation, tree, panel, and import suites with Nim 2.0.10 and
  2.2.10, compile every example on both versions, and pass the complete Nimble
  test, example, documentation, and package-validation tasks.
- Verify the focused list suite and list example with Nim 2.0.10 and 2.2.10,
  and pass the complete Nimble test, example, and documentation tasks with Nim
  2.2.10.
- Verify the focused callout suite and callout example with Nim 2.2.10, and
  pass the complete Nimble test, example, and documentation tasks.
- Verify the focused banner suite and banner example with Nim 2.2.10, and pass
  the complete Nimble test, example, import-probe, and documentation tasks.
- Verify the Phase 6 composition suite, all-layouts example, and sibling-suite
  integration check with Nim 2.2.10 on Linux.
