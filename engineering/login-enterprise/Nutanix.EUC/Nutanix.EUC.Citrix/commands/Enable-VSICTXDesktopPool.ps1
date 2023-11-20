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
        $Hosts
    )

    $MaxRecordCount = "5000"
    $Boot = "" | Select-Object -Property bootstart,boottime

    # Get Auth - Check this Dave!
    if ($Type -eq "CitrixVAD") {
        Get-XDAuthentication -ProfileName ctxonprem -ErrorAction Stop
    }
    if ($Type -eq "CitrixDaaS") {
        Get-XDAuthentication -CustomerID $CustomerID -BearerToken $token.access_token -ErrorAction Stop
    }
    

    #Power off VMs
    $desktops = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName -MaxRecordCount $MaxRecordCount
    $totalDesktops = (Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName -MaxRecordCount $MaxRecordCount).Count

    Start-Sleep 2
    Write-Log -Message "Initiate the shutdown for all the VMs." -Level Info
    foreach ($desktop in $desktops) { 
        $desktop | New-BrokerHostingPowerAction -Action TurnOff | Out-Null
        #Start-Sleep 1
    }
 
    $desktops = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName -MaxRecordCount $totalDesktops | Where-Object {$_.PowerState -eq "On"}	
  
    $startTime = Get-Date
    $date = Get-Date
    $timeout = 180
    while ($desktops.Count -ne 0) {
        $desktops = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName -MaxRecordCount $totalDesktops | Where-Object {$_.PowerState -eq "On"}	
        Write-Log -Update -Message "$($desktops.Count) of $($totalDesktops) still running." -Level Info
     
        $date = Get-Date
        if (($date - $startTime).TotalMinutes -gt $timeout) {
            Write-Log -Message "Shutdown took to long." -Level Error
            Exit 1
        }
        Start-Sleep 10
    }
    Write-Log -Message " " -Level Info
    Write-Log -Message "All VMs are down." -Level Info

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
    Write-Log "Hypervisortype = $HypervisorType and Affinity is set to $Affinity"
    if (($HypervisorType) -eq "AHV" -And ($Affinity)) {
        Write-Log "Set Affinity to Host with IP $Hosts."
        # Build the command and set affinity using SSH
        $VMs = $VMnameprefix -Replace '#','?'
        $command = "~/bin/acli vm.affinity_set $VMs host_list=$($hosts)"
        $password = ConvertTo-SecureString "$CVMsshpassword" -AsPlainText -Force
        $HostCredential = New-Object System.Management.Automation.PSCredential ("nutanix", $password)
        $session = New-SSHSession -ComputerName $ClusterIP -Credential $HostCredential -AcceptKey -KeepAliveInterval 5
        $SSHOutput = (Invoke-SSHCommand -Index $session.SessionId -Command $command -Timeout 7200).output
        Remove-SSHSession -Name $Session | Out-Null
        Write-Log -Message "Set Affinity Finished." -Level Info
    }

    # End set affinity to hosts
    $Boot.bootstart = get-date -format o
    Start-Sleep -Seconds 10
    $BootStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Write-Log -Message "Powering on $PowerOnVMs machines" -Level Info
    $PoweredOnVMs = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName -MaxRecordCount $MaxRecordCount -SortBy MachineName | Select-Object -Last $PowerOnVMs
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
                $PoweredOnVMs = Get-BrokerMachine -AdminAddress $DDC -DesktopGroupName $DesktopPoolName -MaxRecordCount $MaxRecordCount -SortBy MachineName | Select-Object -Last $PowerOnVMs
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