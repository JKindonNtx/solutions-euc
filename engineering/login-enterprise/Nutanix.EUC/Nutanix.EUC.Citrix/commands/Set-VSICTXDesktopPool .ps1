function Set-VSICTXDesktopPool {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$DesktopPoolName,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$ParentVM,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][switch]$Force,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$HypervisorConnection,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$CpuCount,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$MemoryMB,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$NamingPattern,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$OU,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$DomainName,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$SessionsSupport,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$ZoneName,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$EntitledGroup,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][boolean]$SkipImagePrep,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$FunctionalLevel = "L7_22",
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$DDC
    )

    $DesktopKind = "Shared"
    $AllocationType = "Random"
    $CreatePool = $true
    $MaxRecordCount = 5000

    Write-Log -Message "Checking if desktoppool $DesktopPoolName exists..." -Level Info
    $DG = Get-BrokerDesktopGroup -AdminAddress $DDC -Name $DesktopPoolName -erroraction SilentlyContinue

    if ($null -ne $DG) {
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

    if ($Force) { Write-Log -Message "Force specified, removing existing configuration and recreating..." -Level Info }

    if ($CreatePool -eq $true -or $Force) {
        if ($null -ne $DG) {
            Write-Log -Message "Removing existing desktopgroup $DesktopPoolName" -Level Info
            try {
                Remove-BrokerDesktopGroup -AdminAddress $DDC -Name $DesktopPoolName -Force -ErrorAction Stop
            }
            catch {
                Write-Log -Message $_ -Level Error
                Break
            }
                
        }
        if ($null -ne (Get-BrokerCatalog -AdminAddress $DDC -Name $DesktopPoolName -ErrorAction SilentlyContinue)) {
            Write-Log -Message "Removing existing catalog $DesktopPoolName" -Level Info
            try {
                Remove-BrokerCatalog -AdminAddress $DDC -Name $DesktopPoolName -ErrorAction Stop
            }
            catch {
                Write-Log -Message $_ -Level Error
                Break
            }
                
        }
        if ($null -ne (Get-ProvScheme -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName -ea SilentlyContinue)) {
            Write-Log -Message "Removing existing VMS for $DesktopPoolName" -Level Info
            try {
                Get-ProvVM -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName | Unlock-ProvVM -ErrorAction Stop
            }
            catch {
                Write-Log -Message $_ -Level Error
                Break
            }
                
            try {
                $Tasks = Get-ProvVM -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName | Remove-ProvVM -ErrorAction Stop
            }
            catch {
                Write-Log -Message $_ -Level Error
                Break
            }
                
            foreach ($Task in $Tasks) {
                if ($Task.TaskState -ne "Finished") {
                    Write-Log -Message "Failed to remove VM, attempting to remove with forget" -Level Info
                    $VM = Get-ProvVM -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName | Where-Object { $_.ADAccountSid -eq $Task.FailedVirtualMachines[0] }
                    try {
                        $Task2 = $VM  | Remove-ProvVM -AdminAddress $DDC -ForgetVM -ErrorAction Stop
                    }
                    catch {
                        Write-Log -Message $_ -Level Error
                        Break
                    }
                        
                    if ($Task2.TaskState -ne "Finished") {
                        Write-Log -Message "Failed to remove existing VM $($VM.VMName) from provisioning scheme" -Level Error
                    }
                }
            }

            Write-Log -Message "Removing existing provisioningscheme $DesktopPoolName" -Level Info
            try {
                Remove-ProvScheme -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName -ErrorAction Stop
            }
            catch {
                Write-Log -Message $_ -Level Error
                Break
            }
        }

        $IP = Get-AcctIdentityPool -AdminAddress $DDC -IdentityPoolName $DesktopPoolName -ea SilentlyContinue

        if ($null -ne $IP) {
            if ($IP.Lock -eq $true) {
                try {
                    $IP | Unlock-AcctIdentityPool -ErrorAction Stop
                }
                catch {
                    Write-Log -Message $_ -Level Error
                    #Break
                }
            }
            Write-Log -Message "Removing existing AD Accounts for $DesktopPoolName" -ErrorAction Stop
            if ($null -ne (Get-AcctADAccount -AdminAddress $DDC -IdentityPoolName $DesktopPoolName -ea SilentlyContinue -MaxRecordCount $MaxRecordCount)) {
                Get-AcctADAccount -AdminAddress $DDC -IdentityPoolName $DesktopPoolName -MaxRecordCount $MaxRecordCount | Where-Object { $_.Lock -eq $true } | Foreach-Object { $_ | Unlock-AcctADAccount | Out-Null }
                Get-AcctADAccount -AdminAddress $DDC -IdentityPoolName $DesktopPoolName -MaxRecordCount $MaxRecordCount | Foreach-Object { $_ | Remove-AcctADAccount -Force | Out-Null }
            }
            Write-Log -Message "Removing existing identitypool $DesktopPoolName" -ErrorAction Stop
    
            try {
                Remove-AcctIdentityPool -AdminAddress $DDC -IdentityPoolName $DesktopPoolName -ErrorAction Stop
            }
            catch {
                Write-Log -Message $_ -Level Error
                #Break
            }  
        }

        Write-Log -Message "Creating identitypool $DesktopPoolName" -Level Info

        $Zone = Get-ConfigZone -AdminAddress $DDC -Name $ZoneName
        try {
            $IP = New-AcctIdentityPool -AdminAddress $DDC -IdentityPoolName $DesktopPoolName -NamingScheme $NamingPattern -NamingSchemeType Numeric -OU $OU -Domain $DomainName -ZoneUid $Zone.Uid -AllowUnicode -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break
        }

        Write-Log -Message "Creating provisioningscheme $DesktopPoolName" -Level Info
        try {
            $Task = New-ProvScheme -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName `
                -HostingUnitName $HypervisorConnection `
                -VMCpuCount $CpuCount `
                -VMMemoryMB $MemoryMB `
                -CleanOnBoot `
                -IdentityPoolName $DesktopPoolName `
                -MasterImageVM $ParentVM `
                -NoImagePreparation:$SkipImagePrep -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break
        }

        if ($Task.TaskState -ne "Finished") {
            Write-Log -Message "Failed to create Provisioning scheme" -Level Error
            Write-Log -Message $Task.TerminatingError -Level Error
        }

        Write-Log -Message "Creating catalog $DesktopPoolName" -Level Info
        $Params = @{
            AdminAddress           = $DDC 
            AllocationType         = $AllocationType
            Description            = "Created by LoginVSI"
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
        $params = @{
            AdminAddress             = $DDC 
            DeliveryType             = "DesktopsOnly" 
            DesktopKind              = $DesktopKind 
            Description              = "Created by LoginVSI" 
            ColorDepth               = "TwentyFourBit" 
            Name                     = $DesktopPoolName 
            PublishedName            = $DesktopPoolName 
            SessionSupport           = $SessionsSupport 
            MachineLogonType         = "ActiveDirectory"
            ShutdownDesktopsAfterUse = $true 
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

    $DG = Get-BrokerDesktopGroup -AdminAddress $DDC -Name $DesktopPoolName
    if ($DesktopKind -eq "Shared") {
        try {
            Get-BrokerEntitlementPolicyRule -AdminAddress $DDC -Name "$($DesktopPoolName)*" -ea SilentlyContinue | Remove-BrokerEntitlementPolicyRule -ErrorAction Stop
            $Entitlement = New-BrokerEntitlementPolicyRule -AdminAddress $DDC -IncludedUserFilterEnabled $true -IncludedUsers "$EntitledGroup" -DesktopGroupUid $DG.Uid -Name "$($DesktopPoolName)_1" -PublishedName $DesktopPoolName -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break
        }
    }
    else {
        try {
            Get-BrokerAssignmentPolicyRule -AdminAddress $DDC -Name $DesktopPoolName -ea SilentlyContinue | Remove-BrokerAssignmentPolicyRule -ErrorAction Stop
            $Assignment = New-BrokerAssignmentPolicyRule -AdminAddress $DDC -DesktopGroupUid $DG.Uid -IncludedUsers "$EntitledGroup" -IncludedUserFilterEnabled $true -Name $DesktopPoolName -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break
        }
    }
        
    try {
        Get-BrokerAccessPolicyRule -AdminAddress $DDC -Name "$($DesktopPoolName)*" -ea SilentlyContinue | Remove-BrokerAccessPolicyRule -ErrorAction Stop
        $AccessPolicyViaAG = New-BrokerAccessPolicyRule -AdminAddress $DDC -AllowedUsers Filtered -AllowedConnections ViaAG -AllowRestart $true -AllowedProtocol @("HDX", "RDP") -DesktopGroupUid $DG.Uid -Name "$($DesktopPoolName)_AG" -IncludedUserFilterEnabled $true -IncludedSmartAccessFilterEnabled $true  -IncludedUsers "$EntitledGroup" -ErrorAction Stop
        $AccessPolicyNotViaAG = New-BrokerAccessPolicyRule -AdminAddress $DDC -AllowedUsers Filtered -AllowedConnections NotViaAG -AllowRestart $true -AllowedProtocol @("HDX", "RDP") -DesktopGroupUid $DG.Uid -Name "$($DesktopPoolName)_Direct" -IncludedUserFilterEnabled $true -IncludedSmartAccessFilterEnabled $true  -IncludedUsers "$EntitledGroup" -ErrorAction Stop
    
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break
    }
}

