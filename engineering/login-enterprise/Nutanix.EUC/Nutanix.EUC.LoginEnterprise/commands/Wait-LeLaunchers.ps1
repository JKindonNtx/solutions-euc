function Wait-LELaunchers {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][Int32]$Amount,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$NamingPattern,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][Int32]$TimeOutMinutes = 30
    )

    $NamingPattern = $NamingPattern -replace "_", ""
    $Launchers = Get-LELaunchers | Where-Object { $_.machineName -like "$($NamingPattern)*" }
    # Testing without a Launcher Reboot as per Citrix Connection time
    # Restart-LELaunchers -Launchers $Launchers
    Write-Log -Message "Waiting 15 seconds" -Level Info
    Start-Sleep 15
    $StartStamp = Get-Date
    while ($true) {
        $NamingPattern = $NamingPattern -replace "_", ""
        $LaunchersOnline = (Get-LELaunchers | Where-Object { $_.machineName -like "$($NamingPattern)*" } | Measure-Object).Count
        Write-Log -Update -Message "$LaunchersOnline/$Amount launchers registered" -Level Info
        if ($LaunchersOnline -ge $Amount) { break }
        
        Write-Log -Message "Waiting 60 seconds" -Level Info
        Start-Sleep -Seconds 60
        
        $TimeSpan = New-TimeSpan -Start $StartStamp -End (Get-Date)
        
        if ($TimeSpan.TotalMinutes -ge $TimeOutMinutes) {
            Write-Log -Message "Only $Launcher/$Amount launchers registered with LE within $TimoutMinutes minutes" -Level Error
            Exit 1
        }
    }
    Write-Log -Message " " -Level Info
}
