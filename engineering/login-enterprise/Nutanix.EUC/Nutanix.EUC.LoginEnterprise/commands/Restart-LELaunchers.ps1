function Restart-LELaunchers {
    
    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][array]$Launchers
    )

    foreach ($launcher in $launchers) { 
        
        $try = 10
        $i = 0
        do {
            try {
                $i = $i + 1
                Write-Log -Message "Rebooting: $($launcher.machineName)." -Level Info
                Restart-Computer -ComputerName $($launcher.machineName) -Force -ErrorAction Stop
                $rebootLauncher = $true
            }
            catch {
                Write-Log -Message "Something went wrong while rebooting launcher: $($launcher.machineName)." -Level Warn
                Write-Log -Message "Attempt $i of $try." -Level Error
                $rebootLauncher = $false
                    
                if ($i -eq $try) {
                    Write-Log "Failed to reboot launcher: $($launcher.machineName)." -Level Error
                    break
                }
            }
        } while ($rebootLauncher -eq $false)
    }
}
