function Get-VSIHVInfo {
    Param(
        $OutputFolder,
        $DesktopPoolName,
        $ConnectionServer,
        $ConnectionServerUser,
        $ConnectionServerPassword
    )

    If ($ConnectionServerUser.Contains("@")) {
        $Domain = $ConnectionServerUser.Split("@")[1]
        $User = $ConnectionServerUser.Split("@")[0]
    }
    else {
        $Domain = $ConnectionServerUser.Split("\")[0]
        $User = $ConnectionServerUser.Split("\")[1]
    }
    $Body = @{
        domain   = $Domain
        password = $ConnectionServerPassword
        username = $User
    } | ConvertTo-Json
    $token = Invoke-RestMethod -Method POST -Uri "https://$ConnectionServer/rest/login" -Body $Body -ContentType "application/json" -SkipCertificateCheck
    
    $Headers = @{
        "Authorization" = "Bearer $($token.access_token)";
        "Content-Type"  = "application/json"
    }
    
    $EnvironmentProperties = Invoke-RestMethod -Method GET -Uri "https://$ConnectionServer/rest/config/v2/environment-properties" -Headers $Headers -SkipCertificateCheck
    if ($EnvironmentProperties.local_connection_server_version -lt "8.4.0") {
        Write-Log -Message "Getting HorizonView additional information will only work with connection server version 8.4.0 and higher" -Level Warn
    }
    else {
        if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }
        if (-not (Test-Path "$OutputFolder\Configuration.csv")) {
            Set-Content -Path "$OutputFolder\Configuration.csv" -Value "1:l,2:l,3:l"
        }
        $DesktopPoolProperties = Invoke-RestMethod -Method GET -Uri "https://$ConnectionServer/rest/inventory/v5/desktop-pools?filter=%7B%22type%22%3A%22And%22%2C%20%22filters%22%3A%5B%7B%22type%22%3A%22Equals%22%2C%20%22name%22%3A%22name%22%2C%20%22value%22%3A%22$($DesktopPoolName)%22%7D%5D%20%7D&page=1&size=10" -Headers $Headers -SkipCertificateCheck
        Add-Content -Path "$OutputFolder\Configuration.csv" -Value "#Horizon,,"
        Add-Content -Path "$OutputFolder\Configuration.csv" -Value "Connection Server,$($EnvironmentProperties.local_connection_server_version),$($EnvironmentProperties.local_connection_server_build)"
        
        if ($DesktopPoolProperties.Type -eq "AUTOMATED") {
            $DesktopPoolMachines = Invoke-RestMethod -Method GET -Uri "https://$ConnectionServer/rest/inventory/v1/machines" -Headers $Headers -SkipCertificateCheck
            $FirstMachine = $DesktopPoolMachines | Where-Object { $_.desktop_pool_id }  | Select-Object -First 1
            if ($DesktopPoolProperties.automatic_user_assignment -eq $true) {
                $automatic = "(automatic)"
            }
            Add-Content -Path "$OutputFolder\Configuration.csv" -Value "Pool,$($DesktopPoolProperties.user_assignment) $automatic,$($DesktopPoolProperties.pattern_naming_settings.max_number_of_machines) $($DesktopPoolProperties.pattern_naming_settings.provisioning_time) ($($DesktopPoolProperties.pattern_naming_settings.number_of_spare_machines) spares)"
            Add-Content -Path "$OutputFolder\Configuration.csv" -Value "OU and Naming,$($DesktopPoolProperties.customization_settings.ad_container_rdn),$($DesktopPoolProperties.pattern_naming_settings.naming_pattern)"
            Add-Content -Path "$OutputFolder\Configuration.csv" -Value "Storage Accelerator,$($DesktopPoolProperties.view_storage_accelerator_settings.use_view_storage_accelerator),"
            Add-Content -Path "$OutputFolder\Configuration.csv" -Value "Agent,$($FirstMachine.agent_version),$($FirstMachine.agent_build_number)"
            
        }
        if ($DesktopPoolProperties.Type -eq "RDS") {
            $RDSServers = Invoke-RestMethod -Method GET -Uri "https://$ConnectionServer/rest/inventory/v1/rds-servers" -Headers $Headers -SkipCertificateCheck
            $FirstMachine = $RDSServers | Where-Object { $_.farm_id -eq $DesktopPoolProperties.farm_id }  | Select-Object -First 1
            $FarmProperties = Invoke-RestMethod -Method GET -Uri "https://$ConnectionServer/rest/inventory/v3/farms/$($DesktopPoolProperties.farm_id)" -SkipCertificateCheck -Headers $Headers
            Add-Content -Path "$OutputFolder\Configuration.csv" -Value "Pool,RDS,$($FarmProperties.automated_farm_settings.pattern_naming_settings.max_number_of_rds_servers) ($($FarmProperties.automated_farm_settings.min_ready_vms) min ready VMs)"
            Add-Content -Path "$OutputFolder\Configuration.csv" -Value "OU and Naming,$($FarmProperties.automated_farm_settings.customization_settings.ad_container_rdn),$($FarmProperties.automated_farm_settings.pattern_naming_settings.naming_pattern)"
            Add-Content -Path "$OutputFolder\Configuration.csv" -Value "Transparent Sharing,$($FarmProperties.automated_farm_setting.transparent_page_sharing_scope),"
            Add-Content -Path "$OutputFolder\Configuration.csv" -Value "Storage Accelerator,$($FarmProperties.automated_farm_settings.storage_settings.use_view_storage_accelerator),"
            Add-Content -Path "$OutputFolder\Configuration.csv" -Value "Agent,$($FirstMachine.agent_version),$($FirstMachine.agent_build_number)"
        }

        <#
        $output = New-Object -TypeName psobject -Property @{ConnectionServerVersion = $EnvironmentProperties.local_connection_server_version }
        $output | Add-Member -MemberType NoteProperty -Name ConnectionServerBuild -Value $EnvironmentProperties.local_connection_server_build
        if ($DesktopPoolProperties.Type -eq "AUTOMATED") {
            $DesktopPoolMachines = Invoke-RestMethod -Method GET -Uri "https://$ConnectionServer/rest/inventory/v1/machines" -Headers $Headers -SkipCertificateCheck
            $FirstMachine = $DesktopPoolMachines | Where-Object { $_.desktop_pool_id }  | Select-Object -First 1
            $output | Add-Member -MemberType NoteProperty -Name UserAssignement -Value $DesktopPoolProperties.user_assignment
            $output | Add-Member -MemberType NoteProperty -Name AutomaticUserAssignement -Value $DesktopPoolProperties.automatic_user_assignment
            $output | Add-Member -MemberType NoteProperty -Name NamingPattern -Value $DesktopPoolProperties.pattern_naming_settings.naming_pattern
            $output | Add-Member -MemberType NoteProperty -Name ProvisioningTime -Value $DesktopPoolProperties.pattern_naming_settings.provisioning_time
            $output | Add-Member -MemberType NoteProperty -Name MaxNumberOfMachines -Value $DesktopPoolProperties.pattern_naming_settings.max_number_of_machines
            $output | Add-Member -MemberType NoteProperty -Name NumberOfSpareMachines -Value $DesktopPoolProperties.pattern_naming_settings.number_of_spare_machines
            $output | Add-Member -MemberType NoteProperty -Name UseViewStorageAccelerator -Value $DesktopPoolProperties.view_storage_accelerator_settings.use_view_storage_accelerator
            $output | Add-Member -MemberType NoteProperty -Name ADContainer -Value $DesktopPoolProperties.customization_settings.ad_container_rdn
            $output | Add-Member -MemberType NoteProperty -Name AgentVersion -Value $FirstMachine.agent_version
            $output | Add-Member -MemberType NoteProperty -Name AgentBuild -Value $FirstMachine.agent_build_number
        }
        if ($DesktopPoolProperties.Type -eq "RDS") {
            $RDSServers = Invoke-RestMethod -Method GET -Uri "https://$ConnectionServer/rest/inventory/v1/rds-servers" -Headers $Headers -SkipCertificateCheck
            $FirstMachine = $RDSServers | Where-Object { $_.farm_id -eq $DesktopPoolProperties.farm_id }  | Select-Object -First 1
            $FarmProperties = Invoke-RestMethod -Method GET -Uri "https://$ConnectionServer/rest/inventory/v3/farms/$($DesktopPoolProperties.farm_id)" -SkipCertificateCheck -Headers $Headers
            $output | Add-Member -MemberType NoteProperty -Name ADContainer -Value $FarmProperties.automated_farm_settings.customization_settings.ad_container_rdn
            $output | Add-Member -MemberType NoteProperty -Name UseViewStorageAccelerator -Value $FarmProperties.automated_farm_settings.storage_settings.use_view_storage_accelerator
            $output | Add-Member -MemberType NoteProperty -Name MaxNumberOfRDSServers -Value $FarmProperties.automated_farm_settings.pattern_naming_settings.max_number_of_rds_servers
            $output | Add-Member -MemberType NoteProperty -Name NamingPattern -Value $FarmProperties.automated_farm_settings.pattern_naming_settings.naming_pattern
            $output | Add-Member -MemberType NoteProperty -Name MinReadyVMs -Value $FarmProperties.automated_farm_settings.min_ready_vms
            $output | Add-Member -MemberType NoteProperty -Name AgentVersion -Value $FirstMachine.agent_version
            $output | Add-Member -MemberType NoteProperty -Name AgentBuild -Value $FirstMachine.agent_build_number
            $output | Add-Member -MemberType NoteProperty -Name TransparentPageSharingScope -Value $FarmProperties.automated_farm_setting.transparent_page_sharing_scope
        }
        
       
        $output | Export-Csv -NoTypeInformation -Path "$OutputFolder\Horizon info.csv"
        #>
    }
}
