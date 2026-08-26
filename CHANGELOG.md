# Changelog

This project follows Semantic Versioning.

## [Unreleased]

### Added

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

### Changed

- Lower the compiler floor from Nim 2.2.10 to the suite baseline of Nim 2.0.0.
- Replace the generated `add`, `Submodule`, and starter-test APIs with the
  TerminalLayout foundation and focused validation tests.
- Mark every completed Phase 0 deliverable and exit criterion in `PLAN1.md`.
- Mark every completed Phase 1 public API, rendering behavior, test, and
  documentation criterion in `PLAN1.md`.
- Mark every completed Phase 2 public API, rendering behavior, test, example,
  and documentation criterion in `PLAN1.md`.

### Compatibility

- Support Nim 2.0.0 and newer.
- Require TerminalStyle 0.1.1 or newer.
- Verify the foundation tests and compile probes with Nim 2.0.10 and 2.2.10.
- Verify the tree suite with Nim 2.0.10 and 2.2.10, and pass the complete
  Nimble test, example, documentation, and package-validation tasks.
- Verify the foundation, tree, panel, and import suites with Nim 2.0.10 and
  2.2.10, compile every example on both versions, and pass the complete Nimble
  test, example, documentation, and package-validation tasks.
