# Releasing

`terminal_layout` is released only after its declared `terminal_style`
dependency is available from Nimble. TerminalTable and TerminalGraph are not
release dependencies; they compose with TerminalLayout through strings.

## Release prerequisites

- Confirm the public repository URL, default branch, package name, and
  maintainer contact for the Nim packages registry submission.
- Confirm `terminal_style >= 0.1.1` can be installed in an empty Nimble
  directory.
- From a clean checkout, run `nimble releaseCheck` with Nim 2.0.x, 2.2.x, and
  the latest stable compiler.
- Confirm CI passes on Linux, macOS, and Windows.
- Review generated API pages and every example output.
- Confirm the manifest contains no binary and no production dependency beyond
  the Nim standard library and TerminalStyle.
- Replace `Unreleased` in `CHANGELOG.md` with the release date only in the
  release commit.

The release check runs package validation, focused and integration tests,
example compilation, and generated documentation. The sibling-suite
integration task remains a separate development check because its repositories
are not package dependencies.

Commit the release, create an annotated tag matching the manifest version, and
push both the commit and tag. Submit `terminal_layout` to the
[`nim-lang/packages`](https://github.com/nim-lang/packages) registry only after
the tagged repository can be installed by its final URL. Never reuse or move a
published version tag.
