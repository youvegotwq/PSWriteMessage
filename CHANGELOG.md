# Changelog

All notable changes to PSWriteMessage are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project uses [CalVer](https://calver.org/) (`YYYY.0M.0D`), so the version
number reflects a release date, not compatibility. **Breaking changes are called
out explicitly in the notes below** rather than signalled by the version.

## [Unreleased]

### Changed

- **Breaking:** `Write-Message` no longer writes to the success (output) stream.
  All output now goes to the host through `Write-Host` (the information stream,
  `6`), so log lines can no longer contaminate a function's return value or a
  captured pipeline — the `| Out-Host` workaround is no longer needed. Callers
  that captured the rendered string (`$x = Write-Message ...`, or
  `Write-Message ... | <consumer>`) now receive `$null`; redirect `6>&1` or use
  `-OutFile` to capture the text instead. `OutputType` is now `[void]`.
- `Debug` and `Verbose` messages are shown whenever the effective preference is
  anything other than `SilentlyContinue` (previously only `Continue`), matching
  how the built-in `Write-Verbose` / `Write-Debug` decide visibility. This makes
  the common `-Debug` switch work on Windows PowerShell 5.1, where it sets
  `$DebugPreference` to `Inquire` rather than `Continue`. `Write-Message` still
  only prints; it does not reproduce the prompt of `Inquire` or the throw of
  `Stop`.

### Fixed

- `-Verbose` / `-Debug` passed to an ancestor function (in another module or
  script) is now honored. `Write-Message` previously read `$VerbosePreference` /
  `$DebugPreference` unqualified, which resolved against the module's own scope
  and never saw a switch bound on a caller further up the chain. The effective
  preference is now resolved from the caller's scope via
  `$PSCmdlet.GetVariableValue`; a switch bound directly on `Write-Message` still
  takes precedence.

## [2026.08.21] - 2026-08-26

First PowerShell Gallery release.

### Added

- `Write-Message`: a timestamped, type-formatted replacement for the built-in
  `Write-*` cmdlets.
- `-Type` with values `Debug`, `Verbose`, `Info` (default), `Success`,
  `Warning`, and `Error`, each with its own `[LABEL]` prefix.
- `$PSStyle` ANSI colour on PowerShell 7.2+, degrading to plain text on earlier
  versions.
- `-Clean` to strip ANSI formatting, `-NoPrefix` to omit the type label, and
  `-OutFile` to tee the message (always uncoloured) to a log file.

[Unreleased]: https://github.com/youvegotwq/PSWriteMessage/compare/2026.08.21...HEAD
[2026.08.21]: https://github.com/youvegotwq/PSWriteMessage/releases/tag/2026.08.21
