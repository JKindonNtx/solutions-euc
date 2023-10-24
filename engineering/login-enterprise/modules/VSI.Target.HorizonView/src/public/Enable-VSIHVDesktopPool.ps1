function Enable-VSIHVDesktopPool {
    param(
        [string]$Name,
        [Int32]$VMAmount,
        [Int32]$Increment = 15,
        [switch]$AllMachinesUpFront,
        [Int32]$NumberOfSpareVMs = 15,
        [switch]$RDSH
    )

    $Boot = "" | Select-Object -Property bootstart,boottime,firstvmname

    if(!($null -eq (Get-HVPool -PoolName $Name))){
        Write-Log "Pool $($Name) Found"
        Write-Log "Getting VMs in Pool $($Name)"
        $desktops = Get-HVMachine -PoolName $Name | Where-Object {$_.ManagedMachineData.VirtualCenterData.VirtualMachinePowerState -ne "POWERED_OFF"}
        $totalDesktops = $desktops.Count
        Write-Log "Disable Pool $($Name)"
        Set-HVPool  -PoolName $Name -Disable
        Start-Sleep 2
        Write-Log "Initiate the shutdown for all the VMs."
        foreach ($desktop in $desktops.base.Name) { 
            Shutdown-VMGuest -VM $desktop -Confirm:$False | Out-Null
        }
        $boot.firstvmname = $desktops[0].base.dnsname

        $desktops = Get-HVMachine -PoolName $Name | Where-Object {$_.ManagedMachineData.VirtualCenterData.VirtualMachinePowerState -ne "POWERED_OFF"}

        $startTime = Get-Date
        $date = Get-Date
        $timeout = 180
        while ($desktops.Count -ne 0) {
            $desktops = Get-HVMachine -PoolName $Name | Where-Object {$_.ManagedMachineData.VirtualCenterData.VirtualMachinePowerState -ne "POWERED_OFF"}	
            Write-Log -Update "$($desktops.Count) of $($totalDesktops) still running."
            $date = Get-Date
            if (($date - $startTime).TotalMinutes -gt $timeout) {
                throw "Shutdown took to long." 
            }
            Start-Sleep 10
        }    
        Write-Log "All VMs are down."

    } 

    $Boot.bootstart = get-date -format o
    Start-Sleep -Seconds 10
    $BootStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $hvService = $Global:VSIHV_ConnectionServer.ExtensionData
    $desktopservice = New-Object vmware.hv.DesktopService
    $farmservice = New-Object vmware.hv.FarmService
    if ($RDSH) {
        Write-Log "Enabling provisioning of farm F_$Name with $VMAmount VMs"
        $Pool = Get-HVPool -PoolName $Name -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true
        $Farm = Get-HVFarm -hvServer $Global:VSIHV_ConnectionServer -FarmName "F_$Name"
        $farmhelper = $farmservice.read($hvservice, $farm.id)
        $farmhelper.getDataHelper().setEnabled($True)
        $farmhelper.getAutomatedFarmDataHelper().getRdsServerNamingSettingsHelper().getPatternNamingSettingsHelper().setMaxNumberOfRDSServers($VMAmount)
        $farmhelper.getAutomatedFarmDataHelper().getVirtualCenterProvisioningSettingsHelper().setenableprovisioning($True)
        $farmservice.update($hvservice, $farmhelper)
        WaitFor-AvailableMachines -DesktopPoolName $Name -VMAmount $VMAmount -RDSH
        
    } else {
        if ($AllMachinesUpFront) {
            if ($Increment -gt 0) {
                Write-Log "Enabling up front provisioning of pool $Name with an increment of $Increment"
                while ($availableCount -lt $VMAmount) {
                    # Increase VM's by increment
                    $Pool = Get-HVPool -PoolName $Name -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true
                    if ($Pool.Type -eq "AUTOMATED") {
                        $currentCount = $pool.AutomatedDesktopData.VmNamingSettings.PatternNamingSettings.MaxNumberOfMachines
            
                        if (($currentCount + $increment) -gt $VMAmount) {
                            $newMax = $VMAmount
                        } else {
                            $newMax = $currentCount + $increment
                        }
                        $desktophelper = $desktopservice.read($hvService, $pool.id)
                        $desktophelper.getdesktopsettingshelper().setEnabled($True)
                        $desktophelper.getAutomatedDesktopDataHelper().getVmNamingSettingsHelper().getPatternNamingSettingsHelper().setMaxNumberOfMachines($newMax)
                        $desktophelper.getAutomatedDesktopDataHelper().getVmNamingSettingsHelper().getPatternNamingSettingsHelper().setProvisioningtime($desktophelper.getAutomatedDesktopDataHelper().getVmNamingSettingsHelper().getPatternNamingSettingsHelper().PROVISIONING_TIME_UP_FRONT)
                        $desktophelper.getAutomatedDesktopDataHelper().getVirtualCenterProvisioningSettingsHelper().setenableprovisioning($True)
                        $desktophelper.getAutomatedDesktopDataHelper().getVirtualCenterProvisioningSettingsHelper().setStopProvisioningOnError($False)
                        $desktopservice.update($hvservice, $desktophelper)
                        WaitFor-AvailableMachines -DesktopPoolName $Name -VMAmount $newMax
                    }
                }
                Write-Log ""
            } else {
                Write-Log "Enabling up front provisioning of pool $Name with $VMAmount VMs"
                $Pool = Get-HVPool -PoolName $Name -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true
                if ($Pool.Type -eq "AUTOMATED") {
                    $desktophelper = $desktopservice.read($hvService, $pool.id)
                    $desktophelper.getdesktopsettingshelper().setEnabled($True)
                    $desktophelper.getAutomatedDesktopDataHelper().getVmNamingSettingsHelper().getPatternNamingSettingsHelper().setMaxNumberOfMachines($VMAmount)
                    $desktophelper.getAutomatedDesktopDataHelper().getVmNamingSettingsHelper().getPatternNamingSettingsHelper().setProvisioningtime($desktophelper.getAutomatedDesktopDataHelper().getVmNamingSettingsHelper().getPatternNamingSettingsHelper().PROVISIONING_TIME_UP_FRONT)
                    $desktophelper.getAutomatedDesktopDataHelper().getVirtualCenterProvisioningSettingsHelper().setenableprovisioning($True)
                    $desktophelper.getAutomatedDesktopDataHelper().getVirtualCenterProvisioningSettingsHelper().setStopProvisioningOnError($False)
                    $desktopservice.update($hvservice, $desktophelper)
                    WaitFor-AvailableMachines -DesktopPoolName $Name -VMAmount $VMAmount
                }
            }
        } else {
            Write-Log "Enabling OnDemand provisioning of pool $Name with $NumberOfSpareVMs spare VMs"
            $Pool = Get-HVPool -PoolName $Name -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true
            if ($Pool.Type -eq "AUTOMATED") {
                $desktophelper = $desktopservice.read($hvService, $pool.id)
                $desktophelper.getdesktopsettingshelper().setEnabled($True)
                $desktophelper.getAutomatedDesktopDataHelper().getVmNamingSettingsHelper().getPatternNamingSettingsHelper().setMinNumberOfMachines(1)
                $desktophelper.getAutomatedDesktopDataHelper().getVmNamingSettingsHelper().getPatternNamingSettingsHelper().setMaxNumberOfMachines($VMAmount)
                $desktophelper.getAutomatedDesktopDataHelper().getVmNamingSettingsHelper().getPatternNamingSettingsHelper().setNumberOfSpareMachines($NumberOfSpareVMs)
                $desktophelper.getAutomatedDesktopDataHelper().getVmNamingSettingsHelper().getPatternNamingSettingsHelper().setProvisioningtime($desktophelper.getAutomatedDesktopDataHelper().getVmNamingSettingsHelper().getPatternNamingSettingsHelper().PROVISIONING_TIME_ON_DEMAND)
                $desktophelper.getAutomatedDesktopDataHelper().getVirtualCenterProvisioningSettingsHelper().setenableprovisioning($True)
                $desktophelper.getAutomatedDesktopDataHelper().getVirtualCenterProvisioningSettingsHelper().setStopProvisioningOnError($False)
                $desktopservice.update($hvservice, $desktophelper)

                WaitFor-AvailableMachines -DesktopPoolName $Name -VMAmount $NumberOfSpareVMs
            }
        }
    }

    $BootStopwatch.stop()
    $Boot.boottime = $BootStopwatch.elapsed.totalseconds
    $Boot

}

