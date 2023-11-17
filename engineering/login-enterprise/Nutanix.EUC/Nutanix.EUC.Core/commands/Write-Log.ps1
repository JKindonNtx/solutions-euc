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
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][Switch]$Update,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][ValidateSet("Error", "Warn", "Info", "Validation")][String]$Level = "Info"
    )

    # Write message to error, warning, or Info
    switch ($Level) {
        'Error' {
            if ($Update.IsPresent) {
                Write-Host "$([char]0x1b)[31m[$([char]0x1b)[31m$(Get-Date)$([char]0x1b)[31m]$([char]0x1b)[31m ERROR: $Message" -NoNewline
            }
            else {
                Write-Host "$([char]0x1b)[31m[$([char]0x1b)[31m$(Get-Date)$([char]0x1b)[31m]$([char]0x1b)[31m ERROR: $Message"
            }
        }
        'Warn' {
            if ($Update.IsPresent) {
                Write-Host "$([char]0x1b)[33m[$([char]0x1b)[33m$(Get-Date)$([char]0x1b)[33m]$([char]0x1b)[33m WARNING: $Message" -NoNewline
            }
            else {
                Write-Host "$([char]0x1b)[33m[$([char]0x1b)[33m$(Get-Date)$([char]0x1b)[33m]$([char]0x1b)[33m WARNING: $Message"
            }
        }
        'Info' {
            if ($Update.IsPresent) {
                Write-Host "$([char]0x1b)[96m[$([char]0x1b)[97m$(Get-Date)$([char]0x1b)[96m]$([char]0x1b)[97m INFO: $Message" -NoNewline
            }
            else {
                Write-Host "$([char]0x1b)[96m[$([char]0x1b)[97m$(Get-Date)$([char]0x1b)[96m]$([char]0x1b)[97m INFO: $Message"
            }
        }
        'Validation' {
            Write-Host "$([char]0x1b)[96mVALIDATION: $Message"
        }
    }
}
