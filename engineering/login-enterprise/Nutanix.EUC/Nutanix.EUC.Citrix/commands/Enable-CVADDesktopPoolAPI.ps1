Function Enable-CVADDesktopPoolAPI {
    Param(
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$DesktopPoolName,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][int]$NumberOfVMs,
        #$ADUserName,
        #$ADPassword,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][int]$PowerOnVMs,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][int]$VMRegistrationTimeOutMinutes = 180,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$DDC,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$HypervisorType,
        #[Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)]$Affinity,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$ClusterIP,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$CVMSSHPassword,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$VMnameprefix,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$CloneType,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$Hosts,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$Type,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$DomainName,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$OU,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$EncodedAdminCredential,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$DomainAdminCredential,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][int]$MaxRecordCount,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][bool]$ForceAlignVMToHost,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][bool]$EnforceHostMaintenanceMode,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][string]$TargetCVMAdmin,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][string]$TargetCVMPassword,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][string]$HostCount,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][string]$SingleHostTarget,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][string]$Run

    )
    $Boot = "" | Select-Object -Property bootstart,boottime    

    #region Power off VMs
    #region Get List of Machines in Delivery Group
    #----------------------------------------------------------------------------------------------------------------------------
    # Set API call detail
    #----------------------------------------------------------------------------------------------------------------------------
    $Method = "Get"
    $RequestUri = "https://$DDC/cvad/manage/DeliveryGroups/$($DesktopPoolName)/Machines?limit=1000"
    #----------------------------------------------------------------------------------------------------------------------------
    #----------------------------------------------------------------------------------------------------------------------------
    # Check that creds aren't expired before proceeding
    #----------------------------------------------------------------------------------------------------------------------------
    $Global:Headers = Get-CVADAuthDetailsAPI -DDC $DDC -EncodedAdminCredential $EncodedAdminCredential -DomainAdminCredential $DomainAdminCredential

    $delivery_group_machines = @() #Open the array to house the machines
    
    try {
        # Get the first run of machines
        $delivery_group_machines_grab = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop

        # Add them to the array
        $delivery_group_machines += $delivery_group_machines_grab.Items

        #Check and Set Continuation Token
        try { $continuation_token_exists = $delivery_group_machines_grab.ContinuationToken } catch { $continuation_token_exists = $null }

        # Check for a continuation token (there are more machines to get) and append the token to the next query in a loop, until its no longer there (all machines have been pulled)
        while (-not [string]::IsNullOrEmpty($continuation_token_exists)) {
            Write-Log -Message "Grabbing next batch of machines using continuation token $($delivery_group_machines_grab.ContinuationToken)" -Level Info
            #----------------------------------------------------------------------------------------------------------------------------
            # Set API call detail
            #----------------------------------------------------------------------------------------------------------------------------
            $Method = "Get"
            $RequestUri = "https://$DDC/cvad/manage/DeliveryGroups/$($DesktopPoolName)/Machines?limit=1000&ContinuationToken=$($delivery_group_machines_grab.ContinuationToken)"
            #----------------------------------------------------------------------------------------------------------------------------
            try {
                $delivery_group_machines_grab = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
            }
            catch {
                Write-Log -Message $_ -Level Error
                Break #Replace with Exit 1
            }
            
            # Add them to the array
            $delivery_group_machines += $delivery_group_machines_grab.Items

            #Check and Set Continuation Token
            try { $continuation_token_exists = $delivery_group_machines_grab.ContinuationToken } catch { $continuation_token_exists = $null }
        }
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break #Replace with Exit 1
    }

    Write-Log -Message "Retrieved $($delivery_group_machines.Count) machines from Delivery Group $($DesktopPoolName)" -Level Info

    #endregion Get List of Machines in Delivery Group

    # Set the familiar variables
    $Desktops = $delivery_group_machines

    # Filter the Powered On Machines
    $desktopson = $delivery_group_machines | Where-Object {$_.PowerState -eq "On"}

    if ((($desktopson | Measure-Object).Count -ne 0)) {
        #Start-Sleep 2
        Write-Log -Message "Initiate the shutdown for all the VMs." -Level Info
        foreach ($machine_to_target in $desktopson) {  
            #----------------------------------------------------------------------------------------------------------------------------
            # Set API call detail
            #----------------------------------------------------------------------------------------------------------------------------
            $Method = "Post"
            $RequestUri = "https://$DDC/cvad/manage/Machines/$($machine_to_target.Id)/`$shutdown?force=true&detailResponseRequired=false&async=true"
            #----------------------------------------------------------------------------------------------------------------------------
            Write-Log -Message "Stopping machine $($machine_to_target.Name) with Id $($machine_to_target.Id)" -Level Info
            try {
                $machine_stopped = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
            }
            catch {
                Write-Log -Message $_ -Level Error
                Exit 1
            }
        }

        $startTime = Get-Date
        $date = Get-Date
        $timeout = 180
        while (($desktopson | Measure-Object).Count -ne 0) {
            #region Get List of Machines in Delivery Group
            #----------------------------------------------------------------------------------------------------------------------------
            # Set API call detail
            #----------------------------------------------------------------------------------------------------------------------------
            $Method = "Get"
            $RequestUri = "https://$DDC/cvad/manage/DeliveryGroups/$($DesktopPoolName)/Machines?limit=1000"
            #----------------------------------------------------------------------------------------------------------------------------

            $delivery_group_machines = @() #Open the array to house the machines

            try {
                # Get the first run of machines
                $delivery_group_machines_grab = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
                
                # Add them to the array
                $delivery_group_machines += $delivery_group_machines_grab.Items 

                #Check and Set Continuation Token
                try { $continuation_token_exists = $delivery_group_machines_grab.ContinuationToken } catch { $continuation_token_exists = $null }

                # Check for a continuation token (there are more machines to get) and append the token to the next query in a loop, until its no longer there (all machines have been pulled)
                while (-not [string]::IsNullOrEmpty($continuation_token_exists)) {
                    Write-Log -Message "Grabbing next batch of machines using continuation token $($delivery_group_machines_grab.ContinuationToken)" -Level Info
                    #----------------------------------------------------------------------------------------------------------------------------
                    # Set API call detail
                    #----------------------------------------------------------------------------------------------------------------------------
                    $Method = "Get"
                    $RequestUri = "https://$DDC/cvad/manage/DeliveryGroups/$($DesktopPoolName)/Machines?limit=1000&ContinuationToken=$($delivery_group_machines_grab.ContinuationToken)"
                    #----------------------------------------------------------------------------------------------------------------------------
                    try {
                        $delivery_group_machines_grab = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
                    }
                    catch {
                        Write-Log -Message $_ -Level Error
                        Exit 1
                    }
                    
                    # Add them to the array
                    $delivery_group_machines += $delivery_group_machines_grab.Items

                    #Check and Set Continuation Token
                    try { $continuation_token_exists = $delivery_group_machines_grab.ContinuationToken } catch { $continuation_token_exists = $null }
                }
            }
            catch {
                Write-Log -Message $_ -Level Error
                Exit 1
            }

            #Write-Log -Message "Retrieved $($delivery_group_machines.Count) machines from Delivery Group $($DesktopPoolName)" -Level Info

            # Set the familiar variable
            $Desktops = $delivery_group_machines
            # Filter the Powered On Machines
            $desktopson = $delivery_group_machines | Where-Object { $_.PowerState -eq "On" }

            #endregion Get List of Machines in Delivery Group

            Write-Log -Update -Message "$(($desktopson | Measure-Object ).Count) of $(($desktops | Measure-Object).Count) still running." -Level Info
        
            $date = Get-Date
            if (($date - $startTime).TotalMinutes -gt $timeout) {
                Write-Log -Message "Shutdown took to long." -Level Error
                Exit 1
            }
            Start-Sleep 10
        }
        Write-Log -Message "All VMs are down." -Level Info
    }
    else {
        Write-Log -Message "All VMs are already down." -Level Info
    }

    #endregion Power off VMs

    if ($CloneType -eq "MCS"){
        # We already have this info from the above call
        $ExistingVMCount = ($Desktops | Measure-Object).Count  ##//JK At this stage, the count has come from the Delivery Group, not the Catalog. Machines may still exist but not be assigned

        #region figure out Catalog vs Delivery Group Numbers
        if ($ExistingVMCount -lt $NumberOfVMs) {
            # Delivery Group Needs more machines - check catalog
            Write-Log -Message "There are not enough machines in the Delivery Group. Delivery Group has $($ExistingVMCount) machines. Checking the Catalog: $($DesktopPoolName)" -Level Info
            # Now we need to go and poll the Catalog for Machines
            #----------------------------------------------------------------------------------------------------------------------------
            # Set API call detail
            #----------------------------------------------------------------------------------------------------------------------------
            $Method = "Get"
            $RequestUri = "https://$DDC/cvad/manage/MachineCatalogs/$($DesktopPoolName)/Machines/"
            #----------------------------------------------------------------------------------------------------------------------------
            try {
                Write-Log -Message "Getting Machines from Catalog: $($DesktopPoolName)" -Level Info
                $CatalogMachines = (Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop).Items
            }
            catch {
                Write-Log -Message $_ -Level Error
                Break #Replace with Exit 1
            }

            $CatalogMachineCount = ($CatalogMachines | Measure-Object).count
            # Now figure out where we are at with the counts
            if ($CatalogMachineCount -lt $NumberOfVMs) {
                # The Catalog does not have enough machines to handle the requirement.
                Write-Log -Message "The Catalog $($DesktopPoolName) does not have sufficient machines to meet the requirements. Catalog has $($CatalogMachineCount) machines." -Level Info
                # We need $numberOfMachines total, so subtract the existing number of Catalog Machines to figure out how many we need to provision.
                $NumberOfVMsToProvision = $NumberOfVMs - $CatalogMachines
                Write-Log -Message "Will provision an additional $($NumberOfVMsToProvision) machines in Catalog: $($DesktopPoolName)" -Level Info
            }
            elseif ($CatalogMachineCount -eq $NumberOfVMs) {
                Write-Log -Message "The Catalog $($DesktopPoolName) has sufficient machines to meet the requirements. Catalog has $($CatalogMachineCount) machines." -Level Info
                $NumberOfVMsToProvision = 0
                #We need to add machines to the Delivery Group as they are already provisioned. So take the number of VMs we need and minus the number we have. That tells us how many to add
                $DeliveryGroupAdditions = $NumberOfVMs - $ExistingVMCount
            }
            elseif ($CatalogMachineCount -gt $NumberOfVMs) {
                Write-Log -Message "The Catalog $($DesktopPoolName) has more machines than required to meet the requirements. Catalog has $($CatalogMachineCount) machines." -Level Info
                $NumberOfVMsToProvision = 0
                #We need to add machines to the Delivery Group as they are already provisioned. So take the number of VMs we need and minus the number we have. That tells us how many to add
                $DeliveryGroupAdditions = $NumberOfVMs - $ExistingVMCount
            }
        }
        else {
            Write-Log -Message "Delivery Group $($DesktopPoolName) has sufficient machines for the test." -Level Info
        }
        #endregion figure out Catalog vs Delivery Group Numbers
    } 
    else {
        $ExistingVMCount = $NumberOfVMs
    }
    
    #region handle MCS provisioning and Delivery Group Assignments
    if ($CloneType -eq "MCS"){
        
        Write-Log -Message "There are currently $($ExistingVMCount) VMs in $($DesktopPoolName)" -Level Info

        if ($NumberOfVMsToProvision -gt 0) {
            #----------------------------------------------------------------------------------------------------------------------------
            # Set API call detail
            #----------------------------------------------------------------------------------------------------------------------------
            $Method = "Post"
            $RequestUri = "https://$DDC/cvad/manage/`$Batch?async=true"
            $ContentType = "application/json"

            $machines_to_create = $NumberOfVMsToProvision
            $machine_creation_count = 0

            $BatchRequests = @() #open an empty array to contain the content for the Machine Creation

            while ($machine_creation_count -lt $machines_to_create) {
                $BodyTemplate = @{ # this needs to be added in to the $BatchRequests for each machine that needs to be created, incrementing the Reference by 1
                    Reference = "$machine_creation_count" # this needs to grow by 1 for each machine
                    Method = "Post"
                    RelativeUrl = "/MachineCatalogs/$($DesktopPoolName)/Machines"
                    Headers = @(
                        @{
                            Name = "X-AdminCredential"
                            Value = "Basic $DomainAdminCredential"
                        }
                        @{
                            Name = "Authorization"
                            Value = "CWSAuth Bearer=$AccessToken"
                        }
                        @{
                            Name = "X-CC-Locale"
                            Value = "en"
                        }
                    )
                    Body = "{""MachineAccountCreationRules"":{""NamingScheme"":""$VMnameprefix"",""NamingSchemeType"":""numeric"",""Domain"":""$DomainName"",""OU"":""$OU""}}"
                }
                
                $BatchRequests += $BodyTemplate #Add this iteration to the $BatchRequests array
                $machine_creation_count ++ # Increment the count
            }

            $PayloadContent = @{
                Items = @(
                    $BatchRequests
                )
            }
            $Payload = (ConvertTo-Json $PayloadContent -Depth 4)
            #----------------------------------------------------------------------------------------------------------------------------
            #----------------------------------------------------------------------------------------------------------------------------
            # Check that creds aren't expired before proceeding
            #----------------------------------------------------------------------------------------------------------------------------
            $Global:Headers = Get-CVADAuthDetailsAPI -DDC $DDC -EncodedAdminCredential $EncodedAdminCredential -DomainAdminCredential $DomainAdminCredential

            Write-Log -Message "Starting provisioning of $($NumberOfVMsToProvision) VMs in $($DesktopPoolName)" -Level Info
            try {
                $machine_provision_job = Invoke-RestMethod -Method $Method -Headers $Headers -Body $Payload -Uri $RequestUri -SkipCertificateCheck -ContentType $ContentType -ErrorAction Stop
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

            $job = $Jobs | Where-Object {$_.Type -eq "AddMachineCatalogMachine"} | Sort-Object CreationTime | Select-Object -Last 1

            while ($job.Status -ne "Complete") {
                if ($job.Status -eq "Failed") {
                    Write-Log -Message "Provisioning Job Failed with Error $($job.ErrorString) and Error Code $($job.ErrorCode)" -Level Error
                    Exit 1
                }
                #----------------------------------------------------------------------------------------------------------------------------
                # Set API call detail
                #----------------------------------------------------------------------------------------------------------------------------
                $Method = "Get"
                $RequestUri = "https://$DDC/cvad/manage/Jobs/$($job.Id)"
                #----------------------------------------------------------------------------------------------------------------------------
                try {
                    $job = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
                }
                catch {
                    Write-Log -Message $_ -Level Error
                    #Exit 1
                }
                Start-Sleep 5
            }

            Write-Log -Message "Provisioning Job is complete: $($job.Parameters[2].Value)" -Level Info

            #region Add Machines to Delivery Group
            $machines_to_add_to_delivery_group = $NumberOfVMsToProvision
            #----------------------------------------------------------------------------------------------------------------------------
            # Set API call detail
            #----------------------------------------------------------------------------------------------------------------------------
            $Method = "Post"
            $RequestUri = "https://$DDC/cvad/manage/DeliveryGroups/$($DesktopPoolName)/Machines?async=true"
            $ContentType = "application/json"
            $PayloadContent = @{
                MachineCatalog = $DesktopPoolName
                Count = $machines_to_add_to_delivery_group 
            }
            $Payload = (ConvertTo-Json $PayloadContent -Depth 4)
            #----------------------------------------------------------------------------------------------------------------------------
            #----------------------------------------------------------------------------------------------------------------------------
            # Check that creds aren't expired before proceeding
            #----------------------------------------------------------------------------------------------------------------------------
            $Global:Headers = Get-CVADAuthDetailsAPI -DDC $DDC -EncodedAdminCredential $EncodedAdminCredential -DomainAdminCredential $DomainAdminCredential

            Write-Log -Message "Adding $($machines_to_add_to_delivery_group) new machines to Delivery Group $($DesktopPoolName)" -Level Info
            try {
                $machine_add_to_delivery_group = Invoke-RestMethod -Method $Method -Headers $Headers -Body $Payload -Uri $RequestUri -SkipCertificateCheck -ContentType $ContentType -ErrorAction Stop
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

            $job = $Jobs | Where-Object {$_.Type -eq "AddDeliveryGroupMachines"} | Sort-Object CreationTime | Select-Object -Last 1

            while ($job.Status -ne "Complete") {
                if ($job.Status -eq "Failed") {
                    Write-Log -Message "Adding Machines to Delivery Group Failed with Error $($job.ErrorString) and Error Code $($job.ErrorCode)" -Level Error
                    Exit 1
                }
                #----------------------------------------------------------------------------------------------------------------------------
                # Set API call detail
                #----------------------------------------------------------------------------------------------------------------------------
                $Method = "Get"
                $RequestUri = "https://$DDC/cvad/manage/Jobs/$($job.Id)"
                #----------------------------------------------------------------------------------------------------------------------------
                try {
                    $job = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
                }
                catch {
                    Write-Log -Message $_ -Level Error
                    #Exit 1
                }
                Start-Sleep 5
            }

            Write-Log -Message "Adding Machines to Delivery Group Job is complete" -Level Info

            #endregion Add Machines to Delivery Group
        }

        #if we had machines in the Catalog already but need to add them to the Delivery Group
        if ($DeliveryGroupAdditions -gt 0) {
            #region Add Machines to Delivery Group
            $machines_to_add_to_delivery_group = $DeliveryGroupAdditions
            #----------------------------------------------------------------------------------------------------------------------------
            # Set API call detail
            #----------------------------------------------------------------------------------------------------------------------------
            $Method = "Post"
            $RequestUri = "https://$DDC/cvad/manage/DeliveryGroups/$($DesktopPoolName)/Machines?async=true"
            $ContentType = "application/json"
            $PayloadContent = @{
                MachineCatalog = $DesktopPoolName
                Count = $machines_to_add_to_delivery_group 
            }
            $Payload = (ConvertTo-Json $PayloadContent -Depth 4)
            #----------------------------------------------------------------------------------------------------------------------------
            #----------------------------------------------------------------------------------------------------------------------------
            # Check that creds aren't expired before proceeding
            #----------------------------------------------------------------------------------------------------------------------------
            $Global:Headers = Get-CVADAuthDetailsAPI -DDC $DDC -EncodedAdminCredential $EncodedAdminCredential -DomainAdminCredential $DomainAdminCredential

            Write-Log -Message "Adding $($machines_to_add_to_delivery_group) new machines to Delivery Group $($DesktopPoolName)" -Level Info
            try {
                $machine_add_to_delivery_group = Invoke-RestMethod -Method $Method -Headers $Headers -Body $Payload -Uri $RequestUri -SkipCertificateCheck -ContentType $ContentType -ErrorAction Stop
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

            $job = $Jobs | Where-Object {$_.Type -eq "AddDeliveryGroupMachines"} | Sort-Object CreationTime | Select-Object -Last 1

            while ($job.Status -ne "Complete") {
                if ($job.Status -eq "Failed") {
                    Write-Log -Message "Adding Machines to Delivery Group Failed with Error $($job.ErrorString) and Error Code $($job.ErrorCode)" -Level Error
                    Exit 1
                }
                #----------------------------------------------------------------------------------------------------------------------------
                # Set API call detail
                #----------------------------------------------------------------------------------------------------------------------------
                $Method = "Get"
                $RequestUri = "https://$DDC/cvad/manage/Jobs/$($job.Id)"
                #----------------------------------------------------------------------------------------------------------------------------
                try {
                    $job = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
                }
                catch {
                    Write-Log -Message $_ -Level Error
                    #Exit 1
                }
                Start-Sleep 5
            }

            Write-Log -Message "Adding Machines to Delivery Group Job is complete" -Level Info

            #endregion Add Machines to Delivery Group
        }
    }
    #endregion handle MCS provisioning and Delivery Group Assignments

    #region handle PVS Delivery Group Assignments
    if ($CloneType -eq "PVS"){
        # add VMs from PVS catalog to delivery group
        #Get-BrokerMachine -Filter {CatalogName -eq $DesktopPoolName -and DesktopGroupName -eq $null} -MaxRecordCount $MaxRecordCount | Select-Object -Property MachineName | Add-BrokerMachine -DesktopGroup $DesktopPoolName

        #region get a list of machines in the catalog
        #----------------------------------------------------------------------------------------------------------------------------
        # Set API call detail
        #----------------------------------------------------------------------------------------------------------------------------
        $Method = "Get"
        $RequestUri = "https://$DDC/cvad/manage/MachineCatalogs/$($DesktopPoolName)/Machines?limit=1000"
        #----------------------------------------------------------------------------------------------------------------------------

        $catalog_machines = @()

        try {
            # Get the first run of machines
            $catalog_machines_grab = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop

            # Add them to the array
            $catalog_machines += $catalog_machines_grab.Items

            #Check and Set Continuation Token
            try { $continuation_token_exists = $catalog_machines_grab.ContinuationToken } catch { $continuation_token_exists = $null }

            # Check for a continuation token (there are more machines to get) and append the token to the next query in a loop, until its no longer there (all machines have been pulled)
            while (-not [string]::IsNullOrEmpty($continuation_token_exists)) {
                Write-Log -Message "Grabbing next batch of machines using continuation token $($catalog_machines_grab.ContinuationToken)"
                #----------------------------------------------------------------------------------------------------------------------------
                # Set API call detail
                #----------------------------------------------------------------------------------------------------------------------------
                $Method = "Get"
                $RequestUri = "https://$DDC/cvad/manage/MachineCatalogs/$($DesktopPoolName)/Machines?limit=1000&ContinuationToken=$($catalog_machines_grab.ContinuationToken)"
                #----------------------------------------------------------------------------------------------------------------------------
                $catalog_machines_grab = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
                # Add them to the array
                $catalog_machines += $catalog_machines_grab.Items

                #Check and Set Continuation Token
                try { $continuation_token_exists = $catalog_machines_grab.ContinuationToken } catch { $continuation_token_exists = $null }
            }
        }
        catch {
            Write-Log -Message $_ -Level Error
            #Exit 1
        }

        Write-Log -Message "Retrieved $($catalog_machines.Count) machines from Catalog $($DesktopPoolName)" -Level Info

        #endregion get a list of machines in the catalog

        # Find machines that are not yet assigned to a Delivery Group in the list of Machines - grab the count only
        $machines_to_add_to_delivery_group = ($catalog_machines | Where-Object {[string]::IsNullOrEmpty($_.DeliveryGroup)} | Measure-Object ).Count

        #----------------------------------------------------------------------------------------------------------------------------
        # Set API call detail
        #----------------------------------------------------------------------------------------------------------------------------
        $Method = "Post"
        $RequestUri = "https://$DDC/cvad/manage/DeliveryGroups/$($DesktopPoolName)/Machines?async=true"
        $ContentType = "application/json"
        $PayloadContent = @{
            MachineCatalog = $DesktopPoolName
            Count = $machines_to_add_to_delivery_group 
        }
        $Payload = (ConvertTo-Json $PayloadContent -Depth 4)
        #----------------------------------------------------------------------------------------------------------------------------
        Write-Log -Message "Adding $($machines_to_add_to_delivery_group) machines to Delivery Group $($DesktopPoolName)" -Level Info
        try {
            $machine_add_to_delivery_group = Invoke-RestMethod -Method $Method -Headers $Headers -Body $Payload -Uri $RequestUri -SkipCertificateCheck -ContentType $ContentType -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Error
            #Exit 1
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
            #Exit 1
        }

        $job = $Jobs | Where-Object {$_.Type -eq "AddDeliveryGroupMachines"} | Sort-Object CreationTime | Select-Object -Last 1

        while ($job.Status -ne "Complete") {
            if ($job.Status -eq "Failed") {
                Write-Log -Message "Adding Machines to Delivery Group Failed with Error $($job.ErrorString) and Error Code $($job.ErrorCode)" -Level Error
                Exit 1
            }
            #----------------------------------------------------------------------------------------------------------------------------
            # Set API call detail
            #----------------------------------------------------------------------------------------------------------------------------
            $Method = "Get"
            $RequestUri = "https://$DDC/cvad/manage/Jobs/$($job.Id)"
            #----------------------------------------------------------------------------------------------------------------------------
            try {
                $job = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
            }
            catch {
                Write-Log -Message $_ -Level Error
                #Exit 1
            }
            Start-Sleep 5
        }

        Write-Log -Message "Adding Machines to Delivery Group Job is complete" -Level Info
    }
    #endregion handle PVS Delivery Group Assignments

    #region Set affinity to hosts
    if (($HypervisorType) -eq "AHV" -and ($ForceAlignVMToHost)) {
        Write-Log "Hypervisortype = $HypervisorType and VM to Host Alignment is set to $($ForceAlignVMToHost)"
        $params = @{
            DDC                        = $DDC
            MachineCount               = $NumberOfVMs
            HostCount                  = $HostCount
            ClusterIP                  = $ClusterIP
            CVMsshpassword             = $CVMSSHPassword
            TargetCVMAdmin             = $TargetCVMAdmin 
            TargetCVMPassword          = $TargetCVMPassword 
            DesktopGroupName           = $DesktopPoolName
            Run                        = $Run
            MaxRecordCount             = $MaxRecordCount
            EnforceHostMaintenanceMode = $EnforceHostMaintenanceMode
            SingleHostTarget           = $SingleHostTarget
        }
        Set-NTNXHostAlignment @params
        $Params = $null
    }
    <# - Redundant Code Block post single node affinity logic move to Set-NTNXHostAlignment function
    if (($HypervisorType) -eq "AHV" -And ($Affinity) -and (-not $ForceAlignVMToHost)) {
        Write-Log "Hypervisortype = $HypervisorType and Single Node Affinity is set to $Affinity"
        $params = @{
            ClusterIP      = $ClusterIP
            CVMsshpassword = $CVMSSHPassword
            VMnameprefix   = $VMnameprefix
            hosts          = $hosts
            Run            = $Run
        }
        $AffinityProcessed = Set-AffinitySingleNode @params
        $Params = $null
    }
    #>

    #endregion set affinity to hosts

    $Boot.bootstart = get-date -format o
    Start-Sleep -Seconds 10
    $BootStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Write-Log -Message "Powering on $($PowerOnVMs) machines" -Level Info

    #region Power On VMs
    #region Get List of Machines in Delivery Group
    #----------------------------------------------------------------------------------------------------------------------------
    # Set API call detail
    #----------------------------------------------------------------------------------------------------------------------------
    $Method = "Get"
    $RequestUri = "https://$DDC/cvad/manage/DeliveryGroups/$($DesktopPoolName)/Machines?limit=1000"
    #----------------------------------------------------------------------------------------------------------------------------
    #----------------------------------------------------------------------------------------------------------------------------
    # Check that creds aren't expired before proceeding
    #----------------------------------------------------------------------------------------------------------------------------
    $Global:Headers = Get-CVADAuthDetailsAPI -DDC $DDC -EncodedAdminCredential $EncodedAdminCredential -DomainAdminCredential $DomainAdminCredential

    $delivery_group_machines = @() #Open the array to house the machines

    try {
        # Get the first run of machines
        $delivery_group_machines_grab = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
        
        # Add them to the array
        $delivery_group_machines += $delivery_group_machines_grab.Items 

        #Check and Set Continuation Token
        try { $continuation_token_exists = $delivery_group_machines_grab.ContinuationToken } catch { $continuation_token_exists = $null }

        # Check for a continuation token (there are more machines to get) and append the token to the next query in a loop, until its no longer there (all machines have been pulled)
        while (-not [string]::IsNullOrEmpty($continuation_token_exists)) {
            Write-Log -Message "Grabbing next batch of machines using continuation token $($delivery_group_machines_grab.ContinuationToken)" -Level Info
            #----------------------------------------------------------------------------------------------------------------------------
            # Set API call detail
            #----------------------------------------------------------------------------------------------------------------------------
            $Method = "Get"
            $RequestUri = "https://$DDC/cvad/manage/DeliveryGroups/$($DesktopPoolName)/Machines?limit=1000&ContinuationToken=$($delivery_group_machines_grab.ContinuationToken)"
            #----------------------------------------------------------------------------------------------------------------------------
            try {
                $delivery_group_machines_grab = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
            }
            catch {
                Write-Log -Message $_ -Level Error
                #Exit 1
            }
            
            # Add them to the array
            $delivery_group_machines += $delivery_group_machines_grab.Items

            #Check and Set Continuation Token
            try { $continuation_token_exists = $delivery_group_machines_grab.ContinuationToken } catch { $continuation_token_exists = $null }
        }
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break #Replace with Exit 1
    }

    Write-Log -Message "Retrieved $($delivery_group_machines.Count) machines from Delivery Group $($DesktopPoolName)" -Level Info

    #endregion Get List of Machines in Delivery Group

    $PoweredOnVMs = $delivery_group_machines | Sort-Object Name | Select-Object -First $PowerOnVMs
    #----------------------------------------------------------------------------------------------------------------------------
    # Check that creds aren't expired before proceeding
    #----------------------------------------------------------------------------------------------------------------------------
    $Global:Headers = Get-CVADAuthDetailsAPI -DDC $DDC -EncodedAdminCredential $EncodedAdminCredential -DomainAdminCredential $DomainAdminCredential

    foreach ($machine_to_target in $PoweredOnVMs) {
        #----------------------------------------------------------------------------------------------------------------------------
        # Set API call detail
        #----------------------------------------------------------------------------------------------------------------------------
        $Method = "Post"
        $RequestUri = "https://$DDC/cvad/manage/Machines/$($machine_to_target.Id)/`$start?detailResponseRequired=false&async=true"
        #----------------------------------------------------------------------------------------------------------------------------
        Write-Log -Message "Powering On machine $($machine_to_target.Name) with Id $($machine_to_target.Id)" -Level Info
        try {
            $machine_started = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break #Replace with Exit 1
        }
    }

    Write-Log -Message "Waiting for 30 seconds before starting poll for machine registration" -level Info
    Start-Sleep 30
    #endregion Power On VMs

    # Wait untill NumberOfVMs matches buffer provided

    #region VDA Registration

    # Get the first run of machines
    
    #region Get List of Machines in Delivery Group
    #----------------------------------------------------------------------------------------------------------------------------
    # Set API call detail
    #----------------------------------------------------------------------------------------------------------------------------
    $Method = "Get"
    $RequestUri = "https://$DDC/cvad/manage/DeliveryGroups/$($DesktopPoolName)/Machines?limit=1000"
    #----------------------------------------------------------------------------------------------------------------------------
    #----------------------------------------------------------------------------------------------------------------------------
    # Check that creds aren't expired before proceeding
    #----------------------------------------------------------------------------------------------------------------------------
    $Global:Headers = Get-CVADAuthDetailsAPI -DDC $DDC -EncodedAdminCredential $EncodedAdminCredential -DomainAdminCredential $DomainAdminCredential

    $delivery_group_machines = @() #Open the array to house the machines

    try {
        $delivery_group_machines_grab = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
        
        # Add them to the array
        $delivery_group_machines += $delivery_group_machines_grab.Items
        
        #Check and Set Continuation Token
        try { $continuation_token_exists = $delivery_group_machines_grab.ContinuationToken } catch { $continuation_token_exists = $null }

        # Check for a continuation token (there are more machines to get) and append the token to the next query in a loop, until its no longer there (all machines have been pulled)
        while (-not [string]::IsNullOrEmpty($continuation_token_exists)) {
            Write-Log -Message "Grabbing next batch of machines using continuation token $($delivery_group_machines_grab.ContinuationToken)" -Level Info
            #----------------------------------------------------------------------------------------------------------------------------
            # Set API call detail
            #----------------------------------------------------------------------------------------------------------------------------
            $Method = "Get"
            $RequestUri = "https://$DDC/cvad/manage/DeliveryGroups/$($DesktopPoolName)/Machines?limit=1000&ContinuationToken=$($delivery_group_machines_grab.ContinuationToken)"
            #----------------------------------------------------------------------------------------------------------------------------
            try {
                $delivery_group_machines_grab = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
            }
            catch {
                Write-Log -Message $_ -Level Error
                Break #Replace with Exit 1
            }
            
            # Add them to the array
            $delivery_group_machines += $delivery_group_machines_grab.Items

            #Check and Set Continuation Token
            try { $continuation_token_exists = $delivery_group_machines_grab.ContinuationToken } catch { $continuation_token_exists = $null }
        }
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break #Replace with Exit 1
    }

    #Write-Log -Message "Retrieved $($delivery_group_machines.Count) machines from Delivery Group $($DesktopPoolName)" -Level Info

    #endregion Get List of Machines in Delivery Group

    $BrokerVMs = $delivery_group_machines

    # Get initial Registered VM Count 
    $RegisteredVMCount = ($BrokerVMS | Where-Object { $_.RegistrationState -eq "Registered" } | Measure-Object).Count
    $Start = Get-Date
    
    Write-Log -Message "Waiting for $($PowerOnVMs) VMs to be registered" -Level Info
    #----------------------------------------------------------------------------------------------------------------------------
    # Check that creds aren't expired before proceeding
    #----------------------------------------------------------------------------------------------------------------------------
    $Global:Headers = Get-CVADAuthDetailsAPI -DDC $DDC -EncodedAdminCredential $EncodedAdminCredential -DomainAdminCredential $DomainAdminCredential

    # Set a dummy timespan variable. This will be overwritten in the loop later
    $TS = New-TimeSpan

    while ($true) {
        if ($TS.TotalMinutes -gt 15 -and ($RegisteredVMCount -ne $PowerOnVMs)) {
            Write-Log -Message "$RegisteredVMCount/$PowerOnVMs/$NumberOfVMs (Registered/PowerOnVMs/Total). Sleeping for 120 seconds" -Level Info
            Start-Sleep -Seconds 120
        } else {
            Write-Log -Update -Message "$RegisteredVMCount/$PowerOnVMs/$NumberOfVMs (Registered/PowerOnVMs/Total)" -Level Info
        }
        if ($RegisteredVMCount -eq $PowerOnVMs) {
            #Once this is matched, we are good to go, loop until the registration count is the same as the number of VMs required
            Break
        } 
        else {

            # Get a fresh of the VM count

            #region Get List of Machines in Delivery Group
            #----------------------------------------------------------------------------------------------------------------------------
            # Set API call detail
            #----------------------------------------------------------------------------------------------------------------------------
            $Method = "Get"
            $RequestUri = "https://$DDC/cvad/manage/DeliveryGroups/$($DesktopPoolName)/Machines?limit=1000"
            #----------------------------------------------------------------------------------------------------------------------------
            $delivery_group_machines = @() #Open the array to house the machines

            try {
                # Get the first run of machines
                $delivery_group_machines_grab = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
                
                # Add them to the array
                $delivery_group_machines += $delivery_group_machines_grab.Items
                
                #Check and Set Continuation Token
                try { $continuation_token_exists = $delivery_group_machines_grab.ContinuationToken } catch { $continuation_token_exists = $null }

                # Check for a continuation token (there are more machines to get) and append the token to the next query in a loop, until its no longer there (all machines have been pulled)
                while (-not [string]::IsNullOrEmpty($continuation_token_exists)) {
                    Write-Log -Message "Grabbing next batch of machines using continuation token $($delivery_group_machines_grab.ContinuationToken)" -Level Info
                    #----------------------------------------------------------------------------------------------------------------------------
                    # Set API call detail
                    #----------------------------------------------------------------------------------------------------------------------------
                    $Method = "Get"
                    $RequestUri = "https://$DDC/cvad/manage/DeliveryGroups/$($DesktopPoolName)/Machines?limit=1000&ContinuationToken=$($delivery_group_machines_grab.ContinuationToken)"
                    #----------------------------------------------------------------------------------------------------------------------------
                    try {
                        $delivery_group_machines_grab = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
                    }
                    catch {
                        Write-Log -Message $_ -Level Error
                        Break #Replace with Exit 1
                    }
                    
                    # Add them to the array
                    $delivery_group_machines += $delivery_group_machines_grab.Items

                    #Check and Set Continuation Token
                    try { $continuation_token_exists = $delivery_group_machines_grab.ContinuationToken } catch { $continuation_token_exists = $null }
                }
            }
            catch {
                Write-Log -Message $_ -Level Error
                Break #Replace with Exit 1
            }

            #endregion Get List of Machines in Delivery Group

            $BrokerVMs = $delivery_group_machines

            # get the registered VM Count
            $RegisteredVMCount = ($BrokerVMS | Where-Object { $_.RegistrationState -eq "Registered" } | Measure-Object).Count

            # Start a new timer for controlling how long we wait for things to happen
            $TS = New-TimeSpan -Start $Start -End (Get-Date)

            # If we reach 15 minutes, we are now going to try and fix VMs
            if ($TS.TotalMinutes -gt 15) {
                Write-Log -Message "Not all machines are registered. Checking for machines that failed to boot" -Level Info
                
                # Get a fresh VM Count

                #region Get List of Machines in Delivery Group
                #----------------------------------------------------------------------------------------------------------------------------
                # Set API call detail
                #----------------------------------------------------------------------------------------------------------------------------
                $Method = "Get"
                $RequestUri = "https://$DDC/cvad/manage/DeliveryGroups/$($DesktopPoolName)/Machines?limit=1000"
                #----------------------------------------------------------------------------------------------------------------------------
                #----------------------------------------------------------------------------------------------------------------------------
                # Check that creds aren't expired before proceeding
                #----------------------------------------------------------------------------------------------------------------------------
                $Global:Headers = Get-CVADAuthDetailsAPI -DDC $DDC -EncodedAdminCredential $EncodedAdminCredential -DomainAdminCredential $DomainAdminCredential

                $delivery_group_machines = @() #Open the array to house the machines

                try {
                    # Get the first run of machines
                    $delivery_group_machines_grab = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
                    
                    # Add them to the array
                    $delivery_group_machines += $delivery_group_machines_grab.Items
                    
                    #Check and Set Continuation Token
                    try { $continuation_token_exists = $delivery_group_machines_grab.ContinuationToken } catch { $continuation_token_exists = $null }

                    # Check for a continuation token (there are more machines to get) and append the token to the next query in a loop, until its no longer there (all machines have been pulled)
                    while (-not [string]::IsNullOrEmpty($continuation_token_exists)) {
                        Write-Log -Message "Grabbing next batch of machines using continuation token $($delivery_group_machines_grab.ContinuationToken)" -Level Info
                        #----------------------------------------------------------------------------------------------------------------------------
                        # Set API call detail
                        #----------------------------------------------------------------------------------------------------------------------------
                        $Method = "Get"
                        $RequestUri = "https://$DDC/cvad/manage/DeliveryGroups/$($DesktopPoolName)/Machines?limit=1000&ContinuationToken=$($delivery_group_machines_grab.ContinuationToken)"
                        #----------------------------------------------------------------------------------------------------------------------------
                        try {
                            $delivery_group_machines_grab = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
                        }
                        catch {
                            Write-Log -Message $_ -Level Error
                            Break #Replace with Exit 1
                        }
                        
                        # Add them to the array
                        $delivery_group_machines += $delivery_group_machines_grab.Items

                        #Check and Set Continuation Token
                        try { $continuation_token_exists = $delivery_group_machines_grab.ContinuationToken } catch { $continuation_token_exists = $null }
                    }
                }
                catch {
                    Write-Log -Message $_ -Level Error
                    Break #Replace with Exit 1
                }

                #endregion Get List of Machines in Delivery Group

                $BrokerVMs = $delivery_group_machines

                # If there are more machines in the delivery group than the required number of machines, we grab them all and then filter the first. This gives us a consistent set of machines to play with
                $PoweredOnVMs = $delivery_group_machines | Sort-Object Name | Select-Object -First $PowerOnVMs

                # Now that we have the machines, find which ones are off. They should not be.
                $PowerOnStuckVMs = $PoweredOnVMs | Where-Object {$_.PowerState -eq "Off"}

                # Check for VMs in unknown power state - these might be paused and need to be powered off, and then back on.
                $PowerStateUnknownVMs = $delivery_group_machines | Where-Object {$_.PowerState -eq "Unknown"}

                if ($PowerStateUnknownVMs.Count -gt 0) {
                    Write-Log -Message "There are $($PowerStateUnknownVMs.Count) machines in an unknown power state" -Level Info
                    foreach ($machine_to_target in $PowerStateUnknownVMs) {

                        #----------------------------------------------------------------------------------------------------------------------------
                        # Set API call detail
                        #----------------------------------------------------------------------------------------------------------------------------
                        $Method = "Post"
                        $RequestUri = "https://$DDC/cvad/manage/Machines/$($machine_to_target.Id)/`$shutdown?force=true&detailResponseRequired=false&async=true"
                        #----------------------------------------------------------------------------------------------------------------------------
                        Write-Log -Message "Stopping machine $($machine_to_target.Name) with Id $($machine_to_target.Id)" -Level Info
                        try {
                            $machine_stopped = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
                        }
                        catch {
                            Write-Log -Message $_ -Level Error
                            Exit 1
                        }
    
                        #----------------------------------------------------------------------------------------------------------------------------
                        # Set API call detail
                        #----------------------------------------------------------------------------------------------------------------------------
                        $Method = "Post"
                        $RequestUri = "https://$DDC/cvad/manage/Machines/$($machine_to_target.Id)/`$start?detailResponseRequired=false&async=true"
                        #----------------------------------------------------------------------------------------------------------------------------
                        Write-Log -Message "Powering On machine $($machine_to_target.Name) with Id $($machine_to_target.Id)" -Level Info
                        try {
                            $machine_started = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
                        }
                        catch {
                            Write-Log -Message $_ -Level Error
                            Break #Replace with Exit 1
                        }
                    }
                    Start-Sleep 15
                }

                # get an updated registered VM Count
                $RegisteredVMCount = ($BrokerVMS | Where-Object { $_.RegistrationState -eq "Registered" } | Measure-Object).Count
                
                # If there are more than zero machines, power on each of the VMs that are off, that should have been on
                if ($($PowerOnStuckVMs | Measure-Object).Count -gt 0){
                    Write-Log -Message "Attempting to boot $($($PowerOnStuckVMs | Measure-Object).Count) machines" -Level Info
                    #----------------------------------------------------------------------------------------------------------------------------
                    # Check that creds aren't expired before proceeding
                    #----------------------------------------------------------------------------------------------------------------------------
                    $Global:Headers = Get-CVADAuthDetailsAPI -DDC $DDC -EncodedAdminCredential $EncodedAdminCredential -DomainAdminCredential $DomainAdminCredential

                    foreach ($machine_to_target in $PowerOnStuckVMs) {
                        #----------------------------------------------------------------------------------------------------------------------------
                        # Set API call detail
                        #----------------------------------------------------------------------------------------------------------------------------
                        $Method = "Post"
                        $RequestUri = "https://$DDC/cvad/manage/Machines/$($machine_to_target.Id)/`$start?detailResponseRequired=false&async=true"
                        #----------------------------------------------------------------------------------------------------------------------------

                        Write-Log -Message "Powering On machine $($machine_to_target.Name) with Id $($machine_to_target.Id)" -Level Info
                        try {
                            $machine_started = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
                        }
                        catch {
                            Write-Log -Message $_ -Level Error
                            Break #Replace with Exit 1
                        }
                    }
                    # Now sleep for 2 minutes to wait for them to power one and do their thing. No need to spam for updates
                    #Write-Log -Message "Sleeping for 120 seconds" -Level Info
                    #Start-Sleep -Seconds 120
                }
                else {
                    # This is not great. We now have machines that are powered on (based on their being none in the PowerOnStuckVMs array) but not registered.
                    if ($RegisteredVMCount -ne $PowerOnVMs){
                        Write-Log -Message "There are no machines powered off, but there are still only $($RegisteredVMCount) VMs Registered" -Level Warn
                        
                        #$RegisteredVMCount = ($BrokerVMS | Where-Object { $_.RegistrationState -eq "Registered" } | Measure-Object).Count
                        Write-Log -Update -Message "$RegisteredVMCount/$PowerOnVMs/$NumberOfVMs (Registered/PowerOnVMs/Total)" -Level Info

                        #Find the machines that are Powered On but unregistered, these are not in a happy place
                        $UnregisteredMachines = $BrokerVMs | Where-Object { $_.RegistrationState -eq "Unregistered" -and $_.PowerState -eq "on" }

                        #----------------------------------------------------------------------------------------------------------------------------
                        # Check that creds aren't expired before proceeding
                        #----------------------------------------------------------------------------------------------------------------------------
                        $Global:Headers = Get-CVADAuthDetailsAPI -DDC $DDC -EncodedAdminCredential $EncodedAdminCredential -DomainAdminCredential $DomainAdminCredential

                        # for each of these VMs, force a reboot - this is not a graceful reboot
                        foreach ($machine_to_target in $UnregisteredMachines) {
                            #----------------------------------------------------------------------------------------------------------------------------
                            # Set API call detail
                            #----------------------------------------------------------------------------------------------------------------------------
                            #----------------------------------------------------------------------------------------------------------------------------
                            $Method = "Post"
                            $RequestUri = "https://$DDC/cvad/manage/Machines/$($machine_to_target.Id)/`$reboot?detailResponseRequired=false&async=true&force=true"
                            #----------------------------------------------------------------------------------------------------------------------------
                            Write-Log -Message "Resetting machine $($machine_to_target.Name) with Id $($machine_to_target.Id)" -Level Info
                            try {
                                $machine_reset = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
                            }
                            catch {
                                Write-Log -Message $_ -Level Error
                                Break #Replace with Exit 1
                            }
                        }
                        # Now sleep for 2 minutes to wait for them to power one and do their thing. No need to spam for updates
                        Write-Log -Message "Sleeping for 120 seconds" -Level Info
                        Start-Sleep -Seconds 120
                    }
                    else {
                        Write-Log -Update -Message "$RegisteredVMCount/$PowerOnVMs/$NumberOfVMs (Registered/PowerOnVMs/Total)" -Level Info
                    }
                }
            }
            if ($TS.TotalMinutes -gt $VMRegistrationTimeOutMinutes) {
                Write-Log -Message "VMs failed to register within $($VMRegistrationTimeOutMinutes) minutes" -Level Error
                Break #Replace with Exit 1
            }
            # We have now tried to power on VMs that are off, as well as reset vms that are on, but not registered. Have a quick snooze and then go loop through again
            Start-Sleep 15
        }
    }
    #endregion VDA Registration

    $BootStopwatch.stop()
    $Boot.boottime = $BootStopwatch.elapsed.totalseconds
    $Boot
}