Function Enable-VSICTXDesktopPool {
    Param(
        $DesktopPoolName,
        $NumberOfVMs,
        $ADUserName,
        $ADPassword,
        $PowerOnVMs,
        $VMRegistrationTimeOutMinutes = 180,
        $DDC,
        $HypervisorType,
        $Affinity,
        $ClusterIP,
        $CVMSSHPassword,
        $VMnameprefix,
        $CloneType,
        $Hosts,
        $Type,
        [Parameter(Mandatory = $false)][int]$MaxRecordCount,
        [Parameter(Mandatory = $false)][bool]$ForceAlignVMToHost,
        [Parameter(Mandatory = $false)][bool]$EnforceHostMaintenanceMode,
        [Parameter(Mandatory = $false)][string]$TargetCVMAdmin,
        [Parameter(Mandatory = $false)][string]$TargetCVMPassword,
        [Parameter(Mandatory = $false)][string]$HostCount,
        [Parameter(Mandatory = $false)][string]$Run,
        [Parameter(Mandatory = $false)][string]$VCenter, # for vCenter
        [Parameter(Mandatory = $false)][string]$User, #for vCenter Access
        [Parameter(Mandatory = $false)][string]$password, # for vCenter User
        [Parameter(Mandatory = $false)][string]$ClusterName, # for vCenter Cluster
        [Parameter(Mandatory = $false)][string]$DataCenter # for vCenter Datacenter
    )

    #$MaxRecordCount = "5000"
    $Boot = "" | Select-Object -Property bootstart,boottime

    # Get Auth - Check this Dave!
    if ($Type -eq "CitrixVAD") {
        Get-XDAuthentication -ProfileName ctxonprem -ErrorAction Stop
    }
    if ($Type -eq "CitrixDaaS") {
        # Update this once we figure out the JSON formatting
        Get-XDAuthentication -CustomerID $VSI_Target_CustomerID -BearerToken $token.access_token -ErrorAction Stop
    }
    

    # Power off VMs
    # Replace the Power Actions with Native API NTNX Calls
    $desktops = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName -MaxRecordCount $MaxRecordCount
    $DesktopMeasure = $desktops | Measure-Object
    $totalDesktops = $DesktopMeasure.Count


    $desktopson = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName -MaxRecordCount $MaxRecordCount | Where-Object {$_.PowerState -eq "On"}	
    $DesktopsOnMeasure = $desktopson | Measure-Object

    if(!($DesktopsOnMeasure.Count -eq 0)){
        Start-Sleep 2
        Write-Log -Message "Initiate the shutdown for all the VMs." -Level Info
        foreach ($desktop in $desktopson) { 
            $desktop | New-BrokerHostingPowerAction -Action TurnOff | Out-Null
            #Start-Sleep 1
        }

        $startTime = Get-Date
        $date = Get-Date
        $timeout = 180
        while ($DesktopsOnMeasure.Count -ne 0) {
            $desktopson = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName -MaxRecordCount $MaxRecordCount | Where-Object {$_.PowerState -eq "On"}	
            $DesktopsOnMeasure = $desktopson | Measure-Object
            Write-Log -Update -Message "$($DesktopsOnMeasure.Count) of $($totalDesktops) still running." -Level Info
        
            $date = Get-Date
            if (($date - $startTime).TotalMinutes -gt $timeout) {
                Write-Log -Message "Shutdown took to long." -Level Error
                Exit 1
            }
            Start-Sleep 10
        }
        Write-Log -Message " " -Level Info
        Write-Log -Message "All VMs are down." -Level Info
    } else {
        Write-Log -Message "All VMs are already down." -Level Info
    }

    # End Power off VMs
    if ($CloneType -eq "MCS"){
        $ExistingVMCount = (Get-ProvVM -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName -MaxRecordCount $MaxRecordCount | Measure-Object).Count
    } else {
        $ExistingVMCount = $NumberOfVMs
    }
    #
    
    $NumberOfVMsToProvision = $NumberOfVMs - $ExistingVMCount
    Write-Log -Message "Already $ExistingVMCount VM(s) in $DesktopPoolName" -Level Info
    if ($NumberOfVMsToProvision -gt 0) {
        Write-Log -Message "Starting provisioning of $NumberOfVMsToProvision VM(s) in $DesktopPoolName" -Level Info
        $IdentityPool = Get-AcctIdentityPool -AdminAddress $DDC -IdentityPoolName $DesktopPoolName
        if ($IdentityPool.Lock) { Unlock-AcctIdentityPool -AdminAddress $DDC -IdentityPoolName $DesktopPoolName }

        Write-Log -Message "Creating account(s)... " -Level Info
        if ([string]::isNullOrEmpty($ADUserName)) {
            $adAccounts = New-AcctADAccount -AdminAddress $DDC -Count $NumberOfVMsToProvision -IdentityPoolUid $IdentityPool.IdentityPoolUid.Guid -ErrorAction Stop
        } else {
            $adAccounts = New-AcctADAccount -AdminAddress $DDC -Count $NumberOfVMsToProvision -IdentityPoolUid $IdentityPool.IdentityPoolUid.Guid -ADUsername $ADUserName -ADPassword (Convertto-SecureString -AsPlainText -Force -String $ADPassword) -ErrorAction Stop
        }
        
        Write-Log -Message "Creating the virtual machine(s)... " -Level Info
        #return $adAccounts
        $provTaskId = New-ProvVM -AdminAddress $DDC -AdAccountName $adAccounts.SuccessfulAccounts -ProvisioningSchemeName $DesktopPoolName -RunAsynchronously -ErrorAction Stop
        $provtask = Get-ProvTask -AdminAddress $DDC -TaskId $provTaskId
        $totalpercent = 0
        While ($provtask.Active -eq $true) {
            $totalpercent = If ($provTask.TaskProgress) { $provTask.TaskProgress } else { 0 }
            Write-Log -Update -Message "$totalPercent% Complete:" -Level Info
            Start-Sleep 3
            $provtask = Get-ProvTask -AdminAddress $DDC -TaskId $provTaskId
        }
        Write-Log -Message " " -Level Info
        $ProvSchemeUid = (Get-ProvScheme -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName).ProvisioningSchemeUid.Guid
        $Uid = (Get-BrokerCatalog -AdminAddress $DDC -Name $DesktopPoolName).Uid
        $ProvVMS = Get-ProvVM -AdminAddress $DDC -ProvisioningSchemeUid $ProvSchemeUid -MaxRecordCount $MaxRecordCount | Where-Object { $_.Tag -ne "Brokered" }
        
        Write-Log -Message "Assigning newly created machines to $DesktopPoolName..." -Level Info
        Start-Sleep -Seconds 10 
        
        $count = 0
        Foreach ($VM in $ProvVMS) {            
            $count++
            $VMName = $VM.VMName
            Write-Log -Update -Message "Adding vm $VMName ($count of $NumberOfVMsToProvision) to Catalog and DesktopPool              " -Level Info
            Lock-ProvVM -AdminAddress $DDC -ProvisioningSchemeName $DesktopPoolName -Tag "Brokered" -VMID @($VM.VMId) -ErrorAction Stop
            New-BrokerMachine -AdminAddress $DDC -Cataloguid $Uid -MachineName $VM.ADAccountSid -ErrorAction Stop | Add-BrokerMachine -DesktopGroup $DesktopPoolName -ErrorAction Stop
        }
        Write-Log -Message " " -Level Info
    }
    if ($CloneType -eq "PVS"){
        # add VMs from PVS catalog to delivery group
        Get-BrokerMachine -Filter {CatalogName -eq $DesktopPoolName -and DesktopGroupName -eq $null} -MaxRecordCount $MaxRecordCount | Select-Object -Property MachineName | Add-BrokerMachine -DesktopGroup $DesktopPoolName
    } 
    
    # Set affinity to hosts
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
        }
        Set-NTNXHostAlignment @params
        $Params = $null
    }
    if (($HypervisorType) -eq "ESXi" -and ($ForceAlignVMToHost)) {
        Write-Log "Hypervisortype = $HypervisorType and VM to Host Alignment is set to $($ForceAlignVMToHost)"
        $params = @{
            DDC              = $DDC
            MachineCount     = $NumberOfVMs
            HostCount        = $HostCount
            VCenter          = $VCenter
            User             = $User
            Password         = $Password
            ClusterName      = $ClusterName
            DataCenter       = $DataCenter
            DesktopGroupName = $DesktopPoolName
            Run              = $Run
            MaxRecordCount   = $MaxRecordCount
        }
        
        Set-VMWareHostAlignment @params
        $params = $null
    }

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
    # End set affinity to hosts

    $Boot.bootstart = get-date -format o
    Start-Sleep -Seconds 10
    $BootStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Write-Log -Message "Powering on $PowerOnVMs machines" -Level Info
    $PoweredOnVMs = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName -MaxRecordCount $MaxRecordCount -SortBy MachineName | Select-Object -First $PowerOnVMs
    $SetPowerOnVMs = $PoweredOnVMs | New-BrokerHostingPowerAction -Action TurnOn

    # Wait untill NumberOfVMs matches buffer provided
    $BrokerVMs = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName -MaxRecordCount $MaxRecordCount
    $RegisteredVMCount = ($BrokerVMS | Where-Object { $_.RegistrationState -eq "Registered" } | Measure-Object).Count
    $Start = Get-Date
    Write-Log -Message "Waiting for $PowerOnVMs VMs to be registered" -Level Info
    while ($true) {
        Write-Log -Update -Message "$RegisteredVMCount/$PowerOnVMs/$NumberOfVMs (Registered/PowerOnVMs/Total)" -Level Info
        if ($RegisteredVMCount -eq $PowerOnVMs) {
            Write-Log -Message " " -Level Info
            Break
        } else {          
            $BrokerVMs = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName -MaxRecordCount $MaxRecordCount
            $RegisteredVMCount = ($BrokerVMS | Where-Object { $_.RegistrationState -eq "Registered" } | Measure-Object).Count
            $TS = New-TimeSpan -Start $Start -End (Get-Date)
            if ($TS.TotalMinutes -gt 15) {
                $PoweredOnVMs = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName -MaxRecordCount $MaxRecordCount -SortBy MachineName | Select-Object -First $PowerOnVMs
                $PowerOnStuckVMs = $PoweredOnVMs | Where-Object {$_.PowerState -eq "Off"} | New-BrokerHostingPowerAction -Action TurnOn
                Write-Log -Message "Sleeping for 120 seconds" -Level Info
                Start-Sleep -Seconds 120
            }
            if ($TS.TotalMinutes -gt $VMRegistrationTimeOutMinutes) {
                Write-Log -Message "VMs failed to register within $VMRegistrationTimeOutMinutes minutes" -Level Error
                Exit 1
            }
        }
    }
    $BootStopwatch.stop()
    $Boot.boottime = $BootStopwatch.elapsed.totalseconds
    $Boot
}