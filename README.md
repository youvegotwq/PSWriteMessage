# PSWriteMessage

A drop-in replacement for PowerShell's builtin `Write-*` cmdlets. `Write-Message` timestamps every message and formats it by type — Debug, Verbose, Info, Success, Warning, Error — with color and a type-label prefix, and can optionally tee the message to a log file.

## Installation

Clone into a folder on your `$env:PSModulePath` named to match the module, so it can be found by name:

```powershell
git clone https://github.com/youvegotwq/PSWriteMessage.git "$HOME\Documents\PowerShell\Modules\PSWriteMessage"
```

Then import it like any other module:

```powershell
Import-Module PSWriteMessage
```

**Requirements:** PowerShell 5.1 or later. Colored output requires PowerShell 7.2+ (`$PSStyle`); on earlier versions `Write-Message` still works, just without ANSI color.

## Usage

```powershell
Write-Message "a debug message" -Type Debug -Debug
# [Fri Aug 21 00:07:36 2026] [DEBUG]   a debug message

Write-Message "a verbose message" -Type Verbose -Verbose
# [Fri Aug 21 00:07:36 2026] [VERBOSE] a verbose message

Write-Message "a general info message"
# [Fri Aug 21 00:07:36 2026] [INFO]    a general info message

Write-Message "something succeeded" -Type Success
# [Fri Aug 21 00:07:36 2026] [SUCCESS] something succeeded

Write-Message "something is off" -Type Warning
# [Fri Aug 21 00:07:36 2026] [WARNING] something is off

Write-Message "something failed" -Type Error
# [Fri Aug 21 00:07:36 2026] [ERROR]   something failed

Write-Message "no type label here" -NoPrefix
# [Fri Aug 21 00:07:36 2026] no type label here
```

`Debug` and `Verbose` only produce output when their matching preference is active — pass the common `-Debug`/`-Verbose` switch (as above), or set `$DebugPreference`/`$VerbosePreference = 'Continue'` yourself. Without that, the call produces no output at all.

Tee a message to a log file (always written without ANSI color, regardless of `-Clean`):

```powershell
Write-Message "also logged to file" -OutFile ./app.log
```

## Parameters

| Parameter   | Type   | Description |
|-------------|--------|-------------|
| `-Message`  | string, required, positional | The message to write. |
| `-Type`     | string | `Debug`, `Verbose`, `Info` (default), `Success`, `Warning`, `Error`. |
| `-Clean`    | switch | Strips ANSI color from the message. Automatically enforced on PowerShell versions where `$PSStyle` isn't available (below 7.2). |
| `-NoPrefix` | switch | Omits the `[TYPE]` label. |
| `-OutFile`  | string | Also appends the message to the given file path. |

See `Get-Help Write-Message -Full` for complete parameter and example documentation.

## Versioning

This module uses [CalVer](https://calver.org/) (`YYYY.0M.0D`) rather than SemVer — `ModuleVersion` reflects the date of the release, not compatibility guarantees. Note that PowerShell's `ModuleVersion` field is a `[System.Version]`, so the zero-padding is preserved in this file's source but stripped when read back at runtime (`2026.08.21` reports as `2026.8.21` via `Get-Module`/`Test-ModuleManifest`).

## License

[MIT](LICENSE) © William Quinn
