function Set-CVADDesktopPoolAPI {

    [CmdletBinding()]

    param(
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$DesktopPoolName,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$ParentVM,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][switch]$Force,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$HypervisorConnection,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$HypervisorType,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$Networkmap,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][int]$CpuCount,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][int]$CoresCount,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][int]$MemoryGB,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][string]$ContainerID,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$NamingPattern,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$OU,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$DomainName,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$SessionsSupport,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$ZoneName,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$EntitledGroup,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$SkipImagePrep,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$FunctionalLevel,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$CloneType,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$DDC,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$EncodedAdminCredential,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$DomainAdminCredential
    )

    #----------------------------------
    # Variables
    #----------------------------------
    $DesktopKind = "Shared"
    $AllocationType = "Random"
    $MemoryMB = $MemoryGB * 1024
    if ($SkipImagePrep = "True") { $PreparareImage = $False } else { $PreparareImage = $True }

    #----------------------------------
    # Execute logic
    #----------------------------------

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

    #region Check to see if the Delivery Group Exists and its associated Catalog/Prov Scheme
    Write-Log -Message "Checking if Delivery Group $($DesktopPoolName) exists" -Level Info
    #----------------------------------------------------------------------------------------------------------------------------
    # Set API call detail
    #----------------------------------------------------------------------------------------------------------------------------
    $Method = "Get"
    $RequestUri = "https://$DDC/cvad/manage/DeliveryGroups/"
    #----------------------------------------------------------------------------------------------------------------------------
    #----------------------------------------------------------------------------------------------------------------------------
    # Check that creds aren't expired before proceeding
    #----------------------------------------------------------------------------------------------------------------------------
    $Global:Headers = Get-CVADAuthDetailsAPI -DDC $DDC -EncodedAdminCredential $EncodedAdminCredential -DomainAdminCredential $DomainAdminCredential

    try {
        Write-Log -Message "Checking for Delivery Group: $($DesktopPoolName)"
        $delivery_group_exists = (Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop).Items | Where-Object { $_.Name -eq $DesktopPoolName }
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break #Replace with Exit 1
    }

    # Delivery Group Exists, Get MCS Provisioning details
    if (-not [string]::IsNullOrEmpty($delivery_group_exists)) {
        Write-Log -Message "Delivery Group $($DesktopPoolName) exists. Checking Catalog and Provisioning details"
        if ($CloneType -eq "MCS") {
            Write-Log -Message "Checking the catalog to see if image configuration is same as requested" -Level Info
            #----------------------------------------------------------------------------------------------------------------------------
            # Set API call detail
            #----------------------------------------------------------------------------------------------------------------------------
            $Method = "Get"
            $RequestUri = "https://$DDC/cvad/manage/MachineCatalogs/"
            #----------------------------------------------------------------------------------------------------------------------------
            try {
                Write-Log -Message "Checking to see if Catalog $($DesktopPoolName) exists" -Level Info
                $catalog_exists = (Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop).Items | Where-Object { $_.Name -eq $DesktopPoolName }
            }
            catch {
                Write-Log -Message $_ -Level Error
                Break #Replace with Exit 1
            }

            if (-not ([string]::IsNullOrEmpty($catalog_exists))) {
                # Compare the image current vs the image specified
                $image_requested = $ParentVM -replace ".template","" | Split-Path -leaf
                if ($catalog_exists.ProvisioningScheme.MasterImage.Name -eq $image_requested) {
                    Write-Log -Message "Catalog $($DesktopPoolName) is already configured to use $($catalog_exists.ProvisioningScheme.MasterImage.Name)" -Level Info
                    $CreatePool = $false
                }
                else {
                    Write-Log -Message "Catalog $($DesktopPoolName) is currently configured to use $($catalog_exists.ProvisioningScheme.MasterImage.Name), requested: $($image_requested), recreating" -Level Info
                }
            }
            else {
                Write-Log -Message "Catalog $($DesktopPoolName) does not exist, creating" -Level Info
            }
        }
    }
    #endregion Check to see if the Delivery Group Exists and its associated Catalog/Prov Scheme

    if ($Force) { Write-Log -Message "Force specified, removing existing configuration and recreating..." -Level Info }

    if ($CreatePool -eq $true -or $Force) {
        
        # Delete the existing Delivery Group
        if (-not [string]::IsNullOrEmpty($delivery_group_exists)) {
            Write-Log -Message "Removing Delivery Group $($DesktopPoolName)" -Level Info
            #----------------------------------------------------------------------------------------------------------------------------
            # Set API call detail
            #----------------------------------------------------------------------------------------------------------------------------
            $Method = "Delete"
            $RequestUri = "https://$DDC/cvad/manage/DeliveryGroups/$($DesktopPoolName)?async=true"
            #----------------------------------------------------------------------------------------------------------------------------
            #----------------------------------------------------------------------------------------------------------------------------
            # Check that creds aren't expired before proceeding
            #----------------------------------------------------------------------------------------------------------------------------
            $Global:Headers = Get-CVADAuthDetailsAPI -DDC $DDC -EncodedAdminCredential $EncodedAdminCredential -DomainAdminCredential $DomainAdminCredential

            try {
                Write-Log -Message "Deleting Delivery Group $($DesktopPoolName)" -Level Info
                $delivery_group_deletion = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
            }
            catch {
                Write-Log -Message $_ -Level Error
                Break #Replace with Exit 1
            }

            # Find the Job Id from a list of jobs
            #----------------------------------------------------------------------------------------------------------------------------
            # Set API call detail
            #----------------------------------------------------------------------------------------------------------------------------
            $Method = "Get"
            $RequestUri = "https://$DDC/cvad/manage/Jobs/"
            #----------------------------------------------------------------------------------------------------------------------------
            try {
                $jobs = (Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop).Items
            }
            catch {
                Write-Log -Message $_ -Level Error
                Break #Replace with Exit 1
            }

            $job = $jobs | Where-Object { $_.Type -eq "DeleteDeliveryGroup" -and $_.Parameters.Value -eq $($DesktopPoolName) } | Sort-Object CreationTime | Select-Object -last 1

            #Now go monitor the job
            #----------------------------------------------------------------------------------------------------------------------------
            # Set API call detail
            #----------------------------------------------------------------------------------------------------------------------------
            $Method = "Get"
            $RequestUri = "https://$DDC/cvad/manage/Jobs/$($job.id)"
            #----------------------------------------------------------------------------------------------------------------------------
            try {
                $job_status = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
            }
            catch {
                Write-Log -Message $_ -Level Error
                Break #Replace with Exit 1
            }

            while ($job_status.Status -ne "Complete") {
                if ($job_status.Status -eq "Failed") {
                    Write-Log -Message "Job Status is $($job_status.Status) with Error: $($job_status.ErrorString)" -Level Error
                    Break #Replace with Exit 1
                }
                Write-Log -Message "Job Status is $($job_status.Status) and is $($job_status.OverallProgressPercent) complete" -Level Info
                Start-Sleep 5
                Write-Log -Message "Getting Job status for Job ID: $($job.id)" -Level Info
                #----------------------------------------------------------------------------------------------------------------------------
                # Set API call detail
                #----------------------------------------------------------------------------------------------------------------------------
                $Method = "Get"
                $RequestUri = "https://$DDC/cvad/manage/Jobs/$($job.id)"
                #----------------------------------------------------------------------------------------------------------------------------
                try {
                    $job_status = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
                }
                catch {
                    Write-Log -Message $_ -Level Error
                    Break #Replace with Exit 1
                }
            }

            if ($job_status.status -eq "Complete") {
                Write-Log -Message "Delivery Group deleted successfully" -Level Info
            }
        }

        #----------------------------------------------------------------------------------------------------------------------------
        # Set API call detail
        #----------------------------------------------------------------------------------------------------------------------------
        $Method = "Get"
        $RequestUri = "https://$DDC/cvad/manage/MachineCatalogs/"
        #----------------------------------------------------------------------------------------------------------------------------
        try {
            Write-Log "Checking to see if Catalog $($DesktopPoolName) exists" -Level Info
            $catalog_exists = (Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop).Items | Where-Object { $_.Name -eq $DesktopPoolName }
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break #Replace with Exit 1
        }

        # Delete the existing Catalog and all VMs
        if (-not ([string]::IsNullOrEmpty($catalog_exists))) {
            Write-Log -Message "Deleting Catalog $($DesktopPoolName)" -Level Info
            #----------------------------------------------------------------------------------------------------------------------------
            # Set API call detail
            #----------------------------------------------------------------------------------------------------------------------------
            $Method = "Delete"
            $RequestUri = "https://$DDC/cvad/manage/MachineCatalogs/$($DesktopPoolName)?deleteVm=true&purgeDBOnly=false&deleteAccount=Delete&async=true" #this creates a job we need to go find with type DeleteMachineCatalog
            #----------------------------------------------------------------------------------------------------------------------------
            #----------------------------------------------------------------------------------------------------------------------------
            # Check that creds aren't expired before proceeding
            #----------------------------------------------------------------------------------------------------------------------------
            $Global:Headers = Get-CVADAuthDetailsAPI -DDC $DDC -EncodedAdminCredential $EncodedAdminCredential -DomainAdminCredential $DomainAdminCredential
            
            try { 
                $catalog_deletion = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
            }
            catch {
                Write-Log -Message $_ -Level Error
                Break #Replace with Exit 1
            }

            # Find the Job from a list of Jobs
            #----------------------------------------------------------------------------------------------------------------------------
            # Set API call detail
            #----------------------------------------------------------------------------------------------------------------------------
            $Method = "Get"
            $RequestUri = "https://$DDC/cvad/manage/Jobs/"
            #----------------------------------------------------------------------------------------------------------------------------

            try {
                $jobs = (Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop).Items
            }
            catch {
                Write-Log -Message $_ -Level Error
                Break #Replace with Exit 1
            }

            $job = $Jobs | Where-Object { $_.Type -eq "DeleteMachineCatalog" -and $_.Parameters.Value[0] -eq $($DesktopPoolName) } | Sort-Object CreationTime | Select-Object -last 1 # this should be accurate now, now we can get the unique job more efficiently

            # Now go monitor the job
            #----------------------------------------------------------------------------------------------------------------------------
            # Set API call detail
            #----------------------------------------------------------------------------------------------------------------------------
            $Method = "Get"
            $RequestUri = "https://$DDC/cvad/manage/Jobs/$($job.id)"
            #----------------------------------------------------------------------------------------------------------------------------
            try {
                $job_status = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
            }
            catch {
                Write-Log -Message $_ -Level Error
                Break #Replace with Exit 1
            }

            while ($job_status.Status -ne "Complete") {
                if ($job_status.Status -eq "Failed") {
                    Write-Log -Message "Job Status is $($job_status.Status) with Error: $($job_status.ErrorString)" -Level Error
                    Break #Replace with Exit 1
                }
                Write-Log -Message "Job Status is $($job_status.Status) and is $($job_status.OverallProgressPercent) complete" -Level Info
                Start-Sleep 5
                Write-Log -Message "Getting Job status for Job ID: $($job.id)" -Level Info
                #----------------------------------------------------------------------------------------------------------------------------
                # Set API call detail
                #----------------------------------------------------------------------------------------------------------------------------
                $Method = "Get"
                $RequestUri = "https://$DDC/cvad/manage/Jobs/$($job.id)"
                #----------------------------------------------------------------------------------------------------------------------------
                try {
                    $job_status = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
                }
                catch {
                    Write-Log -Message $_ -Level Error
                    Break #Replace with Exit 1
                }
            }

            if ($job_status.status -eq "Complete") {
                Write-Log -Message "Catalog $($DesktopPoolName) deleted successfully" -Level Info
            }

        }
        else {
            Write-Log -Message "Catalog does not exist. Creating" -Level Info
        }

        #region Create the Catalog

        # Create Catalog
        #----------------------------------------------------------------------------------------------------------------------------
        # Set API call detail
        #----------------------------------------------------------------------------------------------------------------------------
        $Method = "Post"
        $RequestUri = "https://$DDC/cvad/manage/MachineCatalogs?async=true"
        $ContentType = "application/json"

        if ($HypervisorType -eq "AHV") {
            $PayloadContent = @{
                Name                   = $DesktopPoolName
                AllocationType         = $AllocationType
                MinimumFunctionalLevel = $FunctionalLevel
                PersistUserChanges     = "Discard"
                ProvisioningType       = "MCS"
                SessionSupport         = $SessionsSupport
                Zone                   = $Zone 
                ProvisioningScheme     = @{ #ProvScheme Components
                    IdentityType                = "ActiveDirectory"
                    CleanOnBoot                 = $true
                    MasterImagePath             = $ParentVM
                    CpuCount                    = $CpuCount
                    MemoryMB                    = $MemoryMB
                    UseWriteBackCache           = $false
                    NumTotalMachines            = 0 
                    NetworkMapping              = @(
                        @{
                            DeviceNameOrId        = $VSI_Target_HypervisorNetwork
                            NetworkDeviceNameOrId = "0"
                            NetworkPath           = $Networkmap
                        }
                    )
                    MachineAccountCreationRules = @{ #AccIdentityPool components
                        NamingScheme     = $NamingScheme
                        NamingSchemeType = "numeric"
                        Domain           = $DomainName
                        OU               = $OU
                    }
                    CustomProperties            = @(
                        @{
                            Name  = "NutanixContainerId"
                            Value = $ContainerID 
                        }
                    )
                    CoresPerCpuCount            = $CoresCount
                    PrepareImage                = $PreparareImage
                }
            }
        }
        elseif ($HypervisorType -eq "ESXi") {
            # Update CPU Count to Reflect vCPUs and Cores
            $TotalCPU = [int]$CpuCount * [int]$CoresCount

            $PayloadContent = @{
                Name                   = $DesktopPoolName
                AllocationType         = $AllocationType
                MinimumFunctionalLevel = $FunctionalLevel
                PersistUserChanges     = "Discard"
                ProvisioningType       = "MCS"
                SessionSupport         = $SessionsSupport
                Zone                   = $Zone 
                ProvisioningScheme     = @{ #ProvScheme Components
                    IdentityType                = "ActiveDirectory"
                    CleanOnBoot                 = $true
                    MasterImagePath             = $ParentVM
                    CpuCount                    = $TotalCPU #Test this ESXi Value
                    MemoryMB                    = $MemoryMB
                    UseWriteBackCache           = $false
                    NumTotalMachines            = 0 
                    NetworkMapping              = @(
                        @{
                            DeviceNameOrId        = $VSI_Target_HypervisorNetwork
                            NetworkDeviceNameOrId = "0"
                            NetworkPath           = $Networkmap
                        }
                    )
                    MachineAccountCreationRules = @{ #AccIdentityPool components
                        NamingScheme     = $NamingScheme
                        NamingSchemeType = "numeric"
                        Domain           = $DomainName
                        OU               = $OU
                    }
                    CustomProperties            = @(
                        @{
                            UseManagedDisks     = $false #Test this ESXi Value
                            ManagedDisksPreview = $false  #Test this ESXi Value
                        }
                    )
                    #CoresPerCpuCount            = $CoresCount
                    PrepareImage                = $PreparareImage
                }
            }
        }
        $Payload = (ConvertTo-Json $PayloadContent -Depth 4)
        #----------------------------------------------------------------------------------------------------------------------------
        #----------------------------------------------------------------------------------------------------------------------------
        # Check that creds aren't expired before proceeding
        #----------------------------------------------------------------------------------------------------------------------------
        $Global:Headers = Get-CVADAuthDetailsAPI -DDC $DDC -EncodedAdminCredential $EncodedAdminCredential -DomainAdminCredential $DomainAdminCredential

        try {
            Write-Log -Message "Attempting to create Catalog $($DesktopPoolName) on Delivery Controller $($DDC)" -Level Info
            $Catalog = Invoke-RestMethod -Method $Method -Headers $Headers -Body $Payload -Uri $RequestUri -SkipCertificateCheck -ContentType $ContentType -TimeoutSec 2400 -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break #Replace with Exit 1
        }
       
        # Find the job ID from all jobs
        #----------------------------------------------------------------------------------------------------------------------------
        # Set API call detail
        #----------------------------------------------------------------------------------------------------------------------------
        $Method = "Get"
        $RequestUri = "https://$DDC/cvad/manage/Jobs/"
        #----------------------------------------------------------------------------------------------------------------------------
        try {
            $current_jobs = (Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop).Items
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break #Replace with Exit 1
        }
       
        $target_job = $current_jobs | Where-Object { $_.Type -eq "CreateMachineCatalog" } | Sort-Object CreationTime | Select-Object -Last 1    
        
        # Get the Job specifics and watch for completion
        #----------------------------------------------------------------------------------------------------------------------------
        # Set API call detail
        #----------------------------------------------------------------------------------------------------------------------------
        $Method = "Get"
        $RequestUri = "https://$DDC/cvad/manage/Jobs/$($target_job.Id)"
        #----------------------------------------------------------------------------------------------------------------------------
        try {
            $job = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break #Replace with Exit 1
        }
        
        $completed_jobs = @() #open the array to capture completed jobs
        while ($job.status -ne "Complete") {
            foreach ($subjob in $job.SubJobs) {
                if ($subjob.Status -ne "Complete") {
                    if ($subjob.Status -eq "Failed") {
                        Write-Log -Message "Job $($subjob.parameters.value) is Failed" -Level Warn
                        Break #Replace with Exit 1
                    }
                    Write-Log -Message "Job $($subjob.parameters.value) is $($subjob.Status)" -Level Info
                    Start-Sleep 5
                }
                elseif ($subjob.Status -eq "Complete" -and $subjob.parameters.value -notin $completed_jobs) {
                    Write-Log -Message "Job $($subjob.parameters.value) is complete" -Level Info
                    $completed_jobs += $subjob.parameters.value
                }
        
                try {
                    $job = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
                }
                catch {
                    Write-Log -Message $_ -Level Error
                }
            }
        }
        Write-Log -Message "Catalog Provisioning is complete" -Level Info
        #endregion Create the Catalog

        #region create the Delivery Group
        # Create the Delivery Group
        #----------------------------------------------------------------------------------------------------------------------------
        Write-Log -Message "Creating Delivery Group $($DesktopPoolName)" -Level Info
        #----------------------------------------------------------------------------------------------------------------------------
        # Set API call detail
        $Method = "Post"
        $RequestUri = "https://$DDC/cvad/manage/DeliveryGroups/?async=false"
        $ContentType = "application/json"
        $PayloadContent = @{
            AutoScaleEnabled         = $false
            ColorDepth               = "TwentyFourBit" 
            Description              = "Created by Nutanix EUC Automation"
            DeliveryType             = "DesktopsOnly"
            Desktops                 = @(
                @{
                    Enabled                   = $True
                    Description               = "Created by Nutanix EUC Automation"
                    IncludedUserFilterEnabled = $true
                    IncludedUsers             = @(
                        $EntitledGroup
                    )
                    Name                      = $DesktopPoolName
                    MaxDesktops               = 1
                    PublishedName             = $DesktopPoolName
                }
            )
            Enabled                  = $true
            InMaintenanceMode        = $false
            MachineLogonType         = "ActiveDirectory"
            MinimumFunctionalLevel   = $FunctionalLevel
            Timezone                 = "Pacific Standard Time"
            MachineCatalogs          = @(
                @{
                    MachineCatalog = $DesktopPoolName
                    Count          = 0
                }
            )
            Name                     = $DesktopPoolName
            SessionSupport           = $SessionsSupport
            ShutdownDesktopsAfterUse = $ShutdownDesktopsAfterUse
            SimpleAccessPolicy       = @{
                IncludedUserFilterEnabled = $true 
                IncludedUsers             = @(
                    $EntitledGroup
                )
            }
        }
        $Payload = (ConvertTo-Json $PayloadContent -Depth 4)
        #----------------------------------------------------------------------------------------------------------------------------
        #----------------------------------------------------------------------------------------------------------------------------
        # Check that creds aren't expired before proceeding
        #----------------------------------------------------------------------------------------------------------------------------
        $Global:Headers = Get-CVADAuthDetailsAPI -DDC $DDC -EncodedAdminCredential $EncodedAdminCredential -DomainAdminCredential $DomainAdminCredential

        try {
            $delivery_group_created = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -Body $Payload -ContentType $ContentType -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
            Write-Log -Message "Delivery Group $($delivery_group_created.Name) Created Successfully" -Level Info
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break #Replace with Exit 1
        }
        #endregion create the Delivery Group

    }
    
    # Handle PVS Delivery Group Creation if the DG doesnt exist.
    if ([string]::IsNullOrEmpty($delivery_group_exists)) {
        if ($CloneType -eq "PVS") {
            #region create the Delivery Group
            # Create the Delivery Group
            #----------------------------------------------------------------------------------------------------------------------------
            Write-Log -Message "Delivery Group $($DesktopPoolName) does not exist. Creating" -Level Info
            #----------------------------------------------------------------------------------------------------------------------------
            # Set API call detail
            $Method = "Post"
            $RequestUri = "https://$DDC/cvad/manage/DeliveryGroups/?async=false"
            $ContentType = "application/json"
            $PayloadContent = @{
                ColorDepth               = "TwentyFourBit" 
                Description              = "Created by Nutanix EUC Automation"
                DeliveryType             = "DesktopsOnly"
                Desktops                 = @(
                    @{
                        Enabled                   = $True
                        Description               = "Created by Nutanix EUC Automation"
                        IncludedUserFilterEnabled = $true
                        IncludedUsers             = @(
                            $EntitledGroup
                        )
                        Name                      = $DesktopPoolName
                        MaxDesktops               = 1
                        PublishedName             = $DesktopPoolName
                    }
                )
                Enabled                  = $true
                InMaintenanceMode        = $false
                MachineLogonType         = "ActiveDirectory"
                MinimumFunctionalLevel   = $FunctionalLevel
                Timezone                 = "Pacific Standard Time"
                MachineCatalogs          = @(
                    @{
                        MachineCatalog = $DesktopPoolName
                        Count          = 0
                    }
                )
                Name                     = $DesktopPoolName
                SessionSupport           = $SessionsSupport
                ShutdownDesktopsAfterUse = $ShutdownDesktopsAfterUse
                SimpleAccessPolicy       = @{
                    IncludedUserFilterEnabled = $true 
                    IncludedUsers             = @(
                        $EntitledGroup
                    )
                }
            }
            $Payload = (ConvertTo-Json $PayloadContent -Depth 4)
            #----------------------------------------------------------------------------------------------------------------------------
            #----------------------------------------------------------------------------------------------------------------------------
            # Check that creds aren't expired before proceeding
            #----------------------------------------------------------------------------------------------------------------------------
            $Global:Headers = Get-CVADAuthDetailsAPI -DDC $DDC -EncodedAdminCredential $EncodedAdminCredential -DomainAdminCredential $DomainAdminCredential

            try {
                $delivery_group_created = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -Body $Payload -ContentType $ContentType -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
                Write-Log -Message "Delivery Group $($delivery_group_created.Name) Created Successfully" -Level Info
            }
            catch {
                Write-Log -Message $_ -Level Error
                Break #Replace with Exit 1
            }
            #endregion create the Delivery Group
        }
    }
}