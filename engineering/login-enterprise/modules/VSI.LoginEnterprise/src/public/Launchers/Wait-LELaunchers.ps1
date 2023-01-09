function Wait-LELaunchers {
    param(
        [Int32]$Amount,
        [String]$NamingPattern,
        [Int32]$TimeOutMinutes = 30
    )
    #[system.array]$Launchers = Get-LELaunchers | Where-Object { $_.Name -like "$($NamingPattern)*" }
    $NamingPattern = $NamingPattern -replace "_", ""
    $Launchers = Get-LELaunchers | Where-Object { $_.machineName -like "$($NamingPattern)*" }
    Restart-LELaunchers -Launchers $Launchers
    Write-Log "Wait 15 seconds"
    Start-Sleep 15
    $StartStamp = Get-Date
    while ($true) {
        $NamingPattern = $NamingPattern -replace "_", ""
        $LaunchersOnline = (Get-LELaunchers | Where-Object { $_.machineName -like "$($NamingPattern)*" } | Measure-Object).Count
        Write-Log -Update "$LaunchersOnline/$Amount launchers registered"
        if ($LaunchersOnline -ge $Amount) { break }
        Start-Sleep -Seconds 60
        $TimeSpan = New-TimeSpan -Start $StartStamp -End (Get-Date)
        if ($TimeSpan.TotalMinutes -ge $TimeOutMinutes) {
            throw "Only $Launcher/$Amount launchers registered with LE within $TimoutMinutes minutes"
        }
    }
    Write-Log ""
}
