$launchers = @()
$numberOfVms = 60

for ($i = 1; $i -le $numberOfVms; $i++) {
    $number = "{0:00}" -f $i
    $launchers += "W10-2021-1$number"
}

foreach ($launcher in $launchers) { 
        
        $try = 10
        $i = 0
        do {
            try {
                $i = $i + 1
                Write-Host (Get-Date) ": Rebooting: $launcher."
                Restart-Computer -ComputerName $launcher -Force
                $rebootLauncher = $true
            } catch {
                Write-Host (Get-Date) ": Something went wrong while rebooting launcher: $launcher."
                Write-Host (Get-Date) ": Attempt $i of $try."
                $rebootLauncher = $false
                
                if ($i -eq $try) {
                    Write-Error ": Failed to reboot launcher: $launcher."
                    break
                }
            }
        } while ($rebootLauncher -eq $false)

    }
