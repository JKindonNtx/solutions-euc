function Write-VSILog {
    param([switch]$Update, $msg)
    if ($Update.IsPresent) {
        Write-Host "`r$([char]0x1b)[96m[$([char]0x1b)[97m$(Get-Date)$([char]0x1b)[96m]$([char]0x1b)[97m $msg" -NoNewline
    } else {
        if ([string]::isNullOrEmpty($msg)) {
            Write-Host ""
        } else {
            Write-Host "$([char]0x1b)[96m[$([char]0x1b)[97m$(Get-Date)$([char]0x1b)[96m]$([char]0x1b)[97m $msg"
        }
    }
}