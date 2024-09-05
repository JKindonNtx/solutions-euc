function Set-VSICTXDesktopPoolNTNX {
    param(
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][String]$DesktopPoolName,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][String]$ParentVM,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][switch]$Force,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][String]$HypervisorConnection,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][String]$HypervisorType,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)]$Networkmap,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)]$CpuCount,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)]$CoresCount,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)]$MemoryGB,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$ContainerID,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][String]$NamingPattern,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][String]$OU,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][String]$DomainName,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][String]$SessionsSupport,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][String]$ZoneName,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][String]$EntitledGroup,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][boolean]$SkipImagePrep,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][String]$FunctionalLevel,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$CloneType,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][String]$DDC
    )
    $DesktopKind = "Shared"
    $AllocationType = "Random"
    #Add-PSSnapin Citrix*
    #Get-XDAuthentication -BearerToken $global:VSICTX_BearerToken
    if ($CloneType -eq "PVS") {
        $CreatePool = $false
    } 
    else {
        $CreatePool = $true
    }

    if ($SessionsSupport -eq "MultiSession") {
        $ShutdownDesktopsAfterUse = $false
    } 
    else {
        $ShutdownDesktopsAfterUse = $true
    }
    
    #region Check Desktop Group Exists
    Write-Log -Message "Checking if desktoppool $DesktopPoolName exists..." -Level Info
    $DG = Get-BrokerDesktopGroup -AdminAddress $DDC -Name $DesktopPoolName -erroraction SilentlyContinue
    if ($null -ne $DG) {
        if ($CloneType -eq "MCS") {
            Write-Log -Message "Checking the catalog to see if image configuration is same as requested" -Level Info
            $Catalog = Get-BrokerCatalog -AdminAddress $DDC -Name $DesktopPoolName -ErrorAction SilentlyContinue
            if ($null -ne $Catalog) {
                $ProvisioningScheme = Get-ProvScheme -AdminAddress $DDC -ProvisioningSchemeUid $Catalog.ProvisioningSchemeId
                if ($ProvisioningScheme.MasterImageVM -eq $ParentVM) {
                    Write-Log -Message "Catalog $DesktopPoolName already configured to use $ParentVM" -Level Info
                    $CreatePool = $false
                }
                else {
                    Write-Log -Message "Catalog $DesktopPoolName is currently configured to use: $($ProvisioningScheme.MasterImageVM), requested: $ParentVM, recreating" -Level Info
                }
            }
            else {
                Write-Log -Message "Catalog $DesktopPoolName does not exist, creating" -Level Info
            }
        }
    }
    #endregion Check Desktop Group Exists
    
    #region Create Catalog and Delivery Group
    if ($Force) { Write-Log -Message "Force specified, removing existing configuration and recreating..." -Level Info }
    if ($CreatePool -eq $true -or $Force) {
        
        if ($null -ne $DG) {
            Write-Log -Message "Removing existing desktopgroup $DesktopPoolName" -Level Info
            Remove-BrokerDesktopGroup -AdminAddress $DDC -Name $DesktopPoolName -Force
        }
        if ($null -ne (Get-BrokerCatalog -AdminAddress $DDC -Name $DesktopPoolName -ErrorAction SilentlyContinue)) {
            Write-Log -Message "Removing existing catalog $DesktopPoolName" -Level Info
            Remove-BrokerCatalog -AdminAddress $DDC -Name $DesktopPoolName
        }
        if ($null -ne (Get-ProvScheme -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName -ea SilentlyContinue)) {
            Write-Log -Message "Removing existing VMS for $DesktopPoolName" -Level Info
            Get-ProvVM -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName -MaxRecordCount 5000 | Unlock-ProvVM
            #$Tasks = Get-ProvVM -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName -MaxRecordCount 2500 | Remove-ProvVM
            $Tasks = ,(Get-ProvVM -ProvisioningSchemeName $DesktopPoolName -MaxRecordCount 5000) | Remove-ProvVM $DesktopPoolName
            foreach ($Task in $Tasks) {
                if ($Task.TaskState -ne "Finished") {
                    Write-Log -Message "Failed to remove VM, attempting to remove with forget" -Level Info
                    $VM = Get-ProvVM -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName -MaxRecordCount 2500 | Where-Object { $_.ADAccountSid -eq $Task.FailedVirtualMachines[0] }
                    $Task2 = $VM  | Remove-ProvVM -AdminAddress $DDC -ForgetVM
                    if ($Task2.TaskState -ne "Finished") {
                        Write-Log -Message "Failed to remove existing VM $($VM.VMName) from provisioning scheme" -Level Error
                        Exit 1
                    }
                }
            }
            Write-Log -Message "Removing existing provisioningscheme $DesktopPoolName"  -Level Info
            Remove-ProvScheme -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName
            
            
        }
        $IP = Get-AcctIdentityPool -AdminAddress $DDC -IdentityPoolName $DesktopPoolName -ea SilentlyContinue
        if ($null -ne $IP) {
            if ($IP.Lock -eq $true) {
                $IP | Unlock-AcctIdentityPool
            }
            Write-Log -Message "Removing existing AD Accounts for $DesktopPoolName" -Level Info
            if ($null -ne (Get-AcctADAccount -AdminAddress $DDC -IdentityPoolName $DesktopPoolName -MaxRecordCount 5000 -ea SilentlyContinue)) {
                Get-AcctADAccount -AdminAddress $DDC -IdentityPoolName $DesktopPoolName -MaxRecordCount 5000 | Where-Object { $_.Lock -eq $true } | Foreach-Object { $_ | Unlock-AcctADAccount | Out-Null }
                Get-AcctADAccount -AdminAddress $DDC -IdentityPoolName $DesktopPoolName -MaxRecordCount 5000 | Foreach-Object { $_ | Remove-AcctADAccount -Force | Out-Null }
            }
            Write-Log -Message "Removing existing identitypool $DesktopPoolName" -Level Info
            Remove-AcctIdentityPool -AdminAddress $DDC -IdentityPoolName $DesktopPoolName
        }
        Write-Log -Message "Creating identitypool $DesktopPoolName" -Level Info
        $Zone = Get-ConfigZone -AdminAddress $DDC -Name $ZoneName
        $IP = New-AcctIdentityPool -AdminAddress $DDC -IdentityPoolName $DesktopPoolName -NamingScheme $NamingPattern -NamingSchemeType Numeric -OU $OU -Domain $DomainName -ZoneUid $Zone.Uid -AllowUnicode -ErrorAction Stop
        Write-Log -Message "Creating provisioningscheme $DesktopPoolName" -Level Info
        
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
                Write-Log -Message "Failed to create Provisioning scheme" -Level Error
                Write-Log -Message "$($Task.TerminatingError)" -Level Error
                Exit 1
            }
            ## ESXi ##
        }
        elseif (($HypervisorType) -eq "ESXi") {
            # Update CPU Count to Reflect vCPUs and Cores
            $TotalCPU = [int]$CpuCount * [int]$CoresCount

            $provcustomProperties = @"
<CustomProperties xmlns="http://schemas.citrix.com/2014/xd/machinecreation">
    <StringProperty Name="UseManagedDisks" Value="true"/>
    <StringProperty Name="ManagedDisksPreview" Value="false"/>
</CustomProperties>
"@
            $Task = New-ProvScheme -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName `
                -HostingUnitName $HypervisorConnection `
                -VMCpuCount $TotalCPU `
                -VMMemoryMB $MemoryMB `
                -CleanOnBoot `
                -IdentityPoolName $DesktopPoolName `
                -MasterImageVM $ParentVM `
                -NetworkMapping $networkMap `
                -CustomProperties $provcustomProperties
            if ($Task.TaskState -ne "Finished") {
                Write-Log -Message "Failed to create Provisioning scheme" -Level Error
                Write-Log -Message "$($Task.TerminatingError)" -Level Error
                Exit 1
            }
        }

        Write-Log -Message "Creating catalog $DesktopPoolName" -Level Info
        $Params = @{
            AdminAddress           = $DDC
            AllocationType         = $AllocationType
            Description            = "Created by EUC Performance Engineering"
            MinimumFunctionalLevel = $FunctionalLevel
            Name                   = $DesktopPoolName
            PersistUserChanges     = "Discard"
            SessionSupport         = $SessionsSupport
            ProvisioningType       = "MCS"
            ProvisioningSchemeId   = $Task.ProvisioningSchemeUid
            ZoneUid                = $Zone.Uid
        }

        try {
            $Catalog = New-BrokerCatalog @Params -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break
        }
        $params = $null

        Write-Log -Message "Creating desktopgroup $DesktopPoolName" -Level Info
        $Params = @{
            AdminAddress             = $DDC
            DeliveryType             = "DesktopsOnly"
            DesktopKind              = $DesktopKind 
            Description              = "Created by EUC Performance Engineering" 
            ColorDepth               = "TwentyFourBit"
            Name                     = $DesktopPoolName 
            PublishedName            = $DesktopPoolName 
            SessionSupport           = $SessionsSupport 
            MachineLogonType         = "ActiveDirectory"
            ShutdownDesktopsAfterUse = $ShutdownDesktopsAfterUse
            MinimumFunctionalLevel   = $FunctionalLevel 
        }
        try {
            $DG = New-BrokerDesktopGroup @params -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break
        }
        $params = $null

        Write-Log -Message "Sleeping for 30 seconds" -Level Info
        Start-Sleep -Seconds 30
        
    }
    #endregion Create Catalog

    #region Create Desktop Group and Delivery Group
    if ($null -eq $DG) {
        if ($CloneType -eq "PVS") {
            Write-Log -Message "Creating desktopgroup $DesktopPoolName" -Level Info
            $Params = @{
                AdminAddress             = $DDC 
                DeliveryType             = "DesktopsOnly" 
                DesktopKind              = $DesktopKind 
                Description              = "Created by EUC Performance Engineering" 
                ColorDepth               = "TwentyFourBit" 
                Name                     = $DesktopPoolName 
                PublishedName            = $DesktopPoolName 
                SessionSupport           = $SessionsSupport 
                MachineLogonType         = "ActiveDirectory" 
                ShutdownDesktopsAfterUse = $ShutdownDesktopsAfterUse 
                MinimumFunctionalLevel   = $FunctionalLevel
            }
            try {
                $DG = New-BrokerDesktopGroup @params -ErrorAction Stop
            }
            catch {
                Write-Log -Message $_ -Level Error
                Break
            }
            $params = $null
            
            Write-Log -Message "Sleeping for 30 seconds" -Level Info
            Start-Sleep -Seconds 30

        }
    }
    #endregion Create Desktop Group

    #region Alter Desktop Group Access Policies
    Write-Log -Message "Handling Access Policies on $($DesktopPoolName)" -Level Info
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
    #endregion Alter Desktop Group Access Policies

    $HypConnectionName = (Get-Item -adminaddress $DDC XDHyp:\HostingUnits\$HypervisorConnection).HypervisorConnection.HypervisorConnectionName
    $PowerActions = Get-BrokerHypervisorConnection -adminaddress $DDC -Name $HypConnectionName | Select-Object *Actions*
    Return $PowerActions
}