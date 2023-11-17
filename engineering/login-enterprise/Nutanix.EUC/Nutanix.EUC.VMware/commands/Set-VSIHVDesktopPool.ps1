function Set-VSIHVDesktopPool {
    param(
        $Name,
        $Description = "Created by VSI",
        $ParentVM,
        $VMSnapshot,
        $VMFolder,
        $HostOrCluster,
        $ResourcePool,
        $ReplicaDatastore,
        $InstantCloneDatastores,
        $NamingPattern,
        $NetBiosName,
        $ADContainer = "OU=Computers",
        $EntitledGroups,
        $PostSyncScript = "",
        $Protocol = "Blast",
        $vTPM = $false,
        $RefreshOsDiskAfterLogoff = "ALWAYS",
        $UserAssignment = "DEDICATED",
        [ValidateSet("RDSH", "InstantClone", "FullClone")]
        $PoolType = "InstantClone",
        $UseViewStorageAccelerator = $true,
        $enableGRIDvGPUs = $true
        
    )
    $CreatePool = $true
    $ExistingPool = Get-HVPool -PoolName $Name -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true
    if ($null -ne $ExistingPool) {
        Switch ($PoolType) {
            "RDSH" { 
                if ($ExistingPool.Type -eq "RDS") {
                    $ExistingFarm = Get-HVFarm -hvServer $Global:VSIHV_ConnectionServer | Where-Object { $_.Id.Id -eq $ExistingPool.RdsDesktopData.Farm.Id }
                    if ($null -ne $ExistingFarm) {
                        $CurrentParentVM = Split-Path $ExistingFarm.AutomatedFarmData.VirtualCenterNamesData.ParentVMPath -Leaf
                        $CurrentSnapshot = Split-Path $ExistingFarm.AutomatedFarmData.VirtualCenterNamesData.SnapshotPath -Leaf
                        if ($ParentVM -eq $CurrentParentVM -and $VMSnapshot -eq $CurrentSnapshot) {
                            Write-Log -Message "RDS farm with name F_$Name and ParentVM: $ParentVM and Snapshot: $VMSnapshot already exists, skipping creation" -Level Info
                            $CreatePool = $false
                        }
                        else {
                            Write-Log -Message "RDSFarm with name F_$Name already exists, but with different ParentVM configuration current: $CurrentParentVM/$CurrentSnapshot requested: $ParentVM/$VMSnapshot, removing" -Level Info
                            Remove-VSIHVDesktopPool -Name $Name
                        }
                    }
                    else {
                        Remove-VSIHVDesktopPool -Name $Name
                    }
                }
                else {
                    Write-Log -Message "Pool with name $Name already exists, but it's not an RDS type pool, removing" -Level Info
                    Remove-VSIHVDesktopPool -Name $Name
                }
            }
            "FullClone" { Write-Host "TODO: check fullclone image config" }
            "InstantClone" {
                if ($ExistingPool.Type -eq "AUTOMATED") {
                    # If pool exists, check the image /snapshot config and remove the pool
                    $CurrentParentVM = Split-Path $ExistingPool.AutomatedDesktopData.VirtualCenterNamesData.ParentVMPath -Leaf
                    $CurrentSnapshot = Split-Path $ExistingPool.AutomatedDesktopData.VirtualCenterNamesData.SnapshotPath -Leaf
                    if ($ParentVM -eq $CurrentParentVM -and $VMSnapshot -eq $CurrentSnapshot) {
                        Write-Log -Message "Desktop pool with name $Name and ParentVM: $ParentVM and Snapshot: $VMSnapshot already exists, skipping creation" -Level Info
                        $CreatePool = $false
                    }
                    else {
                        Write-Log -Message "Desktop pool with name $Name already exists, but with different ParentVM configuration current: $CurrentParentVM/$CurrentSnapshot requested: $ParentVM/$VMSnapshot, removing" -Level Info
                        Remove-VSIHVDesktopPool -Name $Name
                    }
                }
                else {
                    Write-Log -Message "Desktop pool with name $Name already exists, but it's not an InstantClone pool, removing" -Level Info
                    Remove-VSIHVDesktopPool -Name $Name
                }
            }
        }
    }
    $CommonArguments = @{
        
        VmFolder                               = $VMFolder
        HostOrCluster                          = $HostOrCluster
        ResourcePool                           = $ResourcePool
        NamingMethod                           = "PATTERN"
        Datastores                             = $InstantCloneDataStores
        NamingPattern                          = $NamingPattern
        NetBiosName                            = $NetBiosName
        ADContainer                            = $ADContainer
        ParentVM                               = $ParentVM
        SnapshotVM                             = $VMSnapshot
        UseSeparateDatastoresReplicaAndOSDisks = $true
        ReplicaDiskDatastore                   = $ReplicaDatastore
        DefaultDisplayProtocol                 = $Protocol.ToUpper()
        enableGRIDvGPUs                        = $enableGRIDvGPUs
    }
    If (-not ([string]::isNullOrEmpty($PostSyncScript))) {
        $CommonArguments.Add("PostSynchronizationSriptName", $PostSyncScript)
    }
    if ($CreatePool -eq $true) {
        Switch ($PoolType) {
            "InstantClone" {
                Write-Log -Message "Creating DesktopPool $Name with $ParentVM/$VMSnapshot as parent" -Level Info
                
                $CommonArguments.Add("UseViewStorageAccelerator", $UseViewStorageAccelerator)
                $CommonArguments.Add("ViewComposerDiskTypes", "OS_DISKS")
                $CommonArguments.Add("RegenerateViewStorageAcceleratorDays", 7)
                
                if ($UserAssignment.ToUpper() -eq "FLOATING") {
                    $CommonArguments.Add("deleteOrRefreshMachineAfterLogoff", "DELETE")
                }
                if ($UserAssignment.ToUpper() -eq "DEDICATED") {
                    $CommonArguments.Add("deleteOrRefreshMachineAfterLogoff", "REFRESH")
                    $CommonArguments.Add("refreshOsDiskAfterLogoff", $RefreshOsDiskAfterLogoff)
                }

                New-HVPool @CommonArguments -InstantClone `
                    -PoolName $Name `
                    -PoolDisplayName $Name `
                    -AddVirtualTPM $vTPM  `
                    -Description $Description `
                    -UserAssignment $UserAssignment.ToUpper() `
                | Out-Null

                Write-Log -Message "Waiting 60 seconds for DesktopPool $Name to be ready" -Level Info
                Start-Sleep -Seconds 60
                $PoolStatus = (Get-HVPool -PoolName $Name -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true).AutomatedDesktopData.ProvisioningStatusData.InstantCloneProvisioningStatusData
                while ($PoolStatus.Operation -ne "NONE") {
                    $PoolStatus = (Get-HVPool -PoolName $Name -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true).AutomatedDesktopData.ProvisioningStatusData.InstantCloneProvisioningStatusData
                    Write-Log -Update -Message "Progress:  $($Poolstatus.PendingImageProgress)" -Level Info
                    Start-Sleep -Seconds 10
                }
            }
            "RDSH" {

                $CommonArguments["VmFolder"] = Split-Path $VMFolder -Leaf
                $CommonArguments["ReplicaDiskDatastore"] = Split-Path $ReplicaDatastore -Leaf
                $CommonArguments["Datastores"] = $CommonArguments["Datastores"] | ForEach-Object { Split-Path $_ -Leaf }
                $ExistingFarm = Get-HVFarm -hvServer $Global:VSIHV_ConnectionServer -FarmName "F_$Name"
                
                if ($null -eq $ExistingFarm) {
                    
                    Write-Log -Message "Creating RDSH Farm F_$Name with $ParentVM/$VMSnapshot as parent" -Level Info
                    
                    New-HVFarm @CommonArguments -InstantClone `
                        -FarmName "F_$Name" `
                        -FarmDisplayName "F_$Name" `
                        -Description $Description | Out-Null
                    
                        Write-Log -Message "Waiting 60 seconds for Farm F_$Name to be ready" -Level Info
                    Start-Sleep -Seconds 60
                }

                $FarmStatus = (Get-HVFarm -FarmName F_$Name -HvServer $Global:VSIHV_ConnectionServer).AutomatedFarmData.ProvisioningStatusData.InstantCloneProvisioningStatusData
                while ($FarmStatus.Operation -ne "NONE") {
                    $FarmStatus = (Get-HVFarm -FarmName F_$Name -HvServer $Global:VSIHV_ConnectionServer).AutomatedFarmData.ProvisioningStatusData.InstantCloneProvisioningStatusData
                    Write-Log -Update -Message "Progress:  $($FarmStatus.PendingImageProgress)" -Level Info
                    Start-Sleep -Seconds 10
                }

                New-HVPool -Rds `
                    -PoolName $Name `
                    -PoolDisplayName $Name `
                    -Farm "F_$Name" `
                    -Description $Description | Out-Null
            }
        }
        
    }
    
    if (-not [string]::isNullOrEmpty($EntitledGroups)) {
        $ExistingEntitlements = Get-HVEntitlement -ResourceName $Name -Type Group -HvServer $Global:VSIHV_ConnectionServer
        
        Foreach ($EntitledGroup in $EntitledGroups.Split(",")) {
            foreach ($ExistingEntitlement in ($ExistingEntitlements | Where-Object { $_.base.loginName -eq $EntitledGroup.Split("\")[1] })) {
                $global:VSIHV_ConnectionServer.ExtensionData.UserEntitlement.UserEntitlement_DeleteUserEntitlements($ExistingEntitlement.LocalData.DesktopUserEntitlements)
            }
            New-HVEntitlement -ResourceName $Name -Type Group -ResourceType Desktop -User $EntitledGroup -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true
        }
    }
    if ($PoolType -ne "RDSH") {
        Set-HVPool -PoolName $Name -Stop -Disable -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true
    }
    
}