function WaitFor-AvailableMachines {
    Param($DesktopPoolName, $VMAmount, [switch]$RDSH)
    if ($RDSH) {
        $queryService = New-Object VMware.Hv.QueryServiceService
        $Farm = Get-HVFarm -FarmName "F_$DesktopPoolName"
        while ($true) {
            $query = New-Object VMware.Hv.QueryDefinition
            $query.queryEntityType = 'RDSServerSummaryView'
            $filter = New-Object VMware.Hv.QueryFilterEquals -Property @{ 'memberName' = 'base.farm'; 'value' = $farm.id }
            $query.filter = $filter
            $Results = @()
            $GetNext = $false
            $queryResults = $queryService.QueryService_Create($hvservice, $query)
            do {
                if ($GetNext) { $queryResults = $queryService.QueryService_GetNext($hvservice, $queryResults.id) }
                $Results += $queryResults.results
                $GetNext = $true
            }
            while ($queryResults.remainingCount -gt 0)
            $queryService.QueryService_Delete($hvservice, $queryResults.id)
            $Machines = $Results
            $MachineNames = $Machines | ForEach-Object { $_.base | Select-Object -ExpandProperty Name }
            $ErrorMachines = $Machines | Where-Object { $_.RuntimeData.Status -like "*ERROR*" -or $_.RuntimeData.Status -like "*AGENT*" -or $_.RuntimeData.Status -like "*USED*" }
            $AssignedMachines = $Machines | Where-Object { $null -ne $_.base.users }
            $AssignedMachineCount = ($AssignedMachines | Measure-Object).Count
            $ErrorMachineCount = ($ErrorMachines | Measure-Object).Count
            $AvailableCount = ($Machines | Where-Object { $_.RuntimeData.Status -eq "AVAILABLE" } | Measure-Object).Count
            $ProvisioningMachinesCount = ($Machines | Measure-Object).Count - $ErrorMachineCount - $AvailableCount - $AssignedMachineCount
            $Sessions = Get-HVLocalSession | Where-Object { $MachineNames.Contains($_.NamesData.MachineOrRDSServerName) }
            if ($null -ne $Sessions) {
                $MachinesWithSessions = $Sessions | ForEach-Object { $_.NamesData | Select-Object -ExpandProperty MachineOrRDSServerName }
                VMware.VimAutomation.Core\Get-VM -Name $MachinesWithSessions -Server $global:VSIHV_vCenter | VMware.VimAutomation.Core\Restart-VM -Confirm:$false -Server $global:VSIHV_vCenter | Out-Null
                Start-Sleep -Seconds 30
            }
            Write-Log -Update "$AvailableCount/$ProvisioningMachinesCount/$ErrorMachineCount/$AssignedMachineCount/$VMAmount (Available/Provisioning/Errors/Assigned/Total)..."
            if ($provisioningMachinesCount -gt 0) {
                Start-Sleep -Seconds 10
                continue
            }
            $RDSService = New-Object vmware.hv.RDSServerService
            foreach ($errormachine in $errormachines) {
                $RDSService.RDSServer_Recover($hvservice, $errormachine.Id)
            }
            if ($availableCount -eq $VMAmount) { break }
            Start-Sleep -Seconds 10
        }
        Write-Log ""
    } else {
        while ($true) {
            $Machines = Get-HVMachine -PoolName $Name -ErrorAction Ignore -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $True
            if ($null -eq $Machines) { Start-Sleep -Seconds 10; continue }
            $MachineNames = $Machines | ForEach-Object { $_.base | Select-Object -ExpandProperty Name }
            $ErrorMachines = $Machines | Where-Object { $_.base.BasicState -like "*ERROR*" -or $_.base.BasicState -like "*AGENT*" -or $_.base.BasicState -like "*USED*" }
            $AssignedMachines = $Machines | Where-Object { $null -ne $_.base.users }
            $AssignedMachineCount = ($AssignedMachines | Measure-Object).Count
            $ErrorMachineCount = ($ErrorMachines | Measure-Object).Count
            $AvailableCount = ($Machines | Where-Object { $_.base.BasicState -eq "AVAILABLE" } | Measure-Object).Count
            $ProvisioningMachinesCount = ($Machines | Measure-Object).Count - $ErrorMachineCount - $AvailableCount - $AssignedMachineCount
            $Sessions = Get-HVLocalSession | Where-Object { $MachineNames.Contains($_.NamesData.MachineOrRDSServerName) }
            if ($null -ne $Sessions) {
                $MachinesWithSessions = $Sessions | ForEach-Object { $_.NamesData | Select-Object -ExpandProperty MachineOrRDSServerName }
                VMware.VimAutomation.Core\Get-VM -Name $MachinesWithSessions -Server $global:VSIHV_vCenter | VMware.VimAutomation.Core\Restart-VM -Confirm:$false -Server $global:VSIHV_vCenter | Out-Null
                Start-Sleep -Seconds 30
            }
            Write-Log -Update "$AvailableCount/$ProvisioningMachinesCount/$ErrorMachineCount/$AssignedMachineCount/$VMAmount (Available/Provisioning/Errors/Assigned/Total)..."

            if ($provisioningMachinesCount -gt 0) {
                Start-Sleep -Seconds 10
                continue
            }
            $machineService = New-Object vmware.hv.MachineService
            foreach ($errormachine in $errormachines) {
                $machineService.Machine_Recover($hvservice, $errormachine.Id)
            }
            if ($AssignedMachineCount -gt 0) {
                Remove-HVMachine -MachineNames $AssignedMachines.Base.Name -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true -Confirm:$false -DeleteFromDisk | Out-Null
            }
            if ($availableCount -eq $VMAmount) { break }
            if ($availableCount -gt $VMAmount) {
                $AmountToRemove = $AvailableCount - $VMAmount
                $MachinesToRemove = $Machines | Where-Object { $_.base.BasicState -eq "AVAILABLE" } | select -First $AmountToRemove
                Remove-HVMachine -MachineNames $MachinesToRemove.Base.Name -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true -Confirm:$false -DeleteFromDisk | Out-Null
            }
            Start-Sleep -Seconds 10
        }
        Write-Log ""
    }
}
