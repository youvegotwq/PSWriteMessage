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
        Any message to be sent, must in enclosed in quotes.
    .PARAMETER Type
        The type of message to be sent. Valid options are Debug, Verbose,
        Info, Success, Warn, Warning, and Error.
    .PARAMETER Clean
        Removes all ANSI formatting from the message before output.
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
        [Tue May 01 12:00:00 2023] Hello world!

        Writes a general message. With no other parameters, the output is
        assumed to be "Info".
    .EXAMPLE
        Write-Message "An error occurred." -Type Error
        [Tue May 01 12:00:00 2023] [ERROR] An error occurred.

        Writes an error message to output.
    #>

    param(
        [parameter(Mandatory, Position = 0)] [string]$Message,
        [validateset('Debug', 'Verbose', 'Info', 'Success', 'Warning', 'Error')] [string]$Type = 'Info',
        [switch]$Clean,
        [string]$OutFile
    )

    begin {
        #   ┌───I.────────────────────────────────────────┐
        #   │ Enforce $Clean when using older PowerShell. │
        #   └─────────────────────────────────────────────┘

        if ($PSVersionTable.PSVersion.Major -lt 7) { $Clean = $true }
        
        #   ┌───II.───────────────────────────┐
        #   │ Stage parameters and variables. │
        #   └─────────────────────────────────┘

        $Date = $(Get-Date -UFormat "[%a %b %d %T %Y] ")
        if (-not($Clean)) {
            $ColorDefault = "`e[0m"
            $ColorVerbose = "`e[38;5;245m"
            $ColorVerboseBold = "`e[1;38;5;245m"
            $ColorSuccess = "`e[1;92m"
            $ColorWarning = "`e[1;93m"
            $ColorError = "`e[1;91m"
            $ColorDebug = "`e[38;5;240m"
            $ColorDebugBold = "`e[1;38;5;240m"
        }
        $PrefixVerbose = '[VERBOSE] '
        $PrefixSuccess = '[SUCCESS] '
        $PrefixWarning = '[WARNING] '
        $PrefixError = '[ERROR] '
        $PrefixDebug = '[DEBUG] '
    }
    
    process {

        #   ┌───III.─────────────────────────────────────┐
        #   │ Format the message for output to the host. │
        #   └────────────────────────────────────────────┘

        if ($Type -eq 'Debug' -and $DebugPreference -eq 'Continue') { $MessageContent = "$ColorDebug$Date$ColorDebugBold$PrefixDebug$ColorDebug$Message$ColorDefault" }
        if ($Type -eq 'Verbose' -and $VerbosePreference -eq 'Continue') { $MessageContent = "$ColorVerbose$Date$ColorVerboseBold$PrefixVerbose$ColorVerbose$Message$ColorDefault" }
        if ($Type -eq 'Info') { $MessageContent = "$Date$Message$ColorDefault" }
        if ($Type -eq 'Success') { $MessageContent = "$Date$ColorSuccess$PrefixSuccess$ColorDefault$Message" }
        if ($Type -eq 'Warning') { $MessageContent = "$Date$ColorWarning$PrefixWarning$ColorDefault$Message" }
        if ($Type -eq 'Error') { $MessageContent = "$Date$ColorError$PrefixError$ColorDefault$Message" }

        #   ┌───IV.────────────────────────────────────────┐
        #   │ Format the message for output to a log file. │
        #   └──────────────────────────────────────────────┘

        if ($OutFile) {
            if ($DebugPreference -eq 'Continue') { Write-Output "$ColorDebug$Date$ColorDebugBold$PrefixDebug$ColorDebug`$OutFile detected as $OutFile." }
            try {
                if ($Type -eq 'Debug' -and $DebugPreference -eq 'Continue') { Add-Content -Path $OutFile -Value "$Date$PrefixDebug$Message" }
                if ($Type -eq 'Verbose' -and $VerbosePreference -eq 'Continue') { Add-Content -Path $OutFile -Value "$Date$PrefixVerbose$Message" }
                if ($Type -eq 'Info') { Add-Content -Path $OutFile -Value  "$Date$Message" }
                if ($Type -eq 'Success') { Add-Content -Path $OutFile -Value "$Date$PrefixSuccess$Message" }
                if ($Type -eq 'Warn' -or $Type -eq 'Warning') { Add-Content -Path $OutFile -Value "$Date$PrefixWarning$Message" }
                if ($Type -eq 'Error') { Add-Content -Path $OutFile -Value "$Date$PrefixError$Message" }
            }
            catch {
                Write-Output "$Date$ColorError$PrefixError$ColorDefault`An error occurred while attempting to write to the output file. `n                                   $($_.Exception.Message)"
            }
        }
    }

    end {
        return $MessageContent
    }
}

Export-ModuleMember -Function Write-Message