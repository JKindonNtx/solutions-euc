function Set-VSICTXDesktopPoolAz {
    param(
        $DesktopPoolName,    
        $HypervisorConnection,
        $SessionsSupport,
        $ParentVM,
        [ValidateSet("Premium_LRS", "StandardSSD", "StandardHDD", "Ephemeral")]
        $Storage = "Premium_LRS",
        $VMSize = "Standard_D2s_v3",
        $NetworkPath,
        [switch]$Force,
        $NamingPattern,
        $OU,
        $DomainName,       
        $ZoneName,
        $EntitledGroup,
        $ResourceGroup,
        [switch]$SkipImagePrep,
        [switch]$UseSharedImageGallery,
        [switch]$UseManagedDisk
    )
    $DesktopKind = "Shared"
    $AllocationType = "Random"
    
    $CreatePool = $true
    
    
    Write-Log "Checking if desktoppool $DesktopPoolName exists..."
    $DG = Get-BrokerDesktopGroup -Name $DesktopPoolName -erroraction SilentlyContinue
    if ($null -ne $DG) {
        Write-Log "Checking the catalog to see if image configuration is same as requested"
        
        $Catalog = Get-BrokerCatalog -Name $DesktopPoolName -ErrorAction SilentlyContinue
        if ($null -ne $Catalog) {
            $ProvisioningScheme = Get-ProvScheme -ProvisioningSchemeUid $Catalog.ProvisioningSchemeId
            if ($ProvisioningScheme.MasterImageVM -eq $ParentVM) {
                Write-Log "Catalog $DesktopPoolName already configured to use $ParentVM"
                $CreatePool = $false
            } else {
                Write-Log "Catalog $DesktopPoolName is currently configured to use: $($ProvisioningScheme.MasterImageVM), requested: $ParentVM, recreating"
            }
        } else {
            Write-Log "Catalog $DesktopPoolName does not exist, creating"
        }
    }
    if ($Force) { Write-Log "Force specified, removing existing configuration and recreating..." }
    if ($CreatePool -eq $true -or $Force) {
        
        if ($null -ne $DG) {
            Write-Log "Removing existing desktopgroup $DesktopPoolName"
            Remove-BrokerDesktopGroup -Name $DesktopPoolName -Force
        }
        if ($null -ne (Get-BrokerCatalog -Name $DesktopPoolName -ErrorAction SilentlyContinue)) {
            Write-Log "Removing existing catalog $DesktopPoolName"
            Remove-BrokerCatalog -Name $DesktopPoolName
        }
        if ($null -ne (Get-ProvScheme -ProvisioningSchemeName $DesktopPoolName -ea SilentlyContinue)) {
            Write-Log "Removing existing VMS for $DesktopPoolName"
            Get-ProvVM -ProvisioningSchemeName $DesktopPoolName | Unlock-ProvVM
            $Tasks = Get-ProvVM -ProvisioningSchemeName $DesktopPoolName | Remove-ProvVM
            foreach ($Task in $Tasks) {
                if ($Task.TaskState -ne "Finished") {
                    Write-Log "Failed to remove VM, attempting to remove with forget"
                    $VM = Get-ProvVM -ProvisioningSchemeName $DesktopPoolName | Where-Object { $_.ADAccountSid -eq $Task.FailedVirtualMachines[0] }
                    $Task2 = $VM  | Remove-ProvVM -ForgetVM
                    if ($Task2.TaskState -ne "Finished") {
                        throw "Failed to remove existing VM $($VM.VMName) from provisioning scheme"
                    }
                }
            }
            Write-Log "Removing existing provisioningscheme $DesktopPoolName"
            Remove-ProvScheme -ProvisioningSchemeName $DesktopPoolName
            
            
        }
        $IP = Get-AcctIdentityPool -IdentityPoolName $DesktopPoolName -ea SilentlyContinue
        if ($null -ne $IP) {
            if ($IP.Lock -eq $true) {
                $IP | Unlock-AcctIdentityPool
            }
            Write-Log "Removing existing AD Accounts for $DesktopPoolName"
            if ($null -ne (Get-AcctADAccount -IdentityPoolName $DesktopPoolName -ea SilentlyContinue)) {
                Get-AcctADAccount -IdentityPoolName $DesktopPoolName | Where-Object { $_.Lock -eq $true } | Foreach-Object { $_ | Unlock-AcctADAccount | Out-Null }
                Get-AcctADAccount -IdentityPoolName $DesktopPoolName | Foreach-Object { $_ | Remove-AcctADAccount -Force | Out-Null }
            }
            Write-Log "Removing existing identitypool $DesktopPoolName"
            Remove-AcctIdentityPool -IdentityPoolName $DesktopPoolName
        }
        Write-Log "Creating identitypool $DesktopPoolName"
        $Zone = Get-ConfigZone -Name $ZoneName
        $IP = New-AcctIdentityPool -IdentityPoolName $DesktopPoolName -NamingScheme $NamingPattern -NamingSchemeType Numeric -OU $OU -Domain $DomainName -ZoneUid $Zone.Uid -AllowUnicode -DeviceManagementType None -IdentityType ActiveDirectory -ErrorAction Stop
        Write-Log "Creating provisioningscheme $DesktopPoolName"
        $HostingUnit = "XDHyp:\HostingUnits\$HypervisorConnection"
        #Write-Host $HypervisorConnection $ParentVM
        $Net = Get-Item $NetworkPath
        $CustomProperties = "<CustomProperties xmlns=`"http://schemas.citrix.com/2014/xd/machinecreation`" xmlns:xsi=`"http://www.w3.org/2001/XMLSchema-instance`"><Property xsi:type=`"StringProperty`" Name=`"UseManagedDisks`" Value=`"$($UseManagedDisk.ToString().ToLower())`" /><Property xsi:type=`"StringProperty`"
        Name=`"StorageType`" Value=`"$Storage`"/><Property xsi:type=`"StringProperty`" Name=`"LicenseType`" Value=`"Windows_Client`" /><Property xsi:type=`"StringProperty`" Name=`"ResourceGroups`" Value=`"$ResourceGroup`" /><Property xsi:type=`"StringProperty`" Name=`"UseSharedImageGallery`" Value=`"$($UseSharedImageGallery.ToString().ToLower())`"/></CustomProperties>"

        $provTaskId = New-ProvScheme -ProvisioningSchemeName $DesktopPoolName `
            -HostingUnitName $HypervisorConnection `
            -CustomProperties $CustomProperties `
            -ServiceOffering "$HostingUnit\serviceoffering.folder\$VMSize.serviceoffering" `
            -CleanOnBoot `
            -IdentityPoolName $DesktopPoolName `
            -MasterImageVM $ParentVM `
            -NetworkMapping @{ "0" = $Net.FullPath } `
            -NoImagePreparation:$SkipImagePrep `
            -RunAsynchronously
        $provtask = Get-ProvTask -TaskId $provTaskId
        While ($provtask.Active -eq $true) {
            try {
                $totalpercent = If ($provTask.TaskProgress) { $provTask.TaskProgress } else { 0 }
            } catch {
            }
            Write-Log -Update "$totalPercent% Complete:" -percentComplete $totalpercent
            Start-Sleep 3
            Connect-VSICTX -ClientID $VSI_Target_ClientID -Secret $VSI_Target_Secret -CustomerID $VSI_Target_CustomerID
            $provtask = Get-ProvTask -TaskId $provTaskId
        }
        
        if ($provTask.WorkflowStatus -ne "Completed") {
            Write-Log "Failed to create Provisioning scheme"
            return $provTask
        }
        
        # if ($SkipImagePrep) {
        #     Set-ProvSchemeMetadata -ProvisioningSchemeName $DesktopPoolName -Name ImageManagementPrep_DoImagePreparation -Value $false
        # } else {
        #     Set-ProvSchemeMetadata -ProvisioningSchemeName $DesktopPoolName -Name ImageManagementPrep_DoImagePreparation -Value $true
        # }
        #if ($SessionsSupport -eq "MultiSession") {
        $DesktopKind = "Shared"
        $AllocationType = "Random"
        #} else {
        #   $DesktopKind = "Private"
        #   $AllocationType = "Static"
        #
        Write-Log "Creating catalog $DesktopPoolName"
        $Catalog = New-BrokerCatalog -AllocationType $AllocationType `
            -Description "Created by LoginVSI" `
            -MinimumFunctionalLevel "L7_7" `
            -Name $DesktopPoolName `
            -PersistUserChanges "Discard" `
            -SessionSupport $SessionsSupport `
            -ProvisioningType "MCS" `
            -ProvisioningSchemeId $provTask.ProvisioningSchemeUid `
            -ZoneUid $Zone.Uid
        
        
        Write-Log "Creating desktopgroup $DesktopPoolName"
        $DG = New-BrokerDesktopGroup -DeliveryType DesktopsOnly -DesktopKind $DesktopKind -Description "Created by LoginVSI" -ColorDepth TwentyFourBit -Name $DesktopPoolName -PublishedName $DesktopPoolName -SessionSupport $SessionsSupport -MachineLogonType ActiveDirectory -ShutdownDesktopsAfterUse $true -ErrorAction Stop
        Start-Sleep -Seconds 30
    }

    $DG = Get-BrokerDesktopGroup -Name $DesktopPoolName
    if ($DesktopKind -eq "Shared") {
        Get-BrokerEntitlementPolicyRule -Name "$($DesktopPoolName)*" -ea SilentlyContinue | Remove-BrokerEntitlementPolicyRule
        $Entitlement = New-BrokerEntitlementPolicyRule -IncludedUserFilterEnabled $false -DesktopGroupUid $DG.Uid -Name "$($DesktopPoolName)_1" -PublishedName $DesktopPoolName
    } else {
        Get-BrokerAssignmentPolicyRule -Name $DesktopPoolName -ea SilentlyContinue | Remove-BrokerAssignmentPolicyRule
        $Assignment = New-BrokerAssignmentPolicyRule -DesktopGroupUid $DG.Uid -IncludedUsers $EntitledGroup -IncludedUserFilterEnabled $true -Name $DesktopPoolName
    }
    Get-BrokerAccessPolicyRule -Name "$($DesktopPoolName)*" -ea SilentlyContinue | Remove-BrokerAccessPolicyRule
    $AccessPolicyViaAG = New-BrokerAccessPolicyRule -AllowedUsers AnyAuthenticated -AllowedConnections ViaAG -AllowRestart $true -AllowedProtocol @("HDX", "RDP") -DesktopGroupUid $DG.Uid -Name "$($DesktopPoolName)_AG" -IncludedUserFilterEnabled $true -IncludedSmartAccessFilterEnabled $true  -IncludedUsers $EntitledGroup
    $AccessPolicyNotViaAG = New-BrokerAccessPolicyRule -AllowedUsers AnyAuthenticated -AllowedConnections NotViaAG -AllowRestart $true -AllowedProtocol @("HDX", "RDP") -DesktopGroupUid $DG.Uid -Name "$($DesktopPoolName)_Direct" -IncludedUserFilterEnabled $true -IncludedSmartAccessFilterEnabled $true  -IncludedUsers $EntitledGroup
        

}