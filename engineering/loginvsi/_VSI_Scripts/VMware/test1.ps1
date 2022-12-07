
    Get-Module -Name VMware* -ListAvailable | Import-Module

    $configView = Get-Content -Path "$PSScriptRoot\config.View.json" -Raw | ConvertFrom-Json
    Connect-HVServer -server $($configView.ConnectionServer) -User $($configView.UserName) -Password $($configView.Password) -Domain $($configView.Domain) | Out-Null
    $pool = Get-HVPool -PoolDisplayName "W10-1803-IC"

    Write-Host (Get-Date) ": Enabling the pool."
    $pool | Set-HVPool -Enable | Out-Null

    #Start-Sleep 60
        $desktops = Get-HVMachine -PoolName $pool.Base.Name
        $totalDesktops = $desktops.Count  
        $startTime = Get-Date
       # Write-Host (Get-Date) ": Initiate the startup for all the VMs."
        #foreach ($desktop in $desktops) { 
         #   $vm = Get-VM -Name $desktop.Base.Name 
            
          #  if ($vm.State -eq "PoweredOff") {
           #     $desktopsOn += $vm
            #    $vm | Start-VM -Confirm:$false | Out-Null
            #}

       $desktops = Get-HVMachine -PoolName $pool.Base.Name | where {$_.base.basicstate -ne "AVAILABLE"}
        $date = Get-Date
        $timeout = 10
        while ($desktops.Count -ne 0) {
            $desktops = Get-HVMachine -PoolName $pool.Base.Name | where {$_.base.basicstate -ne "AVAILABLE"}	
            Write-Host (Get-Date) ": $($desktops.Count) of $($totalDesktops) still not available."
            $date = Get-Date
            if (($date - $startTime).TotalMinutes -gt $timeout) {
                Write-Error "Booting VMs took to long." 
                Stop-Transcript
            }
    
            Start-Sleep 2
        }
        $endBootTime = Get-Date
        Write-Host (Get-Date) ": All VMs are available."
        $TotalBootTime = "{0:mm} min {0:ss} sec" -f ($endBootTime-$startTime)
        Write-Host (Get-Date) ": The boottime was: $TotalBoottime"
       # "$($totalDesktops),$TotalBoottime,$($config.HardwareType),$($config.CPUType)" | Add-Content -Path "$($config.Share)\$($config.Testname)-Boottime.csv"
       # Slack-Boot -Config $Config -Boot $TotalBootTime