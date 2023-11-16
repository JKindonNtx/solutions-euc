function Restart-LELaunchers {
    
    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][array]$Launchers
    )

    begin {
        # Set strict mode 
        # Set-StrictMode -Version Latest
        Write-Log -Message "Starting Restart-LELaunchers" -Level Info
    }

    process {
        Write-Log "Rebooting launchers."

        foreach ($launcher in $launchers) { 
        
            $try = 10
            $i = 0
            do {
                try {
                    $i = $i + 1
                    Write-Log -Message "Rebooting: $($launcher.machineName)." -Level Info
                    Restart-Computer -ComputerName $($launcher.machineName) -Force -ErrorAction Stop
                    $rebootLauncher = $true
                } catch {
                    Write-Log -Message "Something went wrong while rebooting launcher: $($launcher.machineName)." -Level Error
                    Write-Log -Message "Attempt $i of $try." -Level Error
                    $rebootLauncher = $false
                    
                    if ($i -eq $try) {
                        Write-Log "Failed to reboot launcher: $($launcher.machineName)." -Level Error
                        break
                    }
                }
            } while ($rebootLauncher -eq $false)
    
        }
    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing Restart-LELaunchers" -Level Info
    } # end

}
