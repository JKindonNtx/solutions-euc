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

    #check for global variable and if not found, assume false
    if (-not (Test-Path -Path Variable:global:LastMessageEndedWithNewLine)) {
        $global:LastMessageEndedWithNewLine = $true
    }

    # check for global log output variable and if not found, assume false. If false, we are not logging to a file at all.
    if (-not (Test-Path -Path Variable:global:LogOutputTempFile)) {
        $global:LogOutputTempFile = $false
    } else {
        $LogPath = $global:LogOutputTempFile
        if ($LogPath -ne $false){
            if (-not (Test-Path -path $LogPath)) {
                $null = New-Item -ItemType File -Path $LogPath -Force    
            }
        }
    }
 
    # Write message to error, warning, or Info
    switch ($Level) {
        'Error' {
            if ($Update.IsPresent) {
                $Date = Get-Date
                Write-Host "`r$([char]0x1b)[31m[$([char]0x1b)[31m$($Date)$([char]0x1b)[31m]$([char]0x1b)[31m ERROR: $Message " -NoNewline
                $global:LastMessageEndedWithNewLine = $false
            }
            else {
                if ($global:LastMessageEndedWithNewLine -eq $false) {
                    $Date = Get-Date
                    Write-Host "`n$([char]0x1b)[31m[$([char]0x1b)[31m$($Date)$([char]0x1b)[31m]$([char]0x1b)[31m ERROR: $Message"
                    $global:LastMessageEndedWithNewLine = $true
                    if ($global:LogOutputTempFile) {
                        "`n[$Date] ERROR: $Message" | Out-File -FilePath $LogPath -Append
                    }
                } else {
                    $Date = Get-Date
                    Write-Host "$([char]0x1b)[31m[$([char]0x1b)[31m$($Date)$([char]0x1b)[31m]$([char]0x1b)[31m ERROR: $Message"
                    if ($global:LogOutputTempFile) {
                        "[$Date] ERROR: $Message" | Out-File -FilePath $LogPath -Append
                    }
                }
            }
        }
        'Warn' {
            if ($Update.IsPresent) {
                $Date = Get-Date
                Write-Host "`r$([char]0x1b)[33m[$([char]0x1b)[33m$($Date)$([char]0x1b)[33m]$([char]0x1b)[33m WARNING: $Message" -NoNewline
                $global:LastMessageEndedWithNewLine = $false
            }
            else {
                if ($global:LastMessageEndedWithNewLine -eq $false) {
                    $Date = Get-Date
                    Write-Host "`n$([char]0x1b)[33m[$([char]0x1b)[33m$($Date)$([char]0x1b)[33m]$([char]0x1b)[33m WARNING: $Message"
                    $global:LastMessageEndedWithNewLine = $true
                    if ($global:LogOutputTempFile) {
                        "`n[$Date] WARNING: $Message" | Out-File -FilePath $LogPath -Append
                    }
                }
                else {
                    $Date = Get-Date
                    Write-Host "$([char]0x1b)[33m[$([char]0x1b)[33m$($Date)$([char]0x1b)[33m]$([char]0x1b)[33m WARNING: $Message"
                    if ($global:LogOutputTempFile) {
                        "[$Date] WARNING: $Message" | Out-File -FilePath $LogPath -Append
                    }
                }
            }
        }
        'Info' {
            if ($Update.IsPresent) {
                $Date = Get-Date
                Write-Host "`r$([char]0x1b)[96m[$([char]0x1b)[97m$($Date)$([char]0x1b)[96m]$([char]0x1b)[97m INFO: $Message" -NoNewline
                $global:LastMessageEndedWithNewLine = $false
            }
            else {
                if ($global:LastMessageEndedWithNewLine -eq $false) {
                    $Date = Get-Date
                    Write-Host "`n$([char]0x1b)[96m[$([char]0x1b)[97m$($Date)$([char]0x1b)[96m]$([char]0x1b)[97m INFO: $Message"
                    $global:LastMessageEndedWithNewLine = $true
                    if ($global:LogOutputTempFile) {
                        "`n[$Date] INFO: $Message" | Out-File -FilePath $LogPath -Append
                    }
                } else {
                    $Date = Get-Date
                    Write-Host "$([char]0x1b)[96m[$([char]0x1b)[97m$($Date)$([char]0x1b)[96m]$([char]0x1b)[97m INFO: $Message"
                    if ($global:LogOutputTempFile) {
                        "[$Date] INFO: $Message" | Out-File -FilePath $LogPath -Append
                    }
                }
            }
        }
        'Validation' {
            Write-Host "$([char]0x1b)[96mVALIDATION: $Message"
            $global:LastMessageEndedWithNewLine = $true
            if ($global:LogOutputTempFile) {
                "VALIDATION: $Message" | Out-File -FilePath $LogPath -Append
            }
        }
    }
}
