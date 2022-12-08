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
 
    #Import Nutanix Module
    & "${env:ProgramFiles(x86)}\Nutanix Inc\NutanixCmdlets\powershell\import_modules\ImportModules.PS1"
    
    

    $configAHVServer = Get-Content -Path "$PSScriptRoot\config.AHV.json" -Raw | ConvertFrom-Json
    $clusterpassword = ConvertTo-SecureString $($configAHVServer.Password) -AsPlainText -Force
	Connect-NutanixCluster -Server $($configAHVServer.Cluster) -UserName $configAHVServer.username  -Password $clusterpassword -AcceptInvalidSSLCerts | Out-Null
    $desktops = Get-NTNXVM | Where-Object {$_.vmName -like "frame-instance-prod-*"}
$totalDesktops = $desktops.Count
$desktops = Get-NTNXVM | Where-Object {$_.vmName -like "frame-instance-prod-*"} | Where-Object {$_.powerState -eq 'On'}
$desktopsOn = @()
foreach ($desktop in $desktops) { 
    $vm = $desktop.vmName
    $desktopsOn += $vm
}
Write-Host (Get-Date) ": $($DesktopsOn.count) desktops are powered on."
# Shutdown Frame VMs
if ($desktopsOn.Count -ne 0) {
    Write-Host (Get-Date) ": Shutdown $($desktopsOn.count) VMs."
    foreach ($desktop in $desktops) {
        $vmId = ($desktop.vmid.split(":"))[2]
        Set-NTNXVMPowerState -Vmid $vmId -Transition ACPI_SHUTDOWN -verbose | Out-Null
    }

    $desktops = Get-NTNXVM | Where-Object {$_.vmName -like "frame-instance-prod-*"} | Where-Object {$_.powerState -eq 'On'}
   
    $startTime = Get-Date
    $date = Get-Date
    $timeout = 30
    
    while ($desktops.Count -ne 0) {
  
        $desktops = Get-NTNXVM | Where-Object {$_.vmName -like "frame-instance-prod-*"} | Where-Object {$_.powerState -eq 'On'}
        Write-Host (Get-Date) ": $($desktops.Count) of $($totalDesktops) still running."
    
        $date = Get-Date
        if (($date - $startTime).TotalMinutes -gt $timeout) {
            Write-Error "Shutdown took to long." 
            Stop-Transcript
        }

        Start-Sleep 10
    }

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
 
    #Import Nutanix Module
    & "${env:ProgramFiles(x86)}\Nutanix Inc\NutanixCmdlets\powershell\import_modules\ImportModules.PS1"
    
    

    $configAHVServer = Get-Content -Path "$PSScriptRoot\config.AHV.json" -Raw | ConvertFrom-Json
    $clusterpassword = ConvertTo-SecureString $($configAHVServer.Password) -AsPlainText -Force
	Connect-NutanixCluster -Server $($configAHVServer.Cluster) -UserName $configAHVServer.username  -Password $clusterpassword -AcceptInvalidSSLCerts | Out-Null
    $desktops = Get-NTNXVM | Where-Object {$_.vmName -like "frame-instance-prod-*"}
    $totalDesktops = $desktops.Count
    $desktops = Get-NTNXVM | Where-Object {$_.vmName -like "frame-instance-prod-*"} | Where-Object {$_.powerState -eq 'Off'}

    # Poweron Frame VMs
    Write-Host (Get-Date) ": Powering on $totalDesktops VMs."
    foreach ($desktop in $desktops) {
        $vmId = ($desktop.vmid.split(":"))[2]
        Set-NTNXVMPowerOn -Vmid $vmId | out-null
    }
    
    #Write-Host (Get-Date) ": Waiting 60 seconds."
    #Start-Sleep 60 
    $startTime = Get-Date
    Write-Host (Get-Date) ": Waiting for the startup of all the VMs."
        
    $desktops = Get-NTNXVM | Where-Object {$_.vmName -like "frame-instance-prod-*"} | Where-Object {$_.powerState -eq 'Off'}
    $date = Get-Date
    $timeout = 60
    while ($desktops.Count -ne 0) {
        $desktops = Get-NTNXVM | Where-Object {$_.vmName -like "frame-instance-prod-*"} | Where-Object {$_.powerState -eq 'Off'}	
        Write-Host (Get-Date) ": $($desktops.Count) of $($totalDesktops) still not powered on."
        $date = Get-Date
        if (($date - $startTime).TotalMinutes -gt $timeout) {
            Write-Error "Booting VMs took to long." 
            Stop-Transcript
        }
    
        Start-Sleep 10
    }
    $endBootTime = Get-Date
    Write-Host (Get-Date) ": All VMs are registered."
    $TotalBootTime = "{0:mm} min {0:ss} sec" -f ($endBootTime-$startTime)
    Write-Host (Get-Date) ": The boottime was: $TotalBoottime"
    "$($config.Testname),$date,$($totalDesktops),$TotalBoottime,$($config.HardwareType),$($config.CPUType)" | Add-Content -Path "$($config.Share)\$($config.Testname)-Boottime.csv"
    Slack-Boot -Config $Config -Boot $TotalBootTime
}
