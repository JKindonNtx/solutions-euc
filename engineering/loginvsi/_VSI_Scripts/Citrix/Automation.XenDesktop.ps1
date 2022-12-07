function Disable-Pool {
    ##############################
    #.SYNOPSIS
    #Shutdown of all the VM's via Citrix
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
 
    Add-PSSnapin Citrix*

    Write-Host (Get-Date) ": Set DeliveryGroup in to maintenance mode."
    
    $configCtx = Get-Content -Path "$PSScriptRoot\config.XenDesktop.json" -Raw | ConvertFrom-Json

    if ($configCtx.Cloud) {
        #Set-XDCredentials -CustomerId $($configCtx.CustomerID) -SecureClientFile $($configCtx.SecureClient) -ProfileType CloudAPI -StoreAs "Default"
        Set-XDCredentials -CustomerId $($configCtx.CustomerID) -APIKey $($configCtx.APIKey) -SecretKey $($configCtx.SecretKey)
    } else {
        Set-XDCredentials -ProfileType OnPrem
        #Set-XDCredentials -ProfileType OnPrem
    }

    $try = 10
        $i = 0
        do {
            try {
                $i = $i + 1
                Write-Host (Get-Date) ": Set pool in maintenance."
                Get-BrokerDesktopGroup -AdminAddress $($configCtx.Controller) -Name $PoolName | Set-BrokerDesktopGroup -InMaintenanceMode $true
                $brokermaint = $true
            } catch {
                Write-Host (Get-Date) ": Something went wrong while setting pool in maintenance."
                Write-Host (Get-Date) ": Attempt $i of $try."
                $brokermaint = $false
                
                if ($i -eq $try) {
                    Write-Error ": Failed to set pool in maintenance."
                    break
                }
            }
        } while ($brokermaint -eq $false)
    
    #$desktops = Get-BrokerDesktop -DesktopGroupName $PoolName
    $desktops = Get-BrokerMachine -AdminAddress $($configCtx.Controller) -DesktopGroupName $PoolName -MaxRecordCount 2000
    $totalDesktops = $desktops.Count

    Write-Host (Get-Date) ": Initiate the shutdown for all the VMs."
    foreach ($desktop in $desktops) { 
        $desktop | New-BrokerHostingPowerAction -Action TurnOff | Out-Null
    }

    $desktops = Get-BrokerMachine -AdminAddress $($configCtx.Controller) -DesktopGroupName $PoolName -MaxRecordCount $totalDesktops | Where-Object {$_.PowerState -eq "On"}	
 
	$startTime = Get-Date
	$date = Get-Date
    $timeout = 120
    while ($desktops.Count -ne 0) {
  
        $desktops = Get-BrokerMachine -AdminAddress $($configCtx.Controller) -DesktopGroupName $PoolName -MaxRecordCount $totalDesktops | Where-Object {$_.PowerState -eq "On"}	
        Write-Host (Get-Date) ": $($desktops.Count) of $($totalDesktops) still running."
    
        $date = Get-Date
        if (($date - $startTime).TotalMinutes -gt $timeout) {
            Write-Error "Shutdown took to long." 
            Stop-Transcript
        }

        Start-Sleep 10
    }
		
    Write-Host (Get-Date) ": All VMs are down."
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
 
    Add-PSSnapin Citrix*

    $configCtx = Get-Content -Path "$PSScriptRoot\config.XenDesktop.json" -Raw | ConvertFrom-Json

    if ($configCtx.Cloud) {
        #Set-XDCredentials -CustomerId $($configCtx.CustomerID) -SecureClientFile $($configCtx.SecureClient) -ProfileType CloudAPI -StoreAs "Default"
        Set-XDCredentials -CustomerId $($configCtx.CustomerID) -APIKey $($configCtx.APIKey) -SecretKey $($configCtx.SecretKey)
    } else {
        Set-XDCredentials -ProfileType OnPrem 
        #Set-XDCredentials -ProfileType OnPrem
    }

    Write-Host (Get-Date) ": Disable the maintenance mode on the DeliveryGroup."
    Get-BrokerDesktopGroup -AdminAddress $($configCtx.Controller) -Name $($config.PoolName) | Set-BrokerDesktopGroup -InMaintenanceMode $false

    if ($configCtx.Server) {
        Start-Sleep 20
        $desktops = Get-BrokerMachine -AdminAddress $($configCtx.Controller) -DesktopGroupName $($config.PoolName) -MaxRecordCount 2000
        $totalDesktops = $desktops.Count  
        $startTime = Get-Date
        Write-Host (Get-Date) ": Initiate the startup for all the VMs."
        foreach ($desktop in $desktops) { 
            $desktop | New-BrokerHostingPowerAction -Action  TurnOn | Out-Null
        }

        $desktops = Get-BrokerMachine -AdminAddress $($configCtx.Controller) -DesktopGroupName $($config.PoolName) -MaxRecordCount $totalDesktops | Where-Object {($_.RegistrationState -ne "Registered") -and ($_.PowerState -ne "On")}	
        $date = Get-Date
        $timeout = 120
        while ($desktops.Count -ne 0) {
            $desktops = Get-BrokerMachine -AdminAddress $($configCtx.Controller) -DesktopGroupName $($config.PoolName) -MaxRecordCount $totalDesktops | Where-Object {($_.RegistrationState -ne "Registered") -and ($_.PowerState -ne "On")}
            Write-Host (Get-Date) ": $($desktops.Count) of $($totalDesktops) still unregistered."
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
}