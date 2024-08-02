function Write-Log {
    <#
.SYNOPSIS
Makes a pretty write-host output for logging to console

.DESCRIPTION
Makes a pretty write-host output for logging to console

.PARAMETER Message
The message used for logging output. Mandatory

.PARAMETER Update
If specified, nonewline is used on write host

.PARAMETER Level
Info, Warning or Error. Defaults to Info

.INPUTS
This function will take inputs via pipeline.

.OUTPUTS
What the function returns.

.EXAMPLE
PS> Write-Log -Message "hello" -Level Info
Writes an Info Output to the console

#>
    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][String]$Message,
        [Switch]$Update,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][ValidateSet("Error", "Warn", "Info", "Validation")][String]$Level = "Info"
    )

    # Write message to error, warning, or Info
    switch ($Level) {
        'Error' {
            if ($Update.IsPresent) {
                Write-Host "`r$([char]0x1b)[31m[$([char]0x1b)[31m$(Get-Date)$([char]0x1b)[31m]$([char]0x1b)[31m ERROR: $Message " -NoNewline
                $global:LastMessageEndedWithNewLine = $false
            }
            else {
                if ($global:LastMessageEndedWithNewLine -eq $false) {
                    Write-Host "`n$([char]0x1b)[31m[$([char]0x1b)[31m$(Get-Date)$([char]0x1b)[31m]$([char]0x1b)[31m ERROR: $Message"
                    $global:LastMessageEndedWithNewLine = $true
                } else {
                    Write-Host "$([char]0x1b)[31m[$([char]0x1b)[31m$(Get-Date)$([char]0x1b)[31m]$([char]0x1b)[31m ERROR: $Message"
                }
                #Write-Host "$([char]0x1b)[31m[$([char]0x1b)[31m$(Get-Date)$([char]0x1b)[31m]$([char]0x1b)[31m ERROR: $Message"
                #$global:LastMessageEndedWithNewLine = $true
            }
        }
        'Warn' {
            if ($Update.IsPresent) {
                Write-Host "`r$([char]0x1b)[33m[$([char]0x1b)[33m$(Get-Date)$([char]0x1b)[33m]$([char]0x1b)[33m WARNING: $Message" -NoNewline
                $global:LastMessageEndedWithNewLine = $false
            }
            else {
                if ($global:LastMessageEndedWithNewLine -eq $false) {
                    Write-Host "`n$([char]0x1b)[33m[$([char]0x1b)[33m$(Get-Date)$([char]0x1b)[33m]$([char]0x1b)[33m WARNING: $Message"
                    $global:LastMessageEndedWithNewLine = $true
                }
                else {
                    Write-Host "$([char]0x1b)[33m[$([char]0x1b)[33m$(Get-Date)$([char]0x1b)[33m]$([char]0x1b)[33m WARNING: $Message"
                }
                #Write-Host "$([char]0x1b)[33m[$([char]0x1b)[33m$(Get-Date)$([char]0x1b)[33m]$([char]0x1b)[33m WARNING: $Message"
                #$global:LastMessageEndedWithNewLine = $true
            }
        }
        'Info' {
            if ($Update.IsPresent) {
                Write-Host "`r$([char]0x1b)[96m[$([char]0x1b)[97m$(Get-Date)$([char]0x1b)[96m]$([char]0x1b)[97m INFO: $Message" -NoNewline
                $global:LastMessageEndedWithNewLine = $false
            }
            else {
                if ($global:LastMessageEndedWithNewLine -eq $false) {
                    Write-Host "`n$([char]0x1b)[96m[$([char]0x1b)[97m$(Get-Date)$([char]0x1b)[96m]$([char]0x1b)[97m INFO: $Message"
                    $global:LastMessageEndedWithNewLine = $true
                } else {
                    Write-Host "$([char]0x1b)[96m[$([char]0x1b)[97m$(Get-Date)$([char]0x1b)[96m]$([char]0x1b)[97m INFO: $Message"
                }
                #Write-Host "$([char]0x1b)[96m[$([char]0x1b)[97m$(Get-Date)$([char]0x1b)[96m]$([char]0x1b)[97m INFO: $Message"
                #$global:LastMessageEndedWithNewLine = $true
            }
        }
        'Validation' {
            Write-Host "$([char]0x1b)[96mVALIDATION: $Message"
            $global:LastMessageEndedWithNewLine = $true
        }
    }
}
