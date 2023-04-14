function Set-VSICTXDesktopPoolNTNX {
    param(
        $DesktopPoolName,
        $ParentVM,
        [switch]$Force,
        $HypervisorConnection,
        $HypervisorType,
        $Networkmap,
        $CpuCount,
        $CoresCount,
        $MemoryGB,
        $ContainerID,
        $NamingPattern,
        $OU,
        $DomainName,
        $SessionsSupport,
        $ZoneName,
        $EntitledGroup,
        [boolean]$SkipImagePrep,
        $FunctionalLevel,
        $DDC
    )
    $DesktopKind = "Shared"
    $AllocationType = "Random"
    #Add-PSSnapin Citrix*
    #Get-XDAuthentication -BearerToken $global:VSICTX_BearerToken
    $CreatePool = $true
    
    Write-Log "Checking if desktoppool $DesktopPoolName exists..."
    $DG = Get-BrokerDesktopGroup -AdminAddress $DDC -Name $DesktopPoolName -erroraction SilentlyContinue
    if ($null -ne $DG) {
        Write-Log "Checking the catalog to see if image configuration is same as requested"
        
        $Catalog = Get-BrokerCatalog -AdminAddress $DDC -Name $DesktopPoolName -ErrorAction SilentlyContinue
        if ($null -ne $Catalog) {
            $ProvisioningScheme = Get-ProvScheme -AdminAddress $DDC -ProvisioningSchemeUid $Catalog.ProvisioningSchemeId
            if ($ProvisioningScheme.MasterImageVM -eq $ParentVM) {
                Write-Log "Catalog $DesktopPoolName already configured to use $ParentVM"
                $CreatePool = $false
            }
            else {
                Write-Log "Catalog $DesktopPoolName is currently configured to use: $($ProvisioningScheme.MasterImageVM), requested: $ParentVM, recreating"
            }
        }
        else {
            Write-Log "Catalog $DesktopPoolName does not exist, creating"
        }
    }
    if ($Force) { Write-Log "Force specified, removing existing configuration and recreating..." }
    if ($CreatePool -eq $true -or $Force) {
        
        if ($null -ne $DG) {
            Write-Log "Removing existing desktopgroup $DesktopPoolName"
            Remove-BrokerDesktopGroup -AdminAddress $DDC -Name $DesktopPoolName -Force
        }
        if ($null -ne (Get-BrokerCatalog -AdminAddress $DDC -Name $DesktopPoolName -ErrorAction SilentlyContinue)) {
            Write-Log "Removing existing catalog $DesktopPoolName"
            Remove-BrokerCatalog -AdminAddress $DDC -Name $DesktopPoolName
        }
        if ($null -ne (Get-ProvScheme -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName -ea SilentlyContinue)) {
            Write-Log "Removing existing VMS for $DesktopPoolName"
            Get-ProvVM -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName -MaxRecordCount 2500 | Unlock-ProvVM
            $Tasks = Get-ProvVM -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName -MaxRecordCount 2500 | Remove-ProvVM
            foreach ($Task in $Tasks) {
                if ($Task.TaskState -ne "Finished") {
                    Write-Log "Failed to remove VM, attempting to remove with forget"
                    $VM = Get-ProvVM -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName -MaxRecordCount 2500 | Where-Object { $_.ADAccountSid -eq $Task.FailedVirtualMachines[0] }
                    $Task2 = $VM  | Remove-ProvVM -AdminAddress $DDC -ForgetVM
                    if ($Task2.TaskState -ne "Finished") {
                        throw "Failed to remove existing VM $($VM.VMName) from provisioning scheme"
                    }
                }
            }
            Write-Log "Removing existing provisioningscheme $DesktopPoolName"
            Remove-ProvScheme -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName
            
            
        }
        $IP = Get-AcctIdentityPool -AdminAddress $DDC -IdentityPoolName $DesktopPoolName -ea SilentlyContinue
        if ($null -ne $IP) {
            if ($IP.Lock -eq $true) {
                $IP | Unlock-AcctIdentityPool
            }
            Write-Log "Removing existing AD Accounts for $DesktopPoolName"
            if ($null -ne (Get-AcctADAccount -AdminAddress $DDC -IdentityPoolName $DesktopPoolName -MaxRecordCount 2500 -ea SilentlyContinue)) {
                Get-AcctADAccount -AdminAddress $DDC -IdentityPoolName $DesktopPoolName -MaxRecordCount 2500 | Where-Object { $_.Lock -eq $true } | Foreach-Object { $_ | Unlock-AcctADAccount | Out-Null }
                Get-AcctADAccount -AdminAddress $DDC -IdentityPoolName $DesktopPoolName -MaxRecordCount 2500 | Foreach-Object { $_ | Remove-AcctADAccount -Force | Out-Null }
            }
            Write-Log "Removing existing identitypool $DesktopPoolName"
            Remove-AcctIdentityPool -AdminAddress $DDC -IdentityPoolName $DesktopPoolName
        }
        Write-Log "Creating identitypool $DesktopPoolName"
        $Zone = Get-ConfigZone -AdminAddress $DDC -Name $ZoneName
        $IP = New-AcctIdentityPool -AdminAddress $DDC -IdentityPoolName $DesktopPoolName -NamingScheme $NamingPattern -NamingSchemeType Numeric -OU $OU -Domain $DomainName -ZoneUid $Zone.Uid -AllowUnicode -ErrorAction Stop
        Write-Log "Creating provisioningscheme $DesktopPoolName"
        #Write-Host $HypervisorConnection $ParentVM
        
        $MemoryMB = $($MemoryGB) * 1024
        
        ## AHV ##
        if (($HypervisorType) -eq "AHV") {
            $connectionCustomProperties = "<CustomProperties></CustomProperties>"
            $hostingCustomProperties = "<CustomProperties></CustomProperties>"
            $provcustomProperties = @"
<CustomProperties xmlns="http://schemas.citrix.com/2014/xd/machinecreation">
  <StringProperty Name="ContainerPath" Value="/$ContainerID.container"/>
  <StringProperty Name="vCPU" Value="$CpuCount"/>
  <StringProperty Name="RAM" Value="$MemoryMB"/>
  <StringProperty Name="CPUCores" Value="$CoresCount"/>
</CustomProperties>
"@

            $Task = New-ProvScheme -ProvisioningSchemeName $DesktopPoolName `
                -HostingUnitName $HypervisorConnection `
                -MasterImageVM $ParentVM `
                -VMMemoryMB $MemoryMB `
                -IdentityPoolName $DesktopPoolName `
                -CleanOnBoot `
                -NetworkMapping $networkMap `
                -CustomProperties $provcustomProperties
                if ($Task.TaskState -ne "Finished") {
                    Write-Log "Failed to create Provisioning scheme"
                    throw $Task.TerminatingError
                }
        ## ESXi ##
        } elseif (($HypervisorType) -eq "ESXi") {
            $Task = New-ProvScheme -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName `
                -HostingUnitName $HypervisorConnection `
                -VMCpuCount $CpuCount `
                -VMMemoryMB $MemoryMB `
                -CleanOnBoot `
                -IdentityPoolName $DesktopPoolName `
                -MasterImageVM $ParentVM `
                -NoImagePreparation:$SkipImagePrep
                if ($Task.TaskState -ne "Finished") {
                    Write-Log "Failed to create Provisioning scheme"
                    throw $Task.TerminatingError
                }
        }
        
        #if ($SessionsSupport -eq "MultiSession") {
        $DesktopKind = "Shared"
        $AllocationType = "Random"
        #} else {
        #   $DesktopKind = "Private"
        #   $AllocationType = "Static"
        #
        Write-Log "Creating catalog $DesktopPoolName"
        $Catalog = New-BrokerCatalog -AdminAddress $DDC -AllocationType $AllocationType `
            -Description "Created by LoginVSI" `
            -MinimumFunctionalLevel $FunctionalLevel `
            -Name $DesktopPoolName `
            -PersistUserChanges "Discard" `
            -SessionSupport $SessionsSupport `
            -ProvisioningType "MCS" `
            -ProvisioningSchemeId $Task.ProvisioningSchemeUid `
            -ZoneUid $Zone.Uid
        
        Write-Log "Creating desktopgroup $DesktopPoolName"
        $DG = New-BrokerDesktopGroup -AdminAddress $DDC -DeliveryType DesktopsOnly -DesktopKind $DesktopKind -Description "Created by LoginVSI" -ColorDepth TwentyFourBit -Name $DesktopPoolName -PublishedName $DesktopPoolName -SessionSupport $SessionsSupport -MachineLogonType ActiveDirectory -ShutdownDesktopsAfterUse $true -ErrorAction Stop
        Start-Sleep -Seconds 30
    }

    $DG = Get-BrokerDesktopGroup -AdminAddress $DDC -Name $DesktopPoolName
    if ($DesktopKind -eq "Shared") {
        Get-BrokerEntitlementPolicyRule -AdminAddress $DDC -Name "$($DesktopPoolName)*" -ea SilentlyContinue | Remove-BrokerEntitlementPolicyRule
        $Entitlement = New-BrokerEntitlementPolicyRule -AdminAddress $DDC -IncludedUserFilterEnabled $true -IncludedUsers "$EntitledGroup" -DesktopGroupUid $DG.Uid -Name "$($DesktopPoolName)_1" -PublishedName $DesktopPoolName
    }
    else {
        Get-BrokerAssignmentPolicyRule -AdminAddress $DDC -Name $DesktopPoolName -ea SilentlyContinue | Remove-BrokerAssignmentPolicyRule
        $Assignment = New-BrokerAssignmentPolicyRule -AdminAddress $DDC -DesktopGroupUid $DG.Uid -IncludedUsers "$EntitledGroup" -IncludedUserFilterEnabled $true -Name $DesktopPoolName
    }
    Get-BrokerAccessPolicyRule -AdminAddress $DDC -Name "$($DesktopPoolName)*" -ea SilentlyContinue | Remove-BrokerAccessPolicyRule
    $AccessPolicyViaAG = New-BrokerAccessPolicyRule -AdminAddress $DDC -AllowedUsers Filtered -AllowedConnections ViaAG -AllowRestart $true -AllowedProtocol @("HDX", "RDP") -DesktopGroupUid $DG.Uid -Name "$($DesktopPoolName)_AG" -IncludedUserFilterEnabled $true -IncludedSmartAccessFilterEnabled $true  -IncludedUsers "$EntitledGroup" 
    $AccessPolicyNotViaAG = New-BrokerAccessPolicyRule -AdminAddress $DDC -AllowedUsers Filtered -AllowedConnections NotViaAG -AllowRestart $true -AllowedProtocol @("HDX", "RDP") -DesktopGroupUid $DG.Uid -Name "$($DesktopPoolName)_Direct" -IncludedUserFilterEnabled $true -IncludedSmartAccessFilterEnabled $true  -IncludedUsers "$EntitledGroup"
        

}