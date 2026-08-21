function Write-Message {
    <#
    .SYNOPSIS
        Writes a string to the pipeline in a specifically formatted manner.
    .DESCRIPTION
        Writes a string to the pipeline in a specifically formatted manner.

        'Write-Message' includes functionality for writing PowerShell's
        default messages, including warnings, errors, verbose, and debug
        messages, while also including generic "info" messages and
        "success" messages when needed. Additionally, 'Write-Message'
        includes a formatted date parameter that prefixes every call for
        easy timestamping.

        This function can be utilized in place of the various builtin
        'Write-*' cmdlets.
    .PARAMETER Message
        Any message to be sent, must be enclosed in quotes.
    .PARAMETER Type
        The type of message to be sent. Valid options are Debug, Verbose,
        Info, Success, Warning, and Error. Debug and Verbose only produce
        output when $DebugPreference / $VerbosePreference is 'Continue' --
        pass the common -Debug or -Verbose switch to enable them for a
        single call.
    .PARAMETER Clean
        Removes all ANSI formatting from the message before output. Also
        enforced automatically on PowerShell versions below 7, and on any
        7.x release that predates $PSStyle (7.0-7.1).
    .PARAMETER NoPrefix
        Omits the leading type label (e.g. '[INFO]', '[ERROR]') from the
        message.
    .PARAMETER OutFile
        Tee the message to a specified file. -OutFile enforces -Clean on the
        file only to prevent ANSI definitions from interfering with
        readability.
    .NOTES
        The "Warning" and "Error" types do not write to any builtin variable
        and do not terminate or throw. Error handling must be done via other
        methods, 'Write-Message' is purely an informational utility.
    .EXAMPLE
        Write-Message "Hello world!"
        [Tue May 01 12:00:00 2023] [INFO]    Hello world!

        Writes a general message. With no other parameters, the output is
        assumed to be "Info".
    .EXAMPLE
        Write-Message "An error occurred." -Type Error
        [Tue May 01 12:00:00 2023] [ERROR]   An error occurred.

        Writes an error message to output.
    .EXAMPLE
        Write-Message "Hello world!" -NoPrefix
        [Tue May 01 12:00:00 2023] Hello world!

        Writes a message without its type label.
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, Position = 0)] [string]$Message,
        [ValidateSet('Debug', 'Verbose', 'Info', 'Success', 'Warning', 'Error')] [string]$Type = 'Info',
        [switch]$Clean,
        [switch]$NoPrefix,
        [string]$OutFile
    )

    begin {
        #   ┌───I.────────────────────────────────────────┐
        #   │ Enforce $Clean when using older PowerShell. │
        #   └─────────────────────────────────────────────┘

        if ($PSVersionTable.PSVersion.Major -lt 7) { $Clean = $True }
        
        #   ┌───II.───────────────────────────┐
        #   │ Stage parameters and variables. │
        #   └─────────────────────────────────┘

        $Date = $(Get-Date -UFormat "[%a %b %d %T %Y] ")

        # $PSStyle (PowerShell 7.2+) supplies ANSI styling. Degrade to
        # no color -- same as -Clean -- on PowerShell versions where
        # it isn't defined, rather than erroring on Foreground.* access.
        $UseColor = (-not($Clean)) -and $null -ne $PSStyle
        if ($UseColor) { $ColorDefault = $PSStyle.Reset }

        # Per-Type color/bold/prefix lookup, keyed by -Type. Color and
        # Bold are $null when color is disabled; Prefix is $null when
        # -NoPrefix is set, so they interpolate as empty strings below.
        $TypeInfo = @{
            Debug   = @{
                Color  = $(if ($UseColor) { $PSStyle.Foreground.FromRgb(0x585858) })
                Bold   = $(if ($UseColor) { $PSStyle.Bold + $PSStyle.Foreground.FromRgb(0x585858) })
                Prefix = $(if (-not($NoPrefix)) { '[DEBUG]   ' })
            }
            Verbose = @{
                Color  = $(if ($UseColor) { $PSStyle.Foreground.FromRgb(0x8A8A8A) })
                Bold   = $(if ($UseColor) { $PSStyle.Bold + $PSStyle.Foreground.FromRgb(0x8A8A8A) })
                Prefix = $(if (-not($NoPrefix)) { '[VERBOSE] ' })
            }
            Info    = @{
                Prefix = $(if (-not($NoPrefix)) { '[INFO]    ' })
            }
            Success = @{
                Color  = $(if ($UseColor) { $PSStyle.Bold + $PSStyle.Foreground.BrightGreen })
                Prefix = $(if (-not($NoPrefix)) { '[SUCCESS] ' })
            }
            Warning = @{
                Color  = $(if ($UseColor) { $PSStyle.Bold + $PSStyle.Foreground.BrightYellow })
                Prefix = $(if (-not($NoPrefix)) { '[WARNING] ' })
            }
            Error   = @{
                Color  = $(if ($UseColor) { $PSStyle.Bold + $PSStyle.Foreground.BrightRed })
                Prefix = $(if (-not($NoPrefix)) { '[ERROR]   ' })
            }
        }
    }
    
    process {

        #   ┌───III.─────────────────────────────────────┐
        #   │ Format the message for output to the host. │
        #   └────────────────────────────────────────────┘

        switch ($Type) {
            'Debug' {
                if ($DebugPreference -eq 'Continue') {
                    $t = $TypeInfo.Debug
                    $MessageContent = "$($t.Color)$Date$($t.Bold)$($t.Prefix)$($t.Color)$Message$ColorDefault"
                }
            }
            'Verbose' {
                if ($VerbosePreference -eq 'Continue') {
                    $t = $TypeInfo.Verbose
                    $MessageContent = "$($t.Color)$Date$($t.Bold)$($t.Prefix)$($t.Color)$Message$ColorDefault"
                }
            }
            'Info' { $MessageContent = "$Date$($TypeInfo.Info.Prefix)$Message$ColorDefault" }
            default {
                $t = $TypeInfo[$Type]
                $MessageContent = "$Date$($t.Color)$($t.Prefix)$ColorDefault$Message"
            }
        }

        #   ┌───IV.────────────────────────────────────────┐
        #   │ Format the message for output to a log file. │
        #   └──────────────────────────────────────────────┘

        if ($OutFile) {
            if ($DebugPreference -eq 'Continue') {
                $t = $TypeInfo.Debug
                Write-Output "$($t.Color)$Date$($t.Bold)$($t.Prefix)$($t.Color)`$OutFile detected as $OutFile."
            }
            try {
                switch ($Type) {
                    'Debug' { if ($DebugPreference -eq 'Continue') { Add-Content -Path $OutFile -Value "$Date$($TypeInfo.Debug.Prefix)$Message" } }
                    'Verbose' { if ($VerbosePreference -eq 'Continue') { Add-Content -Path $OutFile -Value "$Date$($TypeInfo.Verbose.Prefix)$Message" } }
                    default { Add-Content -Path $OutFile -Value "$Date$($TypeInfo[$Type].Prefix)$Message" }
                }
            }
            catch {
                $t = $TypeInfo.Error
                Write-Output "$Date$($t.Color)$($t.Prefix)$($ColorDefault)An error occurred while attempting to write to the output file. `n                                   $($_.Exception.Message)"
            }
        }
    }

    end {
        if ($null -ne $MessageContent) { $MessageContent }
    }
}

Export-ModuleMember -Function Write-Message