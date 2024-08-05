function Wait-LELaunchers {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][Int32]$Amount,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$NamingPattern,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][Int32]$TimeOutMinutes = 30,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][Boolean]$RebootLaunchers
    )

    $NamingPattern = $NamingPattern -replace "_", ""
    $Launchers = Get-LELaunchers | Where-Object { $_.machineName -like "$($NamingPattern)*" }
    
    # Handle Luancher Reboot Logic
    if ($RebootLaunchers -eq $true) {
        Write-Log -Message "Rebooting launchers." -Level Info
        Restart-LELaunchers -Launchers $Launchers
    } else {
        # Testing without a Launcher Reboot as per Citrix Connection time
        Write-Log -Message "Skipping Rebooting of launchers." -Level Info
    }
    
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
            Write-Log -Message "Only $LaunchersOnline/$Amount launchers registered with LE within $TimoutMinutes minutes" -Level Error
            Exit 1
        }
    }
}
