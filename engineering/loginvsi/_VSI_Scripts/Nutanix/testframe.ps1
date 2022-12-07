    & "${env:ProgramFiles(x86)}\Nutanix Inc\NutanixCmdlets\powershell\import_modules\ImportModules.PS1"
    
    

    $configAHVServer = Get-Content -Path "$PSScriptRoot\config.AHV.json" -Raw | ConvertFrom-Json
    $clusterpassword = ConvertTo-SecureString $($configAHVServer.Password) -AsPlainText -Force
	Connect-NutanixCluster -Server $($configAHVServer.Cluster) -UserName $configAHVServer.username  -Password $clusterpassword -AcceptInvalidSSLCerts | Out-Null
    
    $password = ConvertTo-SecureString $($configAHVServer.CVMPassword) -AsPlainText -Force
    $ControllerCredentials = New-Object System.Management.Automation.PSCredential ("nutanix", $password)
    Write-Host (Get-Date) ": Shutdown Frame VMs."

    $desktops = Get-NTNXVM | Where-Object {$_.vmName -like "frame-instance-prod-*"} | Where-Object {$_.powerState -eq 'On'}
    Set-NTNXVMPowerOn -Vmid $VMid | out-null
        if($VM.count -eq 1) {
    $desktops = Get-HVMachine -PoolName $pool.Base.Name
    $totalDesktops = $desktops.Count  
    $startTime = Get-Date
    Write-Host (Get-Date) ": Waiting for the refresh of all the VMs."
        
    $desktops = Get-HVMachine -PoolName $pool.Base.Name | where {$_.base.basicstate -ne "AVAILABLE"}
    $date = Get-Date
    $timeout = 60
    while ($desktops.Count -ne 0) {
        $desktops = Get-HVMachine -PoolName $pool.Base.Name | where {$_.base.basicstate -ne "AVAILABLE"}	
        Write-Host (Get-Date) ": $($desktops.Count) of $($totalDesktops) still not refreshed."
        $date = Get-Date
        if (($date - $startTime).TotalMinutes -gt $timeout) {
            Write-Error "Booting VMs took to long." 
            Stop-Transcript
        }
    }

    Write-Host (Get-Date) ": Disabling the pool."
    $pool | Set-HVPool -Disable | Out-Null

    $desktops = Get-HVMachine -PoolName $pool.Base.Name

    $totalDesktops = $desktops.Count
    $desktopsOn = @()
    Write-Host (Get-Date) ": Initiate the shutdown for all the VM's."
    foreach ($desktop in $desktops) { 
        $vm = Get-VM -Name $desktop.Base.Name 
        
        if ($vm.PowerState -ne "PoweredOff") {
            $desktopsOn += $vm
            $vm | Shutdown-VMGuest -Confirm:$false | Out-Null
        }
    }
    
	$startTime = Get-Date
	$date = Get-Date
    $timeout = 30
    while ($desktopsOn.Count -ne 0) {
  
        foreach ($desktop in $desktopsOn) { 
            if ((Get-VM -Name $desktop.Name).PowerState -eq "PoweredOff") {
                $desktopsOn = $desktopsOn | Where-Object {$_.Name -ne $desktop.Name}
            }
        }

        Write-Host (Get-Date) ": $($desktops.Count) of $($totalDesktops) still running."
    
        $date = Get-Date
        if (($date - $startTime).TotalMinutes -gt $timeout) {
            Write-Error "Shutdown took to long." 
            Stop-Transcript
        }

        Start-Sleep 10
    }
		
    Write-Host (Get-Date) ": All VM's are down."
}