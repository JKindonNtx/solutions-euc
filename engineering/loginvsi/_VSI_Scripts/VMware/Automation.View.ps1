function Disable-Pool {
    ##############################
    #.SYNOPSIS
    #Shutdown of all the VM's via VMware Horizon
    #
    #.DESCRIPTION
    #Sets the delivery group in maintance and stops all the running VM's
    #
    #.PARAMETER Controller
    #Name of the Controller
    #
    #.PARAMETER DeliveryGroup
    #Name of the deliveryGroup
    #
    #.EXAMPLE
    #Clean-ShutdownVMs -Controller "VAL-XDC1" -DeliveryGroup "VSI"
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [string]$PoolName)
 
    Get-Module -Name VMware* -ListAvailable | Import-Module
    Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -confirm:$false | Out-Null
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -confirm:$false | Out-Null
    Set-PowerCLIConfiguration -DefaultVIServerMode single -Confirm:$false | Out-Null

    #Connect to vCenter server
    $configESXServer = Get-Content -Path "$PSScriptRoot\config.ESXServer.json" -Raw | ConvertFrom-Json
    $VCPassword = ConvertTo-SecureString $($configESXServer.VCPassword) -AsPlainText -Force
    $VCcredentials = New-Object System.Management.Automation.PSCredential ($($configESXServer.UserName), $VCPassword)
    Connect-VIServer -Server $($configESXServer.vSphereServer) -Credential $VCcredentials | Out-Null

    $configView = Get-Content -Path "$PSScriptRoot\config.View.json" -Raw | ConvertFrom-Json
    Connect-HVServer -server $($configView.ConnectionServer) -User $($configView.UserName) -Password $($configView.Password) -Domain $($configView.Domain) | Out-Null
    $pool = Get-HVPool -PoolDisplayName $PoolName

    $desktops = Get-HVMachine -PoolName $pool.Base.Name
    $totalDesktops = $desktops.Count  
    $startTime = Get-Date
    Write-Host (Get-Date) ": Waiting for the refresh of all the VMs."
        
    $desktops = Get-HVMachine -PoolName $pool.Base.Name | where {$_.base.basicstate -ne "AVAILABLE"}
    $date = Get-Date
    $timeout = 30
    while ($desktops.Count -ne 0) {
        $desktops = Get-HVMachine -PoolName $pool.Base.Name | where {$_.base.basicstate -ne "AVAILABLE"}	
        Write-Host (Get-Date) ": $($desktops.Count) of $($totalDesktops) still not refreshed."
        Start-Sleep 10
        $date = Get-Date
        if (($date - $startTime).TotalMinutes -gt $timeout) {
            Write-Host (Get-Date) ":Refreshing VMs took to long. Resetting error VMs." 
            foreach ($desktop in $desktops) { 
                reset-HVMachine -MachineName $desktop.Base.Name 
            }
            Start-Sleep 15
        }
    }
    Start-Sleep 60
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

function Enable-Pool {
    ##############################
    #.SYNOPSIS
    #Enables the deliverygroup
    #
    #.DESCRIPTION
    #Disables the maintaince mode from the delivery group
    #
    #.PARAMETER Controller
    #Name of the Controller
    #
    #.PARAMETER DeliveryGroup
    #Name of the deliveryGroup
    #
    #.EXAMPLE
    #Enable-DeliveryGroup -Controller "VAL-XDC1" -DeliveryGroup "VSI"
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [System.Object]$Config
        )
 
    Get-Module -Name VMware* -ListAvailable | Import-Module

    $configView = Get-Content -Path "$PSScriptRoot\config.View.json" -Raw | ConvertFrom-Json
    Connect-HVServer -server $($configView.ConnectionServer) -User $($configView.UserName) -Password $($configView.Password) -Domain $($configView.Domain) | Out-Null
    $pool = Get-HVPool -PoolDisplayName $($config.PoolName)

    Write-Host (Get-Date) ": Enabling the pool."
    $pool | Set-HVPool -Enable | Out-Null

    Start-Sleep 60
    $desktops = Get-HVMachine -PoolName $pool.Base.Name
    $totalDesktops = $desktops.Count  
    $startTime = Get-Date
    Write-Host (Get-Date) ": Waiting for the startup of all the VMs."
        
    $desktops = Get-HVMachine -PoolName $pool.Base.Name | where {$_.base.basicstate -ne "AVAILABLE"}
    $date = Get-Date
    $timeout = 60
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
    Write-Host (Get-Date) ": All VMs are registered."
    $TotalBootTime = "{0:mm} min {0:ss} sec" -f ($endBootTime-$startTime)
    Write-Host (Get-Date) ": The boottime was: $TotalBoottime"
    "$($config.Testname),$date,$($totalDesktops),$TotalBoottime,$($config.HardwareType),$($config.CPUType)" | Add-Content -Path "$($config.Share)\$($config.Testname)-Boottime.csv"
    Slack-Boot -Config $Config -Boot $TotalBootTime
}
