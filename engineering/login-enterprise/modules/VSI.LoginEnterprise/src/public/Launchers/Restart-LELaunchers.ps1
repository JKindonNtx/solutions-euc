function Restart-LELaunchers {
    ##############################
    #.SYNOPSIS
    #Reboots the launchers
    #
    #.DESCRIPTION
    #Reboots the Login VSI launchers on the specified host
    #
    #.PARAMETER LauncherPrefix
    #Prefix for the launcher naming
    #
    #.PARAMETER HostName
    #Hostname of the hypervisor where launchers are hosted
    #
    #.EXAMPLE
    #Reboot-LELaunchers -LauncherPrefix "T3L" -HostName "VAL-INFRA2"
    #
    #.NOTES
    #Initial creation of generic function
    ##############################

    param(
        [system.array]$Launchers
        )

    Write-Log "Rebooting launchers."
    
    foreach ($launcher in $launchers) { 
        
        $try = 10
        $i = 0
        do {
            try {
                $i = $i + 1
                Write-Log "Rebooting: $($launcher.machineName)."
                Restart-Computer -ComputerName $($launcher.machineName) -Force
                $rebootLauncher = $true
            } catch {
                Write-Log "Something went wrong while rebooting launcher: $($launcher.machineName)."
                Write-Log "Attempt $i of $try."
                $rebootLauncher = $false
                
                if ($i -eq $try) {
                    Write-Log "Failed to reboot launcher: $($launcher.machineName)."
                    break
                }
            }
        } while ($rebootLauncher -eq $false)

    }
}