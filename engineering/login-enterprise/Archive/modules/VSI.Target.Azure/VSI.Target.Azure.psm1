# Load all the module scripts
foreach ($ps1 in Get-ChildItem -Recurse $PSScriptRoot\src\public\*.ps1) {
    . $ps1.FullName
}

function Write-Log {
    param([switch]$Update, $msg)
    if ($Update.IsPresent) {
        Write-Host "`r$([char]0x1b)[96m[$([char]0x1b)[97m$(Get-Date)$([char]0x1b)[96m]$([char]0x1b)[97m $msg" -NoNewLine
    } else {
        if ([string]::isNullOrEmpty($msg)) {
            Write-Host ""
        } else {
            Write-Host "$([char]0x1b)[96m[$([char]0x1b)[97m$(Get-Date)$([char]0x1b)[96m]$([char]0x1b)[97m $msg"
        }
    }
}
#Remove-PSSnapin Citrix* -ea SilentlyContinue
#Add-PSSnapin Citrix* -ea SilentlyContinue