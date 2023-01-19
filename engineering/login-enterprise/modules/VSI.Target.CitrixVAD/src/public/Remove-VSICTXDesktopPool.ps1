function Remove-VSICTXDesktopPool {
    param(
        $DesktopPoolName,
        $ParentVM,
        [switch]$Force,
        $HypervisorConnection,
        $CpuCount,
        $MemoryMB,
        $NamingPattern,
        $OU,
        $DomainName,
        $SessionsSupport,
        $ZoneName,
        $EntitledGroup,
        [boolean]$SkipImagePrep,
        $FunctionalLevel = "L7_22",
        $DDC
    )

    #Add-PSSnapin Citrix*
    #Get-XDAuthentication -BearerToken $global:VSICTX_BearerToken
    
    
    Write-Log "Checking if desktoppool $DesktopPoolName exists..."
    $DG = Get-BrokerDesktopGroup -AdminAddress $DDC -Name $DesktopPoolName -erroraction SilentlyContinue
    if ($null -ne $DG) {
        Write-Log "Checking the catalog to see if image configuration is same as requested"
        
        $Catalog = Get-BrokerCatalog -AdminAddress $DDC -Name $DesktopPoolName -ErrorAction SilentlyContinue
        if ($null -ne $Catalog) {
            $ProvisioningScheme = Get-ProvScheme -AdminAddress $DDC -ProvisioningSchemeUid $Catalog.ProvisioningSchemeId
        }
        else {
            Write-Log "Catalog $DesktopPoolName does not exist."
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
            Get-ProvVM -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName | Unlock-ProvVM
            $Tasks = Get-ProvVM -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName | Remove-ProvVM
            foreach ($Task in $Tasks) {
                if ($Task.TaskState -ne "Finished") {
                    Write-Log "Failed to remove VM, attempting to remove with forget"
                    $VM = Get-ProvVM -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName | Where-Object { $_.ADAccountSid -eq $Task.FailedVirtualMachines[0] }
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
            if ($null -ne (Get-AcctADAccount -AdminAddress $DDC -IdentityPoolName $DesktopPoolName -ea SilentlyContinue -MaxRecordCount 2000)) {
                Get-AcctADAccount -AdminAddress $DDC -IdentityPoolName $DesktopPoolName -MaxRecordCount 2000 | Where-Object { $_.Lock -eq $true } | Foreach-Object { $_ | Unlock-AcctADAccount | Out-Null }
                Get-AcctADAccount -AdminAddress $DDC -IdentityPoolName $DesktopPoolName -MaxRecordCount 2000 | Foreach-Object { $_ | Remove-AcctADAccount -Force | Out-Null }
            }
            Write-Log "Removing existing identitypool $DesktopPoolName"
            Remove-AcctIdentityPool -AdminAddress $DDC -IdentityPoolName $DesktopPoolName
        }
    }
}